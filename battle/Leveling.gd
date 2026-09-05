class_name Leveling
extends RefCounted
## EXP curve and level-up. Pure; BattleState plays the messages.


static func exp_needed(level: int) -> int:
	return BattleConfig.EXP_BASE + BattleConfig.EXP_PER_LEVEL * level


static func exp_yield(enemy: Creature) -> int:
	if enemy == null:
		return BattleConfig.EXP_YIELD_BASE
	var from_hp := int(enemy.max_hp / 8)
	return BattleConfig.EXP_YIELD_BASE + BattleConfig.EXP_YIELD_PER_LEVEL * enemy.level + from_hp


static func grant_exp(winner: Creature, fainted: Creature) -> Dictionary:
	var report := {"gained": 0, "levels": []}
	if winner == null or fainted == null or winner.is_fainted():
		return report
	var gained := exp_yield(fainted)
	winner.exp += gained
	report["gained"] = gained
	var levels: Array = []
	while winner.level < BattleConfig.MAX_LEVEL and winner.exp >= exp_needed(winner.level):
		winner.exp -= exp_needed(winner.level)
		levels.append(apply_level_up(winner))
	if winner.level >= BattleConfig.MAX_LEVEL:
		winner.exp = 0
	report["levels"] = levels
	return report


static func apply_level_up(creature: Creature) -> Dictionary:
	creature.level += 1
	creature.max_hp += BattleConfig.HP_PER_LEVEL
	if not creature.is_fainted():
		creature.hp = mini(creature.hp + BattleConfig.HP_PER_LEVEL, creature.max_hp)
	creature.attack += BattleConfig.ATK_PER_LEVEL
	if creature.level % 2 == 0:
		creature.defense += BattleConfig.DEF_PER_EVEN_LEVEL
	var learned := Learnset.try_learn_at_level(creature, creature.level)
	return {
		"level": creature.level,
		"learned": String(learned.get("learned", "")),
		"replaced": String(learned.get("replaced", "")),
	}


static func roll_wild_level(player_level: int, rng: RandomNumberGenerator) -> int:
	var base := player_level if player_level > 0 else 5
	return clampi(base + rng.randi_range(-1, 1), 2, BattleConfig.MAX_LEVEL)
