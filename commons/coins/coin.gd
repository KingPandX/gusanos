extends Area2D
class_name Coin

@export var value: int = 1
var collected: bool = false

@onready var sprite: AnimatedSprite2D = $Sprite2D

func _ready() -> void:
	sprite.play("default")
	input_pickable = true
	monitoring = false
	monitorable = false

func _process(_delta: float) -> void:
	if collected:
		return
	if PlayerEffects.has_auto_collect():
		if randf() < PlayerEffects.get_auto_collect_chance():
			collect()
			return
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mouse_pos = get_global_mouse_position()
		if global_position.distance_to(mouse_pos) < 20.0:
			collect()


func collect() -> void:
	if collected:
		return
	collected = true
	var final_value = round(value * PlayerEffects.get_money_multiplier())
	GlobalManager.add_money(final_value)
	queue_free()
