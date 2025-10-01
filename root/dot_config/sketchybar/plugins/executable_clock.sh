#!/bin/sh

# Update the clock label while leaving styling to the shared bubble config
sketchybar --set "$NAME" label="$(date '+%A, %B %d, %Y %H:%M:%S')"
