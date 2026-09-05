class_name MenuItems
extends RefCounted
## Bag item names and use rules. Odds/effects stay out of GameData.

const SAVE_GAG := "This cart has no battery. Your progress is a vibe."

const BAG_ORDER: Array[StringName] = [
	GameData.ITEM_CAPTURE_ORB,
	GameData.ITEM_POTION,
	GameData.ITEM_REVIVE,
]


static func display_name(item_id: StringName) -> String:
	match item_id:
		GameData.ITEM_CAPTURE_ORB:
			return "Capture Orb"
		GameData.ITEM_POTION:
			return "Potion"
		GameData.ITEM_REVIVE:
			return "Revive"
		_:
			return String(item_id)


static func first_fainted_index() -> int:
	for i in GameData.party.size():
		var c: Creature = GameData.party[i]
		if c != null and c.is_fainted():
			return i
	return -1


## Heals the active creature. Returns a message; does not consume on failure.
static func use_potion() -> String:
	var c := GameData.get_active_creature()
	if c == null:
		return "No one is out."
	if c.is_fainted():
		return "Fainted. Use REVIVE."
	if c.hp >= c.max_hp:
		return "%s is already fit." % c.name
	if not GameData.use_item(GameData.ITEM_POTION):
		return "You have none left!"
	var healed := mini(GameConfig.POTION_HEAL, c.max_hp - c.hp)
	c.hp += healed
	EventBus.party_changed.emit(GameData.party)
	return "%s recovered %d HP!" % [c.name, healed]


## Revives a fainted party member (index, or the first fainted). Full HP.
static func use_revive(index: int = -1) -> String:
	var target := index
	if target < 0:
		target = first_fainted_index()
	if target < 0 or target >= GameData.party.size():
		return "Nobody is out."
	var c: Creature = GameData.party[target]
	if c == null or not c.is_fainted():
		return "%s is still up." % (c.name if c else "?")
	if not GameData.use_item(GameData.ITEM_REVIVE):
		return "You have none left!"
	c.hp = c.max_hp
	EventBus.party_changed.emit(GameData.party)
	return "%s is back!" % c.name
