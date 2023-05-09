import dbus

def filter_devices(uuid):
    # Create a dictionary to store the filtered devices
    filtered_devices = {}

    # Connect to the system bus
    bus = dbus.SystemBus()

    # Get the Bluetooth adapter object
    manager_object = bus.get_object('org.bluez', '/')
    manager_interface = dbus.Interface(manager_object, 'org.freedesktop.DBus.ObjectManager')
    objects = manager_interface.GetManagedObjects()

    for path, interfaces in objects.items():
        # Check if the object represents a Bluetooth device
        if 'org.bluez.Device1' in interfaces:
            device_props = interfaces['org.bluez.Device1']

            # Check if the device supports the desired UUID
            if uuid in device_props.get('UUIDs', []):
                # Store the device information in the dictionary
                filtered_devices[path] = device_props
                # Get the device name
                #device_name = device_props['Name']

                # Store the device information in the dictionary
                #filtered_devices[path] = {'Name': device_name}
                

    return filtered_devices
