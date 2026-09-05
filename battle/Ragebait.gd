class_name Ragebait
extends RefCounted
## Signed rage level that shifts catch odds and enemy combat stats.

enum Direction { ENRAGED, WARY }

var level: int = 0
var source: RagebaitSource = RagebaitSource.SingleLine.new()
## Tests set this to force a direction instead of rolling (-1 = roll).
var forced_direction: int = -1


class Outcome:
	extends RefCounted
	var line: String = ""
	var direction: int = Direction.ENRAGED
	var previous_level: int = 0
	var level: int = 0
	var at_cap: bool = false


func reset() -> void:
	level = 0


func taunt(creature: Creature, rng: RandomNumberGenerator) -> Outcome:
	var outcome := Outcome.new()
	outcome.previous_level = level
	outcome.line = source.get_line(creature, level)
	if forced_direction >= 0:
		outcome.direction = forced_direction
	else:
		outcome.direction = Direction.ENRAGED \
			if rng.randf() < BattleConfig.RAGE_ENRAGE_CHANCE else Direction.WARY
	var step := 1 if outcome.direction == Direction.ENRAGED else -1
	level = clampi(level + step, BattleConfig.RAGE_LEVEL_MIN, BattleConfig.RAGE_LEVEL_MAX)
	outcome.level = level
	outcome.at_cap = level == outcome.previous_level
	return outcome


func catch_multiplier() -> float:
	return clampf(
		1.0 + BattleConfig.RAGE_CATCH_PER_LEVEL * float(level),
		BattleConfig.RAGE_CATCH_MULT_MIN,
		BattleConfig.RAGE_CATCH_MULT_MAX
	)


func enemy_attack_multiplier() -> float:
	return clampf(
		1.0 + BattleConfig.RAGE_ATTACK_PER_LEVEL * float(level),
		BattleConfig.RAGE_STAT_MULT_MIN,
		BattleConfig.RAGE_STAT_MULT_MAX
	)


func enemy_defense_multiplier() -> float:
	return clampf(
		1.0 - BattleConfig.RAGE_DEFENSE_PER_LEVEL * float(level),
		BattleConfig.RAGE_STAT_MULT_MIN,
		BattleConfig.RAGE_STAT_MULT_MAX
	)


func outcome_message(creature_name: String, outcome: Outcome) -> String:
	if outcome.at_cap:
		if outcome.level >= BattleConfig.RAGE_LEVEL_MAX:
			return "%s is too furious to hear you!" % creature_name
		return "%s ignores you completely." % creature_name
	if outcome.direction == Direction.ENRAGED:
		return "%s is FURIOUS! Easier to catch, but it hits harder!" % creature_name
	return "%s is WARY! Harder to catch, but it holds back." % creature_name
