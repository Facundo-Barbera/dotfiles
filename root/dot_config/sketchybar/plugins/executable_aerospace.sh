#!/bin/bash
# Highlight active workspace with bold + accent color, make empty workspaces greyer.

WORKSPACE_FONT="JetBrainsMono Nerd Font:Regular:15.0"
WORKSPACE_FONT_BOLD="JetBrainsMono Nerd Font:Bold:15.0"
INACTIVE="0xffc6d0f5"  # Catppuccin Frappé text
ACTIVE_FG="0xff8caaee"  # Catppuccin Frappé blue
EMPTY="0xff6c7086"      # Catppuccin Frappé overlay1

ACTIVE="$(aerospace list-workspaces --focused 2>/dev/null | tr -d '[:space:]')"
[ -n "$FOCUSED_WORKSPACE" ] && ACTIVE="$FOCUSED_WORKSPACE"

# Check for external displays (more than 1 monitor means external display is connected)
MONITOR_COUNT=$(aerospace list-monitors | wc -l | tr -d ' ')
if [ "$MONITOR_COUNT" -gt 1 ]; then
  # External display connected - show divisor between workspace 6 and 7
  sketchybar --set workspace_divisor drawing=on
else
  # Only built-in display - hide divisor
  sketchybar --set workspace_divisor drawing=off
fi

# Handle workspace I
WINDOWS_COUNT_I=$(aerospace list-windows --workspace "I" 2>/dev/null | wc -l | tr -d ' ')
if [ "I" = "$ACTIVE" ]; then
  sketchybar --set "space.I" \
    label.color="$ACTIVE_FG" \
    label.font="$WORKSPACE_FONT_BOLD" \
    label.align=center
elif [ "$WINDOWS_COUNT_I" -gt 0 ]; then
  sketchybar --set "space.I" \
    label.color="$INACTIVE" \
    label.font="$WORKSPACE_FONT" \
    label.align=center
else
  sketchybar --set "space.I" \
    label.color="$EMPTY" \
    label.font="$WORKSPACE_FONT" \
    label.align=center
fi

# Handle workspace M (hidden multimedia workspace - only show if it has windows)
WINDOWS_COUNT_M=$(aerospace list-windows --workspace "M" 2>/dev/null | wc -l | tr -d ' ')
if [ "$WINDOWS_COUNT_M" -gt 0 ]; then
  # Show workspace M
  sketchybar --set "space.M" drawing=on

  if [ "M" = "$ACTIVE" ]; then
    sketchybar --set "space.M" \
      label.color="$ACTIVE_FG" \
      label.font="$WORKSPACE_FONT_BOLD" \
      label.align=center
  else
    sketchybar --set "space.M" \
      label.color="$INACTIVE" \
      label.font="$WORKSPACE_FONT" \
      label.align=center
  fi
else
  # Hide workspace M when empty
  sketchybar --set "space.M" drawing=off
fi

for sid in 1 2 3 4 5 6 7 8 9; do
  # Check if workspace has windows
  WINDOWS_COUNT=$(aerospace list-windows --workspace "$sid" 2>/dev/null | wc -l | tr -d ' ')

  if [ "$sid" = "$ACTIVE" ]; then
    # Active workspace - accent color + bold
    sketchybar --set "space.$sid" \
      label.color="$ACTIVE_FG" \
      label.font="$WORKSPACE_FONT_BOLD" \
      label.align=center
  elif [ "$WINDOWS_COUNT" -gt 0 ]; then
    # Workspace with windows - normal inactive color
    sketchybar --set "space.$sid" \
      label.color="$INACTIVE" \
      label.font="$WORKSPACE_FONT" \
      label.align=center
  else
    # Empty workspace - greyer color
    sketchybar --set "space.$sid" \
      label.color="$EMPTY" \
      label.font="$WORKSPACE_FONT" \
      label.align=center
  fi
done
