#!/bin/sh
# Start wpaperd. On the first run of a login session, show galaxy-1.jpg;
# on later sway reloads, keep whatever wallpaper was showing.
marker="$XDG_RUNTIME_DIR/wpaperd-login-done"
wall="$HOME/wallpapers/galaxy-1.jpg"

if [ -e "$marker" ]; then
    current=$(wpaperctl get-wallpaper eDP-1 2>/dev/null)
    [ -n "$current" ] && wall="$current"
fi
touch "$marker"

pkill -x wpaperd
while pgrep -x wpaperd >/dev/null; do sleep 0.1; done
wpaperd -d

# wait until the daemon has shown its first image, then set ours
for _ in $(seq 100); do
    wpaperctl get-wallpaper eDP-1 >/dev/null 2>&1 && break
    sleep 0.1
done
wpaperctl set-wallpaper "$wall"
