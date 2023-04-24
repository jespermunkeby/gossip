
class PostDatabase:
    """ Handles communication with post database. """

    def __init__(self):
        self.posts = ["A"*512,"B"*512,"C"*512, "D"*512]

    def get_posts(self):
        """ Get all posts in the database as a list. """
        return self.posts