extends Control

@onready var combat_box : PanelContainer = $CombatBox

const FULL_SIZE = Vector2(720, 627)

func _ready() -> void:
	combat_box.pivot_offset = Vector2.ZERO
	combat_box.scale = Vector2.ONE
	_center_combat()
	get_viewport().size_changed.connect(_center_combat)

func _center_combat() -> void:
	combat_box.position = (get_viewport_rect().size - FULL_SIZE) / 2
