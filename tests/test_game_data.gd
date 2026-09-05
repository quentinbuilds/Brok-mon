extends TestCase
## GameData holds party, active creature, inventory; emits EventBus signals on change.

var _party_events := 0
var _inv_events := 0
var _active_events := 0

func _data() -> Node:
	return tree.root.get_node("GameData")

func _bus() -> Node:
	return tree.root.get_node("EventBus")

func _mk(name: String) -> Creature:
	var c := Creature.new()
	c.name = name
	c.max_hp = 10
	c.hp = 10
	return c

func before_each() -> void:
	_party_events = 0
	_inv_events = 0
	_active_events = 0
	_bus().party_changed.connect(func(_p): _party_events += 1)
	_bus().inventory_changed.connect(func(_i): _inv_events += 1)
	_bus().active_creature_changed.connect(func(_c): _active_events += 1)
	_data().reset()

func after_each() -> void:
	for s in ["party_changed", "inventory_changed", "active_creature_changed"]:
		for conn in _bus().get_signal_connection_list(s):
			_bus().disconnect(s, conn["callable"])

func test_reset_gives_starter_and_items() -> void:
	assert_eq(_data().party.size(), 1, "one starter creature")
	assert_ne(_data().get_active_creature(), null)
	assert_eq(_data().get_item_count(&"capture_orb"), GameConfig.START_CAPTURE_ORBS)
	assert_eq(_data().get_item_count(&"potion"), GameConfig.START_POTIONS)
	assert_eq(_data().get_item_count(&"revive"), GameConfig.START_REVIVES)

func test_party_cap_enforced() -> void:
	for i in range(GameConfig.PARTY_SIZE - 1):
		assert_true(_data().add_to_party(_mk("c%d" % i)))
	assert_eq(_data().party.size(), GameConfig.PARTY_SIZE)
	assert_false(_data().add_to_party(_mk("overflow")), "full party rejects")
	assert_eq(_data().party.size(), GameConfig.PARTY_SIZE)

func test_add_to_party_emits_party_changed() -> void:
	_data().add_to_party(_mk("x"))
	assert_eq(_party_events, 1)

func test_remove_from_party_keeps_active_valid() -> void:
	var second := _mk("second")
	_data().add_to_party(second)
	_data().set_active(1)
	_data().remove_from_party(second)
	assert_eq(_data().party.size(), 1)
	assert_ne(_data().get_active_creature(), null)
	assert_eq(_data().get_active_creature().name, _data().party[0].name)

func test_use_item_decrements_and_emits() -> void:
	var before: int = _data().get_item_count(&"potion")
	assert_true(_data().use_item(&"potion"))
	assert_eq(_data().get_item_count(&"potion"), before - 1)
	assert_eq(_inv_events, 1)

func test_use_item_fails_when_empty() -> void:
	while _data().get_item_count(&"potion") > 0:
		_data().use_item(&"potion")
	_inv_events = 0
	assert_false(_data().use_item(&"potion"))
	assert_eq(_inv_events, 0, "no event on failed use")

func test_set_active_emits() -> void:
	_data().add_to_party(_mk("y"))
	_data().set_active(1)
	assert_eq(_data().get_active_creature().name, "y")
	assert_eq(_active_events, 1)

func test_set_active_out_of_range_ignored() -> void:
	_data().set_active(7)
	assert_eq(_data().active_index, 0)
	assert_eq(_active_events, 0)
