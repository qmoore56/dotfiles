#!/bin/bash
# Streams the currently active MPRIS player (Spotify, Firefox/Chrome YouTube, mpv, ...)
# to waybar as JSON. playerctld tracks whichever player was most recently active.
#
# The player icon is shown by the "image#media" module: for browser media it's the
# site's favicon (pulled from Firefox's local favicon cache), otherwise a nerd font
# glyph rendered to a png. The chosen path is written to $cache/current and the
# image module is refreshed with SIGRTMIN+8.

playerctl daemon >/dev/null 2>&1

cache=${XDG_CACHE_HOME:-$HOME/.cache}/waybar-media
mkdir -p "$cache"
ffprofile=$(ls -d "$HOME"/.config/mozilla/firefox/*.default-release \
  "$HOME"/.mozilla/firefox/*.default-release 2>/dev/null | head -n1)

json_escape() {
  local s=$1
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  s=${s//&/&amp;}
  s=${s//</&lt;}
  s=${s//>/&gt;}
  printf '%s' "$s"
}

last_icon=unset
set_icon() {
  [ "$1" = "$last_icon" ] && return
  last_icon=$1
  printf '%s\n' "$1" > "$cache/current"
  pkill -RTMIN+8 -x waybar
}

# Renders a nerd font glyph to a png once, prints its path
glyph_icon() {
  local f="$cache/glyph-$1.png"
  [ -s "$f" ] || printf '<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64"><text x="32" y="52" font-family="IntoneMono Nerd Font Mono" font-size="58" fill="#ffffff" text-anchor="middle">%s</text></svg>' "$2" |
    rsvg-convert -o "$f" 2>/dev/null
  [ -s "$f" ] && printf '%s' "$f"
}

# Prints the cached favicon path for a page url, extracting it from Firefox if needed
favicon() {
  [[ $1 =~ ^(https?)://([A-Za-z0-9.-]+)(:[0-9]+)?(/|$) ]] || return
  local origin="${BASH_REMATCH[1]}://${BASH_REMATCH[2]}${BASH_REMATCH[3]}"
  local f="$cache/fav-${BASH_REMATCH[2]}"
  if [ ! -s "$f" ] && [ -n "$ffprofile" ]; then
    # Firefox keeps the db locked, so query a copy
    local tmp
    tmp=$(mktemp -d) || return
    cp "$ffprofile"/favicons.sqlite* "$tmp"/ 2>/dev/null
    # smallest icon that's at least 32px, falling back to the largest one
    sqlite3 "$tmp/favicons.sqlite" "SELECT writefile('$f', i.data) FROM moz_icons i
      JOIN moz_icons_to_pages ip ON ip.icon_id = i.id
      JOIN moz_pages_w_icons p ON p.id = ip.page_id
      WHERE p.page_url LIKE '$origin/%' AND i.data IS NOT NULL
      ORDER BY (i.width < 32), CASE WHEN i.width < 32 THEN -i.width ELSE i.width END
      LIMIT 1;" >/dev/null 2>&1
    rm -rf "$tmp"
  fi
  [ -s "$f" ] && printf '%s' "$f"
}

set_icon ""

sep=$'\t'
playerctl -p playerctld metadata --follow \
  --format "{{status}}${sep}{{artist}}${sep}{{title}}${sep}{{xesam:url}}" 2>/dev/null |
while IFS=$'\t' read -r status artist title url; do
  if [ -z "$status" ] || [ "$status" = "Stopped" ] || [ -z "$title" ]; then
    set_icon ""
    echo '{"text": "", "class": "stopped"}'
    continue
  fi

  # {{playerName}} via playerctld is always "playerctld"; ask it for the real active player
  player=$(busctl --user get-property org.mpris.MediaPlayer2.playerctld /org/mpris/MediaPlayer2 \
    com.github.altdesktop.playerctld PlayerNames 2>/dev/null |
    sed -n 's/^as [0-9]* "org\.mpris\.MediaPlayer2\.\([^".]*\).*/\1/p')

  icon=
  case "$player" in
    spotify)                  icon=$(glyph_icon spotify "󰓇") ;;
    firefox*|chrom*|brave*)   icon=$(favicon "$url")
                              [ -n "$icon" ] || icon=$(glyph_icon browser "󰖟") ;;
    mpv|vlc)                  icon=$(glyph_icon video "󰕼") ;;
  esac
  [ -n "$icon" ] || icon=$(glyph_icon music "󰝚")
  set_icon "$icon"

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
  printf '{"text": "%s  %s", "class": "%s", "alt": "%s"}\n' \
    "$sicon" "$text" "$class" "$player"
done
