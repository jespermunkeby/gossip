import sqlite3
from util import DATABASE_FILE


def dict_factory(cursor, row):
    """ Specifies how database tuples are returned. From python docs. """
    d = {}
    for idx, col in enumerate(cursor.description):
        d[col[0]] = row[idx]
    return d


class PostDatabase:
    """ Handles communication with post database. """

    def __init__(self):
        sqlite3.threadsafety = 3
        self.connection = sqlite3.connect(DATABASE_FILE, check_same_thread=False)
        self.connection.row_factory = dict_factory
        self.cursor = self.connection.cursor()
        self.__startup__()

    def __startup__(self):
        """ Creates table if there is no table. If there is a table with no keys, updates table."""
        res = self.cursor.execute("SELECT * FROM sqlite_master WHERE name='post'")
        if res.fetchone() is None:
            self.cursor.execute("CREATE TABLE post(key INTEGER PRIMARY KEY AUTOINCREMENT, content TEXT)")

        # TODO: remove else when no old tables exist?
        else:
            self.cursor.execute("PRAGMA table_info(post)")
            row_count = len(self.cursor.fetchall())
            if row_count == 1:
                rows = list(self.cursor.execute("SELECT * FROM post LIMIT 1").fetchone().keys())
                if rows == ['content']:
                    self.convert()

    # TODO: remove function when no old tables exist?
    def convert(self):
        """ Converts the table without keys to one with keys. """
        content = self.get_posts(content_only=True)
        self.cursor.execute("DROP TABLE post")
        self.__startup__()
        self.add_posts(list(content))

    def post_exists(self, content):
        """ Returns true if a specified post exists in the database. """
        res = self.cursor.execute("SELECT key FROM post WHERE content=?", (content,))
        return res.fetchone() is not None

    def add_post(self, new_post):
        """ Add a post to the database. """
        if not self.post_exists(new_post):
            self.cursor.execute("INSERT OR REPLACE INTO post(content) VALUES (?) ", (new_post,))
            self.connection.commit()

    def add_posts(self, posts):
        """ Add several posts to the database. """
        for post in posts:
            self.add_post(post)

    def get_posts(self, content_only=False):
        """ Get all posts in the database as a list. """
        posts = self.cursor.execute("SELECT * FROM post").fetchall()
        if content_only:
            return list(map(lambda row: row['content'], posts))
        return posts

    def get_decoded_posts(self, content_only=False):
        posts = self.get_posts(content_only=content_only)
        if content_only:
            return [post.decode() if type(post) is bytes else post for post in posts]
        else:
            list(map(lambda x: x.update({'content': x['content'].decode()}), posts))
            return posts

    def delete_post(self, post_id):
        """ Delete the post with the given id. """
        self.cursor.execute("DELETE FROM post WHERE key=?", (str(post_id),))
        self.connection.commit()

    def clear(self):
        """ Clear the database of all posts. """
        self.cursor.execute("DELETE FROM post")
        self.connection.commit()

