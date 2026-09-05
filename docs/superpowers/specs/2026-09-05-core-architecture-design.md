# Core Architecture Design — AI-Native Game Boy (gok-mon)

Date: 2026-09-05
Owner: Person 1 (core and integration)
Status: approved in brainstorm, awaiting user review of this document

## 1. Context

The PRD (`/PRD`) describes a 12-hour hackathon building a Game Boy-inspired
monster-catching game for the Arduino UNO Q using Summer Engine. Six developers
work in parallel on one repository. This document is the design for the core
and integration layer that the other five subsystems plug into.

### Facts established during brainstorm

- **Summer Engine is Godot 4.6.1 (Mono build) plus an AI layer.** Projects are
  ordinary Godot projects. Summer adds a `.summer/` project-memory folder and an
  MCP bridge on `localhost:6550` that lets Claude Code or Cursor mutate scenes,
  play the game, and read diagnostics. The desktop app (`/Applications/Summer.app`,
  v0.5.65) is installed on the integration machine. Its `Contents/MacOS/Summer`
  binary is the Godot editor and can be run headless from the terminal.
- **The UNO Q runs Debian on arm64.** The STM32 side reads the Modulino joystick
  and buttons; a Python daemon on the Linux side exposes them as a standard
  virtual gamepad. The game therefore sees a normal gamepad and never touches
  hardware APIs.
- **Display is Waveshare SKU 18396, 5-inch DSI, 800x480 landscape.**
- **Internal resolution is 200x120, integer-scaled 4x** to fill 800x480 exactly.
  8px tiles give a 25x15 tile view; an 8px pixel font renders 32px tall on the
  panel.
- The Godot project root is the repository root.

## 2. Goals and non-goals

Goals

- A running game from hour one: BOOT → TITLE → OVERWORLD → BATTLE → CATCHING →
  OVERWORLD, plus MENU, all with placeholder screens and debug keys.
- Stable interfaces (states, events, input, data) so five other developers can
  work in their own folders without editing `core/`.
- Runs on a Mac with keyboard and on the UNO Q with the gamepad daemon with no
  code change.
- Headless tests for the core so regressions in transitions or data are caught.

Non-goals (owned by other people, not built here)

- Map, player art, movement feel, collision (Person 2).
- Creature definitions, encounter probability (Person 3).
- Battle mechanics and presentation (Person 4).
- Catch algorithm, inventory rules, party UI (Person 5).
- Visual identity, fonts, transitions, audio (Person 6).
- The UNO Q gamepad daemon itself (treated as plug-and-play per PRD §11).

## 3. Repository and project layout

```
project.godot                Godot project at repo root
.summer/                     Summer project memory (committed)
.godot/                      Godot cache (gitignored)
core/                        Person 1 territory
  Main.tscn                  Root scene: WorldLayer + OverlayLayer
  GameState.gd               Autoload: state machine
  GameStateBase.gd           Base class every state extends
  InputManager.gd            Autoload: input abstraction
  EventBus.gd                Autoload: cross-system signals
  GameData.gd                Autoload: player party, inventory, position
  config/GameConfig.gd       Tunable constants (encounter %, cooldown, debug flags)
title/       TitleState.tscn                                  (core stub → Person 6)
world/       OverworldState.tscn, map, player, camera, zones  (Person 2)
creatures/   Creature.gd, data/*.tres, sprites                (Person 3)
encounters/  EncounterSystem.gd                               (Person 3)
battle/      BattleState.tscn                                 (Person 4)
catching/    CatchingState.tscn, inventory, party logic       (Person 5)
menu/        MenuState.tscn                                   (Person 5 / 6)
ui/          theme, pixel font, panels, transitions           (Person 6)
assets/      sprites/ tiles/ backgrounds/ audio/
tests/       run.sh, run_tests.gd, test_*.gd
docs/        ARCHITECTURE.md, superpowers/specs/
hardware/    README.md: UNO Q run notes, gamepad mapping, export checklist
CLAUDE.md    PRD §20 master philosophy for every agent
```

Ownership rule: each state folder belongs to one person. Core owns `core/`,
`project.godot`, `docs/`, `hardware/`, `CLAUDE.md`, and the stub scenes until
their owner replaces them.

## 4. Project settings

| Setting | Value |
|---|---|
| Viewport size | 200 x 120 |
| Window size | 800 x 480 |
| Stretch mode / aspect / scale | `viewport`, `keep`, integer scaling on |
| Default texture filter | Nearest |
| Physics / render | 60 fps |
| Rendering method | Compatibility (GL) for arm64 reliability |
| Autoload order | EventBus, InputManager, GameData, GameState |
| Main scene | `core/Main.tscn` |

`.gitignore`: `.godot/`, `export/`, `*.import` is kept (Godot needs them), OS
junk.

## 5. Autoloads

### 5.1 EventBus

Declares exactly the PRD §12 signals, typed, and nothing else:

```
player_moved(tile: Vector2i, in_encounter_zone: bool)
encounter_triggered(wild: Creature)
battle_started(player_creature: Creature, wild: Creature)
battle_won(wild: Creature)
battle_lost()
battle_escaped()
catch_started(wild: Creature)
creature_caught(wild: Creature)
catch_failed(wild: Creature)
menu_opened()
menu_closed()
inventory_changed(inventory: Dictionary)
party_changed(party: Array[Creature])
active_creature_changed(creature: Creature)
```

Subsystems communicate across folders only through these signals or through
`GameState.transition_to`.

### 5.2 InputManager

Seven InputMap actions defined in `project.godot`:
`move_up`, `move_down`, `move_left`, `move_right`, `confirm`, `cancel`, `menu`.

Default bindings

| Action | Keyboard | Gamepad (UNO Q daemon) |
|---|---|---|
| move_up/down/left/right | Arrow keys | D-pad |
| confirm | Z, Enter | A (button 0) |
| cancel | X, Backspace | B (button 1) |
| menu | Tab | Start |

Public API, matching PRD §5 names:

```
is_up() / is_down() / is_left() / is_right() -> bool
button_a_pressed() / button_b_pressed() / button_menu_pressed() -> bool
button_a_just_pressed() / button_b_just_pressed() / button_menu_just_pressed() -> bool
direction() -> Vector2i        # 4-way only, no diagonals; vertical wins ties
```

Gameplay code never calls `Input` directly. Physical remapping is a
project-settings edit only.

### 5.3 GameData

Holds player data, not rules:

```
party: Array[Creature]          # max GameConfig.PARTY_SIZE (3)
active_index: int
inventory: Dictionary           # Item id (StringName) -> count
player_tile: Vector2i           # last overworld position
reset()
add_to_party(c) -> bool         # false when full; emits party_changed
remove_from_party(c)
set_active(index)               # emits active_creature_changed
add_item(id, n) / use_item(id) -> bool   # emits inventory_changed
```

Items: `&"capture_orb"`, `&"potion"`. Starting inventory and starter creature
come from `GameConfig`. Person 5's catching logic calls this API.

### 5.4 GameState

```
enum State { BOOT, TITLE, OVERWORLD, BATTLE, CATCHING, MENU }
current: State
transition_to(target: State, payload: Dictionary = {})
```

Legal transitions (PRD §5), enforced by a table; an illegal request logs an
error and does nothing:

```
BOOT      → TITLE
TITLE     → OVERWORLD
OVERWORLD → BATTLE, MENU
BATTLE    → CATCHING, OVERWORLD
CATCHING  → OVERWORLD, BATTLE
MENU      → OVERWORLD
```

Core subscribes to EventBus and drives transitions on behalf of subsystems:

| Event | Core action |
|---|---|
| encounter_triggered(wild) | transition_to(BATTLE, {wild}) |
| battle_won / battle_lost / battle_escaped | transition_to(OVERWORLD) |
| creature_caught(wild) | transition_to(OVERWORLD) |
| catch_failed(wild) | transition_to(BATTLE, {wild, resume: true}) |

States request their own exits (Title → Overworld, Menu → Overworld, Battle →
Catching) by calling `transition_to` directly. States never reference each
other.

## 6. Scene model: two layers, not a stack

`core/Main.tscn`:

```
Main
├── WorldLayer      Overworld lives here, instantiated once, persistent
└── OverlayLayer    Title / Battle / Catching / Menu, one at a time
```

- Entering an overlay state hides `WorldLayer` and sets its
  `process_mode = DISABLED`, so movement, encounters, and animation stop.
- Exiting an overlay with nothing replacing it shows and re-enables
  `WorldLayer` at the same position. Player position survives Battle and Menu
  round trips without any save/restore code.
- Overlay swap = `exit()` old, free it, instantiate new, `enter(payload)`.
- A `TransitionHook` (fade in/out) is a no-op function Person 6 fills in.

## 7. State contract

`core/GameStateBase.gd` extends `Node`:

```
func enter(payload: Dictionary) -> void
func update(delta: float) -> void      # called by GameState each frame while active
func exit() -> void
static func debug_payload() -> Dictionary   # override for standalone runs
```

Rendering is ordinary Godot node drawing; there is no separate `render()`.

Standalone rule: if a state scene is run directly (F6) and `Main` is not the
scene root, `GameStateBase._ready()` calls `enter(debug_payload())` so every
state is independently runnable, as the PRD requires.

Payloads

| State | Payload keys |
|---|---|
| BATTLE | `wild: Creature`, optional `resume: bool` after a failed catch |
| CATCHING | `wild: Creature` |
| others | none |

## 8. Data contract

`creatures/Creature.gd` is a `Resource` with the PRD §4 fields:
`id: int, name: String, sprite: Texture2D, type: StringName, max_hp, hp, attack,
defense: int, catch_rate: float`, plus `make_instance() -> Creature` returning
a duplicate with `hp = max_hp`. Definitions live as `creatures/data/*.tres`
(Person 3). Core ships one placeholder creature so battles run before Person 3
lands.

## 9. Debug controls

Behind `GameConfig.DEBUG_KEYS` (true in editor, false in export):

| Key | Effect |
|---|---|
| F1 | emit `encounter_triggered` with the placeholder creature |
| F2 | force next catch to succeed |
| F3 | force next catch to fail |
| F4 | print current state and GameData summary |

## 10. Testing

- `tests/run.sh` runs
  `/Applications/Summer.app/Contents/MacOS/Summer --headless --path . --script tests/run_tests.gd`.
- `run_tests.gd` loads each `tests/test_*.gd`, runs every `test_*` method, and
  exits non-zero on any failure. No framework dependency.
- Core tests: legal/illegal transitions; InputManager just-pressed edge
  detection via `Input.action_press/release`; GameData party cap, inventory
  decrement, signal emission; EventBus signal existence and arity.
- Runtime verification: Summer MCP play + screenshot while the editor is open;
  the end-to-end loop in §12 walked by hand.

## 11. Tooling workflow

1. `npx -y summer-engine@latest setup claude-code --yes` on the integration
   machine (writes skills to `~/.claude/skills/` and the MCP entry). Cursor
   users run the Cursor equivalent.
2. Open the repo in Summer.app once so `.summer/` and the bridge exist.
3. Scene mutations, play, diagnostics via Summer MCP; code via normal editing.

## 12. Hardware delivery

- Export preset `Linux arm64` (release, single binary + pack) to `export/`.
- Copy to the UNO Q over ssh; run fullscreen on the 800x480 panel.
- Input arrives through the board's gamepad daemon; nothing in the game changes.
- `hardware/README.md` records: button mapping table, export command, ssh/run
  steps, and a fallback if the daemon is absent on the day (keyboard over USB).
- **Risk to verify first:** the arm64 Linux export template must be available
  for Summer's Godot build. Check during skeleton implementation; if missing,
  fall back to stock Godot 4.6.1 templates, which are compatible with a plain
  GDScript project.

## 13. Integration documentation

- `docs/ARCHITECTURE.md`: ownership table, state diagram, event list with
  types, InputManager API, GameData API, "how to add your feature" walkthrough
  (extend GameStateBase, emit EventBus signals, never edit `core/`).
- `CLAUDE.md` at repo root carrying the PRD §20 philosophy so every agent on
  every branch reads the same rules.
- Branches created from `main` after the skeleton merges:
  `feature/core`, `feature/world`, `feature/encounters`, `feature/battle`,
  `feature/catching`, `feature/ui`.

## 14. Definition of done for this skeleton

1. Project opens in Summer.app with no errors and runs at 200x120 in an 800x480
   window with crisp scaling.
2. BOOT → TITLE (press confirm) → OVERWORLD shows a placeholder square that
   moves 4-way with arrow keys and stops when input stops.
3. F1 forces a placeholder Battle; confirm in the stub Battle goes to Catching;
   Catching returns to Overworld at the same position; F3 path returns to Battle.
4. Menu opens over Overworld with `menu` and closes with `cancel`; Overworld is
   frozen while Menu is open.
5. Every state scene runs standalone with F6.
6. `tests/run.sh` passes.
7. `docs/ARCHITECTURE.md`, `hardware/README.md`, `CLAUDE.md` exist and match
   the code.
