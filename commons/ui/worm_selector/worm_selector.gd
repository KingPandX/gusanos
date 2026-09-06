extends Control
class_name WormSelector

signal worm_selected(worm_data: Worm_Data)
signal selector_closed

@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var worm_list: VBoxContainer = $Panel/VBoxContainer/ScrollContainer/WormList
@onready var close_button: Button = $Panel/VBoxContainer/CloseButton

var available_worms: Array[Worm_Data] = []

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
	for worm_data in Inventory.worms:
		if worm_data:
			available_worms.append(worm_data)

	if available_worms.is_empty():
		var label = Label.new()
		label.text = "No hay gusanos disponibles"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		worm_list.add_child(label)
		return

	for worm_data in available_worms:
		var btn = _create_worm_button(worm_data)
		worm_list.add_child(btn)

func _create_worm_button(worm_data: Worm_Data) -> Button:
	var btn = Button.new()
	var rarity_name = Rarity.get_rarity_name(worm_data.rarity)
	var worm_name = worm_data.template.worm_name if worm_data.template else "Gusano"
	btn.text = "%s [%s] - HP: %.0f / Daño: %.0f" % [worm_name, rarity_name, worm_data.get_computed_hp_max(), worm_data.get_computed_damage()]
	btn.custom_minimum_size = Vector2(280, 40)

	var rarity_color = Rarity.get_rarity_color(worm_data.rarity)
	btn.add_theme_color_override("font_color", rarity_color)

	btn.pressed.connect(_on_worm_button_pressed.bind(worm_data))
	return btn

func _on_worm_button_pressed(worm_data: Worm_Data) -> void:
	worm_selected.emit(worm_data)
	hide()

func _on_close_pressed() -> void:
	selector_closed.emit()
	hide()

func open() -> void:
	show()
