extends SkillData
class_name MoneyOnKill

@export var money_amount: int = 20
@export var trigger_chance: float = 1.0

func on_kill(_killer: Worm, _victim: Worm) -> void:
	if randf() > trigger_chance:
		return
	GlobalManager.add_money(money_amount)
