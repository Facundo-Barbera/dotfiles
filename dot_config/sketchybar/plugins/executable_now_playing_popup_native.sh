#!/usr/bin/env bash

update_popup() {
    # Get comprehensive track info
    local track_info=$(osascript << 'EOF'
tell application "Music"
    if it is running then
        try
            set track_name to name of current track
            set track_artist to artist of current track
            set track_album to album of current track
            set track_duration to duration of current track
            set track_position to player position
            set is_playing to (player state is playing)

            -- Format duration
            set duration_minutes to (track_duration div 60) as integer
            set duration_seconds to (track_duration mod 60) as integer
            if duration_seconds < 10 then
                set duration_str to (duration_minutes as string) & ":0" & (duration_seconds as string)
            else
                set duration_str to (duration_minutes as string) & ":" & (duration_seconds as string)
            end if

            -- Format position
            set position_minutes to (track_position div 60) as integer
            set position_seconds to (track_position mod 60) as integer
            if position_seconds < 10 then
                set position_str to (position_minutes as string) & ":0" & (position_seconds as string)
            else
                set position_str to (position_minutes as string) & ":" & (position_seconds as string)
            end if

            return track_name & "|||" & track_artist & "|||" & track_album & "|||" & duration_str & "|||" & position_str & "|||" & (is_playing as string)
        on error
            return ""
        end try
    else
        return ""
    end if
end tell
EOF
)

    if [[ -n "$track_info" ]]; then
        # Parse the track info
        IFS='|||' read -r track_name track_artist track_album duration_str position_str is_playing <<< "$track_info"

        # Create formatted text for big box with icons
        local status_icon="$(if [[ "$is_playing" == "true" ]]; then echo "▶︎"; else echo "⏸"; fi)"

        # Format with icons and proper spacing - using special characters that work in SketchyBar
        local big_box_text="♪  ${track_name}
💽  ${track_album}
👤  ${track_artist}
⏰  ${position_str} / ${duration_str} • ${status_icon}"

        # Update the single big popup box
        sketchybar --set now_playing_big_box label="$big_box_text"
    else
        # No track playing
        sketchybar --set now_playing_big_box label="♪  No music playing"
    fi
}

# Handle different events
case "$SENDER" in
    "mouse.entered")
        update_popup
        sketchybar --set now_playing popup.drawing=on
        ;;
    "mouse.exited")
        sketchybar --set now_playing popup.drawing=off
        ;;
    *)
        # Update the bar icon
        track="$(osascript -e 'tell application "Music" to if it is running then name of current track')"
        if [ -n "$track" ]; then
            sketchybar --set now_playing icon="♪" label="" drawing=on
        else
            sketchybar --set now_playing drawing=off
        fi
        ;;
esac