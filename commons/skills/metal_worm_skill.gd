extends SkillData
class_name MetalWormSkill

@export var stat_multiplier_bonus: float = 0.5
@export var trigger_chance: float = 0.4

func on_kill(killer: Worm, _victim: Worm) -> void:
	if randf() > trigger_chance:
		return
	killer.worm_data.stat_multiplier += stat_multiplier_bonus
	killer.max_speed = killer.worm_data.get_computed_speed()
	killer.scale = Vector2.ONE * killer.worm_data.get_computed_size()

func get_display_chance() -> String:
	return " (%d%%)" % int(trigger_chance * 100)
