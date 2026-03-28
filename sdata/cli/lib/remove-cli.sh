#!/usr/bin/env bash

# Command: vynx remove-cli
BIN_PATH="/usr/local/bin/vynx"

echo -e "${RED}• Removing Vynx CLI from the system (requires sudo)...${NC}"

if [ -L "$BIN_PATH" ]; then
    sudo rm "$BIN_PATH"
    echo -e "${GREEN}✓ Vynx CLI has been successfully removed from $BIN_PATH.${NC}"
    echo -e "${BLUE}The repository at $BASE_DIR remains intact.${NC}"
else
    echo -e "${YELLOW}Vynx CLI (/usr/local/bin/vynx) not found.${NC}"
fi
