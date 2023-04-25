import random
from util import CHARACTERISTIC_UUID, UUID, HUB_NAME, APPEARANCE, ADVERTISEMENT_TIME, DOWN_TIME
from bluez_peripheral.util import *
from bluez_peripheral.advert import Advertisement
from bluez_peripheral.gatt.service import Service
from bluez_peripheral.gatt.characteristic import characteristic, CharacteristicFlags as CharFlags
import asyncio
import struct


class MessageService(Service):
    """ Service for sending messages """

    def __init__(self):
        super().__init__(UUID, True)

    @characteristic(CHARACTERISTIC_UUID, CharFlags.NOTIFY)
    def post(self, options):
        """ This function is called when the characteristic is read. """
        pass

    def send_message(self, new_message):
        """ Send the specified message. """
        length = len(new_message)
        message = struct.pack("<" + str(length) + "s", new_message.encode())
        self.post.changed(message)


class Peripheral:
    """ Handles BLE communication as a peripheral. """

    def __init__(self):
        self.posts = None

    def set_posts(self, posts):
        """ Set the posts being sent out over BLE. """
        self.posts = posts

    def advertise(self, quit_event, new_posts_event):
        """ Start advertising the posts. """
        asyncio.run(self.__run(quit_event, new_posts_event))

    async def __run(self, quit_event, new_posts_event):
        bus = await get_message_bus()

        service = MessageService()
        await service.register(bus)

        adapter = await Adapter.get_first(bus)

        # Start an advert that will last for 60 seconds.
        advert = Advertisement(HUB_NAME, [UUID], APPEARANCE, ADVERTISEMENT_TIME)
        await advert.register(bus, adapter)

        while True:
            index = random.randrange(0, len(self.posts))
            while True:
                service.send_message(self.posts[index])
                await asyncio.sleep(DOWN_TIME)
                if quit_event.is_set():
                    break
                if new_posts_event.is_set():
                    new_posts_event.clear()
                    break
            if quit_event.is_set():
                break
