"""Functions for reading and writing the config.json file"""
import json
import os

ROOT_DIR = os.path.realpath(os.path.join(os.path.dirname(__file__), '../..'))
FILE_NAME = "config.json"
FILE_PATH = '/'.join((ROOT_DIR, FILE_NAME))
DEFAULT_CONFIG = {
        "hub_name": { "name": "Hub name", "value": "Gossip Hub", "type": "text" },
        "rcv_posts": { "name": "Receive posts", "value": False, "type": "checkbox" }
}

def read_config():
    '''Read settings from JSON file into list of 
       dictionaries self.config'''
    try:
        with open(FILE_PATH, 'r') as f:
            config = DEFAULT_CONFIG.copy()
            config.update(json.loads(f.read()))
            print(config)
            return config
    except FileNotFoundError:
        print('No config file found, using defaults')
        print(ROOT_DIR)
        return DEFAULT_CONFIG


def _write(config):
    '''Write settings to a JSON file'''
    with open(FILE_PATH, 'w') as f:
        f.write(json.dumps(config))


def set_config(config):
    current_config = read_config()
    bool_config = {k: v == 'True' for k, v in config.items() if current_config[k]['type'] == 'radio'}
    config.update(bool_config)
    for key, value in config.items():
        current_config[key]['value'] = value

    _write(current_config)
    #update_settings(config)


if __name__ == "__main__":
    settings = Settings()
    print(settings.get())
