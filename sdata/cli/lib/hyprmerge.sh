#!/usr/bin/env bash

set -uo pipefail

IS_VERBOSE=false
TEMP_ARGS=()

for arg in "$@"; do
    case "$arg" in
        -v|--verbose) IS_VERBOSE=true ;;
        *) TEMP_ARGS+=("$arg") ;;
    esac
done

set -- "${TEMP_ARGS[@]}"

REPO_CONFIG="${1:-}"
LOCAL_CONFIG="${2:-$HOME/.local/share/ii-vynx/hyprland.conf}"
VERBOSE="$IS_VERBOSE"

if [[ -z "$REPO_CONFIG" || ! -f "$REPO_CONFIG" ]]; then
    echo -e "\e[1;31m[ERROR]\e[0m Source config invalid: $REPO_CONFIG"
    exit 1
fi

if [[ ! -f "$LOCAL_CONFIG" ]]; then
    mkdir -p "$(dirname "$LOCAL_CONFIG")"
    touch "$LOCAL_CONFIG"
fi

log()   { [[ "$VERBOSE" == "true" ]] && echo -e "\e[1;34m[VERBOSE] [hyprmerge]\e[0m $*"; }
skip()  { [[ "$VERBOSE" == "true" ]] && echo -e "\e[1;33m[VERBOSE] [SKIP]\e[0m: $*"; }
apply() { echo -e "\e[1;32m[APPLYING]\e[0m: $*"; }

key_exists_in_section() {
    local section="$1" field="$2"
    # Extracts section block and checks for existing key-value pair
    sed -n "/^[[:space:]]*${section}[[:space:]]*{/,/^[[:space:]]*}/ p" "$LOCAL_CONFIG" | grep -qE "^[[:space:]]*${field}[[:space:]]*="
}

current_section=""
log "Merging $REPO_CONFIG into $LOCAL_CONFIG"

while IFS= read -r line || [[ -n "$line" ]]; do
    # Clean whitespace and carriage returns
    trimmed=$(echo "$line" | tr -d '\r' | xargs)
    
    # Ignore empty lines and comments
    [[ -z "$trimmed" || "$trimmed" =~ ^# ]] && continue

    # Detect section entrance (e.g., general { )
    if echo "$trimmed" | grep -q "{"; then
        section_name=$(echo "$trimmed" | cut -d'{' -f1 | xargs)
        if [[ -n "$section_name" ]]; then
            current_section="$section_name"
            continue
        fi
    fi

    # Detect section exit
    if [[ "$trimmed" == "}" ]]; then
        current_section=""
        continue
    fi

    # Parse Key = Value pairs
    if echo "$trimmed" | grep -q "="; then
        field=$(echo "$trimmed" | cut -d'=' -f1 | xargs)
        value=$(echo "$trimmed" | cut -d'=' -f2- | xargs)

        # Handle specific animation rules
        if [[ "$field" == "animation" ]]; then
            anim_name=$(echo "$value" | cut -d',' -f1 | xargs)
            if grep -q "animation = $anim_name" "$LOCAL_CONFIG"; then
                 skip "animation $anim_name"
            else
                apply "animation $anim_name"
                full_params=$(echo "$value" | cut -d',' -f2- | xargs)
                vynx hyprset anim "$anim_name" "$full_params" >/dev/null 2>&1 || true
            fi
            continue
        fi

        # Process Sectioned or Global keys
        if [[ -n "$current_section" ]]; then
            if key_exists_in_section "$current_section" "$field"; then
                 skip "${current_section}:${field}"
            else
                 apply "${current_section}:${field}"
                 vynx hyprset key "${current_section}:${field}" "$value" >/dev/null 2>&1 || true
                 sleep 0.05
            fi
        else
            # Rules that are appended directly to file (binds, execs, etc.)
            if [[ "$field" =~ ^(layerrule|windowrule|windowrulev2|bind|exec|env|monitor)$ ]]; then
                if grep -qF "$trimmed" "$LOCAL_CONFIG"; then
                    skip "rule: $field"
                else
                    apply "rule: $field"
                    echo "$trimmed" >> "$LOCAL_CONFIG"
                fi
            else
                # Handle standard global settings
                if grep -qE "^[[:space:]]*${field}[[:space:]]*=" "$LOCAL_CONFIG"; then
                    skip "$field"
                else
                    apply "$field"
                    vynx hyprset key "$field" "$value" >/dev/null 2>&1 || true
                fi
            fi
        fi
        continue
    fi
done < "$REPO_CONFIG"

log "Merge complete."