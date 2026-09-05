extends Node

var money_multiplier: float = 1.0
var money_multiplier_timer: float = 0.0

var rarity_boost: float = 0.0
var rarity_boost_timer: float = 0.0

var auto_collect_level: int = 0
var drop_frequency_level: int = 0
var rarity_spawn_boost: float = 0.0
var shop_discount_level: int = 0

func add_money_multiplier(value: float, duration: float):
	money_multiplier = value
	money_multiplier_timer = duration

func add_rarity_boost(value: float, duration: float):
	rarity_boost = value
	rarity_boost_timer = duration

func get_money_multiplier() -> float:
	return money_multiplier

func get_rarity_boost() -> float:
	return rarity_boost

func has_auto_collect() -> bool:
	return auto_collect_level > 0

func get_auto_collect_chance() -> float:
	return min(auto_collect_level * 0.2, 1.0)

func get_rarity_spawn_boost() -> float:
	return rarity_spawn_boost

func get_shop_discount() -> float:
	return shop_discount_level * 0.05

func _process(delta: float) -> void:
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
