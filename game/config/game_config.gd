extends Node

const LOGICAL_WIDTH := 200
const LOGICAL_HEIGHT := 120
const LOGICAL_SIZE := Vector2i(LOGICAL_WIDTH, LOGICAL_HEIGHT)

const DISPLAY_WIDTH := 800
const DISPLAY_HEIGHT := 480
const DISPLAY_SIZE := Vector2i(DISPLAY_WIDTH, DISPLAY_HEIGHT)

const PIXEL_SCALE := 4
const TILE_SIZE := 8

# Compatibility: these now describe the logical art canvas.
const ASSET_WIDTH := LOGICAL_WIDTH
const ASSET_HEIGHT := LOGICAL_HEIGHT
const ASSET_SIZE := LOGICAL_SIZE

const DEBUG_STATE_JUMPS := true

func asset_fit_scale() -> float:
	return float(PIXEL_SCALE)

func asset_to_display(asset_pos: Vector2) -> Vector2:
	return asset_pos * PIXEL_SCALE
