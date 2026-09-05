extends SkillData
class_name IceSkill

@export var damage_reduction: float = 0.2
@export var cooldown_slow: float = 0.3

func on_take_damage(_worm: Worm, _attacker: Worm, _amount: float) -> void:
	pass

func get_incoming_damage_reduction(_worm: Worm, _attacker: Worm, _amount: float) -> float:
	return damage_reduction

func get_attack_cooldown_slow(_worm: Worm) -> float:
	return cooldown_slow
