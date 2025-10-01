#!/bin/sh

PERCENTAGE="$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)"

[ -z "$PERCENTAGE" ] && exit 0

# Update the battery label while leaving styling to the shared bubble config
sketchybar --set "$NAME" \
    label="${PERCENTAGE}%"
