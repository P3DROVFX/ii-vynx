#!/usr/bin/env bash

# Command: vynx run
echo -e "${BLUE}Killing Quickshell & Reloading Hyprland...${NC}"

pkill -x qs
hyprctl reload

sleep 1.0

nohup qs -c ii > /dev/null 2>&1 &
echo -e "${GREEN}✓ Quickshell started${NC}"
