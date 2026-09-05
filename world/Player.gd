extends Sprite2D
## Grid-stepping overworld player (PRD §6). One tile per step, four directions, never
## diagonal. Faces the way it walks, animates only while stepping, and stops the instant a
## step finishes with no direction held.
##
## OverworldState drives this: it reads InputManager and calls try_step() / advance().
## The player never reads input and never talks to another subsystem.

const GrassMap := preload("res://world/GrassMap.gd")

## Seconds to cross one tile (~57 px/s). Lower is snappier; this is tuned to the walk
## cadence of the handheld games the PRD is after.
const STEP_TIME := 0.14

const SPRITE_HEIGHT := 20
const SHEET_COLUMNS := 8

## Sheet layout: frame index is DIR_ROW[facing] * 2 + sub_frame.
const DIR_ROW := {
	Vector2i.DOWN: 0,
	Vector2i.UP: 1,
	Vector2i.LEFT: 2,
	Vector2i.RIGHT: 3,
}

var tile: Vector2i = GrassMap.START_TILE
var facing: Vector2i = Vector2i.DOWN

var _from: Vector2 = Vector2.ZERO
var _to: Vector2 = Vector2.ZERO
var _elapsed: float = 0.0
var _stepping: bool = false
var _walkable_query: Callable

## Configured here rather than in the scene so a bare instance behaves identically in tests.
## The sprite is one tile wide and taller than a tile, so it is offset upward to stand with
## its feet inside the tile it occupies.
func _init() -> void:
	hframes = SHEET_COLUMNS
	vframes = 1
	centered = false
	offset = Vector2(0, -(SPRITE_HEIGHT - GrassMap.TILE))

## Teleports to a tile and cancels any step in progress.
func place(p_tile: Vector2i) -> void:
	tile = p_tile
	_stepping = false
	_elapsed = 0.0
	position = Vector2(p_tile * GrassMap.TILE)
	_refresh_frame()

func is_stepping() -> bool:
	return _stepping

## Lets OverworldState swap map collision without duplicating movement logic.
func set_walkable_query(query: Callable) -> void:
	_walkable_query = query

## Turns to face dir, then starts a step when the target tile is walkable.
## Returns true only when a step actually began; a blocked direction still turns the sprite.
func try_step(dir: Vector2i) -> bool:
	if _stepping or dir == Vector2i.ZERO:
		return false
	facing = dir
	var target := tile + dir
	var can_enter := GrassMap.is_walkable(target)
	if _walkable_query.is_valid():
		can_enter = bool(_walkable_query.call(target))
	if not can_enter:
		_refresh_frame()
		return false
	_from = Vector2(tile * GrassMap.TILE)
	_to = Vector2(target * GrassMap.TILE)
	tile = target
	_elapsed = 0.0
	_stepping = true
	_refresh_frame()
	return true

## Advances a step in progress. Returns true on the one frame the step completes, which is
## when OverworldState emits player_moved.
func advance(delta: float) -> bool:
	if not _stepping:
		return false
	_elapsed += delta
	var t := clampf(_elapsed / STEP_TIME, 0.0, 1.0)
	# Rounded because a sub-pixel sprite shimmers badly at this resolution.
	position = _from.lerp(_to, t).round()
	_refresh_frame()
	if t < 1.0:
		return false
	position = _to
	_stepping = false
	_refresh_frame()
	return true

## Sub-frame 0 is mid-stride, 1 is feet together. Idle rests on feet together and each step
## plays 0 then 1, so a held direction reads as a walk cycle.
func _refresh_frame() -> void:
	var sub := 1
	if _stepping and _elapsed / STEP_TIME < 0.5:
		sub = 0
	frame = int(DIR_ROW[facing]) * 2 + sub
	# The Studio sheet supplies one clean side profile; mirroring it keeps both directions
	# consistent without inventing a mismatched frame.
	flip_h = facing == Vector2i.LEFT
