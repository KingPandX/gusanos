extends Area2D

signal drop_collected(rarity: Rarity.Level)

var rarity: Rarity.Level
var clicks_needed: int
var clicks_remaining: int

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var click_requirements: Dictionary = {
	Rarity.Level.COMMON: 2,
	Rarity.Level.RARE: 3,
	Rarity.Level.EPIC: 4,
	Rarity.Level.LEGENDARY: 6,
}

func _ready() -> void:
	input_pickable = true
	clicks_needed = click_requirements.get(rarity, 2)
	clicks_remaining = clicks_needed

func setup(p_rarity: Rarity.Level) -> void:
	rarity = p_rarity

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _is_mouse_over():
			_on_click()

func _is_mouse_over() -> bool:
	var mouse_pos = get_global_mouse_position()
	var shape = collision_shape.shape
	if shape is CircleShape2D:
		return global_position.distance_to(mouse_pos) <= shape.radius
	return false

func _on_click() -> void:
	clicks_remaining -= 1
	_play_bounce()
	if clicks_remaining <= 0:
		_collect()

func _play_bounce() -> void:
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.3, 0.7), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(sprite, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _collect() -> void:
	sprite.modulate = Rarity.get_rarity_color(rarity)
	
	var social_area = get_tree().get_first_node_in_group("social_area")
	if not social_area:
		queue_free()
		return

	if Inventory.can_add():
		var templates = Inventory.templates
		if not templates.is_empty():
			var worm_data = WormFactory.generate_worm(rarity, templates)
			if worm_data:
				Inventory.add_worm(worm_data, "social")
				social_area.spawn_social_worm(worm_data, global_position)
				drop_collected.emit(rarity)
	else:
		print("Inventario lleno - no se pudo agregar el gusano")

	queue_free()
