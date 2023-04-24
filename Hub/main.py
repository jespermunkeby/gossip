#!/usr/bin/python3
import ble_peripheral
import post_database
import threading

database = post_database.PostDatabase()
posts = database.get_posts()

quit = threading.Event()
peripheral =  ble_peripheral.Peripheral()
peripheral.set_posts(posts)

peripheral_thread = threading.Thread(target=peripheral.advertise, args=(quit,))
peripheral_thread.start()

input() # quit on input
quit.set()
peripheral_thread.join()