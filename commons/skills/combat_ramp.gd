extends SkillData
class_name CombatRamp

@export var damage_per_stack: float = 0.1
@export var max_stacks: int = 5

func on_combat_start(worm: Worm) -> void:
	worm.worm_data.combat_stacks = 0

func on_combat_end(worm: Worm) -> void:
	worm.worm_data.combat_stacks = 0

func on_combat_tick(worm: Worm) -> void:
	if worm.worm_data.combat_stacks < max_stacks:
		worm.worm_data.combat_stacks += 1

func get_damage_multiplier(worm: Worm) -> float:
	return damage_per_stack * worm.worm_data.combat_stacks
