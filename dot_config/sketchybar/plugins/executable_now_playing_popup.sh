#!/usr/bin/env bash

POPUP_PID_FILE="/tmp/sketchybar_now_playing_popup.pid"
ARTWORK_PATH="/tmp/now_playing_artwork.png"

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

            -- Try to get artwork
            set has_artwork to "false"
            try
                set artwork_data to raw data of artwork 1 of current track
                set artwork_path to "/tmp/now_playing_artwork.png"
                set artwork_file to open for access artwork_path with write permission
                write artwork_data to artwork_file
                close access artwork_file
                set has_artwork to "true"
            end try

            return track_name & "|||" & track_artist & "|||" & track_album & "|||" & duration_str & "|||" & position_str & "|||" & (is_playing as string) & "|||" & has_artwork
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
    IFS='|||' read -r track_name track_artist track_album duration_str position_str is_playing has_artwork <<< "$track_info"

    # Create HTML popup content
    local html_content=$(cat << HTML
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #2a2d3a 0%, #3d4152 100%);
            color: #c6d0f5;
            margin: 0;
            padding: 20px;
            border-radius: 12px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.3);
            min-width: 320px;
            max-width: 400px;
        }
        .container {
            display: flex;
            gap: 15px;
            align-items: flex-start;
        }
        .artwork {
            width: 80px;
            height: 80px;
            border-radius: 8px;
            background: #414559;
            display: flex;
            align-items: center;
            justify-content: center;
            flex-shrink: 0;
        }
        .artwork img {
            width: 80px;
            height: 80px;
            border-radius: 8px;
            object-fit: cover;
        }
        .artwork .no-artwork {
            font-size: 32px;
            color: #6c7086;
        }
        .info {
            flex: 1;
            min-width: 0;
        }
        .title {
            font-size: 16px;
            font-weight: 600;
            margin-bottom: 4px;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }
        .artist {
            font-size: 14px;
            color: #a6adc8;
            margin-bottom: 2px;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }
        .album {
            font-size: 12px;
            color: #6c7086;
            margin-bottom: 12px;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }
        .progress-container {
            margin-bottom: 8px;
        }
        .progress-bar {
            width: 100%;
            height: 4px;
            background: #414559;
            border-radius: 2px;
            overflow: hidden;
            margin-bottom: 4px;
        }
        .progress-fill {
            height: 100%;
            background: #8caaee;
            border-radius: 2px;
            transition: width 0.3s ease;
        }
        .time {
            font-size: 11px;
            color: #6c7086;
            display: flex;
            justify-content: space-between;
        }
        .status {
            font-size: 12px;
            display: flex;
            align-items: center;
            gap: 6px;
        }
        .status-icon {
            font-size: 14px;
        }
        .playing { color: #a6e3a1; }
        .paused { color: #f9e2af; }
    </style>
</head>
<body>
    <div class="container">
        <div class="artwork">
HTML
)

    # Add artwork or placeholder
    if [[ "$has_artwork" == "true" && -f "$ARTWORK_PATH" ]]; then
        html_content+="            <img src=\"file://$ARTWORK_PATH\" alt=\"Album artwork\">"
    else
        html_content+="            <div class=\"no-artwork\">♪</div>"
    fi

    # Calculate progress percentage
    local progress=0
    if [[ "$duration_str" != "0:00" ]]; then
        local position_seconds=$(echo "$position_str" | awk -F: '{print ($1 * 60) + $2}')
        local duration_seconds=$(echo "$duration_str" | awk -F: '{print ($1 * 60) + $2}')
        if [[ $duration_seconds -gt 0 ]]; then
            progress=$(( (position_seconds * 100) / duration_seconds ))
        fi
    fi

    html_content+=$(cat << HTML
        </div>
        <div class="info">
            <div class="title">${track_name}</div>
            <div class="artist">${track_artist}</div>
            <div class="album">${track_album}</div>
            <div class="progress-container">
                <div class="progress-bar">
                    <div class="progress-fill" style="width: ${progress}%"></div>
                </div>
                <div class="time">
                    <span>${position_str}</span>
                    <span>${duration_str}</span>
                </div>
            </div>
            <div class="status $(if [[ "$is_playing" == "true" ]]; then echo "playing"; else echo "paused"; fi)">
                <span class="status-icon">$(if [[ "$is_playing" == "true" ]]; then echo "▶︎"; else echo "⏸"; fi)</span>
                <span>$(if [[ "$is_playing" == "true" ]]; then echo "Playing"; else echo "Paused"; fi)</span>
            </div>
        </div>
    </div>
</body>
</html>
HTML
)

    # Save HTML to temp file
    local html_file="/tmp/now_playing_popup.html"
    echo "$html_content" > "$html_file"

    # Create and show popup using Python with tkinter for a native window
    python3 << PYTHON &
import tkinter as tk
from tkinter import ttk
import webview
import threading
import time
import os
import signal

class NowPlayingPopup:
    def __init__(self):
        self.window = None
        self.should_close = False

    def create_popup(self):
        # Get cursor position for popup placement
        try:
            import Cocoa
            mouse_loc = Cocoa.NSEvent.mouseLocation()
            x = int(mouse_loc.x)
            y = int(Cocoa.NSScreen.mainScreen().frame().size.height - mouse_loc.y)
        except:
            x, y = 100, 100

        # Create webview window
        self.window = webview.create_window(
            title='',
            url='file://$html_file',
            width=400,
            height=160,
            x=x + 10,
            y=y + 10,
            resizable=False,
            shadow=True,
            on_top=True,
            transparent=True,
            frameless=True
        )

        # Auto-close after 5 seconds
        def auto_close():
            time.sleep(5)
            if self.window and not self.should_close:
                webview.destroy_window(self.window)

        threading.Thread(target=auto_close, daemon=True).start()

        # Start the webview
        webview.start(debug=False)

popup = NowPlayingPopup()
popup.create_popup()
PYTHON

    # Store the PID
    echo $! > "$POPUP_PID_FILE"

    # Auto-cleanup after 6 seconds
    (sleep 6 && rm -f "$html_file" "$ARTWORK_PATH" "$POPUP_PID_FILE" 2>/dev/null) &
}

hide_popup() {
    if [[ -f "$POPUP_PID_FILE" ]]; then
        local popup_pid=$(cat "$POPUP_PID_FILE")
        if kill -0 "$popup_pid" 2>/dev/null; then
            kill "$popup_pid"
        fi
        rm -f "$POPUP_PID_FILE"
    fi
    # Cleanup temp files
    rm -f "/tmp/now_playing_popup.html" "$ARTWORK_PATH" 2>/dev/null
}

# Handle different events
case "$SENDER" in
    "mouse.entered")
        show_popup
        ;;
    "mouse.exited")
        # Don't immediately hide, let it auto-close
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