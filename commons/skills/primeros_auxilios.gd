extends SkillData
class_name PrimerosAuxilios

@export var hp_threshold: float = 0.3
@export var regen_boost: float = 3.0
@export var boost_duration: float = 5.0
@export var cooldown: float = 120.0

var current_cooldown: float = 0.0

func on_take_damage(worm: Worm, _attacker: Worm, _amount: float) -> void:
	if current_cooldown > 0.0:
		return
	var hp_percent = worm.hp / worm.worm_data.get_computed_hp_max()
	if hp_percent <= hp_threshold:
		worm.activate_regen_boost(regen_boost, boost_duration)
		current_cooldown = cooldown

func on_combat_tick(worm: Worm) -> void:
	if current_cooldown > 0.0:
		current_cooldown = max(current_cooldown - 1.0, 0.0)

func get_display_chance() -> String:
	return " (%d%%)" % int(hp_threshold * 100)
