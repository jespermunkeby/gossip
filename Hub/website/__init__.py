from flask import Flask
from website.settings.settings import BbSettings
import post_database
import sys
from .settings.settings import BbSettings
from views import define_views
sys.path.insert(0, '..')

def list_gen():
    l = ["Time", "Points", "Other"]
    return l

def get_config():
    config = BbSettings()
    config.read()
    return config.get()

def get_abbr():
    config = BbSettings()
    return config.get_abbr()

def create_app(update_posts):
    app = Flask(__name__)
    app.config['SECRET_KEY'] = 'potato'
    database = post_database.PostDatabase()
    
    def delete_post(key):
        """ Deletes post in database and calls update_posts(). """
        print("deleting post")
        database.delete_post(key)
        update_posts()
    
    def get_posts():
        """ Returns all the posts in the database as an array of dictionaries
            in the format {'key': 1, 'content': 'post'} """
        return database.get_posts()

    def add_post(post):
        database.add_post(post)
        update_posts()

    app.jinja_env.globals.update(list_gen=list_gen)
    app.jinja_env.globals.update(get_config=get_config)
    app.jinja_env.globals.update(get_abbr=get_abbr)
    app.jinja_env.globals.update(get_posts=get_posts)
    app.jinja_env.globals.update(delete_post=delete_post)

    views = define_views(add_post, delete_post)
    app.register_blueprint(views, url_prfefix='/')
    
    return app
