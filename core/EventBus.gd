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
