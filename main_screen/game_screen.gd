extends Control

@onready var combat_box : PanelContainer = $CombatBox

var is_centered : bool = true
var center_pos : Vector2

const FULL_SIZE = Vector2(720, 627)
const SCALE_DOWN = 0.45
const CORNER_MARGIN = 10.0

func _ready() -> void:
	combat_box.pivot_offset = Vector2.ZERO
	_update_positions()
	get_viewport().size_changed.connect(_on_resize)
	$CombatBox/SubViewportContainer/SubViewport/Combat.toggle_position_requested.connect(_on_toggle_position)

func _on_resize() -> void:
	_update_positions()

func _update_positions() -> void:
	center_pos = (get_viewport_rect().size - FULL_SIZE) / 2
	if not is_centered:
		combat_box.position = _get_corner_pos()
	else:
		combat_box.position = center_pos

func _get_corner_pos() -> Vector2:
	var viewport_size = get_viewport_rect().size
	var scaled_size = FULL_SIZE * SCALE_DOWN
	return Vector2(
		viewport_size.x - scaled_size.x - CORNER_MARGIN,
		viewport_size.y - scaled_size.y - CORNER_MARGIN
	)

func _on_toggle_position() -> void:
	set_centered(!is_centered)

func set_centered(centered: bool) -> void:
	is_centered = centered
	var target_pos = center_pos if is_centered else _get_corner_pos()
	var target_scale = Vector2(1.0, 1.0) if is_centered else Vector2(SCALE_DOWN, SCALE_DOWN)

	var tween = create_tween().set_parallel(true)
	tween.tween_property(combat_box, "position", target_pos, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(combat_box, "scale", target_scale, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
