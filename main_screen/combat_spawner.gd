extends Node2D

signal toggle_position_requested()

@onready var spawn_min : Marker2D = $SpawnMin
@onready var spawn_max : Marker2D = $SpawnMax

var worm_scene : PackedScene

func _ready() -> void:
	add_to_group("combat_spawner")
	worm_scene = load("res://worms/worm.tscn")

func _on_toggle_position_pressed() -> void:
	toggle_position_requested.emit()

func spawn_worm() -> void:
	if Inventory.templates.is_empty():
		print("ERROR: No templates loaded!")
		return
	if not Inventory.can_add():
		print("ERROR: No slots available!")
		return
	
	var worm_data = WormFactory.generate_random_worm(Inventory.templates)
	if worm_data == null:
		print("ERROR: Failed to generate worm")
		return
	
	Inventory.add_worm(worm_data, "combat")
	var spawn_pos = Vector2(
		randf_range(spawn_min.global_position.x, spawn_max.global_position.x),
		randf_range(spawn_min.global_position.y, spawn_max.global_position.y)
	)
	
	spawn_specific_worm(worm_data, spawn_pos)

func spawn_specific_worm(worm_data: Worm_Data, pos: Vector2) -> Worm:
	var worm_instance = worm_scene.instantiate()
	worm_instance.worm_data = worm_data
	worm_instance.area = "combat"
	
	if pos == Vector2.ZERO:
		pos = Vector2(
			randf_range(spawn_min.global_position.x, spawn_max.global_position.x),
			randf_range(spawn_min.global_position.y, spawn_max.global_position.y)
		)
	
	worm_instance.position = pos
	add_child(worm_instance)
	
	var sprite = worm_instance.get_node("Sprite")
	if sprite:
		var color = Rarity.get_rarity_color(worm_data.rarity)
		sprite.modulate = color
	
	var rarity_name = Rarity.get_rarity_name(worm_data.rarity)
	print("Spawned: %s (%s) at %s" % [worm_data.template.worm_name, rarity_name, pos])
	
	return worm_instance

func remove_worm_from_combat(worm: Worm) -> void:
	if worm and is_instance_valid(worm):
		worm.area = "social"
		worm.exit_combat()
		worm.queue_free()
