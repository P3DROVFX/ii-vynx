#!/usr/bin/env bash

# echo "SCRIPT STARTED $(date)" >> /tmp/region-record.log

CONFIG_FILE="$HOME/.config/illogical-impulse/config.json"
JSON_PATH=".screenRecord.savePath"

STATE_FILE="$HOME/.local/state/quickshell/states.json"
STATE_JSON_PATH=".screenRecord.active"

CUSTOM_PATH=$(jq -r "$JSON_PATH" "$CONFIG_FILE" 2>/dev/null)

RECORDING_DIR=""

TIMER_PID=""  
SECONDS_ELAPSED=-1

if [[ -n "$CUSTOM_PATH" ]]; then
    RECORDING_DIR="$CUSTOM_PATH"
else
    RECORDING_DIR="$HOME/Videos" # Use default path
fi

start_timer() {
    if [[ -n "$TIMER_PID" ]]; then
        kill "$TIMER_PID" 2>/dev/null
    fi

    ( 
        while true; do
            SECONDS_ELAPSED=$((SECONDS_ELAPSED + 1))
            jq ".screenRecord.seconds = $SECONDS_ELAPSED" "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
            sleep 1
        done
    ) &
    TIMER_PID=$!
}
stop_timer() {
    if [[ -n "$TIMER_PID" ]]; then
        kill "$TIMER_PID" 2>/dev/null
        wait "$TIMER_PID" 2>/dev/null
        TIMER_PID=""
        jq ".screenRecord.seconds = 0" "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE" # setting it to 0 after killing the timer
    fi
}


trap stop_timer EXIT


getdate() {
    date '+%Y-%m-%d_%H.%M.%S'
}

getaudiooutput() {
    pactl get-default-sink | sed 's/$/.monitor/'
}
getactivemonitor() {
    hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name'
}

updatestate() {
    local state_value=$1
    jq "$STATE_JSON_PATH = $state_value" "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
    if [[ "$state_value" == "true" ]]; then
        start_timer
    else
        stop_timer
    fi
}


mkdir -p "$RECORDING_DIR"
cd "$RECORDING_DIR" || exit

# parse --region <value> without modifying $@ so other flags like --fullscreen still work
ARGS=("$@")
MANUAL_REGION=""
SOUND_FLAG=0
FULLSCREEN_FLAG=0
for ((i=0;i<${#ARGS[@]};i++)); do
    if [[ "${ARGS[i]}" == "--region" ]]; then
        if (( i+1 < ${#ARGS[@]} )); then
            MANUAL_REGION="${ARGS[i+1]}"
        else
            notify-send "Recording cancelled" "No region specified for --region" -a 'Recorder' & disown
            updatestate false
            exit 1
        fi
    elif [[ "${ARGS[i]}" == "--sound" ]]; then
        SOUND_FLAG=1
    elif [[ "${ARGS[i]}" == "--fullscreen" ]]; then
        FULLSCREEN_FLAG=1
    fi
done

if pgrep -x "obs" > /dev/null || pgrep -f "com.obsproject.Studio" > /dev/null; then
    notify-send "Recording Stopped" "Stopped (OBS)" -a 'Recorder' &
    updatestate false
    # Try multiple ways to kill OBS gracefully
    pkill -TERM -x obs 2>/dev/null
    pkill -TERM -f "com.obsproject.Studio" 2>/dev/null
    exit 0
fi


if pgrep wf-recorder > /dev/null; then
    notify-send "Recording Stopped" "Stopped" -a 'Recorder' &
    updatestate false
    pkill wf-recorder &
    exit 0
fi

# Check if we should use obs or wf-recorder
# Default to wf-recorder unless obs is explicitly requested or configured
# But user requested OBS support. Since we can't easily detect intent, let's look for an env var or config
# For now, let's prefer OBS if it's available and running, or if we force it.
# Actually, the user asked to "make the click ... start an OBS recording".
# So I will prioritize OBS if installed.

# Setup OBS command for Flatpak or native
OBS_CMD=""
if flatpak list 2>/dev/null | grep -q "com.obsproject.Studio"; then
    OBS_CMD="flatpak run com.obsproject.Studio"
elif command -v obs &> /dev/null; then
    OBS_CMD="obs"
fi

# Debug log
# echo "DEBUG: Fullscreen=$FULLSCREEN_FLAG OBS_CMD=$OBS_CMD" >> /tmp/record-debug.log

# Force usage if OBS is found, even if not fullyfullscreen?
# User said "pode deixar a gravação totalmente fullscreen" (you can leave recording totally fullscreen).
# This implies maybe they tried region recording and expected OBS?
# But region recording with OBS is hard without predefined scenes.
# However, if they click the "Record screen" button, FULLSCREEN_FLAG is 1.

if [[ -n "$OBS_CMD" ]]; then
    # Start OBS completely minimized
    notify-send "Recording Started" "Started (OBS)" -a 'Recorder' &
    updatestate true
    
    # Run OBS in background
    # Note: Starting with --startrecording directly
    nohup $OBS_CMD --startrecording --minimize-to-tray > /dev/null 2>&1 &
    
    # Wait for OBS to start if it wasn't running
    sleep 2
    
    # Keep script alive while OBS is running, so timer continues
    # We check for either 'obs' (native) or 'com.obsproject.Studio' (flatpak)
    while pgrep -x "obs" > /dev/null || pgrep -f "com.obsproject.Studio" > /dev/null; do
        sleep 1
    done
    
    # When loop exits (OBS closed), the trap will fire and clean up timer
    exit 0
fi



# Fallback to wf-recorder if OBS not available or not fullscreen
# Since user asked to replace region recording with fullscreen, we default to fullscreen always.

    notify-send "Starting recording" 'recording_'"$(getdate)"'.mp4' -a 'Recorder' & disown
    updatestate true
    if [[ $SOUND_FLAG -eq 1 ]]; then
        wf-recorder -o "$(getactivemonitor)" --pixel-format yuv420p -c libx264 -p preset=fast -p tune=zerolatency -p crf=10 -f './recording_'"$(getdate)"'.mp4' --audio="$(getaudiooutput)"
    else
        wf-recorder -o "$(getactivemonitor)" --pixel-format yuv420p -c libx264 -p preset=fast -p tune=zerolatency -p crf=10 -f './recording_'"$(getdate)"'.mp4' 
    fi

# Region code removed as per user request to replace with fullscreen recorder.
# Manual region check ignored.


# echo "SCRIPT EXIT $(date)" >> /tmp/region-record.log