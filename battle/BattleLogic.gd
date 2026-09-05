class_name BattleLogic
extends RefCounted
## Pure battle maths. No nodes, no signals — headless-testable.


class AttackResult:
	extends RefCounted
	var hit: bool = true
	var damage: int = 0
	var fainted: bool = false


static func damage_variance(rng: RandomNumberGenerator) -> float:
	return rng.randf_range(BattleConfig.DAMAGE_VARIANCE_MIN, BattleConfig.DAMAGE_VARIANCE_MAX)


static func compute_damage(
	attacker_attack: int,
	move_power: int,
	defender_defense: int,
	variance: float,
	attack_mult: float = 1.0,
	defense_mult: float = 1.0
) -> int:
	var effective_attack := float(attacker_attack) * attack_mult
	var effective_defense := float(defender_defense) * defense_mult
	var base := (effective_attack * float(move_power) / 10.0) - (effective_defense / 2.0)
	var dealt := int(round(base * variance))
	return maxi(BattleConfig.MIN_DAMAGE, dealt)


static func apply_damage(defender: Creature, amount: int) -> int:
	var before := defender.hp
	defender.hp = clampi(defender.hp - amount, 0, defender.max_hp)
	return before - defender.hp


static func apply_heal(target: Creature, amount: int) -> int:
	var before := target.hp
	target.hp = clampi(target.hp + amount, 0, target.max_hp)
	return target.hp - before


static func resolve_attack(
	attacker: Creature,
	defender: Creature,
	move: BattleMove,
	rng: RandomNumberGenerator,
	attack_mult: float = 1.0,
	defense_mult: float = 1.0
) -> AttackResult:
	var result := AttackResult.new()
	if rng.randf() > move.accuracy:
		result.hit = false
		return result
	var rolled := compute_damage(
		attacker.attack, move.power, defender.defense,
		damage_variance(rng), attack_mult, defense_mult
	)
	result.damage = apply_damage(defender, rolled)
	result.fainted = defender.is_fainted()
	return result


static func run_chance(failed_attempts: int) -> float:
	var chance := BattleConfig.RUN_BASE_CHANCE \
		+ BattleConfig.RUN_CHANCE_PER_FAIL * float(failed_attempts)
	return clampf(chance, 0.0, BattleConfig.RUN_CHANCE_MAX)


static func try_run(failed_attempts: int, rng: RandomNumberGenerator) -> bool:
	return rng.randf() < run_chance(failed_attempts)


static func default_move(creature: Creature) -> BattleMove:
	match String(creature.type):
		"FIRE":
			return BattleMove.make(&"ember", "EMBER", &"FIRE", 11)
		"GRASS":
			return BattleMove.make(&"vine_whip", "VINE WHIP", &"GRASS", 9)
		"ROCK":
			return BattleMove.make(&"rock_throw", "ROCK THROW", &"ROCK", 10)
		"WATER":
			return BattleMove.make(&"water_gun", "WATER GUN", &"WATER", 10)
		_:
			return BattleMove.make(&"tackle", "TACKLE", &"NORMAL", 10)


static func choose_enemy_move(enemy: Creature, _rng: RandomNumberGenerator) -> BattleMove:
	return default_move(enemy)


static func hp_fraction(creature: Creature) -> float:
	if creature == null or creature.max_hp <= 0:
		return 0.0
	return float(creature.hp) / float(creature.max_hp)
