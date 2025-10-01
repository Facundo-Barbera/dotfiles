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