extends Control
class_name WormSelector

signal worm_selected(worm: Worm)
signal selector_closed

@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var worm_list: VBoxContainer = $Panel/VBoxContainer/ScrollContainer/WormList
@onready var close_button: Button = $Panel/VBoxContainer/CloseButton

var available_worms: Array[Worm] = []
var selected_worm: Worm = null

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed() -> void:
	if visible:
		_refresh_worm_list()

func _refresh_worm_list() -> void:
	for child in worm_list.get_children():
		child.queue_free()
	
	available_worms.clear()
	var worms = get_tree().get_nodes_in_group("worms")
	for worm in worms:
		if worm is Worm and is_instance_valid(worm):
			available_worms.append(worm)
	
	if available_worms.is_empty():
		var label = Label.new()
		label.text = "No hay worms disponibles"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		worm_list.add_child(label)
		return
	
	for worm in available_worms:
		var btn = _create_worm_button(worm)
		worm_list.add_child(btn)

func _create_worm_button(worm: Worm) -> Button:
	var btn = Button.new()
	var rarity_name = Rarity.get_rarity_name(worm.worm_data.rarity)
	var worm_name = worm.worm_data.template.worm_name if worm.worm_data.template else "Gusano"
	btn.text = "%s [%s] - HP: %.0f" % [worm_name, rarity_name, worm.hp]
	btn.custom_minimum_size = Vector2(280, 40)
	
	var rarity_color = Rarity.get_rarity_color(worm.worm_data.rarity)
	btn.add_theme_color_override("font_color", rarity_color)
	
	btn.pressed.connect(_on_worm_button_pressed.bind(worm))
	return btn

func _on_worm_button_pressed(worm: Worm) -> void:
	selected_worm = worm
	worm_selected.emit(worm)
	hide()

func _on_close_pressed() -> void:
	selected_worm = null
	selector_closed.emit()
	hide()

func open() -> void:
	show()

func get_selected_worm() -> Worm:
	return selected_worm
