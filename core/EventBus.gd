extends Node
## Cross-system signals (PRD §12). This is the ONLY way subsystems talk across folders.
## Add nothing here without telling the integration owner.

# World -> Encounters
signal player_moved(tile: Vector2i, in_encounter_zone: bool)
# Encounters -> Core (Core transitions OVERWORLD -> BATTLE)
signal encounter_triggered(wild: Creature)

# Battle lifecycle. Results are consumed by Core to return to OVERWORLD.
signal battle_started(player_creature: Creature, wild: Creature)
signal battle_won(wild: Creature)
signal battle_lost()
signal battle_escaped()

## Emitted by TurnSequencer.impact() the instant a hit lands, for both sides. A signal rather
## than a direct audio call because the flash, the shake, the HUD and rumble all want this same
## moment. amount may be 0 (a hit that did nothing) - consumers decide whether they care.
signal damage_dealt(amount: int, to_player: bool)

## Emitted by TurnSequencer.faint() when a creature drops, for both sides, before the faint
## animation plays. Same shape as damage_dealt so consumers filter the same way.
signal creature_fainted(to_player: bool)

# Catching. creature_caught -> OVERWORLD, catch_failed -> back to BATTLE.
signal catch_started(wild: Creature)
signal creature_caught(wild: Creature)
signal catch_failed(wild: Creature)

# Menu
signal menu_opened()
signal menu_closed()

# Player data changes (emitted by GameData)
signal inventory_changed(inventory: Dictionary)
signal party_changed(party: Array[Creature])
signal active_creature_changed(creature: Creature)
