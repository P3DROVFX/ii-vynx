#!/usr/bin/env bash

set -uo pipefail

CONFIG_PATH="${HOME}/.local/share/ii-vynx/hyprland.conf"
TMP_PATH="/tmp/hypr_config_write.tmp"

die()  { echo "[hyprconf] ERROR: $*" >&2; exit 1; }
warn() { echo "[hyprconf] WARN:  $*" >&2; }

check_safe() {
    local val="$1"
    # Security check for shell injection characters
    if [[ "$val" =~ [\'\"\\\ \`\$\|\&\;] ]]; then
        die "Unsafe characters in argument: '$val'"
    fi
}

require_file() {
    [[ -f "$CONFIG_PATH" ]] || die "Config not found: $CONFIG_PATH"
}

# Key mode

mode_key() {
    local key="$1" value="$2"
    check_safe "$key"
    check_safe "$value"
    require_file

    if [[ "$key" == *:* ]]; then
        local section="${key%%:*}"
        local field="${key#*:}"
        section="${section// /}"
        field="${field// /}"

        # If section doesn't exist, create it at the end of the file
        if ! grep -qE "^[[:space:]]*${section}[[:space:]]*\{" "$CONFIG_PATH"; then
            warn "Section '${section}' missing, creating new block..."
            echo -e "\n${section} {\n    ${field} = ${value}\n}" >> "$CONFIG_PATH"
        else
            # Update existing key within the section
            local replaced
            replaced=$(sed -E "/^[[:space:]]*${section}[[:space:]]*\{/,/^\}/ s|^([[:space:]]*${field}[[:space:]]*=[[:space:]]*).*|\1${value}|" "$CONFIG_PATH")

            if diff -q <(echo "$replaced") "$CONFIG_PATH" > /dev/null 2>&1; then
                # Key not found in section, append it before the closing brace '}'
                warn "Key '${field}' not found in '${section}', appending..."
                sed -E "/^[[:space:]]*${section}[[:space:]]*\{/,/^\}/ {
                    /^\}/ i\\    ${field} = ${value}
                }" "$CONFIG_PATH" > "$TMP_PATH"
                mv "$TMP_PATH" "$CONFIG_PATH"
            else
                echo "$replaced" > "$TMP_PATH"
                mv "$TMP_PATH" "$CONFIG_PATH"
            fi
        fi
    else
        # Handle top-level (global) keys
        if grep -qE "^[[:space:]]*${key}[[:space:]]*=" "$CONFIG_PATH"; then
            sed -E "s|^([[:space:]]*${key}[[:space:]]*=[[:space:]]*).*|\1${value}|" "$CONFIG_PATH" > "$TMP_PATH"
            mv "$TMP_PATH" "$CONFIG_PATH"
        else
            echo "${key} = ${value}" >> "$CONFIG_PATH"
        fi
    fi

    echo "[hyprconf] key: ${key} = ${value}"
}

# Anim mode

mode_anim() {
    local anim_name="$1" full_params="$2"
    check_safe "$anim_name"
    require_file

    # Regex pattern to match existing animation line
    local pattern="^([[:space:]]*animation[[:space:]]*=[[:space:]]*${anim_name}[[:space:]]*,).*"

    if grep -qE "$pattern" "$CONFIG_PATH"; then
        # Update existing animation parameters
        sed -i -E "s|${pattern}.*|\1 ${full_params}|" "$CONFIG_PATH"
    else
        # Append new animation if it doesn't exist
        warn "Animation '${anim_name}' missing, appending..."
        printf "\nanimation = %s, %s\n" "$anim_name" "$full_params" >> "$CONFIG_PATH"
    fi

    echo "[hyprconf] anim: ${anim_name} updated"
}

# Entrypoint

[[ $# -lt 3 ]] && die "Usage: $0 <key|anim> <name> <value>"

MODE="$1"
ARG1="$2"
ARG2="$3"

case "$MODE" in
    key)  mode_key  "$ARG1" "$ARG2" ;;
    anim) mode_anim "$ARG1" "$ARG2" ;;
    *)    die "Unknown mode '$MODE'" ;;
esac