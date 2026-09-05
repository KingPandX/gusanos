extends Control

@onready var combat_box: PanelContainer = $CombatBox
@onready var social_area: Control = $SocialArea
@onready var ui_layer: CanvasLayer = $UILayer

func _ready() -> void:
	DragManager.worm_dropped.connect(_on_worm_dropped)

func _on_worm_dropped(worm_data: Worm_Data, source: int, target_area: int, drop_position: Vector2) -> void:
	if source == target_area:
		_restore_worm(worm_data, source, drop_position)
		return
	if source == DragManager.DragSource.SOCIAL and target_area == DragManager.DropTarget.COMBAT:
		_move_worm_to_combat(worm_data, drop_position)
	elif source == DragManager.DragSource.COMBAT and target_area == DragManager.DropTarget.SOCIAL:
		_spawn_worm_in_social(worm_data, drop_position)

func _restore_worm(worm_data: Worm_Data, area: int, drop_position: Vector2) -> void:
	if area == DragManager.DragSource.SOCIAL:
		var worms_container = social_area.get_node_or_null("WormsContainer")
		if worms_container:
			for child in worms_container.get_children():
				if child is Worm and child.worm_data == worm_data:
					child.is_being_dragged = false
					child.visible = true
					child.global_position = drop_position
					child.new_random_velocity()
					child.set_physics_process(true)
					child.set_process(true)
					child.get_node("Change_direction").start()
					child.get_node("Money").start()
					break
	elif area == DragManager.DragSource.COMBAT:
		var spawner = get_tree().get_first_node_in_group("combat_spawner")
		if spawner:
			var local_pos = drop_position - combat_box.global_position
			var scaled_pos = local_pos / combat_box.scale.x
			spawner.spawn_specific_worm(worm_data, scaled_pos)

func _move_worm_to_combat(worm_data: Worm_Data, drop_position: Vector2) -> void:
	var spawner = get_tree().get_first_node_in_group("combat_spawner")
	if spawner:
		var local_pos = drop_position - combat_box.global_position
		var scaled_pos = local_pos / combat_box.scale.x
		spawner.spawn_specific_worm(worm_data, scaled_pos)
		Inventory.move_worm(worm_data, "combat")
		_remove_from_social_area(worm_data)

func _spawn_worm_in_social(worm_data: Worm_Data, drop_position: Vector2) -> void:
	if social_area:
		social_area.spawn_social_worm(worm_data, drop_position)

func _remove_from_social_area(worm_data: Worm_Data) -> void:
	if social_area:
		var worms_container = social_area.get_node_or_null("WormsContainer")
		if worms_container:
			for child in worms_container.get_children():
				if child is Worm and child.worm_data == worm_data:
					child.queue_free()
					break
