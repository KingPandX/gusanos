extends SkillData
class_name ReflectDamage

@export var reflect_percent: float = 0.5
@export var trigger_chance: float = 0.3

func on_take_damage(worm: Worm, attacker: Worm, amount: float) -> void:
	if attacker == null or not is_instance_valid(attacker):
		return
	if randf() > trigger_chance:
		return
	attacker.take_damage(amount * reflect_percent, null)

func get_display_chance() -> String:
	return " (%d%%)" % int(trigger_chance * 100)
