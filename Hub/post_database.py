import sqlite3

class PostDatabase:
    """ Handles communication with post database. """

    def __init__(self):
        self.connection = sqlite3.connect("posts.db")
        self.connection.row_factory = lambda cursor, row: row[0]
        self.cursor = self.connection.cursor()

    def add_post(self, new_post):
        self.cursor.execute("INSERT INTO post VALUES ('" + new_post + "') ")
        self.connection.commit()

    def test(self):
        res = self.cursor.execute("SELECT content FROM post")
        print(res.fetchall())

    def get_posts(self):
        """ Get all posts in the database as a list. """
        return self.cursor.execute("SELECT content FROM post").fetchall()