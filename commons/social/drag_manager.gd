extends Node

signal drag_started(worm_data: Worm_Data, source: int)
signal drag_ended()
signal worm_dropped(worm_data: Worm_Data, source: int, target_area: int, position: Vector2)

enum DragSource { SOCIAL, COMBAT }
enum DropTarget { SOCIAL, COMBAT }



var is_dragging: bool = false
var dragged_worm_data: Worm_Data = null
var drag_source: DragSource = DragSource.SOCIAL
var drag_preview: Control = null

func start_drag(worm_data: Worm_Data, source: DragSource) -> void:
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
	drag_source = DragSource.SOCIAL
	drag_ended.emit()
	

func set_preview(preview: Control) -> void:
	drag_preview = preview

func get_preview() -> Control:
	return drag_preview

func drop_in_target(target: DropTarget, position: Vector2) -> void:
	if not is_dragging:
		return
	worm_dropped.emit(dragged_worm_data, drag_source, target, position)
	end_drag()

func get_drag_source() -> DragSource:
	return drag_source
