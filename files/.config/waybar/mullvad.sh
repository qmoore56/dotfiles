#!/usr/bin/env bash
# Waybar module: Mullvad VPN status (green lock when connected, white otherwise)
icon=$(printf '')
status=$(mullvad status 2>/dev/null | head -n1)
if [[ $status == Connected* ]]; then
    printf '{"text":"%s","class":"connected","tooltip":"Mullvad: Connected"}\n' "$icon"
else
    printf '{"text":"%s","class":"disconnected","tooltip":"Mullvad: %s"}\n' "$icon" "${status:-Daemon not running}"
fi
