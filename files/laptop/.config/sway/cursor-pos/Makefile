PROTO = wlr-layer-shell-unstable-v1
XDG = /usr/share/wayland-protocols/stable/xdg-shell/xdg-shell.xml

cursor-pos: cursor-pos.c $(PROTO)-protocol.c $(PROTO)-client-protocol.h xdg-shell-protocol.c
	$(CC) -O2 -Wall -I. -o $@ cursor-pos.c $(PROTO)-protocol.c xdg-shell-protocol.c $$(pkg-config --cflags --libs wayland-client)

$(PROTO)-client-protocol.h: $(PROTO).xml
	wayland-scanner client-header $< $@

$(PROTO)-protocol.c: $(PROTO).xml
	wayland-scanner private-code $< $@

xdg-shell-protocol.c: $(XDG)
	wayland-scanner private-code $< $@
