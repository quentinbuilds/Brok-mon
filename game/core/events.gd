extends Node
## Global signal bus. Use these names — do not invent parallel events.
## Payload types are untyped so this autoload parses before class_name cache exists.

signal player_moved(position)
signal encounter_triggered(creature)

signal battle_started(player_creature, wild_creature)
signal battle_won
signal battle_lost
signal battle_escaped

signal catch_started(creature)
signal creature_caught(creature)
signal catch_failed(creature)

signal menu_opened
signal menu_closed

signal inventory_changed
signal party_changed
signal active_creature_changed(creature)
