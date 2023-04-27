# Hub

When running `main.py`, a database `posts.db` is either read from
the current directory, or created if it doesn't exist.

## Files

- `main`: Startup file, also acts as controller.
- `ble_peripheral`: Handles BLE peripheral role (sending out posts)
- `ble_central`: Handles BLE central role (receiving posts)
- `post_database`: Database for posts.
- `util`: Contains constants used in all classes

While `main` handles all classes, they do not know of each other 
(except util).

## Logging

Use `import logging`. To log:

- `logging.debug(message)` -  debug information
- `logging.info(message)` - something working as expected
- `logging.warning(message)` - warnings
- `logging.error(message)` - errors
- `logging.critical(message)` - critical errors

A log file `.hub_log.log` is created for logging. Once it is full,
older entries will be pushed to another file `.hub_log.log.1`. If
both are full, older entries will be deleted.