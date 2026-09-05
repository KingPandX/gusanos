extends Area2D
class_name Coin

@export var value: int = 1
var collected: bool = false
var mouse_hovering: bool = false

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	input_pickable = true
	monitoring = true
	monitorable = true
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			collect()

func _on_mouse_entered() -> void:
	mouse_hovering = true

func _on_mouse_exited() -> void:
	mouse_hovering = false

func _unhandled_input(event: InputEvent) -> void:
	if mouse_hovering and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			collect()

func _on_body_entered(_body: Node) -> void:
	if PlayerEffects.has_auto_collect():
		if randf() < PlayerEffects.get_auto_collect_chance():
			collect()

func collect() -> void:
	if collected:
		return
	collected = true
	var final_value = round(value * PlayerEffects.get_money_multiplier())
	GlobalManager.add_money(final_value)
	queue_free()
