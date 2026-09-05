class_name BattleCopy
extends RefCounted
## Battle flavor. Nostalgic FireRed cadence, 2026 punchline on line 2.
## Every string must wrap to BattleConfig.TEXT_MAX_LINES at TEXT_MAX_WIDTH.


static func intro(enemy_name: String) -> String:
	return "A wild %s wants to debate!" % enemy_name


static func used_move(user_name: String, move_name: String) -> String:
	return "%s used %s!" % [user_name, move_name]


static func wild_used_move(enemy_name: String, move_name: String) -> String:
	return "Wild %s used %s!" % [enemy_name, move_name]


static func miss() -> String:
	return "The attack hallucinated."


static func faint_wild(enemy_name: String) -> String:
	return "Wild %s logged off." % enemy_name


static func faint_player(player_name: String) -> String:
	return "%s fainted! Skill issue." % player_name


static func run_ok() -> String:
	return "Got away safely!"


static func run_fail() -> String:
	return "Couldn't get away! The grass is unionizing."


static func no_item() -> String:
	return "You have none left!"


static func recovered(player_name: String, amount: int) -> String:
	return "%s recovered %d HP!" % [player_name, amount]


static func no_orbs() -> String:
	return "You have no Capture Orbs!"


static func catch_throw(rage_level: int) -> String:
	if rage_level >= 2:
		return "You yeeted a Capture Orb!"
	return "You threw a Capture Orb!"


static func already_out(player_name: String) -> String:
	return "%s is already out!" % player_name


static func switch_out(player_name: String) -> String:
	return "Come back, %s! The discourse is toxic." % player_name


static func switch_in(player_name: String) -> String:
	return "Go, %s! Don't read the comments." % player_name


static func you_said(line: String) -> String:
	return "You: \"%s\"" % line


static func fits(text: String) -> bool:
	var wrapped := MessageBox.wrap_lines(text)
	if wrapped.size() > BattleConfig.TEXT_MAX_LINES or wrapped.is_empty():
		return false
	var rebuilt: PackedStringArray = []
	for part in wrapped:
		rebuilt.append(part)
	return " ".join(rebuilt) == text
