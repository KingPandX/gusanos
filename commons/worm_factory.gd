extends Node
class_name WormFactory

static func generate_worm(rarity: Rarity.Level, templates: Array[WormTemplate]) -> Worm_Data:
	if templates.is_empty():
		return null
	
	var template = templates[randi() % templates.size()]
	var stat_range = template.get_stats_for_rarity(rarity)
	var stats = stat_range.roll_stats()
	
	var worm_data = Worm_Data.new()
	worm_data.template = template
	worm_data.rarity = rarity
	worm_data.hp_max = stats.hp_max
	worm_data.damage = stats.damage
	worm_data.cooldown_attack = stats.cooldown_attack
	worm_data.cooldown_money = stats.cooldown_money
	worm_data.speed = stats.speed
	worm_data.size = stats.size
	
	return worm_data

static func generate_random_worm(templates: Array[WormTemplate]) -> Worm_Data:
	var rarity = Rarity.roll_rarity()
	return generate_worm(rarity, templates)
