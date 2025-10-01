#!/usr/bin/env bash
# Now Playing Module Installer
# Idempotent installer for SketchyBar now playing module

# Set default paths
CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
PLUGIN_DIR="$CONFIG_DIR/plugins"
MODULE_DIR="$CONFIG_DIR/modules"

echo "Installing Now Playing module for SketchyBar..."

# Create directories if they don't exist
mkdir -p "$MODULE_DIR"
mkdir -p "$PLUGIN_DIR"

echo "✓ Created directories"

# Write plugin script
cat > "$PLUGIN_DIR/now_playing.sh" << 'EOF'
#!/usr/bin/env bash
# Now Playing module (album art + scrolling label + tiny viz + popup)

ITEM="$NAME"  # set by SketchyBar

escape() { echo "$1" | sed 's/"/\\"/g'; }

get_music_state() {
  osascript <<'APPLESCRIPT'
  tell application "System Events"
    set musicRunning to (exists process "Music")
  end tell
  if musicRunning then
    tell application "Music"
      set ps to player state
      if ps is playing or ps is paused then
        set theTitle to (name of current track)
        set theArtist to (artist of current track)
        set theAlbum to (album of current track)
        return "Music|" & ps & "|" & theTitle & "|" & theArtist & "|" & theAlbum
      else
        return "Music|stopped|||"
      end if
    end tell
  else
    return ""
  end if
APPLESCRIPT
}

get_spotify_state() {
  osascript <<'APPLESCRIPT'
  tell application "System Events"
    set spotRunning to (exists process "Spotify")
  end tell
  if spotRunning then
    tell application "Spotify"
      set ps to player state
      if ps is playing or ps is paused then
        set theTitle to (name of current track)
        set theArtist to (artist of current track)
        set theAlbum to (album of current track)
        return "Spotify|" & ps & "|" & theTitle & "|" & theArtist & "|" & theAlbum
      else
        return "Spotify|stopped|||"
      end if
    end tell
  else
    return ""
  end if
APPLESCRIPT
}

get_sys_volume() {
  osascript -e 'output volume of (get volume settings)' 2>/dev/null
}

STATE="$(get_music_state)"
[ -z "$STATE" ] && STATE="$(get_spotify_state)"

PLAYER="${STATE%%|*}"
REST="${STATE#*|}"
PSTATE="${REST%%|*}"
REST="${REST#*|}"
TITLE="${REST%%|*}"
REST="${REST#*|}"
ARTIST="${REST%%|*}"
ALBUM="${REST#*|}"

VOL="$(get_sys_volume)"; [ -z "$VOL" ] && VOL=0

if [ -z "$PLAYER" ] || [ "$PSTATE" = "stopped" ] || [ -z "$TITLE$ARTIST" ]; then
  LABEL="Not playing"
  POP="No media playing"
else
  LABEL="♪ $(escape "$TITLE")  •  $(escape "$ARTIST")"
  POP="$PLAYER: $PSTATE\nTitle: $TITLE\nArtist: $ARTIST\nAlbum: $ALBUM"
fi

# Update UI
sketchybar --set now_playing.label label="$LABEL"

# Volume (0..100) -> width (12..60)
MINW=12; MAXW=60
W=$(( MINW + ( (VOL * (MAXW - MINW)) / 100 ) ))
[ "$W" -lt "$MINW" ] && W="$MINW"
[ "$W" -gt "$MAXW" ] && W="$MAXW"
sketchybar --set now_playing.viz width="$W"

sketchybar --set now_playing.popup label="$POP"

# Hover control — toggle popup on the anchor (label)
case "$SENDER" in
  "mouse.entered")
    case "$NAME" in
      now_playing.art|now_playing.label|now_playing.viz)
        sketchybar --set now_playing.label popup.drawing=on
        ;;
    esac
    ;;
  "mouse.exited")
    case "$NAME" in
      now_playing.art|now_playing.label|now_playing.viz)
        sketchybar --set now_playing.label popup.drawing=off
        ;;
    esac
    ;;
  *) : ;;
esac
EOF

# Make plugin executable
chmod +x "$PLUGIN_DIR/now_playing.sh"

echo "✓ Created and made executable: $PLUGIN_DIR/now_playing.sh"

# Write module configuration
cat > "$MODULE_DIR/now_playing.conf" << 'EOF'
# Artwork (auto-updates)
sketchybar --add item now_playing.art right \
  --set now_playing.art \
    width=28 padding_left=10 padding_right=6 \
    background.drawing=off \
    image.drawing=on image=media.artwork image.corner_radius=6 image.scale=1.0 \
    script="$PLUGIN_DIR/now_playing.sh" \
  --subscribe now_playing.art media_change

# Scrolling title • artist
sketchybar --add item now_playing.label right \
  --set now_playing.label \
    script="$PLUGIN_DIR/now_playing.sh" \
    update_freq=2 \
    icon.drawing=off background.drawing=off \
    label.font="JetBrainsMono Nerd Font:Regular:12.0" \
    label.max_chars=28 scroll_texts=on scroll_duration=120 \
    width=260 label.padding_left=0 label.padding_right=0 \
  --subscribe now_playing.label media_change mouse.entered mouse.exited

# Tiny visualizer (width bound to system output volume)
sketchybar --add item now_playing.viz right \
  --set now_playing.viz \
    script="$PLUGIN_DIR/now_playing.sh" \
    update_freq=2 icon= label= \
    background.drawing=on background.color=0xff414559 \
    background.corner_radius=15 background.height=6 \
    width=60 padding_left=8 padding_right=8 \
  --subscribe now_playing.viz mouse.entered mouse.exited

# Popup anchored to the LABEL (not a bracket!)
sketchybar --add item now_playing.popup popup.now_playing.label \
  --set now_playing.popup \
    drawing=on \
    background.drawing=on background.color=0xff414559 \
    background.corner_radius=15 background.height=100 \
    label="…" label.font="JetBrainsMono Nerd Font:Regular:12.0" label.color=0xffc6d0f5 \
    padding_left=20 padding_right=20

# Cosmetic capsule around the 3 items
sketchybar --add bracket now_playing.bracket now_playing.art now_playing.label now_playing.viz \
  --set now_playing.bracket \
    background.color=0xff414559 \
    background.corner_radius=15 \
    background.height=30
EOF

echo "✓ Created: $MODULE_DIR/now_playing.conf"

# Check if items already exist and remove them to avoid duplicates
echo "Checking for existing items..."
existing_items=$(sketchybar --query bar 2>/dev/null | grep -o 'now_playing\.[a-z]*' | sort -u || true)

if [ -n "$existing_items" ]; then
    echo "Removing existing now playing items to avoid duplicates..."
    for item in $existing_items; do
        sketchybar --remove "$item" 2>/dev/null || true
    done
    # Also remove bracket and popup if they exist
    sketchybar --remove now_playing.bracket 2>/dev/null || true
    sketchybar --remove now_playing.popup 2>/dev/null || true
    sketchybar --remove now_playing 2>/dev/null || true
fi

echo "Loading module into SketchyBar..."

# Source the module configuration
source "$MODULE_DIR/now_playing.conf"

echo "✓ Module loaded"

# Reload and update SketchyBar
echo "Reloading SketchyBar..."
sketchybar --reload
sketchybar --update

echo "✓ Installation complete!"
echo ""
echo "The Now Playing module has been installed with:"
echo "  • Album artwork (auto-updating)"
echo "  • Scrolling title and artist"
echo "  • Volume-responsive visualizer"
echo "  • Hover popup with track details"
echo ""
echo "Files created:"
echo "  • $PLUGIN_DIR/now_playing.sh"
echo "  • $MODULE_DIR/now_playing.conf"
echo ""
echo "To use this module in your main config, add:"
echo "  source \"\$CONFIG_DIR/modules/now_playing.conf\""