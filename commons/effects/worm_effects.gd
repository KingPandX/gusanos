class_name WormEffects

static func permanent_boost(worm: Worm, stat: String, value: float):
	match stat:
		"damage":
			worm.worm_data.damage += worm.worm_data.damage * value
		"speed":
			worm.worm_data.speed += worm.worm_data.speed * value
		"hp_max":
			worm.worm_data.hp_max += worm.worm_data.hp_max * value
			worm.hp = worm.worm_data.hp_max
		"size":
			worm.worm_data.size += worm.worm_data.size * value
			worm.scale = Vector2.ONE * worm.worm_data.size

static func upgrade_rarity(worm: Worm):
	if worm.worm_data.rarity >= Rarity.Level.LEGENDARY:
		return
	worm.worm_data.rarity = worm.worm_data.rarity + 1
	var stat_range = worm.worm_data.template.get_stats_for_rarity(worm.worm_data.rarity)
	var stats = stat_range.roll_stats()
	worm.worm_data.hp_max = stats.hp_max
	worm.worm_data.damage = stats.damage
	worm.worm_data.speed = stats.speed
	worm.worm_data.size = stats.size
	worm.worm_data.cooldown_attack = stats.cooldown_attack
	worm.worm_data.cooldown_money = stats.cooldown_money
	worm.hp = worm.worm_data.hp_max
	var color = Rarity.get_rarity_color(worm.worm_data.rarity)
	worm.sprite.modulate = color

static func add_shield(worm: Worm, value: float, duration: float):
	worm.add_effect("shield", value, duration)

static func heal(worm: Worm, value: float):
	var heal_amount = worm.worm_data.hp_max * value
	worm.hp = min(worm.hp + heal_amount, worm.worm_data.hp_max)
