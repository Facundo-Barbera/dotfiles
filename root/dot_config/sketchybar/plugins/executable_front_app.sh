#!/bin/sh

# Update the front app label while leaving styling to the shared bubble config
if [ "$SENDER" = "front_app_switched" ] || [ -z "$SENDER" ]; then
  sketchybar --set "$NAME" \
      label="$INFO"
fi
