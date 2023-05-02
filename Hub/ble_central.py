#!/usr/bin/python3
from gi.repository import GLib
import bluetooth_constants as bc
import bluetooth_utils as butil
import util
import dbus
import dbus.mainloop.glib
import numpy
import time
import sys
sys.path.insert(0, '.')

class Central:
    def __init__(self, store_message_cb):
        dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
        self.bus = dbus.SystemBus()
        self.store_message_cb = store_message_cb
    # end __init__
        
    # -- Methods for discovering -- #
    def scan(self, scantime=util.DEFAULT_SCANTIME_MS):
        self.devices = {}
        self.device_interface = None
        self.device_path = None

        self.scantime = scantime
        self.get_known_devices(self.bus)
        self.discover_devices(self.bus, scantime)
        print("Devices found:")
        print(list(self.devices.keys()))
        return len(self.devices) > 0
    # end scan

    def get_known_devices(self, bus):
        object_manager = dbus.Interface(bus.get_object(bc.BLUEZ_SERVICE_NAME, "/"), bc.DBUS_OM_IFACE)
        managed_objects = object_manager.GetManagedObjects()

        for path, ifaces in managed_objects.items():
            for iface_name in ifaces:
                if iface_name == bc.DEVICE_INTERFACE:
                    device_properties = ifaces[bc.DEVICE_INTERFACE]
                    self.devices[path] = device_properties
    # end get_known_devices

    def interfaces_added(self, path, interfaces):
        # interfaces is an array of dictionary entries
        if not bc.DEVICE_INTERFACE in interfaces:
            return
        device_properties = interfaces[bc.DEVICE_INTERFACE]
        if path not in self.devices:
            self.devices[path] = device_properties
    # end interfaces_added

    def properties_changed(self, interface, changed, invalidated, path):
        if interface != bc.DEVICE_INTERFACE:
            return
        if path in self.devices:
            self.devices[path] = dict(self.devices[path].items())
            self.devices[path].update(changed.items())
        else:
            self.devices[path] = changed
    # end properties_changed

    def interfaces_removed(self, path, interfaces):
        # interfaces is an array of dictionary entries
        if not bc.DEVICE_INTERFACE in interfaces:
            return
        if path in self.devices:
            del self.devices[path]
    # end interfaces_removed

    def discovery_cleanup(self):
        GLib.source_remove(self.timer_id)
        self.mainloop.quit()
        self.adapter_interface.StopDiscovery()
        self.bus.remove_signal_receiver(self.interfaces_added, "InterfacesAdded")
        self.bus.remove_signal_receiver(self.interfaces_added, "InterfacesRemoved")
        self.bus.remove_signal_receiver(self.properties_changed, "PropertiesChanged")
        self.adapter_interface.SetDiscoveryFilter({})
        return True
    # end discovery_cleanup

    def discover_devices(self, bus, timeout):
        adapter_path = bc.BLUEZ_NAMESPACE + bc.ADAPTER_NAME
        # acquire an adapter proxy object and is Adapter1 interface so we
        # can call its methods
        adapter_object = bus.get_object(bc.BLUEZ_SERVICE_NAME, adapter_path)
        self.adapter_interface = dbus.Interface(adapter_object, bc.ADAPTER_INTERFACE)
    
        # register signal handler functions so we can asynchronously report
        # discovered devices
    
        # InterfaceAdded signal is emitted by BlueZ when an advertising packet
        # from a device it doesn't already know about is received
        bus.add_signal_receiver(self.interfaces_added,
                                dbus_interface = bc.DBUS_OM_IFACE,
                                signal_name = "InterfacesAdded")
    
        # InterfacesRemoved signal is emitted by BlueZ when a device "goes away"
        bus.add_signal_receiver(self.interfaces_removed,
                                dbus_interface = bc.DBUS_OM_IFACE,
                                signal_name = "InterfacesRemoved")
    
        # PropertiesChanged signal is emitted by BlueZ when a device already
        # encountered changes e.g. the RSSI value
        bus.add_signal_receiver(self.properties_changed,
                                dbus_interface = bc.DBUS_PROPERTIES,
                                signal_name = "PropertiesChanged",
                                path_keyword = "path")
    
        self.mainloop = GLib.MainLoop()
        self.timer_id = GLib.timeout_add(timeout, self.discovery_cleanup)
        self.adapter_interface.SetDiscoveryFilter({"UUIDs" : [util.UUID]})
        self.adapter_interface.StartDiscovery(byte_arrays=True)
    
        self.mainloop.run()
    # end discover_devices

    # -- Methods for connecting/disconnecting -- #
    def connect(self):
        if not self.device_interface:
            return bc.RESULT_ERR_NOT_FOUND
        try:
            self.device_interface.Connect()
        except Exception as e:
            print("Failed to connect")
            print(e.get_dbus_name())
            print(e.get_dbus_message())
            if ("UnknownObject" in e.get_dbus_name()):
                print("Try scanning first to resolve this problem")
            return bc.RESULT_EXCEPTION
        else:
            print("Connected OK")
            return bc.RESULT_OK
    # end connect

    def disconnect(self):
        if not self.device_interface:
            return bc.RESULT_ERR_NOT_FOUND
        try:
            self.device_interface.Disconnect()
        except Exception as e:
            print("Failed to disconnect")
            print(e.get_dbus_name())
            print(e.get_dbus_message())
            return bc.RESULT_EXCEPTION
        else:
            print("Disconnected OK")
            return bc.RESULT_OK
    # end disconnect

    def select_random_device(self):
        if len(self.devices) < 1:
            print("No device found")
            return bc.RESULT_EXCEPTION
        index = int(numpy.random.uniform(0, len(self.devices)))
        self.device_path = list(self.devices.keys())[index]
        device_proxy = self.bus.get_object(bc.BLUEZ_SERVICE_NAME, self.device_path)
        self.device_interface = dbus.Interface(device_proxy, bc.DEVICE_INTERFACE)
    # end select_random_device

    # -- Methods for receiving notifications -- #
    def listen_for_notifications(self, timeout):
        self.char_interface = None
        self.signal_receiver = None
        print("Listening for notifications...")

        self.pc_path = self.get_char_address()
        if self.pc_path:
            self.listening_for_characteristic = False
            self.start_notifications()
        else:
            self.bus.add_signal_receiver(self.char_interfaces_added,
                                dbus_interface = bc.DBUS_OM_IFACE,
                                signal_name = "InterfacesAdded")
            self.listening_for_characteristic = True
        self.timer_id = GLib.timeout_add(timeout, self.notifications_cleanup)
        self.mainloop.run()
    # end listen_for_notifications

    def get_char_address(self):
        object_manager = dbus.Interface(self.bus.get_object(bc.BLUEZ_SERVICE_NAME, "/"), bc.DBUS_OM_IFACE)
        managed_objects = object_manager.GetManagedObjects()
        for path in managed_objects:
            chr_uuid = managed_objects[path].get('org.bluez.GattCharacteristic1', {}).get('UUID')
            if path.startswith(self.device_path) and chr_uuid == util.CHARACTERISTIC_UUID.casefold():
                print(path)
                return path
    # end get_char_address

    def char_interfaces_added(self, path, interfaces):
        # code for finding gossip transfer characteristic path
        if bc.GATT_CHARACTERISTIC_INTERFACE in interfaces:
            properties = interfaces[bc.GATT_CHARACTERISTIC_INTERFACE]
            if 'UUID' in properties:
                if properties['UUID'] == util.CHARACTERISTIC_UUID.casefold():
                    print("P2P Gossip characteristic found")
                    self.pc_path = path
                    self.start_notifications()
    # end char_interfaces_added

    def start_notifications(self):
        print ("P2P Gossip characteristic path:", self.pc_path)
        char_proxy = self.bus.get_object(bc.BLUEZ_SERVICE_NAME, self.pc_path)
        self.char_interface = dbus.Interface(char_proxy, bc.GATT_CHARACTERISTIC_INTERFACE)
        self.signal_receiver = self.bus.add_signal_receiver(self.post_rcvd,
                dbus_interface = bc.DBUS_PROPERTIES,
                signal_name = "PropertiesChanged",
                path = self.pc_path,
                path_keyword = "path")

        try:
            print("Start notifications")
            self.char_interface.StartNotify()
            print("Done starting notifications")
        except Exception as e:
            print("Failed to start notifications")
            print(e.get_dbus_name())
            print(e.get_dbus_message())
            return bc.RESULT_EXCEPTION
        else:
            return bc.RESULT_OK
    # end start_notify

    def post_rcvd(self, interface, changed, invalidated, path):
        if 'Value' in changed:
            message = butil.dbus_to_string(changed['Value'])
            print("Message: " + str(message))
            self.store_message_cb(message)
    # end post_rcvd

    def notifications_cleanup(self):
        GLib.source_remove(self.timer_id)
        self.mainloop.quit()
        #self.bus.remove_signal_receiver(self.post_rcvd,
        #        dbus_interface = bc.DBUS_PROPERTIES,
        #        signal_name = "PropertiesChanged",
        #        path = self.pc_path,
        #        path_keyword = "path")
        self.signal_receiver.remove()

        #self.bus.remove_signal_receiver(self.post_rcvd, "PropertiesChanged")
        if self.listening_for_characteristic:
            self.bus.remove_signal_receiver(self.char_interfaces_added, "InterfacesAdded")
        if self.char_interface:
            self.char_interface.StopNotify()
    # end notifications_cleanup

    # -- loop for running the program -- #
    def run(self):
        while True:
            print("Scanning for devices...")
            if (self.scan()):
                self.select_random_device()
                print("Connecting")
                if self.connect() == bc.RESULT_OK:
                    self.listen_for_notifications(util.CENTRAL_LISTEN_TIME)
                    print("Disconnecting")
                    self.disconnect()
            time.sleep(util.CENTRAL_IDLE_TIME)
    # end run


if __name__ == "__main__":
    central = Central(print)
    central.run()
