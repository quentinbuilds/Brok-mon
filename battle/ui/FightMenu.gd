class_name FightMenu
extends RefCounted
## FireRed 2x2 move picker. Empty cells are skipped.

var moves: Array[BattleMove] = []
var col: int = 0
var row: int = 0


func reset() -> void:
	col = 0
	row = 0


func set_moves(new_moves: Array[BattleMove]) -> void:
	moves = new_moves
	reset()
	if current() == null:
		move(1, 0)


func _index(r: int, c: int) -> int:
	return r * BattleConfig.FIGHT_COLS + c


func cell_at(r: int, c: int) -> BattleMove:
	var i := _index(r, c)
	if i < 0 or i >= moves.size():
		return null
	return moves[i]


func current() -> BattleMove:
	return cell_at(row, col)


func is_empty() -> bool:
	return moves.is_empty()


func move(dx: int, dy: int) -> bool:
	if moves.size() <= 1:
		return false
	var dest_col := wrapi(col + dx, 0, BattleConfig.FIGHT_COLS)
	var dest_row := wrapi(row + dy, 0, BattleConfig.FIGHT_ROWS)
	var try_col := dest_col
	var try_row := dest_row
	if cell_at(try_row, try_col) == null:
		# Empty slot: land on the other filled cell in that row or column.
		if dy != 0:
			try_col = wrapi(dest_col + 1, 0, BattleConfig.FIGHT_COLS)
		if dx != 0:
			try_row = wrapi(dest_row + 1, 0, BattleConfig.FIGHT_ROWS)
	if cell_at(try_row, try_col) == null or (try_col == col and try_row == row):
		return false
	col = try_col
	row = try_row
	return true
