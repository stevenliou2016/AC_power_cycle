#!/usr/bin/python

from __future__ import print_function

import sys
import time

from relay_lib import *


def process_all_on():
    # turn all of the relays on
    relay_all_on()

# Now see what we're supposed to do next
if __name__ == "__main__":
    try:
        process_all_on()
    except KeyboardInterrupt:
        # tell the user what we're doing...
        print("\nExiting application")
        # turn off all of the relays
        relay_all_off()
        # exit the application
        sys.exit(0)
