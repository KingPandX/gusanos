extends Control
class_name DropZone

@export var zone_name: String = ""

func _ready() -> void:
	if zone_name.is_empty():
		push_warning("DropZone: zone_name vacío en %s" % name)
		return
	DragManager.register_zone(zone_name, self)

func _exit_tree() -> void:
	DragManager.unregister_zone(zone_name)

func is_point_inside(point: Vector2) -> bool:
	return get_global_rect().has_point(point)

func on_worm_dropped(worm_data: Worm_Data, source: String, drop_position: Vector2) -> void:
	pass
