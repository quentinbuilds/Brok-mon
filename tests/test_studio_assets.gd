extends TestCase
## Guards the handoff from Summer Studio assets into the playable scenes.

const STUDIO := "res://assets/studio/"

func test_studio_assets_are_imported() -> void:
	for file in ["trainer_walk.png", "overworld_tileset.png", "grass_starter.png",
			"fire_starter.png", "water_starter.png", "dialogue_box.png",
			"battle_menu.png", "battle_hud.png"]:
		assert_true(ResourceLoader.exists(STUDIO + file), file)

func test_starter_and_debug_wild_use_studio_art() -> void:
	var starter := load(GameConfig.STARTER_PATH) as Creature
	var wild := load(GameConfig.DEBUG_WILD_PATH) as Creature
	assert_true(starter.sprite != null)
	assert_true(wild.sprite != null)
	assert_true(starter.sprite.resource_path.begins_with(STUDIO))
	assert_true(wild.sprite.resource_path.begins_with(STUDIO))

func test_battle_and_catching_present_creature_sprites() -> void:
	var battle: BattleState = load("res://battle/BattleState.tscn").instantiate()
	var catching: Node = load("res://catching/CatchingState.tscn").instantiate()
	tree.root.add_child(battle)
	await tree.process_frame
	var starter := (load(GameConfig.STARTER_PATH) as Creature).make_instance()
	var wild := (load(GameConfig.DEBUG_WILD_PATH) as Creature).make_instance()
	battle.ui.bind(starter, wild)
	assert_true(battle.ui.player_view.creature.sprite != null)
	assert_true(battle.ui.enemy_view.creature.sprite != null)
	assert_true(catching.has_node("WildSprite"))
	battle.free()
	catching.free()
