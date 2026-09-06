extends CanvasLayer

signal step_completed(signal_str: String)

@onready var frame_top: ColorRect = $Top
@onready var frame_bottom: ColorRect = $Bottom
@onready var frame_left: ColorRect = $Left
@onready var frame_right: ColorRect = $Right

var current_step = null
var current_target: Node = null
var current_targets: Array = []
var is_waiting_for_action: bool = false
var action_connections: Array = []
var action_trigger_count: int = 0
var action_target_count: int = 1
var _action_click_target: Node = null
var _waiting_tween: Tween = null

var DARK_COLOR := Color(0, 0, 0, 0.65)

const MAX_HOLES := 32

# Popup is in a separate CanvasLayer so it gets input priority
var popup_layer: CanvasLayer = null
var popup_instance: PanelContainer = null
var message_label: Label = null
var waiting_label: Label = null
var button1: Button = null
var button2: Button = null
var button_row: HBoxContainer = null

# Full-screen dark mask with shader that cuts multiple transparent holes
var _mask: ColorRect = null
var _mask_material: ShaderMaterial = null
var _mask_shader: Shader = null

const POPUP_SCENE = preload("res://commons/tutorial/text_popup.tscn")
const MASK_SHADER = preload("res://commons/tutorial/highlight_mask.gdshader")

func _ready() -> void:
	_hide_all()
	_create_popup_layer()
	_mask_shader = MASK_SHADER
	_mask_material = ShaderMaterial.new()
	_mask_material.shader = _mask_shader
	_mask = ColorRect.new()
	_mask.material = _mask_material
	_mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_mask)

	var transparent = Color(0, 0, 0, 0)
	frame_top.color = transparent
	frame_bottom.color = transparent
	frame_left.color = transparent
	frame_right.color = transparent

func _create_popup_layer() -> void:
	popup_layer = CanvasLayer.new()
	popup_layer.layer = 101
	add_child(popup_layer)

	popup_instance = POPUP_SCENE.instantiate()
	popup_layer.add_child(popup_instance)

	message_label = popup_instance.get_node("VBox/MessageLabel")
	waiting_label = popup_instance.get_node("VBox/WaitingLabel")
	button_row = popup_instance.get_node("VBox/ButtonRow")
	button1 = button_row.get_node("Button1")
	button2 = button_row.get_node("Button2")

	button1.pressed.connect(_on_button1_pressed)
	button2.pressed.connect(_on_button2_pressed)
	popup_instance.visible = false

func _set_frame_input_blocked(blocked: bool) -> void:
	var filter = Control.MOUSE_FILTER_STOP if blocked else Control.MOUSE_FILTER_IGNORE
	frame_top.mouse_filter = filter
	frame_bottom.mouse_filter = filter
	frame_left.mouse_filter = filter
	frame_right.mouse_filter = filter

func _hide_all() -> void:
	if frame_top:
		frame_top.visible = false
	if frame_bottom:
		frame_bottom.visible = false
	if frame_left:
		frame_left.visible = false
	if frame_right:
		frame_right.visible = false
	if popup_instance:
		popup_instance.visible = false
	if _mask and is_instance_valid(_mask):
		_mask.visible = false

func _cleanup_invalid_targets() -> bool:
	var cleaned := false
	var new_targets: Array = []
	for t in current_targets:
		if is_instance_valid(t) and t.is_inside_tree():
			new_targets.append(t)
		else:
			cleaned = true
	current_targets = new_targets
	return cleaned

func _is_trackable_target(node) -> bool:
	if not is_instance_valid(node) or not node.is_inside_tree():
		return false
	# Los gusanos de combate viven en el subviewport y tienen coordenadas
	# propias, no deben destacarse junto a los del área social.
	if node is Worm and node.area == "combat":
		return false
	return true

func _process(_delta: float) -> void:
	if current_step == null:
		return
	var highlight_needs_update := false
	_cleanup_invalid_targets()
	if not current_step.dynamic_target_group.is_empty():
		var nodes = get_tree().get_nodes_in_group(current_step.dynamic_target_group)
		var valid_nodes = nodes.filter(func(n): return _is_trackable_target(n))
		for n in valid_nodes:
			if not current_targets.has(n):
				current_targets.append(n)
				highlight_needs_update = true
		var new_targets: Array = []
		for t in current_targets:
			if not _is_trackable_target(t):
				highlight_needs_update = true
				continue
			if t.is_in_group(current_step.dynamic_target_group) and not valid_nodes.has(t):
				highlight_needs_update = true
				continue
			new_targets.append(t)
		if new_targets.size() != current_targets.size():
			current_targets = new_targets
		# Los targets dinámicos (gusanos) pueden moverse: actualiza el
		# highlight cada frame para que siga su posición
		if not current_targets.is_empty():
			highlight_needs_update = true
	elif current_step.follow_target and not current_targets.is_empty():
		highlight_needs_update = true
	if highlight_needs_update:
		if not current_targets.is_empty():
			current_target = current_targets[0]
		_update_highlight()
		_position_popup(current_step)

func _input(event: InputEvent) -> void:
	if not is_waiting_for_action:
		return
	if _action_click_target == null or not is_instance_valid(_action_click_target):
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
		
	var mouse_pos = get_viewport().get_mouse_position()
	print("[DEBUG TOUR] Clic detectado en pantalla: ", mouse_pos)
	
	if _action_click_target is Control:
		var rect = _action_click_target.get_global_rect()
		print("[DEBUG TOUR] Rect del Target (Control): ", rect)
		if rect.has_point(mouse_pos):
			print("[DEBUG TOUR] ¡CLIC DENTRO DEL DELIMITADOR (Control)!")
			_on_action_triggered()
		else:
			print("[DEBUG TOUR] Clic fuera del área objetivo")
	elif _action_click_target is Node2D:
		var center = _get_node2d_center(_action_click_target)
		var size = _get_node2d_size(_action_click_target)
		var rect = Rect2(center - size / 2.0, size)
		print("[DEBUG TOUR] Rect del Target (Node2D): ", rect)
		if rect.has_point(mouse_pos):
			print("[DEBUG TOUR] ¡CLIC DENTRO DEL DELIMITADOR (Node2D)!")
			_on_action_triggered()
		else:
			print("[DEBUG TOUR] Clic fuera del área objetivo")

func show_step(step) -> void:
	current_step = step
	popup_instance.visible = true
	message_label.text = step.message
	_resolve_target(step)

	frame_top.visible = true
	frame_bottom.visible = true
	frame_left.visible = true
	frame_right.visible = true

	var is_action = step.step_type == TourStep.StepType.ACTION
	_set_frame_input_blocked(is_action)

	if step.step_type == TourStep.StepType.TEXT:
		is_waiting_for_action = false
		waiting_label.visible = false
		_setup_buttons(step)
		_update_highlight()
		_position_popup(step)
	elif step.step_type == TourStep.StepType.ACTION:
		is_waiting_for_action = true
		action_trigger_count = 0
		action_target_count = step.action_count
		button_row.visible = false
		waiting_label.visible = true
		waiting_label.text = step.action_message_waiting
		_start_waiting_animation()
		_connect_action_signals(step)
		_update_highlight()
		_position_popup(step)

func hide_overlay() -> void:
	_hide_all()
	current_step = null
	current_target = null
	current_targets.clear()
	is_waiting_for_action = false
	_disconnect_all_signals()
	_stop_waiting_animation()
	if _mask and is_instance_valid(_mask):
		_mask.visible = false
	_mask_material.set_shader_parameter("hole_count", 0)

func _resolve_target(step) -> void:
	current_targets.clear()
	current_target = null
	var root = get_tree().current_scene
	if root == null:
		return
	if not step.target_node_paths.is_empty():
		for path in step.target_node_paths:
			var node = root.get_node_or_null(path)
			if node and is_instance_valid(node):
				current_targets.append(node)
	elif not step.target_node_path.is_empty():
		var node = root.get_node_or_null(step.target_node_path)
		if node and is_instance_valid(node):
			current_targets.append(node)
	if not step.dynamic_target_group.is_empty():
		var nodes = get_tree().get_nodes_in_group(step.dynamic_target_group)
		var valid_nodes = nodes.filter(func(n): return _is_trackable_target(n))
		for n in valid_nodes:
			if not current_targets.has(n):
				current_targets.append(n)
	if not current_targets.is_empty():
		current_target = current_targets[0]

func _update_highlight() -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	_mask.position = Vector2.ZERO
	_mask.size = viewport_size

	var rects = _get_current_highlight_rects()
	if rects.is_empty():
		_mask_material.set_shader_parameter("hole_count", 0)
		_mask.visible = false
		return

	_mask.visible = true
	var holes: Array = []
	for rect in rects:
		_hole_to_uv(rect, viewport_size, holes)
		if holes.size() >= MAX_HOLES:
			break

	while holes.size() < MAX_HOLES:
		holes.append(Vector4.ZERO)
	_mask_material.set_shader_parameter("holes", PackedVector4Array(holes))
	_mask_material.set_shader_parameter("hole_count", holes.size())

func _hole_to_uv(rect: Rect2, viewport_size: Vector2, holes: Array) -> void:
	holes.append(Vector4(
		rect.position.x / viewport_size.x,
		rect.position.y / viewport_size.y,
		rect.size.x / viewport_size.x,
		rect.size.y / viewport_size.y
	))

func _get_node2d_center(node: Node2D) -> Vector2:
	if node is Worm:
		return node.global_position + Vector2(0, -32)
	return node.global_position

func _get_node2d_size(node: Node2D) -> Vector2:
	if node is Worm:
		var collision = node.get_node_or_null("CollisionShape2D")
		if collision and collision.shape is CircleShape2D:
			var radius = collision.shape.radius * node.scale.x
			return Vector2(radius * 2.0, radius * 2.0)
		return Vector2(64, 64) * node.scale.x
	return Vector2(32, 32)

func _get_current_highlight_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	if current_step == null:
		return rects
	for target in current_targets:
		if not _is_trackable_target(target):
			continue
		var center: Vector2
		var size: Vector2
		var is_dragging_preview := false
		if DragManager.is_dragging and target is Worm and DragManager.dragged_worm_data == target.worm_data:
			if DragManager.drag_preview != null and is_instance_valid(DragManager.drag_preview):
				center = DragManager.drag_preview.global_position
				size = _get_drag_preview_size()
				is_dragging_preview = true
		if target is Control:
			var rect = target.get_global_rect()
			if is_dragging_preview:
				rect = Rect2(center - size / 2.0, size)
			rect = Rect2(rect.position - current_step.highlight_padding, rect.size + current_step.highlight_padding * 2.0)
			rects.append(rect)
		elif target is Node2D:
			var t_center = center if is_dragging_preview else _get_node2d_center(target)
			var t_size = size if is_dragging_preview else _get_node2d_size(target)
			var rect = Rect2(t_center - t_size / 2.0 - current_step.highlight_padding, t_size + current_step.highlight_padding * 2.0)
			rects.append(rect)
	return rects

func _rects_array_overlap(a: Rect2, rects: Array[Rect2]) -> bool:
	for r in rects:
		if a.intersects(r):
			return true
	return false

func _get_drag_preview_size() -> Vector2:
	if DragManager.drag_preview == null or not is_instance_valid(DragManager.drag_preview):
		return Vector2(64, 64)
	var sprite = DragManager.drag_preview.get_node_or_null("Sprite")
	if sprite and sprite is AnimatedSprite2D:
		var frame_tex = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
		if frame_tex:
			return frame_tex.get_size() * DragManager.drag_preview.scale
	return Vector2(64, 64) * DragManager.drag_preview.scale

func _position_popup(step) -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	var popup_size = popup_instance.size

	var rects: Array[Rect2] = _get_current_highlight_rects()
	if rects.is_empty():
		var center = viewport_size / 2.0
		popup_instance.position = center - popup_size / 2.0
		return

	var target_rect = rects[0]
	for rect in rects.slice(1):
		target_rect = target_rect.merge(rect)

	var margin := 8.0
	var candidates: Array[Rect2] = []

	match step.popup_position:
		TourStep.PopupPosition.BELOW:
			candidates.append(Rect2(target_rect.position + Vector2(0, target_rect.size.y + 20), popup_size))
		TourStep.PopupPosition.ABOVE:
			candidates.append(Rect2(target_rect.position + Vector2(0, -20 - popup_size.y), popup_size))
		TourStep.PopupPosition.LEFT:
			candidates.append(Rect2(target_rect.position + Vector2(-20 - popup_size.x, 0), popup_size))
		TourStep.PopupPosition.RIGHT:
			candidates.append(Rect2(target_rect.position + Vector2(target_rect.size.x + 20, 0), popup_size))
		TourStep.PopupPosition.CENTER:
			candidates.append(Rect2(viewport_size / 2.0 - popup_size / 2.0, popup_size))

	if candidates.is_empty() or candidates[0] == Rect2(viewport_size / 2.0 - popup_size / 2.0, popup_size):
		if step.popup_position != TourStep.PopupPosition.CENTER:
			candidates.append(Rect2(viewport_size / 2.0 - popup_size / 2.0, popup_size))

	# Posiciones alternativas en caso de que la preferida se salga o se superponga
	var fallbacks: Array[Rect2] = [
		Rect2(target_rect.position + Vector2(0, target_rect.size.y + 20), popup_size),
		Rect2(target_rect.position + Vector2(0, -20 - popup_size.y), popup_size),
		Rect2(target_rect.position + Vector2(-20 - popup_size.x, 0), popup_size),
		Rect2(target_rect.position + Vector2(target_rect.size.x + 20, 0), popup_size),
		Rect2(viewport_size / 2.0 - popup_size / 2.0, popup_size)
	]
	for fb in fallbacks:
		if not candidates.has(fb):
			candidates.append(fb)

	if not step.avoid_overlap:
		var preferred = candidates[0]
		preferred.position.x = clampf(preferred.position.x, margin, viewport_size.x - preferred.size.x - margin)
		preferred.position.y = clampf(preferred.position.y, margin, viewport_size.y - preferred.size.y - margin)
		popup_instance.position = preferred.position
		return

	for cand in candidates:
		var clamped = cand
		clamped.position.x = clampf(clamped.position.x, margin, viewport_size.x - clamped.size.x - margin)
		clamped.position.y = clampf(clamped.position.y, margin, viewport_size.y - clamped.size.y - margin)
		if not _rects_array_overlap(clamped, rects):
			popup_instance.position = clamped.position
			return

	popup_instance.position = candidates[0].position

func _setup_buttons(step) -> void:
	button_row.visible = true
	if step.button_1_text.is_empty():
		button1.visible = false
	else:
		button1.visible = true
		button1.text = step.button_1_text
	if step.button_2_text.is_empty():
		button2.visible = false
	else:
		button2.visible = true
		button2.text = step.button_2_text

func _on_button1_pressed() -> void:
	_perform_action(current_step.button_1_action)

func _on_button2_pressed() -> void:
	_perform_action(current_step.button_2_action)

func _perform_action(action) -> void:
	match action:
		TourStep.ButtonAction.NONE:
			pass
		TourStep.ButtonAction.ADVANCE:
			var completed_id: String = current_step.signal_string if current_step else ""
			step_completed.emit(completed_id)
		TourStep.ButtonAction.SKIP:
			if TutorialManager:
				TutorialManager.skip_tour()

func _connect_action_signals(step) -> void:
	_disconnect_all_signals()
	var tree = get_tree()
	if tree == null:
		print("[DEBUG TOUR] Error: SceneTree es NULL")
		return
		
	print("[DEBUG TOUR] === CONFIGURANDO ACCIÓN TIPO: ", step.action_type, " ===")
	
	match step.action_type:
		TourStep.ActionType.COLLECT_WORM_DROP:
			var social_area = tree.get_first_node_in_group("social_area")
			if social_area and social_area.has_signal("worm_added_to_social"):
				var callable = _on_worm_added
				social_area.worm_added_to_social.connect(callable)
				action_connections.append({"node": social_area, "signal_name": "worm_added_to_social", "callable": callable})
				print("[DEBUG TOUR] Conectado exitosamente a social_area")
			else:
				print("[DEBUG TOUR] ERROR: No se encontró social_area en el grupo o no tiene la señal 'worm_added_to_social'")

		TourStep.ActionType.DRAG_WORM_TO_COMBAT:
			var callable = _on_worm_dropped_to_combat
			DragManager.worm_dropped.connect(callable)
			action_connections.append({"node": DragManager, "signal_name": "worm_dropped", "callable": callable})
			print("[DEBUG TOUR] Conectado a DragManager.worm_dropped (Esperando 'combat')")

		TourStep.ActionType.DRAG_WORM_TO_SOCIAL:
			var callable = _on_worm_dropped_to_social
			DragManager.worm_dropped.connect(callable)
			action_connections.append({"node": DragManager, "signal_name": "worm_dropped", "callable": callable})
			print("[DEBUG TOUR] Conectado a DragManager.worm_dropped (Esperando 'social')")

		TourStep.ActionType.CLICK_NODE:
			var target = get_tree().current_scene.get_node_or_null(step.action_target_node)
			if target == null:
				target = get_node_or_null(step.action_target_node)
			
			if target:
				_action_click_target = target
				print("[DEBUG TOUR] Target para CLICK asignado: ", target.name, " (", target.get_class(), ")")
			else:
				print("[DEBUG TOUR] ERROR: No se encontró el nodo objetivo para CLICK en la ruta: ", step.action_target_node)

		TourStep.ActionType.CUSTOM_SIGNAL:
			var target = get_tree().current_scene.get_node_or_null(step.action_target_node)
			if target == null:
				target = get_node_or_null(step.action_target_node)
			
			if target and target.has_signal(step.action_signal_name):
				var callable = _on_custom_signal
				target.connect(step.action_signal_name, callable)
				action_connections.append({"node": target, "signal_name": step.action_signal_name, "callable": callable})
				print("[DEBUG TOUR] Conectado a señal '", step.action_signal_name, "' en el nodo ", target.name)
			else:
				print("[DEBUG TOUR] ERROR: El nodo no existe o no contiene la señal '", step.action_signal_name, "' en la ruta: ", step.action_target_node)

func _disconnect_all_signals() -> void:
	for conn in action_connections:
		if is_instance_valid(conn.node):
			if conn.node.is_connected(conn.signal_name, conn.callable):
				conn.node.disconnect(conn.signal_name, conn.callable)
	action_connections.clear()
	_action_click_target = null

func _on_worm_added(_worm) -> void:
	print("[DEBUG TOUR] Evento recibido: _on_worm_added")
	_on_action_triggered()

func _on_worm_dropped_to_combat(_worm_data, _source: String, target_area: String, _position: Vector2) -> void:
	print("[DEBUG TOUR] Drag disparado (COMBAT). Target area recibida: '", target_area, "'")
	if target_area == "combat":
		_on_action_triggered()

func _on_worm_dropped_to_social(_worm_data, _source: String, target_area: String, _position: Vector2) -> void:
	print("[DEBUG TOUR] Drag disparado (SOCIAL). Target area recibida: '", target_area, "'")
	if target_area == "social":
		_on_action_triggered()

func _on_custom_signal() -> void:
	print("[DEBUG TOUR] Evento recibido: _on_custom_signal")
	_on_action_triggered()

func _on_action_triggered() -> void:
	action_trigger_count += 1
	print("[DEBUG TOUR] Progreso de acción: ", action_trigger_count, "/", action_target_count)
	if action_trigger_count >= action_target_count:
		print("[DEBUG TOUR] ¡Acción requerida completada! Avanzando de paso...")
		_disconnect_all_signals()
		is_waiting_for_action = false
		waiting_label.visible = false
		button_row.visible = false
		_stop_waiting_animation()
		var completed_id: String = current_step.signal_string if current_step else ""
		step_completed.emit(completed_id)

func _start_waiting_animation() -> void:
	_stop_waiting_animation()
	_waiting_tween = create_tween().set_loops()
	_waiting_tween.tween_property(waiting_label, "text", "Esperando.", 0.4)
	_waiting_tween.tween_property(waiting_label, "text", "Esperando..", 0.4)
	_waiting_tween.tween_property(waiting_label, "text", "Esperando...", 0.4)

func _stop_waiting_animation() -> void:
	if _waiting_tween:
		_waiting_tween.kill()
		_waiting_tween = null
