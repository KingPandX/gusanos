extends Resource
class_name UpgradeData

@export var upgrade_name: String
@export var description: String
@export var icon: Texture2D
@export var effect: EffectData
@export var cost: int
@export var cost_multiplier: float = 1.5
@export var max_level: int = 5
@export var prerequisite: UpgradeData

var current_level: int = 0

func get_current_cost() -> int:
	return round(cost * pow(cost_multiplier, current_level))

func can_upgrade() -> bool:
	if current_level >= max_level:
		return false
	if prerequisite and prerequisite.current_level < 1:
		return false
	return true

func apply() -> void:
	if not can_upgrade():
		return
	current_level += 1
	EffectProcessor.apply(effect)
