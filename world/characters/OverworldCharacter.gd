@tool
extends AnimatedSprite2D
## 16x16 overworld character from characters_v3.png. Set character_id 0-19 to pick a row.

const SHEET_PATH := "res://assets/sprites/characters/characters_v3.png"
const CELL := 16
const COLS := 10
const ROWS := 20
const COUNT := 20
const EMPTY_COL := 3
const FIRST_WALK_COL := 4
const LAST_COL := 9
const WALK_FPS := 6.0
const NPC_GROUP := "npc"

const NAMES: PackedStringArray = [
	"cap_beard",
	"elder",
	"youth",
	"pink_dress",
	"rusty_hair",
	"grey_shirt",
	"vest_man",
	"maroon",
	"mohawk",
	"grey_tee",
	"goblin",
	"knight",
	"skeleton",
	"viking",
	"wizard",
	"explorer",
	"red_band",
	"purple_band",
	"green_shirt",
	"pigtails",
]

const ANIM_COLS := {
	&"idle_front": [0],
	&"idle_back": [1],
	&"idle_side": [2],
	&"walk_front": [4, 5],
	&"walk_back": [6, 7],
	&"walk_side": [8, 9],
}

@export var is_npc: bool = true

@export_range(0, 19, 1) var character_id: int = 0:
	set(value):
		character_id = clampi(value, 0, COUNT - 1)
		if is_node_ready():
			_rebuild_frames()
			_sync_animation()

var _facing := Vector2i.DOWN
var _walk := false

func _ready() -> void:
	centered = false
	texture_filter = TEXTURE_FILTER_NEAREST
	_rebuild_frames()
	_sync_animation()
	if is_npc:
		add_to_group(NPC_GROUP)
	else:
		remove_from_group(NPC_GROUP)


func apply_move_dir(dir: Vector2i) -> void:
	_walk = dir != Vector2i.ZERO
	if _walk:
		_facing = dir
	_sync_animation()


func atlas_frame(anim: StringName, index: int) -> AtlasTexture:
	if sprite_frames == null or not sprite_frames.has_animation(anim):
		return null
	return sprite_frames.get_frame_texture(anim, index) as AtlasTexture


static func frame_region(id: int, col: int) -> Rect2:
	return Rect2(col * CELL, id * CELL, CELL, CELL)


static func scene_path(id: int) -> String:
	return "res://world/characters/%s.tscn" % NAMES[id]


func _rebuild_frames() -> void:
	var sheet := load(SHEET_PATH) as Texture2D
	var frames := SpriteFrames.new()
	for anim in ANIM_COLS:
		frames.add_animation(anim)
		frames.set_animation_loop(anim, true)
		var cols: Array = ANIM_COLS[anim]
		frames.set_animation_speed(anim, WALK_FPS if cols.size() > 1 else 1.0)
		for col in cols:
			var atlas := AtlasTexture.new()
			atlas.atlas = sheet
			atlas.region = frame_region(character_id, int(col))
			atlas.filter_clip = true
			frames.add_frame(anim, atlas)
	sprite_frames = frames


func _sync_animation() -> void:
	flip_h = _facing.x < 0
	var anim := _anim_name()
	if animation != anim or not is_playing():
		play(anim)


func _anim_name() -> StringName:
	var prefix := "walk" if _walk else "idle"
	if _facing.y < 0:
		return StringName("%s_back" % prefix)
	if _facing.y > 0:
		return StringName("%s_front" % prefix)
	return StringName("%s_side" % prefix)
