#!/usr/bin/env bash

# Command: vynx update
echo -e "${BLUE}Updating Vynx...${NC}"

export VERBOSE="${VERBOSE:-false}"

SETUP_FLAGS="--no-confirm --no-backup"
[[ "$VERBOSE" == "true" ]] && SETUP_FLAGS="$SETUP_FLAGS -v"

if [ -d "$BASE_DIR" ]; then
    cd "$BASE_DIR"
    if [[ "$VERBOSE" == "true" ]]; then
        git pull
    else
        git pull > /dev/null 2>&1
    fi
    
    echo -e "${GREEN}Vynx repo updated successfully!${NC}"
    
    bash setup-ii-vynx.sh $SETUP_FLAGS
else
    echo -e "${RED}Error: Cannot find install path.${NC}"
    exit 1
fi