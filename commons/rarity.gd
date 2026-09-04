class_name Rarity

enum Level { COMMON, RARE, EPIC, LEGENDARY }

const RARITY_WEIGHTS = [60, 25, 12, 3]

const SLOT_COSTS = [0, 0, 0, 500, 1000, 2000, 4000, 8000, 15000, 30000]

static func get_rarity_name(rarity: Level) -> String:
	match rarity:
		Level.COMMON: return "Common"
		Level.RARE: return "Rare"
		Level.EPIC: return "Epic"
		Level.LEGENDARY: return "Legendary"
	return ""

static func get_rarity_color(rarity: Level) -> Color:
	match rarity:
		Level.COMMON: return Color.WHITE
		Level.RARE: return Color(0.3, 0.5, 1.0)
		Level.EPIC: return Color(0.7, 0.2, 0.9)
		Level.LEGENDARY: return Color(1.0, 0.8, 0.0)
	return Color.WHITE

static func roll_rarity() -> Level:
	var total = 0
	for w in RARITY_WEIGHTS:
		total += w
	var roll = randi() % total
	var cumulative = 0
	for i in range(RARITY_WEIGHTS.size()):
		cumulative += RARITY_WEIGHTS[i]
		if roll < cumulative:
			return i as Level
	return Level.COMMON

static func get_slot_cost(slot_index: int) -> int:
	if slot_index < SLOT_COSTS.size():
		return SLOT_COSTS[slot_index]
	return -1
