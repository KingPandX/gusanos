extends SkillData
class_name MoneyOnFight

@export var money_amount: int = 3
@export var trigger_chance: float = 0.4

func on_deal_damage(worm: Worm, _amount: float) -> void:
	if randf() > trigger_chance:
		return
	GlobalManager.add_money(money_amount)

func get_display_chance() -> String:
	return " (%d%%)" % int(trigger_chance * 100)
