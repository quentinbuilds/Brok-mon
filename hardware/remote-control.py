#!/usr/bin/env python3
"""
Drive the UNO Q from your Mac keyboard over adb.

Relays keypresses to the board's summer-hid-injector (UDP 127.0.0.1:5555 on the board,
installed by setup-board.sh), which turns them into real keyboard/mouse events. So this
works for the game (W/A/S/D + J/K/L) and for the Debian desktop (mouse mode).

Usage:  python3 hardware/remote-control.py
Needs:  adb on PATH, board listed in `adb devices`, setup-board.sh already run once.

Game mode (default)
  arrows / w a s d   joystick (held while you hold the key)
  j  or  z / enter   button A
  k  or  x           button B
  l  or  tab         button C (menu)
  m                  toggle mouse mode
  q / ctrl-c         quit

Mouse mode
  arrows / w a s d   move pointer (hold shift-free; step 25 px)
  space / enter      left click        b   right click
  m                  back to game mode
"""
import json, os, select, subprocess, sys, termios, threading, time, tty

RELAY = r'''
import json, socket, sys
s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
for line in sys.stdin:
    line = line.strip()
    if line:
        s.sendto(line.encode(), ("127.0.0.1", 5555))
'''

HOLD_RELEASE_S = 0.18   # release a "held" key if no repeat arrives within this window
MOUSE_STEP = 25

GAME_KEYS = {
    "\x1b[A": "W", "\x1b[B": "S", "\x1b[D": "A", "\x1b[C": "D",
    "w": "W", "s": "S", "a": "A", "d": "D",
    "j": "J", "z": "J", "\r": "J", "\n": "J",
    "k": "K", "x": "K",
    "l": "L", "\t": "L",
}
MOUSE_MOVES = {
    "\x1b[A": (0, -MOUSE_STEP), "\x1b[B": (0, MOUSE_STEP),
    "\x1b[D": (-MOUSE_STEP, 0), "\x1b[C": (MOUSE_STEP, 0),
    "w": (0, -MOUSE_STEP), "s": (0, MOUSE_STEP), "a": (-MOUSE_STEP, 0), "d": (MOUSE_STEP, 0),
}


class Board:
    def __init__(self):
        self.proc = subprocess.Popen(
            ["adb", "shell", "python3", "-c", RELAY],
            stdin=subprocess.PIPE, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, text=True)
        time.sleep(0.5)
        if self.proc.poll() is not None:
            sys.exit("adb relay failed to start:\n" + self.proc.stderr.read())
        self.held = {}          # key -> last press time
        self.lock = threading.Lock()
        threading.Thread(target=self._releaser, daemon=True).start()

    def send(self, msg: dict):
        try:
            self.proc.stdin.write(json.dumps(msg) + "\n")
            self.proc.stdin.flush()
        except BrokenPipeError:
            sys.exit("lost adb connection")

    def key_down(self, key: str):
        with self.lock:
            fresh = key not in self.held
            self.held[key] = time.monotonic()
        if fresh:
            self.send({"type": "key", "key": key, "action": "down"})

    def _releaser(self):
        while True:
            time.sleep(0.03)
            now = time.monotonic()
            with self.lock:
                expired = [k for k, t in self.held.items() if now - t > HOLD_RELEASE_S]
                for k in expired:
                    del self.held[k]
            for k in expired:
                self.send({"type": "key", "key": k, "action": "up"})

    def release_all(self):
        with self.lock:
            keys = list(self.held)
            self.held.clear()
        for k in keys:
            self.send({"type": "key", "key": k, "action": "up"})

    def close(self):
        self.release_all()
        try:
            self.proc.stdin.close()
            self.proc.terminate()
        except Exception:
            pass


def read_key(fd) -> str:
    ch = os.read(fd, 1).decode(errors="ignore")
    if ch == "\x1b":                         # escape sequence (arrows)
        if select.select([fd], [], [], 0.01)[0]:
            ch += os.read(fd, 2).decode(errors="ignore")
    return ch


def main():
    if subprocess.run(["adb", "get-state"], capture_output=True, text=True).returncode != 0:
        sys.exit("no board in `adb devices` (data cable, no hub, wait 60 s after power-up)")
    board = Board()
    fd = sys.stdin.fileno()
    saved = termios.tcgetattr(fd)
    mouse = False
    print(__doc__)
    print("[game mode] connected. press q to quit.\r")
    try:
        tty.setraw(fd)
        while True:
            k = read_key(fd)
            if k in ("q", "\x03"):
                break
            if k == "m":
                mouse = not mouse
                board.release_all()
                print(f"\r[{'mouse' if mouse else 'game'} mode]\r")
                continue
            if mouse:
                if k in MOUSE_MOVES:
                    dx, dy = MOUSE_MOVES[k]
                    board.send({"type": "mouse_move", "dx": dx, "dy": dy})
                elif k in (" ", "\r", "\n"):
                    board.send({"type": "mouse_click", "button": "left", "action": "tap"})
                elif k == "b":
                    board.send({"type": "mouse_click", "button": "right", "action": "tap"})
            else:
                key = GAME_KEYS.get(k)
                if key:
                    board.key_down(key)
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, saved)
        board.close()
        print("\nbye")


if __name__ == "__main__":
    main()
