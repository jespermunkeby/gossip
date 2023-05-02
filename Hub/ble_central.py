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
    """
    Handles BLE communication as central. 
    Discover, filter, connects and disconnects to devices 
    """
    def __init__(self, store_message_cb):
        """
        Iniitialize class. Sets mainloop to Glib, 
        bus to SystemBus and sets event handler from argument
        """
        dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
        self.bus = dbus.SystemBus()
        self.store_message_cb = store_message_cb
    # end __init__
    
    def select_random_device(self, devices):
        """
        Selects a random device from the dictionary of found devices 
        and returns the device path and the dBus interface object
        """
        index = int(numpy.random.uniform(0, len(devices)))
        device_path = list(devices.keys())[index]
        device_proxy = self.bus.get_object(bc.BLUEZ_SERVICE_NAME, device_path)
        device_interface = dbus.Interface(device_proxy, bc.DEVICE_INTERFACE)
        return device_path, device_interface
    # end select_random_device

    def scan(self):
        """
        Scanning for devices with UUID filter. 
        """
        scan = Scan(self.bus)
        scan.get_known_devices() # Is needed because bluez remembers found devices for an amount of time.
        scan.discover_devices(util.DEFAULT_SCANTIME_MS) 
        print("Devices found:")
        print(list(scan.devices.keys()))
        return scan.get_devices()

    # -- loop for running the program -- #
    def run(self):
        while True:
            print("Scanning for devices...")
            devices = self.scan()
            if (devices):
                path, interface = self.select_random_device(devices)
                print("Connecting")
                connection = Connection(path, interface)

                if connection.connect() == bc.RESULT_OK:
                    nh = NotificationHandler(self.bus, path, self.store_message_cb)
                    nh.listen_for_notifications(util.CENTRAL_LISTEN_TIME)
                
                print("Disconnecting")
                connection.disconnect()

            time.sleep(util.CENTRAL_IDLE_TIME)
    # end run


class Scan:
    """
    Contains methods for device discovery.
    """
    def __init__(self, bus):
        """
        Creates an empty dictionary for found devices and class variables.
        """
        self.bus = bus
        self.devices = {}
        self.adapter_interface = None
        self.mainloop = None

    def get_devices(self):
        """
        Returns true if any devices has been found.
        """
        return self.devices

    def get_known_devices(self):
        """
        Puts known dBus interfaces that are bluetooth devices into device dictionary
        """
        object_manager = dbus.Interface(self.bus.get_object(bc.BLUEZ_SERVICE_NAME, "/"), bc.DBUS_OM_IFACE)
        managed_objects = object_manager.GetManagedObjects()

        for path, ifaces in managed_objects.items():
            for iface_name in ifaces:
                if iface_name == bc.DEVICE_INTERFACE:
                    device_properties = ifaces[bc.DEVICE_INTERFACE]
                    self.devices[path] = device_properties
    # end get_known_devices

    def interfaces_added(self, path, interfaces):
        """ 
        Adds interfaces to device dictionary. Interfaces is an array of dictionary entries
        """
        if not bc.DEVICE_INTERFACE in interfaces:
            return
        device_properties = interfaces[bc.DEVICE_INTERFACE]
        if path not in self.devices:
            self.devices[path] = device_properties
    # end interfaces_added

    def properties_changed(self, interface, changed, invalidated, path):
        """
        Updates properties of local isntances of devices.
        """
        if interface != bc.DEVICE_INTERFACE:
            return
        if path in self.devices:
            self.devices[path] = dict(self.devices[path].items())
            self.devices[path].update(changed.items())
        else:
            self.devices[path] = changed
    # end properties_changed

    def interfaces_removed(self, path, interfaces):
        """
        Removes local instances of device if device no longer available in bluez.
        """
        # interfaces is an array of dictionary entries
        if not bc.DEVICE_INTERFACE in interfaces:
            return
        if path in self.devices:
            del self.devices[path]
    # end interfaces_removed

    def discovery_cleanup(self):
        """
        Removes listener and resets filters and timers and exits event loop.
        """
        GLib.source_remove(self.timer_id)
        self.mainloop.quit()
        self.adapter_interface.StopDiscovery()
        self.bus.remove_signal_receiver(self.interfaces_added, "InterfacesAdded")
        self.bus.remove_signal_receiver(self.interfaces_added, "InterfacesRemoved")
        self.bus.remove_signal_receiver(self.properties_changed, "PropertiesChanged")
        self.adapter_interface.SetDiscoveryFilter({})
        return True
    # end discovery_cleanup

    def discover_devices(self, timeout):
        """
        Adds listeners on interfaces and properties to system bus 
        then sets filters and starts eventloop mainloop. 
        """
        adapter_path = bc.BLUEZ_NAMESPACE + bc.ADAPTER_NAME
        # acquire an adapter proxy object and is Adapter1 interface so we
        # can call its methods
        adapter_object = self.bus.get_object(bc.BLUEZ_SERVICE_NAME, adapter_path)
        self.adapter_interface = dbus.Interface(adapter_object, bc.ADAPTER_INTERFACE)
    
        # register signal handler functions so we can asynchronously report
        # discovered devices
    
        # InterfaceAdded signal is emitted by BlueZ when an advertising packet
        # from a device it doesn't already know about is received
        self.bus.add_signal_receiver(self.interfaces_added,
                                dbus_interface = bc.DBUS_OM_IFACE,
                                signal_name = "InterfacesAdded")
    
        # InterfacesRemoved signal is emitted by BlueZ when a device "goes away"
        self.bus.add_signal_receiver(self.interfaces_removed,
                                dbus_interface = bc.DBUS_OM_IFACE,
                                signal_name = "InterfacesRemoved")
    
        # PropertiesChanged signal is emitted by BlueZ when a device already
        # encountered changes e.g. the RSSI value
        self.bus.add_signal_receiver(self.properties_changed,
                                dbus_interface = bc.DBUS_PROPERTIES,
                                signal_name = "PropertiesChanged",
                                path_keyword = "path")
    
        self.mainloop = GLib.MainLoop()
        self.timer_id = GLib.timeout_add(timeout, self.discovery_cleanup)
        self.adapter_interface.SetDiscoveryFilter({"UUIDs" : [util.UUID]})
        self.adapter_interface.StartDiscovery(byte_arrays=True)
    
        self.mainloop.run()
    # end discover_devices

# end of Scan class

class Connection:
    """ 
    Methods for connecting/disconnecting 
    """
    def __init__(self, device_path, device_interface):
        self.device_path = device_path
        self.device_interface = device_interface



    def connect(self):
        """
        Establish a connection with the device specified by device_path
        """
        if not self.device_interface:
            return bc.RESULT_ERR_NOT_FOUND
        try:
            print(self.device_path)
            self.device_interface.Connect() #calls method Connect from dBus object
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
        """
        Disconnects from the connected device
        """
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

class NotificationHandler:
    """
    Methods for receiving notifications
    """
    def __init__(self, bus, device_path, store_message_cb):
        self.bus = bus
        self.device_path = device_path
        self.store_message_cb = store_message_cb
        self.mainloop = GLib.MainLoop()

        self.char_interface = None
        self.signal_receiver = None
        self.timer_id = None
        self.pc_path = self.get_char_address()

    def listen_for_notifications(self, timeout):
        """ 
        Setup and handling of notifications. 
        cleanup of notifications after certain time interval 
        """
        print("Listening for notifications...")
        if self.pc_path:
            self.start_notifications()
        else:
            self.bus.add_signal_receiver(self.char_interfaces_added,
                                dbus_interface = bc.DBUS_OM_IFACE,
                                signal_name = "InterfacesAdded")
        self.timer_id = GLib.timeout_add(timeout, self.notifications_cleanup)
        self.mainloop.run()
    # end listen_for_notifications

    def get_char_address(self):
        """
        Returns path to message transfer characteristic filtered on UUID
        """
        object_manager = dbus.Interface(self.bus.get_object(bc.BLUEZ_SERVICE_NAME, "/"), bc.DBUS_OM_IFACE)
        managed_objects = object_manager.GetManagedObjects()
        for path in managed_objects:
            chr_uuid = managed_objects[path].get('org.bluez.GattCharacteristic1', {}).get('UUID')
            if path.startswith(self.device_path) and chr_uuid == util.CHARACTERISTIC_UUID.casefold():
                print(path)
                return path
    # end get_char_address

    def char_interfaces_added(self, path, interfaces):
        """
        Callback for finding gossip transfer characteristic path
        """
        if bc.GATT_CHARACTERISTIC_INTERFACE in interfaces:
            properties = interfaces[bc.GATT_CHARACTERISTIC_INTERFACE]
            if 'UUID' in properties:
                if properties['UUID'] == util.CHARACTERISTIC_UUID.casefold():
                    print("P2P Gossip characteristic found")
                    self.pc_path = path
                    self.bus.remove_signal_receiver(self.char_interfaces_added, "InterfacesAdded")
                    self.start_notifications()
    # end char_interfaces_added

    def start_notifications(self):
        """
        Starts notifications for characteristics by calling StartNotify() method in dBus interface.
        """
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
        """
        Callback to handle a revieced post notification.
        """
        if 'Value' in changed:
            message = butil.dbus_to_string(changed['Value'])
            print("Message: " + str(message))
            self.store_message_cb(message)
    # end post_rcvd

    def notifications_cleanup(self):
        """
        Closes mainloop and removes listeners.
        """
        GLib.source_remove(self.timer_id)
        self.mainloop.quit()
        self.signal_receiver.remove()
        if self.char_interface:
            self.char_interface.StopNotify()
    # end notifications_cleanup


if __name__ == "__main__":
    central = Central(print)
    central.run()
