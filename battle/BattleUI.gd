class_name BattleUI
extends Control
## Immediate-mode battle screen. BattleState owns the rules.

## Map data only -- pure static tables, never an overworld node. The backdrop is built
## from the terrain the encounter started on.
const MapCycle := preload("res://world/MapCycle.gd")
const GrassMap := preload("res://world/GrassMap.gd")

enum Mode { MESSAGE, ACTION, BAG, PARTY, FIGHT }

var mode: int = Mode.MESSAGE
var player: Creature
var enemy: Creature
var player_display_hp: float = 0.0
var enemy_display_hp: float = 0.0
var rage_level: int = 0
var show_enemy_panel: bool = true
var show_player_panel: bool = true

var action_menu := ActionMenu.new()
var bag_menu := ListMenu.new()
var party_menu := ListMenu.new()
var fight_menu := FightMenu.new()
var message := MessageBox.new()

var enemy_view: CreatureView
var player_view: CreatureView
var fx: BattleFX
var audio: BattleAudio
var _low_hp_phase: float = 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	enemy_view = CreatureView.new()
	enemy_view.rect = BattleConfig.ENEMY_SPRITE_RECT
	enemy_view.use_back_sprite = false
	enemy_view.lunge_direction = Vector2(-1, 1)
	add_child(enemy_view)
	player_view = CreatureView.new()
	player_view.rect = BattleConfig.PLAYER_SPRITE_RECT
	player_view.use_back_sprite = true
	player_view.lunge_direction = Vector2(1, -1)
	add_child(player_view)
	fx = BattleFX.new()
	add_child(fx)
	audio = BattleAudio.new()
	add_child(audio)
	set_process(true)


func bind(player_creature: Creature, wild_creature: Creature) -> void:
	player = player_creature
	enemy = wild_creature
	player_display_hp = float(player.hp)
	enemy_display_hp = float(enemy.hp)
	player_view.bind(player)
	enemy_view.bind(enemy)


func _process(delta: float) -> void:
	_low_hp_phase += delta
	message.tick(delta)
	var shake := fx.shake_offset if fx != null else Vector2.ZERO
	enemy_view.position = shake
	player_view.position = shake
	if player != null and audio != null:
		if BattleLogic.hp_fraction(player) <= BattleConfig.LOW_HP_FRACTION and player.hp > 0:
			audio.start_low_hp()
		else:
			audio.stop_low_hp()
	queue_redraw()


func _low_hp_flash_on() -> bool:
	return fmod(_low_hp_phase, BattleConfig.LOW_HP_FLASH_CYCLE * 2.0) < BattleConfig.LOW_HP_FLASH_CYCLE


func _draw() -> void:
	_draw_world()
	if show_enemy_panel and enemy != null:
		_draw_enemy_panel()
	if show_player_panel and player != null:
		_draw_player_panel()
	_draw_bottom_box()


## Sky over ground tiled with the terrain the encounter started on, rather than the flat
## four-colour wash this used to be. The terrain comes from world/ map data, which is pure data
## any system may ask about; nothing here touches an overworld node. Falls back to the old flat
## bands if the atlas is missing, so a checkout without assets still fights.
func _draw_world() -> void:
	var ground_top := float(BattleConfig.HORIZON_Y)
	var ground_h := BattleConfig.BOTTOM_BOX.position.y - BattleConfig.HORIZON_Y
	draw_rect(Rect2(0, 0, BattleConfig.SCREEN.x, ground_top), MapCycle.battle_sky(), true)

	var atlas := ground_texture()
	var column: int = GrassMap.ATLAS_COLUMN.get(MapCycle.battle_ground_glyph(), 0)
	if atlas == null:
		draw_rect(Rect2(0, ground_top, BattleConfig.SCREEN.x, ground_h), BattleConfig.LIGHT, true)
	else:
		var tile := float(GrassMap.TILE)
		var source := Rect2(column * tile, 0.0, tile, tile)
		var y := ground_top
		while y < ground_top + ground_h:
			var x := 0.0
			while x < float(BattleConfig.SCREEN.x):
				draw_texture_rect_region(atlas, Rect2(x, y, tile, tile), source)
				x += tile
			y += tile

	draw_rect(Rect2(0, ground_top, BattleConfig.SCREEN.x, 1), BattleConfig.DARKEST, true)
	Dmg.platform(self, BattleConfig.ENEMY_PLATFORM_CENTER, BattleConfig.ENEMY_PLATFORM_RADIUS,
		BattleConfig.PLATFORM_SHADOW)
	Dmg.platform(self, BattleConfig.PLAYER_PLATFORM_CENTER, BattleConfig.PLAYER_PLATFORM_RADIUS,
		BattleConfig.PLATFORM_SHADOW)


static func ground_texture() -> Texture2D:
	if not ResourceLoader.exists(BattleConfig.GROUND_ATLAS):
		return null
	return load(BattleConfig.GROUND_ATLAS) as Texture2D


func _draw_enemy_panel() -> void:
	var r := BattleConfig.ENEMY_PANEL
	Dmg.panel(self, r)
	Dmg.text(self, Vector2i(r.position.x + 4, r.position.y + 3), enemy.name)
	_draw_level(r, enemy.level)
	var bar := Rect2i(r.position.x + 4, r.position.y + 14, BattleConfig.HP_BAR_SIZE.x, BattleConfig.HP_BAR_SIZE.y)
	var frac := enemy_display_hp / float(enemy.max_hp) if enemy.max_hp > 0 else 0.0
	Dmg.hp_bar(self, bar, frac)
	_draw_rage_meter(Vector2i(bar.position.x + bar.size.x + 4, bar.position.y))


func _draw_rage_meter(at: Vector2i) -> void:
	if rage_level == 0:
		return
	var count := absi(rage_level)
	var filled := rage_level > 0
	for i in count:
		var cell := Rect2(at.x + i * (BattleConfig.RAGE_PIP_SIZE.x + 1), at.y,
			BattleConfig.RAGE_PIP_SIZE.x, BattleConfig.RAGE_PIP_SIZE.y)
		draw_rect(cell, BattleConfig.DARKEST, filled)


func _draw_player_panel() -> void:
	var r := BattleConfig.PLAYER_PANEL
	Dmg.panel(self, r)
	Dmg.text(self, Vector2i(r.position.x + 4, r.position.y + 3), player.name)
	_draw_level(r, player.level)
	var bar := Rect2i(r.position.x + 4, r.position.y + 13, BattleConfig.HP_BAR_SIZE.x, BattleConfig.HP_BAR_SIZE.y)
	var frac := player_display_hp / float(player.max_hp) if player.max_hp > 0 else 0.0
	var flash := frac <= BattleConfig.LOW_HP_FRACTION and frac > 0.0 and _low_hp_flash_on()
	Dmg.hp_bar(self, bar, frac, flash)
	Dmg.text(self, Vector2i(r.position.x + 4, r.position.y + 21),
		"%d/%d" % [int(ceil(player_display_hp)), player.max_hp])


func _draw_bottom_box() -> void:
	Dmg.panel(self, BattleConfig.BOTTOM_BOX)
	match mode:
		Mode.ACTION:
			_draw_action_menu()
		Mode.FIGHT:
			_draw_fight_menu()
		Mode.BAG:
			_draw_list(bag_menu, "BAG EMPTY")
		Mode.PARTY:
			_draw_list(party_menu, "NO OTHERS")
		_:
			_draw_message()


func _draw_message() -> void:
	var lines := MessageBox.wrap_lines(message.visible_text())
	for i in lines.size():
		Dmg.text(self, Vector2i(
			BattleConfig.TEXT_ORIGIN.x,
			BattleConfig.TEXT_ORIGIN.y + i * BattleConfig.TEXT_LINE_HEIGHT
		), lines[i])
	if message.prompt_visible():
		Dmg.cursor(self, Vector2i(BattleConfig.SCREEN.x - 12, BattleConfig.BOTTOM_BOX.position.y + 24))


func _draw_level(panel: Rect2i, level: int) -> void:
	var label := "Lv%d" % level
	var x := panel.position.x + panel.size.x - 4 - int(Dmg.text_width(label))
	Dmg.text(self, Vector2i(x, panel.position.y + 3), label)


func _draw_fight_menu() -> void:
	if fight_menu.is_empty():
		Dmg.text(self, BattleConfig.TEXT_ORIGIN, "NO MOVES")
		return
	for row in BattleConfig.FIGHT_ROWS:
		for col in BattleConfig.FIGHT_COLS:
			var move := fight_menu.cell_at(row, col)
			if move == null:
				continue
			var pos := Vector2i(
				BattleConfig.MENU_ORIGIN.x + col * BattleConfig.FIGHT_COL_WIDTH,
				BattleConfig.MENU_ORIGIN.y + row * BattleConfig.MENU_ROW_HEIGHT
			)
			Dmg.text(self, pos, move.name)
			if fight_menu.row == row and fight_menu.col == col:
				Dmg.cursor(self, Vector2i(pos.x - 8, pos.y + 1))
	Dmg.text(self, Vector2i(BattleConfig.SCREEN.x - 40, BattleConfig.BOTTOM_BOX.position.y + 24), "B BACK")


func _draw_action_menu() -> void:
	for row in BattleConfig.MENU_ROWS:
		for col in BattleConfig.MENU_COLS:
			var action := action_menu.cell_at(row, col)
			if action == -1:
				continue
			var pos := Vector2i(
				BattleConfig.MENU_ORIGIN.x + col * BattleConfig.MENU_COL_WIDTH,
				BattleConfig.MENU_ORIGIN.y + row * BattleConfig.MENU_ROW_HEIGHT
			)
			var label: String = ActionMenu.LABELS[action]
			if action == ActionMenu.Action.RAGE:
				draw_rect(Rect2(pos.x - 3, pos.y - 2, Dmg.text_width(label) + 6, BattleConfig.FONT_SIZE + 4),
					BattleConfig.DARKEST, false, 1.0)
			Dmg.text(self, pos, label)
			if action_menu.row == row and action_menu.col == col:
				Dmg.cursor(self, Vector2i(pos.x - 8, pos.y + 1))


func _draw_list(menu: ListMenu, empty_text: String) -> void:
	if menu.is_empty():
		Dmg.text(self, BattleConfig.TEXT_ORIGIN, empty_text)
		return
	var rows := menu.visible_rows()
	for i in rows.size():
		var row: Dictionary = rows[i]
		var pos := Vector2i(
			BattleConfig.MENU_ORIGIN.x,
			BattleConfig.MENU_ORIGIN.y + i * BattleConfig.MENU_ROW_HEIGHT
		)
		var label: String = str(row.get("name", "?"))
		if row.has("count"):
			label = "%s x%d" % [label, int(row["count"])]
		elif row.has("hp"):
			label = "%s %d/%d" % [label, int(row["hp"]), int(row["max_hp"])]
		Dmg.text(self, pos, label)
		if row.get("_selected", false):
			Dmg.cursor(self, Vector2i(pos.x - 8, pos.y + 1))
	Dmg.text(self, Vector2i(BattleConfig.SCREEN.x - 40, BattleConfig.BOTTOM_BOX.position.y + 24), "B BACK")


func enemy_center() -> Vector2:
	var r := BattleConfig.ENEMY_SPRITE_RECT
	return Vector2(r.position.x + r.size.x * 0.5, r.position.y + r.size.y * 0.5)


func player_center() -> Vector2:
	var r := BattleConfig.PLAYER_SPRITE_RECT
	return Vector2(r.position.x + r.size.x * 0.5, r.position.y + r.size.y * 0.5)


func enemy_head() -> Vector2:
	var r := BattleConfig.ENEMY_SPRITE_RECT
	return Vector2(r.position.x + r.size.x * 0.5, float(r.position.y) - 2.0)
