extends TestCase
## Losing a battle: the fade, the heal, and the walk home.

const MapCycle := preload("res://world/MapCycle.gd")
const GrassMap := preload("res://world/GrassMap.gd")


func _overworld() -> OverworldState:
	var world := load("res://world/OverworldState.tscn").instantiate() as OverworldState
	tree.root.add_child(world)
	GameData.player_tile = GrassMap.START_TILE
	world.enter({})
	return world


func before_each() -> void:
	GameData.reset()


func test_blackout_line_reads_and_fits_the_box() -> void:
	var line := BattleCopy.blacked_out("Starterpup")
	assert_true(line.contains("blacked out"), "says what happened")
	assert_true(BattleCopy.fits(line), "wraps inside the message box")


func test_the_fade_is_slower_than_an_ordinary_transition() -> void:
	assert_true(BattleConfig.BLACKOUT_FADE > 0.0, "there is a fade at all")
	assert_true(BattleConfig.BLACKOUT_FADE >= Transition.DEFAULT_DURATION, "losing lands")


## Without this the next encounter would open on a creature already at nought HP.
func test_healing_revives_the_whole_party() -> void:
	var first: Creature = load("res://creatures/data/emberfox.tres").make_instance()
	var second: Creature = load("res://creatures/data/aquafin.tres").make_instance()
	GameData.add_to_party(first)
	GameData.add_to_party(second)
	first.hp = 0
	second.hp = 1
	BattleState.heal_party()
	for creature in GameData.get_party():
		assert_eq(creature.hp, creature.max_hp, "%s healed" % creature.name)
		assert_false(creature.is_fainted(), "%s back on its feet" % creature.name)


func test_the_overworld_listens_for_the_loss() -> void:
	var world := _overworld()
	assert_true(EventBus.battle_lost.is_connected(world._on_blacked_out), "wired to battle_lost")
	world.free()


func test_blacking_out_puts_the_player_back_at_the_start() -> void:
	var world := _overworld()
	world._player.place(Vector2i(40, 35))
	GameData.player_tile = Vector2i(40, 35)
	world._on_blacked_out()
	assert_eq(GameData.player_tile, GrassMap.START_TILE, "walked home")
	assert_eq(world._player.tile, GrassMap.START_TILE)
	assert_eq(world.map_mode, MapCycle.Mode.DEFAULT, "and back onto the home map")
	world.free()


## Blacking out on the beach still brings the player home rather than leaving them on an island.
func test_blacking_out_leaves_the_beach() -> void:
	var world := _overworld()
	world._switch_map(MapCycle.Mode.BEACH, MapCycle.BEACH_RETURN)
	assert_eq(world.map_mode, MapCycle.Mode.BEACH)
	world._on_blacked_out()
	assert_eq(world.map_mode, MapCycle.Mode.DEFAULT)
	assert_eq(world._player.tile, GrassMap.START_TILE)
	assert_true(world.get_node("Tiles").visible, "home map is showing again")
	assert_false(world.get_node("BeachBackground").visible)
	world.free()


func test_blacking_out_closes_an_open_dialogue() -> void:
	var world := _overworld()
	world._open_talk("mid sentence", "")
	assert_true(world.talking)
	world._on_blacked_out()
	assert_false(world.talking, "the box does not survive the blackout")
	world.free()


## The iris is the shared autoload, so it survives the scene swap it is covering.
func test_the_transition_can_cover_and_uncover() -> void:
	assert_false(Transition.is_covered())
	await Transition.close(Vector2(100, 60), 0.0)
	assert_true(Transition.is_covered(), "screen is black across the swap")
	await Transition.open(0.0)
	assert_false(Transition.is_covered(), "and opens again afterwards")
