extends SkillData
class_name MoneyOnHit

@export var money_amount: int = 5
@export var trigger_chance: float = 0.25

func on_take_damage(worm: Worm, _attacker: Worm, _amount: float) -> void:
	if randf() > trigger_chance:
		return
	GlobalManager.add_money(money_amount)

func get_display_chance() -> String:
	return " (%d%%)" % int(trigger_chance * 100)
