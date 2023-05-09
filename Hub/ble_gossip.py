from dbus_to_python import dbus_to_python
from discovery_filter import filter_devices
from time import sleep
import dbus
from gi.repository import Gio, GLib

BLUEZ_SERVICE_NAME = "org.bluez"
BLUEZ_ADAPTER = "org.bluez.Adapter1"
BLUEZ_DEVICE = "org.bluez.Device1"
BLUEZ_GATT_CHRC = "org.bluez.GattCharacteristic1"
ADAPTER_PATH = "/org/bluez/hci0"

UUID = "E20A39F4-73F5-4BC4-A12F-17D1AD07A961"
CHARACTERISTIC_UUID = "08590F7E-DB05-467E-8757-72F6FAEB13D4"


bus = dbus.SystemBus()


def get_managed_objects():
    """
    Return the objects currently managed by the D-Bus Object Manager for BlueZ.
    """
    manager = dbus.Interface(
        bus.get_object(BLUEZ_SERVICE_NAME, "/"),
        "org.freedesktop.DBus.ObjectManager"
    )
    return manager.GetManagedObjects()


def gatt_chrc_path(uuid, path_start="/"):
    """
    Find the D-Bus path for a GATT Characteristic of given uuid.
    Use `path_start` to ensure it is on the correct device or service
    """
    for path, info in get_managed_objects().items():
        found_uuid = info.get(BLUEZ_GATT_CHRC, {}).get("UUID", "")
        if all((uuid.casefold() == found_uuid.casefold(),
                path.startswith(path_start))):
            return path
    return None


class BluezProxy(dbus.proxies.Interface):
    """
        A proxy to the remote Object. A ProxyObject is provided so functions
        can be called like normal Python objects.
     """
    def __init__(self, dbus_path, interface):
        self.dbus_object = bus.get_object(BLUEZ_SERVICE_NAME, dbus_path)
        self.prop_iface = dbus.Interface(self.dbus_object,
                                         dbus.PROPERTIES_IFACE)
        super().__init__(self.dbus_object, interface)

    def get_all(self):
        """Return all properties on Interface"""
        return dbus_to_python(self.prop_iface.GetAll(self.dbus_interface))

    def get(self, prop_name, default=None):
        """Access properties on the interface"""
        try:
            value = self.prop_iface.Get(self.dbus_interface, prop_name)
        except dbus.exceptions.DBusException:
            return default
        return dbus_to_python(value)
    

#def main():
adapter = BluezProxy(ADAPTER_PATH, BLUEZ_ADAPTER)
adapter.StartDiscovery()
sleep(5)
gossip_devices = filter_devices(UUID)
for device_path in gossip_devices:
    device = BluezProxy(device_path, BLUEZ_DEVICE) 
    device.Connect()
    while not device.get("ServicesResolved"):
        sleep(0.5)
    message_characteristic_path = gatt_chrc_path(CHARACTERISTIC_UUID, device.object_path)
    message_characteristic_proxy = BluezProxy(message_characteristic_path, BLUEZ_GATT_CHRC)

    message_characteristic_proxy.StartNotify()
    device.Disconnect()
        
