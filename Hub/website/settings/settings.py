import csv

class BbSettings:
    def __init__(self, file_name="config"):
        self.file_name = file_name
        self.config = {"gbl_led_brightness"   : 100,
                       "gbl_volume"       : 100,
                       "sad_g_time"       : 600,
                       "sad_b_time"       : 180,
                       "dom_g_time"       : 600,
                       "dom_points"       : 100,
                       "demo_g_time"      : 180,
                       "ext_easter_eggs"  : 4}
                       
        self.abbr = {"gbl"  :  "Global Settings",
                     "sad"  :  "Search and Destroy",
                     "dom"  :  "Domination",
                     "demo" : "Demolition",
                     "ext"  : "Extra"}
    
    
    def __str__(self):
        return str(self.config)
    
    
    def read(self):
        '''Read settings from CSV file into dictionary self.config'''
        try:
            with open(self.file_name, 'r') as f:
                csv_reader = csv.reader(f, delimiter=',')
                
                # Read file
                for line in csv_reader:
                    self.config[line[0]] = line[1]
        except FileNotFoundError:
            print('No config file found, using defaults')
    
    
    def write(self):
        '''Write settings to file using the CSV format'''
        with open(self.file_name, 'w') as f:
            csv_writer = csv.writer(f, delimiter=',')
            
            # Write file
            for key, value in self.config.items():
                csv_writer.writerow([key, value])
    
    
    def get(self):
        return self.config
    
    
    def set(self, key, value):
        self.config[key] = value
    
    
    def set_all(self, d):
        for key, value in d.items():
            self.config[key] = value
    
    
    def get_abbr(self):
        return self.abbr
