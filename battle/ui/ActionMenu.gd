class_name ActionMenu
extends RefCounted
## FireRed-style 2x3 battle menu. Sixth cell is empty and skipped.

enum Action { FIGHT, BAG, PARTY, RUN, RAGE }

const LAYOUT := [
	[Action.FIGHT, Action.BAG, Action.PARTY],
	[Action.RUN, Action.RAGE, -1],
]

const LABELS := {
	Action.FIGHT: "FIGHT",
	Action.BAG: "BAG",
	Action.PARTY: "PARTY",
	Action.RUN: "RUN",
	Action.RAGE: "RAGE",
}

var col: int = 0
var row: int = 0


func reset() -> void:
	col = 0
	row = 0


func current() -> int:
	return LAYOUT[row][col]


func cell_at(r: int, c: int) -> int:
	return LAYOUT[r][c]


func move(dx: int, dy: int) -> bool:
	var start_col := col
	var start_row := row
	var c := col
	var r := row
	for _i in range(BattleConfig.MENU_COLS * BattleConfig.MENU_ROWS):
		c = wrapi(c + dx, 0, BattleConfig.MENU_COLS)
		r = wrapi(r + dy, 0, BattleConfig.MENU_ROWS)
		if LAYOUT[r][c] != -1:
			col = c
			row = r
			return col != start_col or row != start_row
	return false
