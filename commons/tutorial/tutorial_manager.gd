extends Node

signal tour_completed(tour_name: String)
signal step_completed(signal_str: String)

var current_tour = null
var current_step_index: int = 0
var overlay_instance: CanvasLayer = null

const OVERLAY_SCENE = preload("res://commons/tutorial/ui_tour_overlay.tscn")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func is_tour_completed(tour_name: String) -> bool:
	var completed = SaveManager.get_trigger("tours_completed", {})
	return completed.get(tour_name, false)

func start_tour(tour_data) -> void:
	if tour_data == null or tour_data.steps.is_empty():
		return
	if is_tour_completed(tour_data.tour_name):
		return
	if current_tour != null:
		return

	current_tour = tour_data
	current_step_index = 0
	_ensure_overlay()
	overlay_instance.show_step(current_tour.steps[current_step_index])
	overlay_instance.step_completed.connect(_on_step_completed)

func skip_tour() -> void:
	if current_tour == null:
		return
	_complete_tour()

func advance_step() -> void:
	current_step_index += 1
	if current_step_index >= current_tour.steps.size():
		_complete_tour()
	else:
		_show_current_step()

func _show_current_step() -> void:
	if overlay_instance == null:
		return
	overlay_instance.show_step(current_tour.steps[current_step_index])

func _on_step_completed(signal_str: String) -> void:
	step_completed.emit(signal_str)
	advance_step()

func _complete_tour() -> void:
	var completed = SaveManager.get_trigger("tours_completed", {})
	completed[current_tour.tour_name] = true
	SaveManager.set_trigger("tours_completed", completed)

	var tour_name = current_tour.tour_name

	if overlay_instance:
		overlay_instance.step_completed.disconnect(_on_step_completed)
		overlay_instance.hide_overlay()

	current_tour = null
	current_step_index = 0

	tour_completed.emit(tour_name)

func _ensure_overlay() -> void:
	if overlay_instance != null and is_instance_valid(overlay_instance):
		return
	overlay_instance = OVERLAY_SCENE.instantiate()
	get_tree().root.add_child(overlay_instance)
