extends Control

signal worm_added_to_social(worm: Worm)
signal worm_removed_from_social(worm: Worm)

var social_worms: Array[Worm] = []
var worm_scene: PackedScene = preload("res://worms/worm.tscn")

func _ready() -> void:
	add_to_group("social_area")

func spawn_social_worm(worm_data: Worm_Data, pos: Vector2 = Vector2.ZERO) -> Worm:
	var worm_instance = worm_scene.instantiate()
	worm_instance.worm_data = worm_data
	worm_instance.area = "social"

	if pos == Vector2.ZERO:
		pos = _get_random_position()

	worm_instance.position = pos
	$WormsContainer.add_child(worm_instance)

	var sprite = worm_instance.get_node("Sprite")
	if sprite:
		var color = Rarity.get_rarity_color(worm_data.rarity)
		sprite.modulate = color

	social_worms.append(worm_instance)
	worm_instance.tree_exiting.connect(_on_worm_removed.bind(worm_instance))
	worm_added_to_social.emit(worm_instance)

	return worm_instance

func remove_social_worm(worm: Worm) -> void:
	if worm in social_worms:
		social_worms.erase(worm)
		worm_removed_from_social.emit(worm)
		worm.queue_free()

func _on_worm_removed(worm: Worm) -> void:
	social_worms.erase(worm)

func _get_random_position() -> Vector2:
	var viewport_size = get_viewport_rect().size
	return Vector2(
		randf_range(50, viewport_size.x - 250),
		randf_range(50, viewport_size.y - 50)
	)

func get_worms_in_social() -> Array[Worm]:
	return social_worms.filter(func(w): return is_instance_valid(w))

func is_point_in_social(point: Vector2) -> bool:
	return get_viewport_rect().has_point(point)
