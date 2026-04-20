#!/usr/bin/env bash

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
    RECORDING_DIR="$HOME/Videos"
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
        jq ".screenRecord.seconds = 0" "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
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

updateloading() {
    local state_value=$1
    jq ".screenRecord.loading = $state_value" "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
}

updatestate() {
    local state_value=$1
    if [[ "$state_value" == "true" ]]; then
        jq "$STATE_JSON_PATH = true | .screenRecord.loading = false" "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
        start_timer
    else
        jq "$STATE_JSON_PATH = false | .screenRecord.loading = false" "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
        stop_timer
    fi
}

mkdir -p "$RECORDING_DIR"
cd "$RECORDING_DIR" || exit

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
    notify-send "Recording Stopped" "Stopped (OBS) & Closed" -a 'Recorder' &
    updatestate false
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

OBS_CMD=""
if flatpak list 2>/dev/null | grep -q "com.obsproject.Studio"; then
    OBS_CMD="flatpak run com.obsproject.Studio"
elif command -v obs &> /dev/null; then
    OBS_CMD="obs"
fi

if [[ -n "$OBS_CMD" ]]; then
    notify-send "Starting OBS..." "OBS starting to record" -a 'Recorder' &
    updateloading true
    
    nohup $OBS_CMD --startrecording --minimize-to-tray > /dev/null 2>&1 &
    
    while ! pgrep -x "obs" > /dev/null && ! pgrep -f "com.obsproject.Studio" > /dev/null; do
        sleep 1
    done
    
    # OBS pode levar de 4 a 6 segundos para engatar o inicio do video
    # Encontramos o arquivo de log mais recente para saber o frame EXATO
    sleep 1 # Wait slightly for log file to actually be created
    LOG_FILE=$(ls -1t ~/.var/app/com.obsproject.Studio/config/obs-studio/logs/*.txt ~/.config/obs-studio/logs/*.txt 2>/dev/null | head -1)
    
    if [[ -f "$LOG_FILE" ]]; then
        for i in {1..20}; do
            if grep -q "==== Recording Start" "$LOG_FILE"; then
                break
            fi
            sleep 0.5
        done
    else
        sleep 4
    fi

    updatestate true
    notify-send "Recording Started" "Started (OBS)" -a 'Recorder' &
    
    while pgrep -x "obs" > /dev/null || pgrep -f "com.obsproject.Studio" > /dev/null; do
        sleep 1
    done
    
    updatestate false
    exit 0
fi

notify-send "Starting recording" 'recording_'"$(getdate)"'.mp4' -a 'Recorder' & disown
updatestate true
if [[ $SOUND_FLAG -eq 1 ]]; then
    wf-recorder -o "$(getactivemonitor)" --pixel-format yuv420p -c libx264 -p preset=fast -p tune=zerolatency -p crf=10 -f './recording_'"$(getdate)"'.mp4' --audio="$(getaudiooutput)"
else
    wf-recorder -o "$(getactivemonitor)" --pixel-format yuv420p -c libx264 -p preset=fast -p tune=zerolatency -p crf=10 -f './recording_'"$(getdate)"'.mp4' 
fi
