extends Node
## Screen transitions (PRD §5). An iris that closes to black and opens again, living above every
## layer so it survives the scene swap it is covering.
##
## GameState.transition_to() frees the outgoing overlay, so an effect owned by a state scene can
## only ever play half a transition - it is gone before the new state appears. This owns its own
## CanvasLayer instead, parented to the autoload rather than to Main, so nothing it draws depends
## on which state is up.
##
## Usage is always the same shape, and the cover call must be awaited:
##     await Transition.close(some_screen_position)
##     GameState.transition_to(...)
##     Transition.open()          # deliberately NOT awaited - the caller is about to be freed
##
## Idle cost is nothing: the rect is fully transparent and hidden until the first close().

## Above Main's OverlayLayer (layer 1) so it covers overlays as well as the world.
const LAYER := 128

const DEFAULT_DURATION := 0.55

## Hard-edged circle, no anti-aliasing - a soft gradient would dither into mush at 200x120 and
## look nothing like the hardware this is imitating. `aspect` keeps the iris round rather than
## letting it stretch into an ellipse on a non-square viewport.
const SHADER := """
shader_type canvas_item;
render_mode unshaded;
uniform vec2 iris_center = vec2(0.5, 0.5);
uniform float iris_radius = 2.0;
uniform vec2 aspect = vec2(1.0, 1.0);
void fragment() {
	float d = length((UV - iris_center) * aspect);
	COLOR = vec4(0.0, 0.0, 0.0, step(iris_radius, d));
}
"""

var _layer: CanvasLayer
var _rect: ColorRect
var _mat: ShaderMaterial
var _tween: Tween
var _covered := false

func _ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = LAYER
	add_child(_layer)

	var shader := Shader.new()
	shader.code = SHADER
	_mat = ShaderMaterial.new()
	_mat.shader = shader

	_rect = ColorRect.new()
	_rect.material = _mat
	# Never eat input; this sits over everything and would otherwise swallow every click.
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.visible = false
	_layer.add_child(_rect)

	_set_radius(_open_radius(Vector2(0.5, 0.5)))
	get_tree().root.size_changed.connect(_fit)
	_fit()

## True while the screen is black. Mainly for tests and for anything that must not start drawing
## until the cover is up.
func is_covered() -> bool:
	return _covered

## Closes the iris onto a point, given in viewport pixels. Await this, then swap states.
## Returns immediately if already covered, so a double press cannot stack two transitions.
func close(center_px: Vector2 = Vector2.INF, duration := DEFAULT_DURATION) -> void:
	if _covered:
		return
	_fit()
	var size := _viewport_size()
	var center := Vector2(0.5, 0.5) if center_px == Vector2.INF else center_px / size
	center = center.clamp(Vector2.ZERO, Vector2.ONE)
	_mat.set_shader_parameter("iris_center", center)
	_rect.visible = true
	_covered = true
	await _run(_open_radius(center), 0.0, duration)

## Opens the iris back out from wherever it closed. Safe to call when already open.
func open(duration := DEFAULT_DURATION) -> void:
	if not _covered:
		return
	_covered = false
	var center: Vector2 = _mat.get_shader_parameter("iris_center")
	await _run(0.0, _open_radius(center), duration)
	_rect.visible = false

## Drops the cover instantly, no animation. For tests, and for a player skipping the intro.
func snap_open() -> void:
	_kill_tween()
	_covered = false
	_rect.visible = false
	_set_radius(_open_radius(Vector2(0.5, 0.5)))

func _run(from: float, to: float, duration: float) -> void:
	_kill_tween()
	if duration <= 0.0:
		_set_radius(to)
		return
	_set_radius(from)
	_tween = create_tween()
	_tween.tween_method(_set_radius, from, to, duration)
	await _tween.finished

func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null

func _set_radius(r: float) -> void:
	_mat.set_shader_parameter("iris_radius", r)

## Radius that clears the furthest corner from this centre, so "open" really is fully open no
## matter where the iris is anchored. Measured in the same aspect-corrected units as the shader.
func _open_radius(center: Vector2) -> float:
	var a := _aspect()
	var far := Vector2(maxf(center.x, 1.0 - center.x), maxf(center.y, 1.0 - center.y))
	return (far * a).length() + 0.01

func _aspect() -> Vector2:
	var size := _viewport_size()
	if size.x <= 0.0 or size.y <= 0.0:
		return Vector2.ONE
	# Normalise against the longer edge so the circle stays a circle.
	return Vector2(size.x, size.y) / maxf(size.x, size.y)

func _viewport_size() -> Vector2:
	return get_viewport().get_visible_rect().size

func _fit() -> void:
	if _rect == null:
		return
	_rect.size = _viewport_size()
	_rect.position = Vector2.ZERO
	_mat.set_shader_parameter("aspect", _aspect())
