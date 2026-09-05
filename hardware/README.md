# Running on the Arduino UNO Q

Official path: the `ship-to-unoq` skill from https://github.com/SummerEngine/summer-uno-q
(cloned to `~/summer-uno-q`, linked into `~/.claude/skills/ship-to-unoq` on the integration
machine). It exports the game headlessly for Linux arm64, provisions the board once, installs the
game as an Arduino App Lab app, and makes it the boot app. Tell Claude Code:

> ship gok-mon to the uno q

It will ask for the game name and an emoji, then do the rest. First deploy takes about five
minutes and needs you to run one `adb shell -t ... setup-board.sh` command in your own terminal
for the sudo password.

## Redeploying after that

Once the board has the game, new builds do not need Claude or the skill's question flow:

```
hardware/redeploy.sh          # tests, exports, installs over the running app
hardware/redeploy.sh --fast   # skip the tests
```

About 45 seconds. It refuses to deploy on a failing suite, and deletes the old zip before
exporting so a silently-failed export cannot ship yesterday's build. `APP_NAME`, `APP_ICON`,
`PRESET`, `GODOT_BIN` and `INSTALLER` are all overridable from the environment.

## Target

| Item | Value |
|---|---|
| Board | Arduino UNO Q, Debian on arm64 (Qualcomm QRB2210, Adreno 702) |
| Display | Waveshare 18396, 5 inch DSI, 800 x 480 landscape |
| Game viewport | 200 x 120, `stretch/mode=viewport`, integer-scaled 4x, fills the panel |
| Renderer | `gl_compatibility` (mandatory on this GPU), `import_etc2_astc=true` |
| Export preset | `Linux arm64 (Uno Q)` in `export_presets.cfg`, separate `.pck`, release |
| Output | `build/game-linux-arm64.zip` (gitignored) |

## Controls: the Modulino bridge sends keyboard keys

The board runs Arduino's Modulino HID bridge. Physical controls arrive in the game as ordinary
keyboard events, so the InputMap in `project.godot` binds them directly. This is a fixed contract.

| Physical | Key sent | InputMap action | InputManager |
|---|---|---|---|
| Joystick up / left / down / right | W / A / S / D | `move_*` | `direction()`, `is_up()` ... |
| Button A | J | `confirm` | `button_a_*` |
| Button B | K | `cancel` | `button_b_*` |
| Button C | L | `menu` | `button_menu_*` |

Desktop aliases stay bound: arrows, Z or Enter, X or Backspace, Tab. A real gamepad also works.
`tests/test_input_bindings.gd` fails if anyone removes the W/A/S/D or J/K/L bindings.

**UI text must say "joystick", "A", "B", "C". Never print key names.** Players hold a handheld.

## Prerequisites (integration machine)

- `adb` (installed: Android platform-tools via Homebrew). Board on a data USB-C cable, direct,
  allow up to a minute after power-up before `adb devices` lists it.
- Linux arm64 export templates for this exact engine build, installed on 2026-09-05 to
  `~/Library/Application Support/Godot/export_templates/4.7.2.stable.mono/`
  from `SummerEngine/summer-builds` release `templates`,
  asset `summer-linux-templates-4.7.2.stable.mono.tpz`.

## Manual export (what the skill runs)

```sh
mkdir -p build
/Applications/Summer.app/Contents/MacOS/Summer --headless --path . \
  --export-release "Linux arm64 (Uno Q)" build/game-linux-arm64.zip
ls -la build/game-linux-arm64.zip   # exit 0 without a fresh zip is NOT success
```

## Troubleshooting (short)

| Symptom | Fix |
|---|---|
| `adb devices` empty | data cable, no hub, wait 60 s |
| Textures pink or black on board | preset needs `etc2_astc=true`; re-import then re-export |
| Game runs but frozen at 0% CPU | board not provisioned; re-run `setup-board.sh` |
| Buttons do nothing, keyboard works | Modulinos unplugged or bridge not flashed; redeploy |

Full troubleshooting table: `~/summer-uno-q/SKILL.md`.
