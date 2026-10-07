// Prints the output name and output-local position of the pointer, e.g. "eDP-1 812 455".
// Sway's IPC can't report the cursor position, so this maps a transparent overlay
// layer surface on every output for a moment and reads the pointer enter event.
// Sway only sends that event on cursor motion, so it nudges the cursor by 0,0.
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/mman.h>
#include <wayland-client.h>
#include "wlr-layer-shell-unstable-v1-client-protocol.h"

struct out {
	struct wl_output *wl;
	char name[64];
	struct wl_surface *surf;
	struct out *next;
};

static struct wl_compositor *compositor;
static struct wl_shm *shm;
static struct wl_seat *seat;
static struct zwlr_layer_shell_v1 *layer_shell;
static struct out *outs;
static int done, mapped;

static void out_geometry(void *d, struct wl_output *o, int32_t x, int32_t y, int32_t pw, int32_t ph,
		int32_t sp, const char *make, const char *model, int32_t t) {}
static void out_mode(void *d, struct wl_output *o, uint32_t f, int32_t w, int32_t h, int32_t r) {}
static void out_done(void *d, struct wl_output *o) {}
static void out_scale(void *d, struct wl_output *o, int32_t s) {}
static void out_name(void *d, struct wl_output *o, const char *name) {
	struct out *out = d;
	snprintf(out->name, sizeof(out->name), "%s", name);
}
static void out_description(void *d, struct wl_output *o, const char *desc) {}
static const struct wl_output_listener output_listener = {
	out_geometry, out_mode, out_done, out_scale, out_name, out_description,
};

static void ptr_enter(void *d, struct wl_pointer *p, uint32_t serial, struct wl_surface *surf,
		wl_fixed_t sx, wl_fixed_t sy) {
	for (struct out *o = outs; o; o = o->next) {
		if (o->surf == surf) {
			printf("%s %d %d\n", o->name, wl_fixed_to_int(sx), wl_fixed_to_int(sy));
			done = 1;
		}
	}
}
static void ptr_leave(void *d, struct wl_pointer *p, uint32_t serial, struct wl_surface *s) {}
static void ptr_motion(void *d, struct wl_pointer *p, uint32_t t, wl_fixed_t x, wl_fixed_t y) {}
static void ptr_button(void *d, struct wl_pointer *p, uint32_t serial, uint32_t t, uint32_t b, uint32_t s) {}
static void ptr_axis(void *d, struct wl_pointer *p, uint32_t t, uint32_t a, wl_fixed_t v) {}
static const struct wl_pointer_listener pointer_listener = {
	ptr_enter, ptr_leave, ptr_motion, ptr_button, ptr_axis,
};

static void seat_caps(void *d, struct wl_seat *s, uint32_t caps) {
	if (caps & WL_SEAT_CAPABILITY_POINTER)
		wl_pointer_add_listener(wl_seat_get_pointer(s), &pointer_listener, NULL);
}
static const struct wl_seat_listener seat_listener = { seat_caps };

static void ls_configure(void *d, struct zwlr_layer_surface_v1 *ls, uint32_t serial, uint32_t w, uint32_t h) {
	struct out *o = d;
	zwlr_layer_surface_v1_ack_configure(ls, serial);
	if (!w || !h)
		return;
	int stride = w * 4, size = stride * h;
	int fd = memfd_create("cursor-pos", MFD_CLOEXEC);
	if (fd < 0 || ftruncate(fd, size) < 0)
		exit(1);
	struct wl_shm_pool *pool = wl_shm_create_pool(shm, fd, size);
	struct wl_buffer *buf = wl_shm_pool_create_buffer(pool, 0, w, h, stride, WL_SHM_FORMAT_ARGB8888);
	wl_shm_pool_destroy(pool);
	close(fd);
	wl_surface_attach(o->surf, buf, 0, 0);
	wl_surface_commit(o->surf);
	mapped++;
}
static void ls_closed(void *d, struct zwlr_layer_surface_v1 *ls) {}
static const struct zwlr_layer_surface_v1_listener layer_surface_listener = { ls_configure, ls_closed };

static void reg_global(void *d, struct wl_registry *r, uint32_t name, const char *iface, uint32_t ver) {
	if (!strcmp(iface, wl_compositor_interface.name)) {
		compositor = wl_registry_bind(r, name, &wl_compositor_interface, 4);
	} else if (!strcmp(iface, wl_shm_interface.name)) {
		shm = wl_registry_bind(r, name, &wl_shm_interface, 1);
	} else if (!strcmp(iface, wl_seat_interface.name) && !seat) {
		seat = wl_registry_bind(r, name, &wl_seat_interface, 1);
		wl_seat_add_listener(seat, &seat_listener, NULL);
	} else if (!strcmp(iface, zwlr_layer_shell_v1_interface.name)) {
		layer_shell = wl_registry_bind(r, name, &zwlr_layer_shell_v1_interface, 1);
	} else if (!strcmp(iface, wl_output_interface.name) && ver >= 4) {
		struct out *o = calloc(1, sizeof(*o));
		o->wl = wl_registry_bind(r, name, &wl_output_interface, 4);
		wl_output_add_listener(o->wl, &output_listener, o);
		o->next = outs;
		outs = o;
	}
}
static void reg_remove(void *d, struct wl_registry *r, uint32_t name) {}
static const struct wl_registry_listener registry_listener = { reg_global, reg_remove };

int main(void) {
	alarm(1); // give up rather than hang if no enter event arrives
	struct wl_display *dpy = wl_display_connect(NULL);
	if (!dpy)
		return 1;
	wl_registry_add_listener(wl_display_get_registry(dpy), &registry_listener, NULL);
	wl_display_roundtrip(dpy);
	wl_display_roundtrip(dpy);
	if (!compositor || !shm || !seat || !layer_shell || !outs)
		return 1;

	for (struct out *o = outs; o; o = o->next) {
		o->surf = wl_compositor_create_surface(compositor);
		struct zwlr_layer_surface_v1 *ls = zwlr_layer_shell_v1_get_layer_surface(layer_shell,
				o->surf, o->wl, ZWLR_LAYER_SHELL_V1_LAYER_OVERLAY, "cursor-pos");
		zwlr_layer_surface_v1_add_listener(ls, &layer_surface_listener, o);
		zwlr_layer_surface_v1_set_anchor(ls, ZWLR_LAYER_SURFACE_V1_ANCHOR_TOP |
				ZWLR_LAYER_SURFACE_V1_ANCHOR_BOTTOM | ZWLR_LAYER_SURFACE_V1_ANCHOR_LEFT |
				ZWLR_LAYER_SURFACE_V1_ANCHOR_RIGHT);
		zwlr_layer_surface_v1_set_exclusive_zone(ls, -1);
		wl_surface_commit(o->surf);
	}

	int n = 0;
	for (struct out *o = outs; o; o = o->next)
		n++;
	while (mapped < n && wl_display_dispatch(dpy) != -1)
		;
	wl_display_roundtrip(dpy);
	if (system("swaymsg -q 'seat - cursor move 0 0'") != 0)
		return 1;
	while (!done && wl_display_dispatch(dpy) != -1)
		;
	wl_display_disconnect(dpy);
	return done ? 0 : 1;
}
