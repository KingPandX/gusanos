extends Resource
class_name EffectData

enum Target {
	PLAYER,
	WORM,
	ALL_WORMS,
	GAME_MECHANIC
}

enum Type {
	STAT_BOOST,
	RARITY_UPGRADE,
	SHIELD,
	MONEY_MULTIPLIER,
	RARITY_BOOST,
	HEAL,
	RESURRECT,
	AUTO_COLLECT,
	EXTRA_SLOTS,
	SHOP_DISCOUNT,
	SHOP_EXTRA_ITEMS,
	DROP_FREQUENCY,
}

@export var effect_name: String
@export var description: String
@export var icon: Texture2D
@export var effect_type: Type
@export var target: Target
@export var stat: String = ""
@export var value: float = 0.0
@export var duration: float = 0.0
@export var cost: int = 0
@export var is_upgrade: bool = false
