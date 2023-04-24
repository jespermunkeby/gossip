from util import CHARACTERISTIC_UUID, UUID, HUB_NAME, APPEARANCE, ADVERTISEMENT_TIME, DOWN_TIME
from bluez_peripheral.util import *
from bluez_peripheral.advert import Advertisement
from bluez_peripheral.gatt.service import Service
from bluez_peripheral.gatt.characteristic import characteristic, CharacteristicFlags as CharFlags
import asyncio
import threading
import struct

class MessageService(Service):
    def __init__(self):
        # Base 16 service UUID, This should be a primary service.
        super().__init__(UUID, True)

    @characteristic(CHARACTERISTIC_UUID, CharFlags.NOTIFY)
    def post(self, options):
        # This function is called when the characteristic is read.
        # Since this characteristic is notify only this function is a placeholder.
        pass

    def send_message(self, new_message):
        length = len(new_message)
        message = struct.pack("<" + str(length) + "s", new_message.encode())
        self.post.changed(message)
        

class Peripheral:

    def set_posts(self, posts):
        self.posts = posts

    def advertise(self, quit):
        asyncio.run(self.__run(quit))

    async def __run(self, quit):
        bus = await get_message_bus()

        service = MessageService()
        await service.register(bus)

        adapter = await Adapter.get_first(bus)

        # Start an advert that will last for 60 seconds.
        advert = Advertisement(HUB_NAME, [UUID], APPEARANCE, ADVERTISEMENT_TIME)
        await advert.register(bus, adapter)

        while True:
            for message in self.posts:
                service.send_message(message) # Send a message
                if(quit.is_set()):
                    break
                await asyncio.sleep(DOWN_TIME)