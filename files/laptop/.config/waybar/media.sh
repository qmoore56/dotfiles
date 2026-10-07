#!/bin/bash
# Streams the currently active MPRIS player (Spotify, Firefox/Chrome YouTube, mpv, ...)
# to waybar as JSON. playerctld tracks whichever player was most recently active.

playerctl daemon >/dev/null 2>&1

json_escape() {
  local s=$1
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  s=${s//&/&amp;}
  s=${s//</&lt;}
  s=${s//>/&gt;}
  printf '%s' "$s"
}

sep=$'\t'
playerctl -p playerctld metadata --follow \
  --format "{{status}}${sep}{{playerName}}${sep}{{artist}}${sep}{{title}}" 2>/dev/null |
while IFS=$'\t' read -r status player artist title; do
  if [ -z "$status" ] || [ "$status" = "Stopped" ] || [ -z "$title" ]; then
    echo '{"text": "", "class": "stopped"}'
    continue
  fi

  case "$player" in
    spotify)                  picon="󰓇" ;;
    firefox*|chrom*|brave*)   picon="󰗃" ;; # YouTube / browser media
    mpv|vlc)                  picon="󰕼" ;;
    *)                        picon="󰝚" ;;
  esac

  if [ "$status" = "Playing" ]; then
    sicon="󰏤"; class="playing"
  else
    sicon="󰐊"; class="paused"
  fi

  if [ -n "$artist" ]; then
    text="$artist - $title"
  else
    text="$title"
  fi

  text=$(json_escape "$text")
  printf '{"text": "%s %s  %s", "class": "%s", "alt": "%s"}\n' \
    "$sicon" "$picon" "$text" "$class" "$player"
done
