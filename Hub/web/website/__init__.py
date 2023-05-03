from flask import Flask
from .settings.settings import BbSettings

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

def create_app():
    app = Flask(__name__)
    app.config['SECRET_KEY'] = 'potato'
    
    app.jinja_env.globals.update(list_gen=list_gen)
    app.jinja_env.globals.update(get_config=get_config)
    app.jinja_env.globals.update(get_abbr=get_abbr)
    
    from .views import views
    app.register_blueprint(views, url_prfefix='/')
    
    return app



