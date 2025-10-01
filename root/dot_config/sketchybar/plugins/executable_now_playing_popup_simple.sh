#!/usr/bin/env bash

POPUP_PID_FILE="/tmp/sketchybar_now_playing_popup.pid"

show_popup() {
    # Kill existing popup if running
    if [[ -f "$POPUP_PID_FILE" ]]; then
        local old_pid=$(cat "$POPUP_PID_FILE")
        if kill -0 "$old_pid" 2>/dev/null; then
            kill "$old_pid"
        fi
        rm -f "$POPUP_PID_FILE"
    fi

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

    if [[ -z "$track_info" ]]; then
        return
    fi

    # Parse the track info
    IFS='|||' read -r track_name track_artist track_album duration_str position_str is_playing <<< "$track_info"

    # Create a non-intrusive notification using macOS notification system
    local notification_title="♪ Now Playing"
    local notification_text="${track_name}
${track_artist} • ${track_album}
${position_str} / ${duration_str} • $(if [[ "$is_playing" == "true" ]]; then echo "Playing"; else echo "Paused"; fi)"

    # Use osascript to send a notification that doesn't steal focus
    osascript << EOF &
        display notification "$notification_text" with title "$notification_title" sound name ""
EOF

    # Store the PID
    echo $! > "$POPUP_PID_FILE"
}

hide_popup() {
    if [[ -f "$POPUP_PID_FILE" ]]; then
        local popup_pid=$(cat "$POPUP_PID_FILE")
        if kill -0 "$popup_pid" 2>/dev/null; then
            kill "$popup_pid"
        fi
        rm -f "$POPUP_PID_FILE"
    fi
}

# Handle different events
case "$SENDER" in
    "mouse.entered")
        echo "$(date): mouse.entered event received" >> /tmp/sketchybar_debug.log
        show_popup
        ;;
    "mouse.exited")
        echo "$(date): mouse.exited event received" >> /tmp/sketchybar_debug.log
        # Let the popup auto-close
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