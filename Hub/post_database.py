import sqlite3

class PostDatabase:
    """ Handles communication with post database. """

    def __init__(self, new_posts_event):
        self.connection = sqlite3.connect("posts.db")
        self.connection.row_factory = lambda cursor, row: row[0]
        self.cursor = self.connection.cursor()
        self.new_posts_event = new_posts_event

    def add_post(self, new_post):
        self.cursor.execute("INSERT INTO post VALUES ('" + new_post + "') ")
        self.connection.commit()
        self.new_posts_event.set()

    def get_posts(self):
        """ Get all posts in the database as a list. """
        return self.cursor.execute("SELECT content FROM post").fetchall()
    
    def clear(self):
        self.cursor.execute("DELETE FROM post")