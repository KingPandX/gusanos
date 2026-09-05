extends Resource
class_name Worm_Data

@export var template : WormTemplate
@export var rarity : Rarity.Level

@export var hp_max : float
@export var damage : float
@export var cooldown_attack : float
@export var cooldown_money : float
@export var size : float = 1
@export var speed : float = 60

@export var skills: Array[SkillData] = []
var combat_stacks: int = 0
var stat_multiplier: float = 1.0

func get_computed_damage() -> float:
	return damage * stat_multiplier

func get_computed_hp_max() -> float:
	return hp_max * stat_multiplier

func get_computed_speed() -> float:
	return speed * stat_multiplier

func get_computed_size() -> float:
	return size * stat_multiplier

func get_computed_cooldown_attack() -> float:
	return cooldown_attack / stat_multiplier

var worm: Worm
