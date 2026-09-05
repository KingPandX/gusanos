class_name PlayerEffects

static var money_multiplier: float = 1.0
static var money_multiplier_timer: float = 0.0

static var rarity_boost: float = 0.0
static var rarity_boost_timer: float = 0.0

static var auto_collect_level: int = 0

static func add_money_multiplier(value: float, duration: float):
	money_multiplier = value
	money_multiplier_timer = duration

static func add_rarity_boost(value: float, duration: float):
	rarity_boost = value
	rarity_boost_timer = duration

static func get_money_multiplier() -> float:
	return money_multiplier

static func get_rarity_boost() -> float:
	return rarity_boost

static func has_auto_collect() -> bool:
	return auto_collect_level > 0

static func get_auto_collect_chance() -> float:
	return min(auto_collect_level * 0.2, 1.0)

static func update(delta: float):
	if money_multiplier_timer > 0:
		money_multiplier_timer -= delta
		if money_multiplier_timer <= 0:
			money_multiplier = 1.0
			money_multiplier_timer = 0.0
	if rarity_boost_timer > 0:
		rarity_boost_timer -= delta
		if rarity_boost_timer <= 0:
			rarity_boost = 0.0
			rarity_boost_timer = 0.0
