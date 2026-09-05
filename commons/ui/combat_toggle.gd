extends PanelContainer

signal toggle_changed(is_expanded: bool)

@export var mini_scale: float = 0.28
@export var expanded_scale: float = 1.0
@export var animation_speed: float = 8.0

var is_expanded: bool = false
var target_position: Vector2
var target_scale: float
var mini_position: Vector2
var combat_sub_viewport: SubViewport = null

const EXPANDED_SIZE = Vector2(720, 627)

func _ready() -> void:
	scale = Vector2.ONE * mini_scale
	_setup_positions()
	target_position = mini_position
	target_scale = mini_scale
	position = mini_position
	gui_input.connect(_on_gui_input)
	combat_sub_viewport = _find_sub_viewport()
	get_viewport().size_changed.connect(_setup_positions)

func _find_sub_viewport() -> SubViewport:
	var container = get_node_or_null("SubViewportContainer")
	if container:
		return container.get_node_or_null("SubViewport")
	return null

func _setup_positions() -> void:
	var viewport_size = get_viewport_rect().size
	var scaled_mini = EXPANDED_SIZE * mini_scale
	mini_position = Vector2(
		viewport_size.x - scaled_mini.x - 10,
		viewport_size.y - scaled_mini.y - 10
	)
	var expanded_position = (viewport_size - EXPANDED_SIZE) / 2
	target_position = expanded_position if is_expanded else mini_position

func _process(delta: float) -> void:
	position = position.lerp(target_position, delta * animation_speed)
	var current_scale = lerp(scale.x, target_scale, delta * animation_speed)
	scale = Vector2.ONE * current_scale

func _unhandled_input(event: InputEvent) -> void:
	if is_expanded and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_global_mouse_position()
		if not get_combat_rect().has_point(mouse_pos):
			collapse()

func _on_gui_input(event: InputEvent) -> void:
	if DragManager.is_dragging:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			DragManager.drop_in_target(DragManager.DropTarget.COMBAT, get_global_mouse_position())
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_expanded:
			_try_extract_worm()
		else:
			toggle()

func _try_extract_worm() -> void:
	if not combat_sub_viewport:
		return
	var local_mouse = get_local_mouse_position()
	var viewport_mouse = local_mouse / EXPANDED_SIZE * Vector2(combat_sub_viewport.size)
	var all_worms = get_tree().get_nodes_in_group("worms")
	var closest_worm: Worm = null
	var closest_dist: float = 60.0
	for node in all_worms:
		if node is Worm and is_instance_valid(node) and node.area == "combat":
			var dist = node.global_position.distance_to(viewport_mouse)
			if dist < closest_dist:
				closest_dist = dist
				closest_worm = node
	if closest_worm:
		_start_combat_extract(closest_worm)

func _start_combat_extract(worm: Worm) -> void:
	DragManager.start_drag(worm.worm_data, DragManager.DragSource.COMBAT)
	var preview_scene = preload("res://commons/ui/drag_preview.gd")
	var preview = Control.new()
	preview.set_script(preview_scene)
	preview.setup(worm.worm_data)
	get_tree().current_scene.add_child(preview)
	DragManager.set_preview(preview)
	var spawner = get_tree().get_first_node_in_group("combat_spawner")
	if spawner:
		spawner.remove_worm_from_combat(worm)
	Inventory.move_worm(worm.worm_data, "social")

func toggle() -> void:
	is_expanded = not is_expanded
	_update_target()
	toggle_changed.emit(is_expanded)

func expand() -> void:
	if not is_expanded:
		toggle()

func collapse() -> void:
	if is_expanded:
		toggle()

func _update_target() -> void:
	var viewport_size = get_viewport_rect().size
	if is_expanded:
		target_position = (viewport_size - EXPANDED_SIZE) / 2
		target_scale = expanded_scale
	else:
		var scaled_mini = EXPANDED_SIZE * mini_scale
		mini_position = Vector2(
			viewport_size.x - scaled_mini.x - 10,
			viewport_size.y - scaled_mini.y - 10
		)
		target_position = mini_position
		target_scale = mini_scale

func get_combat_rect() -> Rect2:
	var scaled_size = EXPANDED_SIZE * scale.x
	return Rect2(global_position, scaled_size)

func is_point_inside(point: Vector2) -> bool:
	return get_combat_rect().has_point(point)
