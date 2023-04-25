#!/usr/bin/python3
import ble_peripheral
import post_database
import threading

def update_posts():
    posts = database.get_posts()
    print("* broadcasting: " + str(posts))
    peripheral.set_posts(posts)

def add_post(post):
    database.add_post(post)
    new_posts_event.set()
    update_posts()

print("q: quit, c: clear database, write anything else to add message")

quit_event = threading.Event()
new_posts_event = threading.Event()

database = post_database.PostDatabase()

peripheral =  ble_peripheral.Peripheral()
update_posts()

peripheral_thread = threading.Thread(target=peripheral.advertise, args=(quit_event, new_posts_event))
peripheral_thread.start()

while(True):
    i = input() # quit on input
    if(i == 'q'):
        print("exiting...")
        quit_event.set()
        peripheral_thread.join()
        break
    elif (i == 'c'):
        print("* cleared database")
        database.clear()
    elif(i != ''):
        add_post(i)

