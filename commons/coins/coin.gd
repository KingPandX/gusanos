extends Area2D
class_name Coin

@export var value: int = 1
var collected: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	input_event.connect(_on_input_event)
	body_entered.connect(_on_body_entered)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
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
