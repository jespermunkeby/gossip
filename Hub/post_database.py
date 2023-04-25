import sqlite3
from util import DATABASE_FILE


class PostDatabase:
    """ Handles communication with post database. """

    def __init__(self):
        self.connection = sqlite3.connect(DATABASE_FILE)
        self.connection.row_factory = lambda cursor, row: row[0]
        self.cursor = self.connection.cursor()
        self.__create_table()

    def __create_table(self):
        res = self.cursor.execute("SELECT name FROM sqlite_master WHERE name='post'")
        if res.fetchone() is None:
            self.cursor.execute("CREATE TABLE post(content PRIMARY KEY)")

    def add_post(self, new_post):
        self.cursor.execute("INSERT OR REPLACE INTO post VALUES ('" + new_post + "') ")
        self.connection.commit()

    def get_posts(self):
        """ Get all posts in the database as a list. """
        return self.cursor.execute("SELECT content FROM post").fetchall()

    def clear(self):
        self.cursor.execute("DELETE FROM post")
        self.connection.commit()
