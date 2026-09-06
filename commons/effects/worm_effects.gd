class_name WormEffects

static func permanent_boost(worm: Worm, stat: String, value: float, ensure_min: bool = false):
	match stat:
		"damage":
			if ensure_min:
				worm.worm_data.damage = maxf(worm.worm_data.damage, 1.0)
			worm.worm_data.damage += worm.worm_data.damage * value
		"speed":
			if ensure_min:
				worm.worm_data.speed = maxf(worm.worm_data.speed, 1.0)
			worm.worm_data.speed += worm.worm_data.speed * value
		"hp_max":
			if ensure_min:
				worm.worm_data.hp_max = maxf(worm.worm_data.hp_max, 1.0)
			worm.worm_data.hp_max += worm.worm_data.hp_max * value
			worm.set_hp(worm.worm_data.hp_max)
		"size":
			if ensure_min:
				worm.worm_data.size = maxf(worm.worm_data.size, 1.0)
			worm.worm_data.size += worm.worm_data.size * value
			worm.scale = Vector2.ONE * worm.worm_data.size
		"cooldown_attack":
			if ensure_min:
				worm.worm_data.cooldown_attack = maxf(worm.worm_data.cooldown_attack, 1.0)
			worm.worm_data.cooldown_attack -= worm.worm_data.cooldown_attack * value
		"cooldown_money":
			if ensure_min:
				worm.worm_data.cooldown_money = maxf(worm.worm_data.cooldown_money, 1.0)
			worm.worm_data.cooldown_money -= worm.worm_data.cooldown_money * value

static func add_random_skill(worm: Worm):
	if not worm.worm_data.template or worm.worm_data.template.skills.is_empty():
		return
	var available: Array[SkillData] = []
	for entry in worm.worm_data.template.skills:
		if entry.skill not in worm.worm_data.skills:
			available.append(entry.skill)
	if available.is_empty():
		return
	var skill = available[randi() % available.size()]
	worm.worm_data.skills.append(skill)

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
	worm.set_hp(worm.worm_data.hp_max)
	var color = Rarity.get_rarity_color(worm.worm_data.rarity)
	worm.sprite.modulate = color

static func add_shield(worm: Worm, value: float, duration: float):
	worm.add_effect("shield", value, duration)

static func heal(worm: Worm, value: float):
	var heal_amount = worm.worm_data.hp_max * value
	worm.set_hp(min(worm.hp + heal_amount, worm.worm_data.hp_max))

static func permanent_boost_data(worm_data: Worm_Data, stat: String, value: float, ensure_min: bool = false):
	match stat:
		"damage":
			if ensure_min:
				worm_data.damage = maxf(worm_data.damage, 1.0)
			worm_data.damage += worm_data.damage * value
		"speed":
			if ensure_min:
				worm_data.speed = maxf(worm_data.speed, 1.0)
			worm_data.speed += worm_data.speed * value
		"hp_max":
			if ensure_min:
				worm_data.hp_max = maxf(worm_data.hp_max, 1.0)
			worm_data.hp_max += worm_data.hp_max * value
			worm_data.current_hp = worm_data.hp_max
		"size":
			if ensure_min:
				worm_data.size = maxf(worm_data.size, 1.0)
			worm_data.size += worm_data.size * value
		"cooldown_attack":
			if ensure_min:
				worm_data.cooldown_attack = maxf(worm_data.cooldown_attack, 1.0)
			worm_data.cooldown_attack -= worm_data.cooldown_attack * value
		"cooldown_money":
			if ensure_min:
				worm_data.cooldown_money = maxf(worm_data.cooldown_money, 1.0)
			worm_data.cooldown_money -= worm_data.cooldown_money * value

static func upgrade_rarity_data(worm_data: Worm_Data):
	if worm_data.rarity >= Rarity.Level.LEGENDARY:
		return
	worm_data.rarity = worm_data.rarity + 1
	var stat_range = worm_data.template.get_stats_for_rarity(worm_data.rarity)
	var stats = stat_range.roll_stats()
	worm_data.hp_max = stats.hp_max
	worm_data.damage = stats.damage
	worm_data.speed = stats.speed
	worm_data.size = stats.size
	worm_data.cooldown_attack = stats.cooldown_attack
	worm_data.cooldown_money = stats.cooldown_money
	worm_data.current_hp = worm_data.hp_max
