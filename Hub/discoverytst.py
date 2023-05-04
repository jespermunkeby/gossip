from gi.repository import GLib
import dbus.mainloop.glib
import dbus
import time
import bluetooth_constants as bc

# Define the bus and object paths
BUS_NAME = 'org.bluez'
ADAPTER_PATH = '/org/bluez/hci0'
DBUS_PROPERTIES="org.freedesktop.DBus.Properties"
DBUS_OM_IFACE = 'org.freedesktop.DBus.ObjectManager'
UUID = "E20A39F4-73F5-4BC4-A12F-17D1AD07A961"
CHARACTERISTIC_UUID = "08590F7E-DB05-467E-8757-72F6FAEB13D4"
#DEVICE_PATH = f'/org/bluez/hci0/dev_{DEVICE_ADDRESS.replace(":", "_")}'

devices = {}
# Set GLib mainloop
dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
# Create a new session bus
bus = dbus.SystemBus()



mainloop = GLib.MainLoop()

# Get the adapter object
adapter = bus.get_object(BUS_NAME, ADAPTER_PATH)

adapter_iface = dbus.Interface(adapter, dbus_interface=BUS_NAME + '.Adapter1')

def device_discovered(path, interfaces):
    device = bus.get_object(BUS_NAME, path)
    device_iface = dbus.Interface(device, dbus_interface=BUS_NAME + '.Device1')
    device_iface.Connect()
    service = device_iface.GetService(UUID)
    # Get the GATT characteristic object
    characteristic = bus.get_object(bc.BLUEZ_SERVICE_NAME, path)
    # Enable notifications on the characteristic
    characteristic_iface = dbus.Interface(characteristic, dbus_interface=BUS_NAME + '.GattCharacteristic1')
    characteristic_iface.StartNotify()
    print("hello")
    # Wait for notifications to be received
    time.sleep(10)

    # Disable notifications on the characteristic
    characteristic_iface.StopNotify()


#add signal receiver on discovered devices
bus.add_signal_receiver(device_discovered,
                                dbus_interface = DBUS_OM_IFACE,
                                signal_name = "InterfacesAdded")



# Set discovery filter to filter on UUIDs
adapter_iface.SetDiscoveryFilter({"UUIDs" : [UUID]})


#mainloop.quit()
# Start scanning for BLE devices
adapter_iface.StartDiscovery()

mainloop.run()
# Wait for a few seconds for devices to be discovered

# Stop scanning for devices
adapter_iface.StopDiscovery()

