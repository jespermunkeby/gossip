#!/usr/bin/python3

from bluez_peripheral.util import *
from bluez_peripheral.advert import Advertisement
from bluez_peripheral.agent import NoIoAgent
from bluez_peripheral.gatt.service import Service
from bluez_peripheral.gatt.characteristic import characteristic, CharacteristicFlags as CharFlags
import asyncio
import time

import struct

UUID = "E20A39F4-73F5-4BC4-A12F-17D1AD07A961"
CHARACTERISTIC_UUID = "08590F7E-DB05-467E-8757-72F6FAEB13D4"

class HeartRateService(Service):
    def __init__(self):
        # Base 16 service UUID, This should be a primary service.
        # super().__init__("180D", True)
        super().__init__(UUID, True)

    @characteristic(CHARACTERISTIC_UUID, CharFlags.NOTIFY)
    def heart_rate_measurement(self, options):
        # This function is called when the characteristic is read.
        # Since this characteristic is notify only this function is a placeholder.
        # You don't need this function Python 3.9+ (See PEP 614).
        # You can generally ignore the options argument
        # (see Advanced Characteristics and Descriptors Documentation).
        pass

    def update_heart_rate(self, new_rate):
        # Call this when you get a new heartrate reading.
        # Note that notification is asynchronous (you must await something at some point after calling this).
        # flags = 0

        # Bluetooth data is little endian.
        rate = struct.pack("<512s", new_rate)
        self.heart_rate_measurement.changed(rate)
        time.sleep(5)

    def end_of_msg(self):
        rate = struct.pack("<3s", "EOM".encode())
        self.heart_rate_measurement.changed(rate)

async def main():
    # Alternativly you can request this bus directly from dbus_next.
    bus = await get_message_bus()

    service = HeartRateService()
    await service.register(bus)

    # An agent is required to handle pairing
    agent = NoIoAgent()
    # This script needs superuser for this to work.
    await agent.register(bus)

    adapter = await Adapter.get_first(bus)

    # Start an advert that will last for 60 seconds.
    advert = Advertisement("P2P GOSSIP", [UUID], 0x0, 60*120)
    await advert.register(bus, adapter)

    while True:
        # Update the heart rate.
        service.update_heart_rate(("H"*500 + "a"*12).encode())
        # Handle dbus requests..
        await asyncio.sleep(5)
        service.end_of_msg()
        # Handle dbus requests..
        await asyncio.sleep(5)


    await bus.wait_for_disconnect()

if __name__ == "__main__":
    asyncio.run(main())
