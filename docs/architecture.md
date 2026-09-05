# Gok-Mon architecture (Person 1)

Open **`game/`** in Summer Engine. That folder is the Godot/Summer project.

This is a 12-hour hackathon. Do not rewrite the core. Implement against the interfaces below.

## Display and assets

Canonical numbers live in [`game/config/game_config.gd`](../game/config/game_config.gd):

- Physical display: **800×480** (landscape)
- Logical viewport and source-art canvas: **200×120**
- Integer pixel scale: **4**
- Jungle movement and tile grid step: **8 logical pixels**
- Use `GameConfig.asset_fit_scale()` to place 200×120 art onto the 800×480
  display without inventing a second scale

Do not change these constants without telling the integration owner.

## Autoloads

Gameplay systems talk to these. Never call joystick or Arduino APIs directly.

| Autoload | File | Job |
| --- | --- | --- |
| `Events` | `game/core/events.gd` | Signal bus |
| `GameConfig` | `game/config/game_config.gd` | Display, asset size, debug flags |
| `InputManager` | `game/core/input_manager.gd` | Hardware seam |
| `Game` | `game/core/game.gd` | State machine + session data |

## State machine

```
BOOT → TITLE → OVERWORLD ⇄ MENU
                 ↓
               BATTLE ⇄ CATCHING
                 ↓
              OVERWORLD
```

Every state scene extends `GameState` (`enter`, `update`, `exit`) and lives under `game/states/`.

`Game.change_state(GameState.Id.OVERWORLD)` is how you switch. Do not call `get_tree().change_scene_to_file()`.

| Id | Scene | Owner after Phase 1 |
| --- | --- | --- |
| TITLE | `game/states/title.tscn` | Person 6 polish |
| OVERWORLD | `game/states/overworld.tscn` | Person 2 replaces |
| BATTLE | `game/states/battle.tscn` | Person 4 replaces |
| CATCHING | `game/states/catching.tscn` | Person 5 replaces |
| MENU | `game/states/menu.tscn` | Person 6 replaces |

## InputManager

```
is_up() / is_down() / is_left() / is_right()
move_vector()                    # 4-direction, no diagonals
button_a_pressed() / button_a_just_pressed()
button_b_pressed() / button_b_just_pressed()
button_menu_pressed() / button_menu_just_pressed()
```

PC mapping (change only in `input_manager.gd`):

- Move: WASD + arrows
- A / confirm: Z, Enter, Space
- B / back: X, Escape
- Menu: C, Tab

## Events

PRD name → GDScript signal

- `PLAYER_MOVED` → `Events.player_moved(position)`
- `ENCOUNTER_TRIGGERED` → `Events.encounter_triggered(creature)`
- `BATTLE_STARTED` → `Events.battle_started(player_creature, wild_creature)`
- `BATTLE_WON` / `BATTLE_LOST` / `BATTLE_ESCAPED`
- `CATCH_STARTED` / `CREATURE_CAUGHT` / `CATCH_FAILED`
- `MENU_OPENED` / `MENU_CLOSED`
- `INVENTORY_CHANGED` / `PARTY_CHANGED` / `ACTIVE_CREATURE_CHANGED`

Core already listens to `encounter_triggered` (OVERWORLD → BATTLE) and `catch_started` (BATTLE → CATCHING).

The jungle world only identifies encounter zones; it does not emit
`encounter_triggered` or contain battle logic. Person 3 owns the encounter roll
and signal handoff after a completed `player_moved` step.

## Shared types

- `Creature` — `game/core/creature.gd`. Starter: Emberfox (FIRE). Original creatures only.
- `PlayerData` — `game/core/player_data.gd`. `Game.player` is the session instance.
- `Inventory` — `game/core/inventory.gd`. Capture Orb, Potion.

Party max is 3. One active creature.

## How to integrate your feature

1. Pull `main`, then branch `feature/<your-system>`.
2. Work in your owner folder. Do not rewrite `game/core/` unless you are Person 1.
3. Replace your stub scene, keep the `GameState` methods and the same `res://states/<name>.tscn` path (or tell Person 1 if the path must change).
4. Drive transitions through `Game` and `Events`.
5. Read input only through `InputManager`.

Person 2 world/player: [`docs/world.md`](world.md).

The MVP contains the jungle biome only. Volcanic, snowy mountain, desert, and
forest biomes are planned but absent; their jungle exit markers remain blocked.

Owner folders:

- Person 2: `game/world/`
- Person 3: `game/creatures/`
- Person 4: `game/battle/`
- Person 5: `game/catching/`
- Person 6: `game/ui/`
- Shared art: `game/assets/{sprites,tiles,backgrounds,audio}/`

## Debug jumps

With `GameConfig.DEBUG_STATE_JUMPS`:

- F1 title
- F2 overworld
- F3 battle stub
- F4 catching stub
- F5 menu stub
- F6 title (reset)

## Phase 1 playable stub

1. Play from `game/`.
2. Title → press A → overworld.
3. WASD moves the red square and emits `player_moved`.
4. C opens the menu stub; B returns.
5. F-keys jump into battle/catching stubs.
