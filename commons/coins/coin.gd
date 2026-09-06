extends Area2D
class_name Coin

@export var value: int = 1
var collected: bool = false

@onready var sprite: AnimatedSprite2D = $Sprite2D
const MONDEDAS_1 = preload("uid://ybc6uwqxd75t")

func _ready() -> void:
	if PlayerEffects.has_auto_collect():
		if randf() < PlayerEffects.get_auto_collect_chance():
			collect()
	visible = true
	sprite.play("default")
	input_pickable = true
	monitoring = false
	monitorable = false
	input_event.connect(_on_input_event)

func _process(_delta: float) -> void:
	if collected:
		return

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if collected:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		collect()

func collect() -> void:
	AudioManager.play_sfx(MONDEDAS_1, randf_range(0.7, 1.3))
	if collected:
		return
	collected = true
	var final_value = round(value * PlayerEffects.get_money_multiplier())
	GlobalManager.add_money(final_value)
	queue_free()
