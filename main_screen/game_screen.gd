extends Control

@onready var combat_box: PanelContainer = $UILayer/CombatBox
@onready var social_area: Control = $SocialArea
@onready var ui_layer: CanvasLayer = $UILayer

const MAIN_GAME_TOUR = preload("uid://dwv0liiqydc5d")

func _ready() -> void:
	DragManager.worm_dropped.connect(_on_worm_dropped)
	if SaveManager.has_save():
		SaveManager.load_game()
	else:
		SaveManager.new_game()
	_start_main_tour_if_needed()

func _start_main_tour_if_needed() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if not TutorialManager.is_tour_completed(MAIN_GAME_TOUR.tour_name):
		TutorialManager.start_tour(MAIN_GAME_TOUR)

func _process(delta: float) -> void:
	Shop.update(delta)

func _on_worm_dropped(worm_data: Worm_Data, source: String, target_area: String, drop_position: Vector2) -> void:
	if source == target_area:
		_restore_worm(worm_data, source, drop_position)
		return
	if target_area == "social":
		_spawn_worm_in_social(worm_data, drop_position)
		return
	var zone = DragManager.registered_zones.get(target_area)
	if zone:
		zone.on_worm_dropped(worm_data, source, drop_position)

func _restore_worm(worm_data: Worm_Data, area: String, drop_position: Vector2) -> void:
	if area == "social":
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
	elif area == "combat":
		var spawner = get_tree().get_first_node_in_group("combat_spawner")
		if spawner:
			var local_pos = drop_position - combat_box.global_position
			var scaled_pos = local_pos / combat_box.scale.x
			spawner.spawn_specific_worm(worm_data, scaled_pos)

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
