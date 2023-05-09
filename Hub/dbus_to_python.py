import dbus

def dbus_to_python(data):
    """convert D-Bus data types to python data types"""
    if isinstance(data, dbus.String):
        data = str(data)
    elif isinstance(data, dbus.Boolean):
        data = bool(data)
    elif isinstance(data, dbus.Byte):
        data = int(data)
    elif isinstance(data, dbus.UInt16):
        data = int(data)
    elif isinstance(data, dbus.UInt32):
        data = int(data)
    elif isinstance(data, dbus.Int64):
        data = int(data)
    elif isinstance(data, dbus.Double):
        data = float(data)
    elif isinstance(data, dbus.ObjectPath):
        data = str(data)
    elif isinstance(data, dbus.Array):
        if data.signature == dbus.Signature('y'):
            data = bytearray(data)
        else:
            data = [dbus_to_python(value) for value in data]
    elif isinstance(data, dbus.Dictionary):
        new_data = dict()
        for key in data:
            new_data[dbus_to_python(key)] = dbus_to_python(data[key])
        data = new_data
    return data