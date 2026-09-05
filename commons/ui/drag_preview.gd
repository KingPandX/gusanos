extends Control

var worm_data: Worm_Data = null
var sprite: AnimatedSprite2D = null
var offset: Vector2 = Vector2.ZERO
var was_mouse_pressed: bool = false
var stretch_timer: float = 0.0

const STRETCH_X: float = 0.85
const STRETCH_Y: float = 1.2
const STRETCH_SPEED: float = 6.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 100

func setup(data: Worm_Data) -> void:
	worm_data = data
	scale = Vector2.ONE * worm_data.size
	offset = Vector2(0, 10)
	_create_sprite()

func _create_sprite() -> void:
	sprite = AnimatedSprite2D.new()
	if worm_data.template and worm_data.template.sprite_frames:
		sprite.sprite_frames = worm_data.template.sprite_frames
		sprite.position = Vector2(0, -worm_data.template.sprite_offset.y)
	sprite.modulate = Rarity.get_rarity_color(worm_data.rarity)
	sprite.modulate.a = 0.7
	add_child(sprite)

func _process(delta: float) -> void:
	if DragManager.is_dragging:
		global_position = get_global_mouse_position() + offset
		show()
		stretch_timer += delta * STRETCH_SPEED
		var t = (sin(stretch_timer) + 1.0) * 0.5
		sprite.scale = Vector2(
			lerp(1.0, STRETCH_X, t),
			lerp(1.0, STRETCH_Y, t)
		)
		var mouse_pressed = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		if was_mouse_pressed and not mouse_pressed:
			_on_drop()
		was_mouse_pressed = mouse_pressed
	else:
		hide()
		was_mouse_pressed = false
		stretch_timer = 0.0
		if sprite:
			sprite.scale = Vector2.ONE

func _on_drop() -> void:
	var mouse_pos = get_global_mouse_position()
	var game_scene = get_tree().current_scene
	if not game_scene:
		DragManager.end_drag()
		return

	var combat_box = game_scene.get_node_or_null("CombatBox")
	if combat_box and combat_box.is_point_inside(mouse_pos):
		DragManager.drop_in_target(DragManager.DropTarget.COMBAT, mouse_pos)
	else:
		DragManager.drop_in_target(DragManager.DropTarget.SOCIAL, mouse_pos)
	queue_free()

func _exit_tree() -> void:
	if DragManager.get_preview() == self:
		DragManager.set_preview(null)
