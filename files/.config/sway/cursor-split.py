#!/usr/bin/env python3
# Hyprland-style placement for sway: a new tiled window opens on the side of the
# previously focused window that the cursor is closest to (bottom -> below,
# left -> to the left, etc).

import json
import os
import socket
import struct
import subprocess

CURSOR_POS = os.path.expanduser("~/.config/sway/cursor-pos/cursor-pos")
MAGIC = b"i3-ipc"
RUN_COMMAND, GET_OUTPUTS, SUBSCRIBE, GET_TREE = 0, 3, 2, 4


class Sway:
    def __init__(self):
        self.sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        self.sock.connect(os.environ["SWAYSOCK"])

    def _recv(self, n):
        buf = b""
        while len(buf) < n:
            chunk = self.sock.recv(n - len(buf))
            if not chunk:
                raise ConnectionError("sway closed the IPC socket")
            buf += chunk
        return buf

    def send(self, kind, payload=""):
        data = payload.encode()
        self.sock.sendall(MAGIC + struct.pack("<II", len(data), kind) + data)

    def read(self):
        length, kind = struct.unpack("<II", self._recv(len(MAGIC) + 8)[len(MAGIC):])
        return kind, json.loads(self._recv(length))

    def request(self, kind, payload=""):
        self.send(kind, payload)
        return self.read()[1]


def find(node, con_id, parent=None):
    if node["id"] == con_id:
        return node, parent
    for child in node["nodes"] + node["floating_nodes"]:
        found = find(child, con_id, node)
        if found[0]:
            return found
    return None, None


def find_focused(node):
    if node.get("focused"):
        return node["id"]
    for child in node["nodes"] + node["floating_nodes"]:
        found = find_focused(child)
        if found:
            return found
    return None


def cursor_position(sway):
    try:
        out = subprocess.run([CURSOR_POS], capture_output=True, text=True, timeout=1).stdout.split()
    except (OSError, subprocess.TimeoutExpired):
        return None
    if len(out) != 3:
        return None
    name, x, y = out[0], int(out[1]), int(out[2])
    for output in sway.request(GET_OUTPUTS):
        if output["name"] == name:
            return output["rect"]["x"] + x, output["rect"]["y"] + y
    return None


def place(sway, prev_id, new_id):
    tree = sway.request(GET_TREE)
    prev, prev_parent = find(tree, prev_id)
    new, parent = find(tree, new_id)
    if not prev or not new or parent is not prev_parent or parent["layout"] not in ("splith", "splitv"):
        return
    if new in parent["floating_nodes"] or prev in parent["floating_nodes"]:
        return

    # sway put the new window right after the old one, splitting its space,
    # so together they cover where the old window was when the cursor chose.
    siblings = parent["nodes"]
    if siblings.index(new) != siblings.index(prev) + 1:
        return
    a, b = prev["rect"], new["rect"]
    x0, y0 = min(a["x"], b["x"]), min(a["y"], b["y"])
    x1 = max(a["x"] + a["width"], b["x"] + b["width"])
    y1 = max(a["y"] + a["height"], b["y"] + b["height"])

    pos = cursor_position(sway)
    if not pos or not (x0 <= pos[0] < x1 and y0 <= pos[1] < y1):
        return
    fx = (pos[0] - x0) / (x1 - x0) - 0.5
    fy = (pos[1] - y0) / (y1 - y0) - 0.5
    if abs(fy) > abs(fx):
        layout, after, back = "splitv", fy > 0, "up"
    else:
        layout, after, back = "splith", fx > 0, "left"

    cmds = []
    if parent["layout"] != layout:
        if len(siblings) == 2:
            cmds.append(f"[con_id={prev_id}] layout {layout}")
        else:
            # nest the old window in a new split and move the new window in after it
            cmds += [
                f"[con_id={prev_id}] mark --add _cursor_split",
                f"[con_id={prev_id}] split {layout[5]}",
                f"[con_id={new_id}] move container to mark _cursor_split",
                f"[con_id={prev_id}] unmark _cursor_split",
            ]
    if not after:
        cmds.append(f"[con_id={new_id}] move {back}")
    if cmds:
        cmds.append(f"[con_id={new_id}] focus")
        sway.request(RUN_COMMAND, "; ".join(cmds))


def main():
    events, commands = Sway(), Sway()
    events.request(SUBSCRIBE, json.dumps(["window"]))
    focused = find_focused(commands.request(GET_TREE))
    while True:
        _, event = events.read()
        con = event.get("container") or {}
        if event.get("change") == "new" and focused is not None:
            try:
                place(commands, focused, con["id"])
            except (KeyError, ValueError):
                pass
        if event.get("change") == "focus":
            focused = con.get("id")


if __name__ == "__main__":
    main()
