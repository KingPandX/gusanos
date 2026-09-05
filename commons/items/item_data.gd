extends Resource
class_name ItemData

enum Target {
	PLAYER,
	WORM
}

@export var item_name: String
@export var description: String
@export var icon: Texture2D
@export var effect: EffectData
@export var target: Target = Target.WORM
@export var cost: int = 100
@export var quantity: int = 1
