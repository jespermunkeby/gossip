
from discovery_filter import filter_devices
from time import sleep
from datetime import datetime
import dbus
from gi.repository import Gio, GLib


UUID = "E20A39F4-73F5-4BC4-A12F-17D1AD07A961"
CHARACTERISTIC_UUID = "08590F7E-DB05-467E-8757-72F6FAEB13D4"


bus_type = Gio.BusType.SYSTEM
BLUEZ_NAME = 'org.bluez'
ADAPTER_PATH = '/org/bluez/hci0'
BLUEZ_ADAPTER = "org.bluez.Adapter1"
MNGR_IFACE = 'org.freedesktop.DBus.ObjectManager'
PROP_IFACE = 'org.freedesktop.DBus.Properties'
DEVICE_IFACE = 'org.bluez.Device1'
BLE_CHRC_IFACE = 'org.bluez.GattCharacteristic1'

def bluez_proxy(object_path, interface):
    return Gio.DBusProxy.new_for_bus_sync(
        bus_type=bus_type,
        flags=Gio.DBusProxyFlags.NONE,
        info=None,
        name=BLUEZ_NAME,
        object_path=object_path,
        interface_name=interface,
        cancellable=None)

#start discovery
adapter = bluez_proxy(ADAPTER_PATH, BLUEZ_ADAPTER)
adapter.StartDiscovery()
sleep(5)
gossip_devices = filter_devices(UUID)

device_path = gossip_devices[1]
# setup dbus
mngr = bluez_proxy('/', MNGR_IFACE)
device = bluez_proxy(device_path, DEVICE_IFACE)
dev_props = bluez_proxy(device_path, PROP_IFACE)

# Connect to device
device.Connect()