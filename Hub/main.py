#!/usr/bin/python3
from datetime import datetime

import ble_peripheral
import ble_central
import fun_ble_central
import logging
import post_database
import threading
import logging.config
from logging.handlers import RotatingFileHandler
from website import create_app
from util import WEB_APP_IP, WEB_APP_PORT
from website.settings.settings import read_config
import time
import os


def init_log():  # adapted from https://stackoverflow.com/a/56369583
    """ Initializes logging. Should only be called once. """
    logging.basicConfig(
        handlers=[RotatingFileHandler('.hub_log.log', maxBytes=100000, backupCount=1)],
        level=logging.DEBUG,
        format="[%(asctime)s] %(levelname)s [%(name)s.%(funcName)s:%(lineno)d] %(message)s",
        datefmt='%Y-%m-%d %H:%M:%S')


class Main:

    def __init__(self):
        print("q: quit, c: clear database, write anything else to add message")
        init_log()
        os.system("sudo systemctl restart bluetooth")
        time.sleep(1)
        fun_ble_central.clear_device_cache()
        self.quit_event = threading.Event()          # event telling threads to finish up to exit program
        self.new_posts_event = threading.Event()     # event telling peripheral to load new posts to advertise
        self.database = post_database.PostDatabase()
        self.settings = None
        self.peripheral = None
        self.central = None
        self.ble_thread = None
        self.webb_app = None
        self.run_central = None

    def update_posts(self):
        """ Reads posts from the database, and updates peripheral to broadcast those posts. """
        posts = self.database.get_decoded_posts(content_only=True)
        print("* broadcasting: " + str(posts))
        if self.peripheral:
            self.peripheral.set_posts(posts)
            self.new_posts_event.set()

    def add_post(self, post):
        """ Adds post to database and calls update_posts(). """
        self.database.add_post(post)
        self.update_posts()

    def run_web_config(self):
        self.webb_app = create_app(self.update_posts, self.settings_updated)
        self.webb_app.run(host=WEB_APP_IP, port=WEB_APP_PORT, debug=False, use_reloader=False)

    def bluetooth_loop(self):
        self.peripheral = ble_peripheral.Peripheral(self.quit_event,
                                                    self.new_posts_event,
                                                    hub_name=self.settings["hub_name"]["value"])
        self.update_posts()  # add posts to peripheral to broadcast
        self.new_posts_event.clear()  # clear event, no need for it at start
        self.central = ble_central.Central(self.quit_event, self.add_post)
        #self.run_central = fun_ble_central.initialize()

        while not self.quit_event.is_set():
            print("starting peripheral: " + datetime.now().strftime("%H:%M:%S"))
            self.peripheral.advertise()
            if self.settings["rcv_posts"]["value"] and not self.quit_event.is_set():
                print("starting central: " + datetime.now().strftime("%H:%M:%S"))
                self.central.run()
                #self.run_central(self.add_post, self.quit_event)

    def input_loop(self):
        while True:
            user_input = input()
            if user_input == 'q':  # temporary (?), user enters q to quit
                print("exiting...")
                self.quit_event.set()  # set quit event, should get threads to finish
                if self.ble_thread:
                    self.ble_thread.join()  # wait for peripheral thread to finish
                os.system("sudo systemctl restart bluetooth")
                os._exit(1)
            elif user_input == 'c':  # temporary (?), user enters c to clear database
                print("* cleared database")
                self.database.clear()
            elif user_input != '':  # temporary (?), user enters post to add
                self.add_post(user_input.encode())

    def settings_updated(self):
        self.settings = read_config()

        # quit threads
        self.quit_event.set()
        self.ble_thread.join()
        self.quit_event.clear()

        # restart thread
        self.ble_thread = threading.Thread(target=self.bluetooth_loop)
        self.ble_thread.start()

    def run(self):
        self.settings = read_config()

        self.ble_thread = threading.Thread(target=self.bluetooth_loop)
        self.ble_thread.start()

        web_thread = threading.Thread(target=self.run_web_config)
        web_thread.start()

        self.input_loop()


if __name__ == "__main__":
    main = Main()
    main.run()
