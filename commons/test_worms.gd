extends Node

func generate_test_worms() -> Array[Worm_Data]:
	var worms : Array[Worm_Data] = []
	for i in range(3):
		var worm = WormFactory.generate_random_worm(Inventory.templates)
		if worm:
			worms.append(worm)
	return worms

func print_worm_stats(worm: Worm_Data) -> void:
	if worm == null:
		return
	var rarity_name = Rarity.get_rarity_name(worm.rarity)
	var template_name = worm.template.worm_name if worm.template else "Unknown"
	print("=== %s (%s) ===" % [template_name, rarity_name])
	print("HP: %.0f | Damage: %.0f | Speed: %.0f" % [worm.hp_max, worm.damage, worm.speed])
	print("Attack Cooldown: %.2fs | Money Cooldown: %.2fs" % [worm.cooldown_attack, worm.cooldown_money])
	print("")
