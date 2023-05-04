#!/usr/bin/python3
import ble_peripheral
import ble_central
import logging
import post_database
import threading
import logging.config
from logging.handlers import RotatingFileHandler
import os


def init_log():  # adapted from https://stackoverflow.com/a/56369583
    """ Initializes logging. Should only be called once. """
    logging.basicConfig(
        handlers=[RotatingFileHandler('.hub_log.log', maxBytes=100000, backupCount=1)],
        level=logging.DEBUG,
        format="[%(asctime)s] %(levelname)s [%(name)s.%(funcName)s:%(lineno)d] %(message)s",
        datefmt='%Y-%m-%d %H:%M:%S')


def update_posts():
    """ Reads posts from the database, and updates peripheral to broadcast those posts. """
    posts = database.get_posts()
    print("* broadcasting: " + str(posts))
    peripheral.set_posts(posts)
    new_posts_event.set()


def add_post(post):
    """ Adds post to database and calls update_posts(). """
    database.add_post(post)
    update_posts()


os.system("sudo systemctl restart bluetooth")
# https://man.archlinux.org/man/bt-agent.1.en
#os.system("bt-agent --capability=NoInputNoOutput -d") #new pairing agent with NoInputNoOutput set
os.system("bt-adapter --set Pairable off")

print("q: quit, c: clear database, write anything else to add message")
init_log()

quit_event = threading.Event()              # event telling threads to finish up to exit program
new_posts_event = threading.Event()         # event telling peripheral to load new posts to advertise
database = post_database.PostDatabase()

peripheral = ble_peripheral.Peripheral(quit_event, new_posts_event)
central = ble_central.Central(add_post)
update_posts()              # add posts to peripheral to broadcast
new_posts_event.clear()     # clear event, no need for it at start

# create and run thread for peripheral
peripheral_thread = threading.Thread(target=peripheral.advertise, args=())
central_thread = threading.Thread(target=central.run, args=())
peripheral_thread.start()
central_thread.start()

# user input loop
while True:
    user_input = input()
    if user_input == 'q':           # temporary (?), user enters q to quit
        print("exiting...")
        quit_event.set()            # set quit event, should get threads to finish
        peripheral_thread.join()    # wait for peripheral thread to finish
        central_thread.join()
        break
    elif user_input == 'c':         # temporary (?), user enters c to clear database
        print("* cleared database")
        database.clear()
    elif user_input != '':          # temporary (?), user enters post to add
        add_post(user_input)

