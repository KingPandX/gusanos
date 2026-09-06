extends Control

signal pause_menu_closed

@onready var bg: ColorRect = $BG
@onready var panel: PanelContainer = $Panel
@onready var save_btn: Button = $Panel/VBox/SaveBtn
@onready var load_btn: Button = $Panel/VBox/LoadBtn
@onready var delete_btn: Button = $Panel/VBox/DeleteBtn
@onready var resume_btn: Button = $Panel/VBox/ResumeBtn

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	bg.gui_input.connect(_on_bg_input)
	save_btn.pressed.connect(_on_save_pressed)
	load_btn.pressed.connect(_on_load_pressed)
	delete_btn.pressed.connect(_on_delete_pressed)
	resume_btn.pressed.connect(_on_resume_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if get_tree().paused:
			_on_resume_pressed()
		else:
			open()

func open() -> void:
	_close_other_popups()
	get_tree().paused = true
	visible = true
	get_parent().move_child(self, get_parent().get_child_count() - 1)

func _close_other_popups() -> void:
	var tree = get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group("bottom_bar"):
		if node.has_method("_on_shop_menu_closed") and node.shop_menu_instance and is_instance_valid(node.shop_menu_instance):
			node.shop_menu_instance.queue_free()
			node.shop_menu_instance = null
		if node.has_method("_on_slot_machine_closed") and node.slot_machine_instance and is_instance_valid(node.slot_machine_instance):
			node.slot_machine_instance.queue_free()
			node.slot_machine_instance = null
		if node.has_method("_on_worm_details_closed") and node.worm_details_instance and is_instance_valid(node.worm_details_instance):
			node.worm_details_instance.queue_free()
			node.worm_details_instance = null
		if node.has_method("_on_selector_closed") and node.worm_selector_instance and is_instance_valid(node.worm_selector_instance):
			node.worm_selector_instance.queue_free()
			node.worm_selector_instance = null

func _on_bg_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_on_resume_pressed()

func _on_save_pressed() -> void:
	SaveManager.save_game()
	save_btn.text = "Guardado!"
	await get_tree().create_timer(1.0).timeout
	save_btn.text = "Guardar Partida"

func _on_load_pressed() -> void:
	SaveManager.load_game()
	_on_resume_pressed()

func _on_delete_pressed() -> void:
	SaveManager.delete_save()
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_resume_pressed() -> void:
	get_tree().paused = false
	visible = false
	pause_menu_closed.emit()
