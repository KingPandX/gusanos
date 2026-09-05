extends Node

signal drag_started(worm_data: Worm_Data, source: String)
signal drag_ended()
signal worm_dropped(worm_data: Worm_Data, source: String, target_area: String, position: Vector2)

var registered_zones: Dictionary = {}

var is_dragging: bool = false
var dragged_worm_data: Worm_Data = null
var drag_source: String = "social"
var drag_preview: Control = null

func register_zone(zone_name: String, zone: Control) -> void:
	registered_zones[zone_name] = zone

func unregister_zone(zone_name: String) -> void:
	registered_zones.erase(zone_name)

func get_zone_at_point(point: Vector2) -> String:
	for zone_name in registered_zones:
		var zone = registered_zones[zone_name]
		if is_instance_valid(zone) and zone.is_point_inside(point):
			return zone_name
	return "social"

func start_drag(worm_data: Worm_Data, source: String) -> void:
	if is_dragging:
		return
	is_dragging = true
	dragged_worm_data = worm_data
	drag_source = source
	drag_started.emit(worm_data, source)

func end_drag() -> void:
	if not is_dragging:
		return
	is_dragging = false
	dragged_worm_data = null
	drag_source = "social"
	drag_ended.emit()

func set_preview(preview: Control) -> void:
	drag_preview = preview

func get_preview() -> Control:
	return drag_preview

func drop_in_target(target: String, position: Vector2) -> void:
	if not is_dragging:
		return
	worm_dropped.emit(dragged_worm_data, drag_source, target, position)
	end_drag()

func get_drag_source() -> String:
	return drag_source
