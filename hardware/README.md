# Running on the Arduino UNO Q

The game never talks to hardware. It reads Godot InputMap actions, which are bound to both a
keyboard and a standard gamepad. On the UNO Q, the board's Python daemon presents the Modulino
joystick and buttons as a virtual gamepad, so the same build runs unchanged.

## Target

| Item | Value |
|---|---|
| Board | Arduino UNO Q (Debian, arm64 Cortex-A53) |
| Display | Waveshare 18396, 5 inch DSI, 800 x 480 landscape |
| Game viewport | 200 x 120, integer-scaled 4x, fills the panel exactly |
| Controls | Modulino Joystick + Modulino Buttons via gamepad daemon |

## Button mapping

Expected gamepad events from the daemon and the InputMap actions they hit. Remap in
`project.godot` under `[input]` if the daemon differs.

| Physical | Gamepad | Action |
|---|---|---|
| Joystick up/down/left/right | D-pad 11/12/13/14 or axes 0/1 | `move_*` |
| Button 1 | A (button 0) | `confirm` |
| Button 2 | B (button 1) | `cancel` |
| Button 3 | Start (button 6) | `menu` |

Keyboard equivalents for desktop: arrows, Z or Enter, X or Backspace, Tab.

## Export

1. In Summer.app: Project > Export > Add > Linux, architecture `arm64`, release, embed PCK.
   Output: `export/gok-mon.arm64`.
2. Or headless:
   ```sh
   /Applications/Summer.app/Contents/MacOS/Summer --headless --path . \
     --export-release "Linux arm64" export/gok-mon.arm64
   ```
3. Export templates for this exact engine build (4.7.2 Summer) must be installed first.
   Check Editor > Manage Export Templates in Summer.app. **Status on 2026-09-05: no templates
   installed on the integration machine yet.** Verify early on hackathon day.

## Run on the board

```sh
scp export/gok-mon.arm64 arduino@<board-ip>:~/
ssh arduino@<board-ip>
chmod +x gok-mon.arm64
./gok-mon.arm64 --fullscreen --rendering-driver opengl3   # GL Compatibility renderer
```
Use `--rendering-driver opengl3_es` if the desktop GL path fails on the Qualcomm GPU.

## Fallback if the gamepad daemon is missing

Plug a USB keyboard into the UNO Q. The keyboard bindings above work out of the box.
