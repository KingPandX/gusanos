extends SkillData
class_name MutualKill

@export var trigger_chance: float = 1.0

func on_take_damage(worm: Worm, attacker: Worm, _amount: float) -> void:
	if randf() > trigger_chance:
		return
	if attacker != null and is_instance_valid(attacker):
		attacker.set_hp(0)
	worm.set_hp(0)

func get_display_chance() -> String:
	return " (%d%%)" % int(trigger_chance * 100)
