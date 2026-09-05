extends Node
## Overall display and asset contract for the whole team.
## Arduino Waveshare screen is portrait 480x800.
## Source art is authored at 200x120 and scaled up to the display.

const DISPLAY_WIDTH := 480
const DISPLAY_HEIGHT := 800
const DISPLAY_SIZE := Vector2i(DISPLAY_WIDTH, DISPLAY_HEIGHT)

const ASSET_WIDTH := 200
const ASSET_HEIGHT := 120
const ASSET_SIZE := Vector2i(ASSET_WIDTH, ASSET_HEIGHT)

const DEBUG_STATE_JUMPS := true

## Uniform scale that fits a 200x120 asset onto the 480x800 display.
func asset_fit_scale() -> float:
	var sx := float(DISPLAY_WIDTH) / float(ASSET_WIDTH)
	var sy := float(DISPLAY_HEIGHT) / float(ASSET_HEIGHT)
	return minf(sx, sy)


func asset_to_display(asset_pos: Vector2) -> Vector2:
	return asset_pos * asset_fit_scale()
