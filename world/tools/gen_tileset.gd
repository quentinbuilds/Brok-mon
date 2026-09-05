extends SceneTree
## Builds world/overworld_tileset.tres from the generated atlas. Hand-writing a TileSet
## .tres is error prone, so it is generated instead.
##
## Run after gen_art.gd + an --import pass:
##   Summer --headless --disable-crash-handler --path . -s res://world/tools/gen_tileset.gd
##
## Collision is NOT stored here. OverworldState asks GrassMap whether a tile is walkable,
## so there are no physics bodies in the overworld at all.

const ATLAS := "res://assets/tiles/overworld.png"
const OUT := "res://world/overworld_tileset.tres"
const TILE := Vector2i(8, 8)
const COLUMNS := 8

func _initialize() -> void:
	var tex := load(ATLAS) as Texture2D
	if tex == null:
		push_error("atlas not imported yet: %s (run --import first)" % ATLAS)
		quit(1)
		return

	var source := TileSetAtlasSource.new()
	source.texture = tex
	source.texture_region_size = TILE
	for i in COLUMNS:
		source.create_tile(Vector2i(i, 0))

	var tile_set := TileSet.new()
	tile_set.tile_size = TILE
	tile_set.add_source(source, 0)

	var err := ResourceSaver.save(tile_set, OUT)
	if err != OK:
		push_error("could not save %s (%d)" % [OUT, err])
		quit(1)
		return
	print("wrote %s with %d tiles" % [OUT, COLUMNS])
	quit(0)
