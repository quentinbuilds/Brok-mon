# encounters/ — creature pool and wild encounters

Owner: Person 3. Scope is PRD §7 only: creature definitions, the wild pool, the encounter
roll, its probability and cooldown, and handing a wild creature to core. No battle logic, no
catching, no menus.

## Files

| File | Purpose |
|---|---|
| `CreaturePool.gd` | Which creatures can appear and how often. Weighted random selection. |
| `EncounterSystem.gd` | Listens for completed steps, rolls, applies the cooldown, emits `encounter_triggered`. |
| `EncounterSystem.tscn` | A bare `Node` with the script, instanced by `world/OverworldState.tscn`. |
| `../creatures/data/*.tres` | The five creature definitions. |
| `../creatures/tools/gen_creature_art.gd` | Generates the creature sprites. |

Tests live in `tests/test_encounters.gd`.

## Where it lives, and why

`EncounterSystem` is a child of `OverworldState`, not an autoload — adding an autoload would
mean editing `project.godot`, which is core-owned. Living under the overworld is also what
`docs/ARCHITECTURE.md` describes: an overlay freezes the overworld and everything in it, so
encounters stop during a battle or menu for free.

It holds no reference to any world node. The tile and the tall-grass flag both arrive on
`EventBus.player_moved`, so `world/` and `encounters/` stay independent.

## The loop

```
player steps onto a tile
        v
EventBus.player_moved(tile, in_encounter_zone)
        v
EncounterSystem.try_encounter(in_encounter_zone)
        v
cooldown spent?  in tall grass?  roll < ENCOUNTER_CHANCE?
        v
EventBus.encounter_triggered(wild)
        v
core: OVERWORLD -> BATTLE with {wild}
```

One roll per completed step, never per frame, so walking speed does not change the
encounter rate. A blocked move emits no step, so bumping into a tree is not a roll.

## Tuning

Both values live in `core/config/GameConfig.gd`, not here:

| Constant | Value | Meaning |
|---|---|---|
| `ENCOUNTER_CHANCE` | `0.08` | Chance per eligible step. PRD §7 asks for 5–10%. |
| `ENCOUNTER_COOLDOWN_STEPS` | `4` | Steps to walk off before another roll can happen. |

The cooldown counts *every* step, including steps outside the grass, so leaving the field and
stepping straight back in cannot re-trigger.

## API

```
try_encounter(in_encounter_zone: bool) -> bool   one roll for one completed step
generate_wild_creature() -> Creature             fresh healed weighted-random creature
start_encounter(wild: Creature)                  announce it and start the cooldown
steps_until_ready() -> int                       cooldown remaining
reset_cooldown()                                 clear the cooldown
pool_size() -> int                               how many definitions loaded
force_next: bool                                 next eligible step triggers; cleared on use
rng: RandomNumberGenerator                        seed it for deterministic runs
```

`try_encounter` takes the flag rather than a position (the PRD sketches
`try_encounter(player_position)`) because the world has already computed it; asking the map
again would couple this system to `world/`.

## Testing and debugging

- `force_next = true` makes the next grass step trigger, no matter the roll.
- `rng.seed = <n>` makes selection and rolls fully reproducible.
- `F1` in a debug build still forces an encounter with the core placeholder creature.
- `tests/test_encounters.gd` measures the real rate over 4000 steps and asserts it tracks
  `ENCOUNTER_CHANCE`, so retuning the constant cannot silently break the roll.

Note for anyone writing tests: a triggered encounter sends core to `BATTLE`, and
`try_encounter` deliberately refuses to roll outside `OVERWORLD`. A test that wants a second
encounter has to transition back first.

## The pool

Five original creatures, one grassland biome. Weights are relative, and the two extreme
statlines are the rare ones so that finding them feels like something.

| Creature | Type | HP | Atk | Def | Catch | Weight | Silhouette |
|---|---|---|---|---|---|---|---|
| Mossbug | GRASS | 20 | 5 | 6 | 0.45 | 35 | round beetle, antenna, legs |
| Pebblit | ROCK | 30 | 4 | 9 | 0.40 | 25 | hard-edged block |
| Aquafin | WATER | 26 | 6 | 5 | 0.35 | 20 | finned fish |
| Emberfox | FIRE | 24 | 8 | 4 | 0.30 | 15 | pointed ears, narrow muzzle |
| Rizzzmoth | ELECTRIC | 18 | 9 | 3 | 0.25 | 5 | quadruped, tail swept up |

All names, stats and sprites are original. Sprites are 16x16 in the same four shades as the
overworld: the game is monochrome-green by design, so a creature is told apart by silhouette
and shading rather than hue. Person 4 can scale them 2x for the battle screen; Person 6 owns
any final restyle.

Regenerate the art after editing `creatures/tools/gen_creature_art.gd`:

```sh
S=/Applications/Summer.app/Contents/MacOS/Summer
$S --headless --disable-crash-handler --path . -s res://creatures/tools/gen_creature_art.gd
$S --headless --path . --import
```

It also drops a 6x contact sheet at `/tmp/creature_review.png` for eyeballing.
