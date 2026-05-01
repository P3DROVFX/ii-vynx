#!/bin/bash
ACTION=$1
ARG2=$2
ARG3=$3

TARGET_DIR="$HOME/.config/quickshell/ii/assets/images/devices/"
mkdir -p "$TARGET_DIR"

if [ "$ACTION" == "pick" ]; then
    # Pick a PNG file using kdialog or zenity
    if command -v kdialog >/dev/null; then
        kdialog --getopenfilename "$HOME" "*.png|Portable Network Graphics (*.png)" 2>/dev/null
    elif command -v zenity >/dev/null; then
        zenity --file-selection --file-filter="*.png" 2>/dev/null
    else
        echo "Error: No file picker found (kdialog or zenity required)" >&2
        exit 1
    fi
elif [ "$ACTION" == "copy" ]; then
    # Copy and rename image based on MAC
    # Usage: copy <source_path> <mac_address>
    SOURCE_PATH=$ARG2
    MAC=$ARG3
    
    if [ ! -f "$SOURCE_PATH" ]; then
        echo "Error: Source file not found" >&2
        exit 1
    fi
    
    SAFE_MAC=$(echo "$MAC" | tr ':' '_')
    FILENAME="device_${SAFE_MAC}.png"
    cp "$SOURCE_PATH" "$TARGET_DIR$FILENAME"
    echo "$FILENAME"
fi
