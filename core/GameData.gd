extends Node
## Player data: party, active creature, inventory, last overworld tile.
## Holds data and emits EventBus change signals. Rules (catch odds, item effects) live in
## the owning subsystem, which mutates data through these methods.

const ITEM_CAPTURE_ORB := &"capture_orb"
const ITEM_POTION := &"potion"

var party: Array[Creature] = []
var active_index: int = 0
var inventory: Dictionary = {}
var player_tile: Vector2i = Vector2i.ZERO

func _ready() -> void:
	reset()

## Fresh game. Does not emit signals; callers refresh UI on state entry.
func reset() -> void:
	party.clear()
	active_index = 0
	player_tile = Vector2i.ZERO
	inventory = {
		ITEM_CAPTURE_ORB: GameConfig.START_CAPTURE_ORBS,
		ITEM_POTION: GameConfig.START_POTIONS,
	}
	var starter := load(GameConfig.STARTER_PATH) as Creature
	if starter:
		party.append(starter.make_instance())
	else:
		push_error("GameData: starter creature missing at %s" % GameConfig.STARTER_PATH)

# --- Party ---

func get_active_creature() -> Creature:
	if active_index >= 0 and active_index < party.size():
		return party[active_index]
	return null

func get_party() -> Array[Creature]:
	return party

## Returns false when the party is full.
func add_to_party(c: Creature) -> bool:
	if party.size() >= GameConfig.PARTY_SIZE:
		return false
	party.append(c)
	EventBus.party_changed.emit(party)
	return true

func remove_from_party(c: Creature) -> void:
	var idx := party.find(c)
	if idx == -1:
		return
	party.remove_at(idx)
	var new_active := clampi(active_index, 0, max(party.size() - 1, 0))
	EventBus.party_changed.emit(party)
	if new_active != active_index:
		active_index = new_active
		EventBus.active_creature_changed.emit(get_active_creature())

func set_active(index: int) -> void:
	if index < 0 or index >= party.size():
		return
	active_index = index
	EventBus.active_creature_changed.emit(party[index])

# --- Inventory ---

func get_inventory() -> Dictionary:
	return inventory

func get_item_count(item: StringName) -> int:
	return inventory.get(item, 0)

func add_item(item: StringName, amount: int = 1) -> void:
	inventory[item] = get_item_count(item) + amount
	EventBus.inventory_changed.emit(inventory)

## Consumes one. Returns false (and emits nothing) when none are left.
func use_item(item: StringName) -> bool:
	if get_item_count(item) <= 0:
		return false
	inventory[item] -= 1
	EventBus.inventory_changed.emit(inventory)
	return true
