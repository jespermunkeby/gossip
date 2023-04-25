#!/usr/bin/python3
import ble_peripheral
import logging
import post_database
import threading
import logging.config


def init_log():
    logging.basicConfig(level=logging.DEBUG,
                        filename='log.log',
                        format='[%(levelname)s:%(asctime)s] %(message)s')


def update_posts():
    posts = database.get_posts()
    print("* broadcasting: " + str(posts))
    peripheral.set_posts(posts)


def add_post(post):
    database.add_post(post)
    new_posts_event.set()
    update_posts()


print("q: quit, c: clear database, write anything else to add message")
init_log()

quit_event = threading.Event()
new_posts_event = threading.Event()

database = post_database.PostDatabase()

peripheral = ble_peripheral.Peripheral()
update_posts()

peripheral_thread = threading.Thread(target=peripheral.advertise, args=(quit_event, new_posts_event))
peripheral_thread.start()

while True:
    user_input = input()
    if user_input == 'q':
        print("exiting...")
        quit_event.set()
        peripheral_thread.join()
        break
    elif user_input == 'c':
        print("* cleared database")
        database.clear()
    elif user_input != '':
        add_post(user_input)
