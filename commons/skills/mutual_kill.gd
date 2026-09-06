extends SkillData
class_name MutualKill

@export var trigger_chance: float = 1.0

func on_take_damage(worm: Worm, attacker: Worm, _amount: float) -> void:
	if randf() > trigger_chance:
		return
	if attacker != null and is_instance_valid(attacker) and not attacker.is_dead:
		attacker.die()
	if not worm.is_dead:
		worm.die()

func get_display_chance() -> String:
	return " (%d%%)" % int(trigger_chance * 100)
