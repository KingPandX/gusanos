extends Resource
class_name SkillData

@export var skill_name: String = ""
@export var description: String = ""
@export var icon: Texture2D

func on_take_damage(_worm: Worm, _attacker: Worm, _amount: float) -> void:
	pass

func on_deal_damage(_worm: Worm, _amount: float) -> void:
	pass

func on_kill(_killer: Worm, _victim: Worm) -> void:
	pass

func on_combat_start(_worm: Worm) -> void:
	pass

func on_combat_end(_worm: Worm) -> void:
	pass

func on_combat_tick(_worm: Worm) -> void:
	pass

func get_damage_multiplier(_worm: Worm) -> float:
	return 0.0

func get_incoming_damage_reduction(_worm: Worm, _attacker: Worm, _amount: float) -> float:
	return 0.0

func get_attack_cooldown_slow(_worm: Worm) -> float:
	return 0.0
