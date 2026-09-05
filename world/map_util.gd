extends RefCounted
## Shared grid helpers. No map-definition preloads.


static func filled_grid(width: int, height: int, value: int) -> Array:
	var grid: Array = []
	for _y in height:
		var row: Array[int] = []
		row.resize(width)
		row.fill(value)
		grid.append(row)
	return grid


static func stamp_rect(grid: Array, rect: Rect2i, value: int) -> void:
	var height: int = grid.size()
	var width: int = 0 if height == 0 else (grid[0] as Array).size()
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			if x >= 0 and y >= 0 and x < width and y < height:
				grid[y][x] = value


static func carve(grid: Array, tile: Vector2i, value: int) -> void:
	if tile.y < 0 or tile.y >= grid.size():
		return
	var row: Array = grid[tile.y]
	if tile.x < 0 or tile.x >= row.size():
		return
	row[tile.x] = value


static func carve_path(grid: Array, from_tile: Vector2i, to_tile: Vector2i, width: int, value: int) -> void:
	var cursor := from_tile
	var step := Vector2i(signi(to_tile.x - from_tile.x), signi(to_tile.y - from_tile.y))
	while true:
		for offset in range(-(width / 2), width - width / 2):
			var tile := cursor + (Vector2i(0, offset) if step.x != 0 else Vector2i(offset, 0))
			carve(grid, tile, value)
		if cursor == to_tile:
			break
		cursor += step


static func visual_to_nav(rect: Rect2i) -> Rect2i:
	return Rect2i(rect.position * 2, rect.size * 2)


static func block_rect(blocked: Dictionary, rect: Rect2i) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			blocked[Vector2i(x, y)] = true
