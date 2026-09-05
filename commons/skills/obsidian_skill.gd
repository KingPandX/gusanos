extends SkillData
class_name ObsidianSkill

@export var ignore_damage_chance: float = 0.25
@export var heal_percent: float = 0.1

func on_take_damage(worm: Worm, _attacker: Worm, amount: float) -> void:
	if randf() < ignore_damage_chance:
		worm.hp = min(worm.hp + amount, worm.worm_data.get_computed_hp_max())
		return
	var heal = worm.worm_data.get_computed_hp_max() * heal_percent
	worm.hp = min(worm.hp + heal, worm.worm_data.get_computed_hp_max())

func get_display_chance() -> String:
	return " (%d%%)" % int(ignore_damage_chance * 100)
