extends Resource
class_name PlayerPersistentSaveData

@export var auto_collect_level: int = 0
@export var drop_frequency_level: int = 0
@export var rarity_spawn_boost: float = 0.0
@export var shop_discount_level: int = 0

static func create_from_game() -> PlayerPersistentSaveData:
	var data = PlayerPersistentSaveData.new()
	data.auto_collect_level = PlayerEffects.auto_collect_level
	data.drop_frequency_level = PlayerEffects.drop_frequency_level
	data.rarity_spawn_boost = PlayerEffects.rarity_spawn_boost
	data.shop_discount_level = PlayerEffects.shop_discount_level
	return data
