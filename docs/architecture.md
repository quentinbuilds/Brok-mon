# Architecture and integration guide

Design spec: `docs/superpowers/specs/2026-09-05-core-architecture-design.md`.
This file is the working reference for teammates. If code and this file disagree, fix one and
tell the integration owner.

## Who owns what

| Folder | Owner | Contents |
|---|---|---|
| `core/` | Person 1 | `Main.tscn`, autoloads, `GameStateBase`, `config/GameConfig.gd` |
| `title/` | Person 6 | `TitleState.tscn` |
| `world/` | Person 2 | `OverworldState.tscn`, map, player, camera, encounter zones |
| `creatures/` | Person 3 | `Creature.gd` (core-owned contract), `data/*.tres`, sprites |
| `encounters/` | Person 3 | `EncounterSystem` |
| `battle/` | Person 4 | `BattleState.tscn` |
| `catching/` | Person 5 | `CatchingState.tscn`, catch odds, party and inventory rules |
| `menu/` | Person 5 / 6 | `MenuState.tscn` |
| `ui/` | Person 6 | theme, pixel font, panels, transitions |
| `assets/` | everyone | `sprites/ tiles/ backgrounds/ audio/`, original only |
| `tests/` | everyone | `tests/run.sh`, `test_*.gd` |
| `hardware/` | Person 1 | UNO Q notes and export checklist |

Every state folder currently holds a **placeholder stub** that already transitions correctly.
Replace the stub's visuals and logic; keep the contract listed in its script header.

## Screen

200 x 120 internal viewport, integer-scaled 4x to the 800 x 480 Waveshare panel.
Nearest-neighbour filtering. 8 px tiles give a 25 x 15 tile view. An 8 px font is 32 px tall on
the real screen, so it stays readable.

## Autoloads (load order)

### EventBus
Exactly the PRD §12 signals. Typed. Emit from your subsystem, connect from yours, never add a
signal without telling Person 1.

```
player_moved(tile: Vector2i, in_encounter_zone: bool)     world -> encounters
encounter_triggered(wild: Creature)                        encounters -> core (OVERWORLD -> BATTLE)
battle_started(player_creature, wild)                      battle
battle_won(wild) / battle_lost() / battle_escaped()        battle -> core (-> OVERWORLD)
catch_started(wild) / creature_caught(wild) / catch_failed(wild)   catching -> core
menu_opened() / menu_closed()                              menu
inventory_changed(inventory) / party_changed(party) / active_creature_changed(creature)   GameData
```

### InputManager
```
is_up() is_down() is_left() is_right()           held
direction() -> Vector2i                          4-way, no diagonals, vertical wins
direction_just_pressed() -> Vector2i             edge-triggered, for menus
button_a_pressed() button_b_pressed() button_menu_pressed()
button_a_just_pressed() button_b_just_pressed() button_menu_just_pressed()
```
A = confirm, B = cancel, MENU = menu. Bindings live in `project.godot` under `[input]`.
On the UNO Q the Modulino bridge sends **keyboard keys**: joystick = W/A/S/D, buttons A/B/C =
J/K/L. Desktop aliases for playtesting on Mac/Windows: movement = arrows or WASD,
A = Space, Enter or Z, B = Escape, Backspace or X, C/MENU = Escape or Tab. A gamepad also works.
`tests/test_input_bindings.gd` guards this. In UI text say "joystick", "A", "B", "C", never key
names. See `hardware/README.md`.

### GameData
```
party: Array[Creature]   active_index: int   inventory: Dictionary   player_tile: Vector2i
reset()
get_active_creature() get_party()
add_to_party(c) -> bool          false when full (GameConfig.PARTY_SIZE = 3), emits party_changed
remove_from_party(c)             emits party_changed (+ active_creature_changed if index moved)
set_active(index)                emits active_creature_changed
get_inventory() get_item_count(item)
add_item(item, n) use_item(item) -> bool     emit inventory_changed
```
Item ids: `GameData.ITEM_CAPTURE_ORB`, `GameData.ITEM_POTION`.

### GameState
```
enum State { BOOT, TITLE, OVERWORLD, BATTLE, CATCHING, MENU }
current: State
transition_to(to: State, payload := {}) -> bool     false + error if illegal
can_transition(to) -> bool
signal state_changed(from, to)
transition_hook: Callable(from, to)                 Person 6: fades go here
```
Legal transitions:
```
BOOT -> TITLE
TITLE -> OVERWORLD
OVERWORLD -> BATTLE | MENU
BATTLE -> CATCHING | OVERWORLD
CATCHING -> OVERWORLD | BATTLE
MENU -> OVERWORLD
```
Core reacts to events so subsystems never call each other:

| Event | Core does |
|---|---|
| `encounter_triggered(wild)` while OVERWORLD | `transition_to(BATTLE, {wild})` |
| `battle_won` / `battle_lost` / `battle_escaped` while BATTLE | `transition_to(OVERWORLD)` |
| `creature_caught(wild)` while CATCHING | `transition_to(OVERWORLD)` |
| `catch_failed(wild)` while CATCHING | `transition_to(BATTLE, {wild, resume: true})` |

## Scene model

```
Main (core/Main.tscn)
├── WorldLayer   (Node2D)       OVERWORLD lives here, created once, never freed
└── OverlayLayer (CanvasLayer)  TITLE / BATTLE / CATCHING / MENU, one at a time
```
When an overlay enters, the overworld is hidden and `process_mode = DISABLED`, so movement,
encounters, and animations stop. When the overlay exits, the overworld is shown and resumed at
the same position. OverlayLayer is a CanvasLayer so the overworld Camera2D does not move overlays.

## State contract

Your state scene's root **must extend `GameStateBase`** (a Node2D). Put Controls as children.

```gdscript
extends GameStateBase

func _on_enter() -> void:        # payload is set; read payload["wild"] etc.
func update(delta: float) -> void:   # called each frame while active; read InputManager here
func exit() -> void:             # about to be freed (overlays) 
func debug_payload() -> Dictionary:  # what to use when run standalone with F6
```
Payload keys: BATTLE gets `wild: Creature` and optionally `resume: bool`; CATCHING gets
`wild: Creature`. Others get `{}`.

Run any state scene alone with F6: `GameStateBase` notices it is the current scene and calls
`enter(debug_payload())`.

## Creature

`creatures/Creature.gd` is a Resource: `id, name, sprite, type, max_hp, hp, attack, defense,
catch_rate`. Definitions are `creatures/data/*.tres`. Call `make_instance()` to get a healed copy
before using one in battle or adding it to the party. `is_fainted()` is `hp <= 0`.

## Config

`core/config/GameConfig.gd`: `PARTY_SIZE`, starting items, `ENCOUNTER_CHANCE`,
`ENCOUNTER_COOLDOWN_STEPS`, `debug_force_catch`. Add your tunables here rather than hardcoding.

## Debug keys (editor / debug builds only)

| Key | Effect |
|---|---|
| F1 | force an encounter with the placeholder wild creature (in OVERWORLD) |
| F2 | force next catch to succeed |
| F3 | force next catch to fail |
| F4 | print state, party, inventory |

## How to add your feature

1. `git checkout main && git pull && git checkout -b feature/<yours>`.
2. Open the repo in Summer.app. Run the game (F5) and confirm the stub loop works.
3. Edit only your folder. Replace the stub scene's contents, keep the root extending
   `GameStateBase`, keep the contract in the script header.
4. Talk to other systems only via `EventBus` and `GameState.transition_to()`.
   Read input only via `InputManager`. Read player data only via `GameData`.
5. Add `tests/test_<yours>.gd` extending `TestCase`; run `tests/run.sh`.
6. Run your scene standalone (F6) and inside the full game (F5). Both must work.
7. Commit small: `feat: add grassland collision`. Merge only when it runs.

## Testing

`tests/run.sh` runs an import pass then the headless runner
(`tests/run_tests.gd`) against every `tests/test_*.gd`. Tests extend `TestCase`, define
`test_*` methods, may `await tree.process_frame`, and reach autoloads with
`tree.root.get_node("GameState")`. Exit code is non-zero on failure.
