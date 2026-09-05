extends Resource
class_name WormTemplate

@export var worm_name : String = ""
@export var sprite_frames : SpriteFrames
@export var sprite_offset : Vector2 = Vector2.ZERO

@export var common_stats : StatRange
@export var rare_stats : StatRange
@export var epic_stats : StatRange
@export var legendary_stats : StatRange

@export var skills: Array[SkillEntry] = []

func get_stats_for_rarity(rarity: Rarity.Level) -> StatRange:
	match rarity:
		Rarity.Level.COMMON: return common_stats
		Rarity.Level.RARE: return rare_stats
		Rarity.Level.EPIC: return epic_stats
		Rarity.Level.LEGENDARY: return legendary_stats
	return common_stats
