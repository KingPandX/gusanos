extends Control

@onready var combat_box : PanelContainer = $CombatBox

func _ready() -> void:
	combat_box.pivot_offset = Vector2.ZERO
	combat_box.scale = Vector2.ONE
