#!/usr/bin/python3
from gi.repository import GLib
import bluetooth_constants as bcon
import bluetooth_utils as butil
import util
import dbus
import dbus.mainloop.glib
import numpy
import time
import os
import sys
sys.path.insert(0, '.')


def start_central(store_message_cb, quit_event):
    return lambda: run(store_message_cb, quit_event)

def run(store_message_cb, quit_event):
    props = {'store_message_cb': store_message_cb,
             'quit_event': quit_event}

    initialize(props)
    scan(props)
    props['mainloop'].run()
    #mainloop.quit()
# end run

def initialize(props):
    clear_device_cache()
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    props['mainloop'] = GLib.MainLoop()
    props['bus'] = dbus.SystemBus()
# end init_state

def clear_device_cache():
    for device in os.popen("bluetoothctl devices").read().split('\n')[0:-1]:
        os.system("bluetoothctl remove " + device.split(' ')[1])
# end clear_device_cache

def scan(props):
    if props['quit_event'] != True and props['quit_event'].is_set():
        print('Central exited')
        return True

    props['devices'] = {}
    get_known_devices(props)
    discover_devices(props, 6000)
    print("Scanning...")
# end scan

def connect_and_find_characteristic(props):
        print("Devices found:")
        print(list(props['devices'].keys()))

        if props['devices']:
            props['device_path'], props['device_interface'] = select_random_device(props['bus'], props['devices'])
            
            if connect(props['device_interface']) == bcon.RESULT_OK and props['device_interface'].Connected:
                props['pc_path'] = find_characteristic(props['bus'], props['device_path'])
                if props['pc_path']:
                    wait_for_notifications(props)
                else:
                    listen_for_characteristic(props, wait_for_notifications)
# end connect_and_find_characteristic

def wait_for_notifications(props):
    props['notify_timer_id'] = GLib.timeout_add(7000, lambda: cleanup(props))
    start_notifications(props)
# end wait_for_notifications

def cleanup(props):
    disconnect(props['device_interface'])
    notifications_cleanup(props)
# end cleanup


## -- Functions for discovering devices -- ##
def get_known_devices(props):
    """
    Puts known bluetooth devices (as dBus interfaces) into dictionary 'devices'
    """
    object_manager = dbus.Interface(props['bus'].get_object(bcon.BLUEZ_SERVICE_NAME, "/"), bcon.DBUS_OM_IFACE)
    managed_objects = object_manager.GetManagedObjects()
    for path, interfaces in managed_objects.items():
        interfaces_added(props, path, interfaces)
# end get_known_devices

def interfaces_added(props, path, interfaces):
    """
    Adds discovered bluetooth interface to dictionary 'devices'.
    interfaces is an array of dictionary entries.
    """
    if not bcon.DEVICE_INTERFACE in interfaces:
        return
    device_properties = interfaces[bcon.DEVICE_INTERFACE]
    if path not in props['devices']:
        props['devices'][path] = device_properties
# end interfaces_added


def interfaces_removed(devices, path, interfaces):
    """
    Removes interfaces from dictionary 'devices' if interface no longer available in bluez
    interfaces is an array of dictionary entries
    """
    if not bcon.DEVICE_INTERFACE in interfaces:
        return
    if path in devices:
        del devices[path]
# end interfaces_removed

def discovery_cleanup(props, cb_functions):
    GLib.source_remove(props['scan_timer_id'])
    props['adapter_interface'].StopDiscovery()
    #props['adapter_interface'].SetDiscoveryFilter({})
    props['bus'].remove_signal_receiver(cb_functions['interfaces_added'], "InterfacesAdded")
    props['bus'].remove_signal_receiver(cb_functions['interfaces_removed'], "InterfacesRemoved")
    connect_and_find_characteristic(props)
# end discovery_cleanup

#def discover_devices(bus, devices, t_id_gen, timeout, pgm):
def discover_devices(props, timeout):
    """
    Adds listeners on interfaces and properties to system bus and sets filters.
    """
    adapter_path = bcon.BLUEZ_NAMESPACE + bcon.ADAPTER_NAME
    # acquire an adapter proxy object and its Adapter1 interface so we
    # can call its methods
    adapter_object = props['bus'].get_object(bcon.BLUEZ_SERVICE_NAME, adapter_path)
    props['adapter_interface'] = dbus.Interface(adapter_object, bcon.ADAPTER_INTERFACE)
    
    # register signal handler functions so we can asynchronously report
    # discovered devices
    cb_functions = {}
    
    # InterfaceAdded signal is emitted by BlueZ when an advertising packet
    # from a device it doesn't already know about is received
    cb_functions['interfaces_added'] = lambda x,y: interfaces_added(props, x, y)
    props['bus'].add_signal_receiver(cb_functions['interfaces_added'],
                            dbus_interface = bcon.DBUS_OM_IFACE,
                            signal_name = "InterfacesAdded")

    # InterfacesRemoved signal is emitted by BlueZ when a device "goes away"
    cb_functions['interfaces_removed'] = lambda x,y: interfaces_removed(props['devices'], x, y)
    props['bus'].add_signal_receiver(cb_functions['interfaces_removed'],
                            dbus_interface = bcon.DBUS_OM_IFACE,
                            signal_name = "InterfacesRemoved")
    props['scan_timer_id'] = GLib.timeout_add(timeout,
                                lambda: discovery_cleanup(props, cb_functions))

    props['adapter_interface'].SetDiscoveryFilter({"UUIDs": [util.UUID]})
    props['adapter_interface'].StartDiscovery(byte_arrays=True)
# end discover_devices


def select_random_device(bus, devices):
    index = int(numpy.random.uniform(0, len(devices)))
    device_path = list(devices.keys())[index]
    device_proxy = bus.get_object(bcon.BLUEZ_SERVICE_NAME, device_path)
    return device_path, dbus.Interface(device_proxy, bcon.DEVICE_INTERFACE)
# end select_random_device


def connect(device_interface):
    """
    Establish a connection with the device specified by device_path
    """
    try:
        device_interface.Connect()
    except Exception as e:
        print("Failed to connect")
        print(e.get_dbus_name())
        print(e.get_dbus_message())
        if ("UnknownObject" in e.get_dbus_name()):
            print("Try scanning first to resolve this problem")
        return bcon.RESULT_EXCEPTION
    else:
        print("Connected OK")
        return bcon.RESULT_OK
# end connect

def disconnect(device_interface):
    try:
        device_interface.Disconnect()
    except Exception as e:
        print("Failed to disconnect")
        print(e.get_dbus_name())
        print(e.get_dbus_message())
        return bcon.RESULT_EXCEPTION
    else:
        print("Disconnected OK")
        return bcon.RESULT_OK
# end disconnect
    

def listen_for_characteristic(props, cb):
    props['bus'].add_signal_receiver(lambda x,y: char_interfaces_added(props, cb, x, y),
                            dbus_interface = bcon.DBUS_OM_IFACE,
                            signal_name = "InterfacesAdded")
# end listen_for_characteristic

def find_characteristic(bus, device_path):
    object_manager = dbus.Interface(bus.get_object(bcon.BLUEZ_SERVICE_NAME, "/"),
                                    bcon.DBUS_OM_IFACE)
    managed_objects = object_manager.GetManagedObjects()
    for path in managed_objects:
        characteristic_uuid = managed_objects[path].get('org.bluez.GattCharacteristic1', {}).get('UUID')
        if path.startswith(device_path) and characteristic_uuid == util.CHARACTERISTIC_UUID.casefold():
            return path
# end find_characteristic


def char_interfaces_added(props, cb, path, interfaces):
    """
    Callback for finding gossip transfer characteristic path
    """
    if bcon.GATT_CHARACTERISTIC_INTERFACE in interfaces:
        properties = interfaces[bcon.GATT_CHARACTERISTIC_INTERFACE]
        if 'UUID' in properties and properties['UUID'] == util.CHARACTERISTIC_UUID.casefold():
            print("Found characteristic")
            props['bus'].remove_signal_receiver(char_interfaces_added, "InterfacesAdded")
            props['pc_path'] = path
            cb(props)
# end char_interfaces_added

def start_notifications(props):
    """
    Starts notifications for characteristics by calling StartNotify() method in dBus interface.
    """
    char_proxy = props['bus'].get_object(bcon.BLUEZ_SERVICE_NAME, props['pc_path'])
    char_interface = dbus.Interface(char_proxy, bcon.GATT_CHARACTERISTIC_INTERFACE)
    props['signal_receiver'] = props['bus'].add_signal_receiver(lambda a,b,c,path: post_received(a,b,c,path, props['store_message_cb']),
                                              dbus_interface = bcon.DBUS_PROPERTIES,
                                              signal_name = "PropertiesChanged",
                                              path = props['pc_path'],
                                              path_keyword = "path")
    try:
        char_interface.StartNotify()
    except Exception as e:
        print("Failed to start notifications")
        print(e.get_dbus_name())
        print(e.get_dbus_message())
        result =  bcon.RESULT_EXCEPTION
    else:
        result =  bcon.RESULT_OK
    return result
# end start_notifications

def post_received(interface, changed, invalidated, path, store_message_cb):
    """
    Callback to handle a revieced post notification.
    """
    if 'Value' in changed:
        message = butil.dbus_to_string(changed['Value'])
        print("Received message: ", str(message))
        store_message_cb(message)
# end post_received

def notifications_cleanup(props):
    GLib.source_remove(props['notify_timer_id'])
    props['signal_receiver'].remove()
    print("looping")
    scan(props)
# end notifications_cleanup




if __name__ == "__main__":
    run(print, True)
