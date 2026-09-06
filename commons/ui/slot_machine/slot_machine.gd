extends Control

signal slot_machine_closed

enum DropType { NOTHING, MONEY, ITEM, WORM }

@export var worm_pool: Array[WormTemplate] = []

@onready var bg: ColorRect = $BG
@onready var panel: PanelContainer = $Panel
@onready var close_btn: Button = $Panel/VBox/Header/CloseBtn
@onready var gusano_info: VBoxContainer = $Panel/VBox/GusanoInfo
@onready var gusano_name_label: Label = $Panel/VBox/GusanoInfo/GusanoName
@onready var gusano_rarity_label: Label = $Panel/VBox/GusanoInfo/GusanoRarity
@onready var gusano_size_label: Label = $Panel/VBox/GusanoInfo/GusanoSize
@onready var tiradas_label: Label = $Panel/VBox/GusanoInfo/TiradasLabel
@onready var gusano_preview: TextureRect = $Panel/VBox/GusanoInfo/GusanoPreview
@onready var select_gusano_btn: Button = $Panel/VBox/GusanoInfo/SelectBtn
@onready var tirar_btn: Button = $Panel/VBox/TirarBtn
@onready var resultados_scroll: ScrollContainer = $Panel/VBox/ResultadosScroll
@onready var resultados_list: VBoxContainer = $Panel/VBox/ResultadosScroll/ResultadosList
@onready var money_label: Label = $Panel/VBox/Footer/MoneyLabel
@onready var pity_label: Label = $Panel/VBox/Footer/PityLabel

var selected_worm: Worm_Data = null
var is_spinning: bool = false
var available_items: Array[ItemData] = []
var worm_selector_instance: WormSelector = null

static var consecutive_nothing: int = 0

const DROP_WEIGHTS := {
	Rarity.Level.COMMON:     {DropType.NOTHING: 40, DropType.MONEY: 35, DropType.ITEM: 15, DropType.WORM: 10},
	Rarity.Level.RARE:       {DropType.NOTHING: 30, DropType.MONEY: 35, DropType.ITEM: 25, DropType.WORM: 10},
	Rarity.Level.EPIC:       {DropType.NOTHING: 20, DropType.MONEY: 35, DropType.ITEM: 30, DropType.WORM: 15},
	Rarity.Level.LEGENDARY:  {DropType.NOTHING: 10, DropType.MONEY: 30, DropType.ITEM: 30, DropType.WORM: 30},
}

const MONEY_RANGES := {
	Rarity.Level.COMMON:     Vector2i(5, 20),
	Rarity.Level.RARE:       Vector2i(15, 50),
	Rarity.Level.EPIC:       Vector2i(40, 100),
	Rarity.Level.LEGENDARY:  Vector2i(80, 200),
}

const LUCK_MULTI_CHANCE := {
	Rarity.Level.COMMON:     0.15,
	Rarity.Level.RARE:       0.20,
	Rarity.Level.EPIC:       0.25,
	Rarity.Level.LEGENDARY:  0.30,
}

const LUCK_TRIPLE_CHANCE := {
	Rarity.Level.COMMON:     0.05,
	Rarity.Level.RARE:       0.08,
	Rarity.Level.EPIC:       0.10,
	Rarity.Level.LEGENDARY:  0.15,
}

func _ready() -> void:
	bg.gui_input.connect(_on_bg_input)
	close_btn.pressed.connect(_on_close_pressed)
	select_gusano_btn.pressed.connect(_on_select_gusano)
	tirar_btn.pressed.connect(_on_tirar)
	GlobalManager.money_changed.connect(_on_money_changed)
	_load_available_items()
	_update_ui()

func _load_available_items() -> void:
	available_items.clear()
	var dirs = ["res://assets/items/"]
	for path in dirs:
		var dir = DirAccess.open(path)
		if dir == null:
			continue
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var resource = load(path + file_name)
				if resource is ItemData:
					available_items.append(resource)
			file_name = dir.get_next()

func open() -> void:
	visible = true
	_update_ui()

func close() -> void:
	visible = false
	if worm_selector_instance and is_instance_valid(worm_selector_instance):
		worm_selector_instance.hide()
	slot_machine_closed.emit()

func _on_bg_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		close()

func _on_close_pressed() -> void:
	close()

func _on_select_gusano() -> void:
	if worm_selector_instance == null or not is_instance_valid(worm_selector_instance):
		worm_selector_instance = load("res://commons/ui/worm_selector/worm_selector.tscn").instantiate()
		worm_selector_instance.worm_selected.connect(_on_worm_chosen)
		worm_selector_instance.selector_closed.connect(_on_selector_closed)
		add_child(worm_selector_instance)
	worm_selector_instance.open()

func _on_worm_chosen(worm_data: Worm_Data) -> void:
	selected_worm = worm_data
	_update_ui()

func _on_selector_closed() -> void:
	pass

func _on_money_changed(_v: int) -> void:
	_update_money_label()

func _update_ui() -> void:
	_update_gusano_info()
	_update_tirar_button()
	_update_money_label()
	_update_pity_label()

func _update_gusano_info() -> void:
	if selected_worm == null:
		gusano_name_label.text = "Ningún gusano seleccionado"
		gusano_rarity_label.text = ""
		gusano_size_label.text = ""
		tiradas_label.text = ""
		gusano_preview.texture = null
		return

	var rarity = selected_worm.rarity
	var worm_size = selected_worm.size
	var tiradas = maxi(1, int(floor(worm_size)))

	gusano_name_label.text = selected_worm.template.worm_name if selected_worm.template else "Desconocido"
	gusano_rarity_label.text = Rarity.get_rarity_name(rarity)
	gusano_rarity_label.add_theme_color_override("font_color", Rarity.get_rarity_color(rarity))
	gusano_size_label.text = "Tamaño: %.1f" % worm_size
	tiradas_label.text = "Tiradas: %d" % tiradas

	if selected_worm.template and selected_worm.template.sprite_frames:
		gusano_preview.texture = selected_worm.template.sprite_frames.get_frame_texture("default", 0)
	else:
		gusano_preview.texture = null

func _update_tirar_button() -> void:
	tirar_btn.disabled = selected_worm == null or is_spinning

func _update_money_label() -> void:
	money_label.text = "Dinero: %d¢" % GlobalManager.money

func _update_pity_label() -> void:
	pity_label.text = "Pity: %d/3" % consecutive_nothing

func _on_tirar() -> void:
	if selected_worm == null or is_spinning:
		return

	is_spinning = true
	_update_tirar_button()

	var worm_size = selected_worm.size
	var tiradas = maxi(1, int(floor(worm_size)))
	var rarity = selected_worm.rarity
	var worm_data_to_consume = selected_worm

	_destroy_worm_node(worm_data_to_consume)
	Inventory.remove_worm_data(worm_data_to_consume)
	selected_worm = null
	_update_gusano_info()

	_clear_resultados()

	for i in range(tiradas):
		await _do_single_roll(rarity, i + 1, tiradas)
		if tiradas > 1:
			await get_tree().create_timer(0.5).timeout

	is_spinning = false
	_update_tirar_button()

func _clear_resultados() -> void:
	for child in resultados_list.get_children():
		child.queue_free()

func _destroy_worm_node(worm_data: Worm_Data) -> void:
	var tree = get_tree() as SceneTree
	if tree == null:
		return
	for node in tree.get_nodes_in_group("worms"):
		if node is Worm and node.worm_data == worm_data:
			node.queue_free()
			break

func _spawn_worm_in_social(worm_data: Worm_Data) -> void:
	var social_area = get_tree().get_first_node_in_group("social_area")
	if social_area:
		social_area.spawn_social_worm(worm_data)

func _do_single_roll(worm_rarity: Rarity.Level, roll_num: int, total_rolls: int) -> void:
	var is_pity = consecutive_nothing >= 3
	var drop = _roll_single_drop(worm_rarity, is_pity)

	var card = _build_result_card(drop, roll_num)
	resultados_list.add_child(card)

	resultados_scroll.scroll_vertical = resultados_scroll.get_v_scroll_bar().max_value

func _roll_single_drop(worm_rarity: Rarity.Level, is_pity: bool) -> Dictionary:
	if is_pity:
		consecutive_nothing = 0
		return _force_legendary_drop()

	var weights = DROP_WEIGHTS[worm_rarity].duplicate()
	var total = 0
	for w in weights.values():
		total += w

	var roll = randi() % total
	var cumulative = 0
	for type in weights:
		cumulative += weights[type]
		if roll < cumulative:
			match type:
				DropType.NOTHING:
					consecutive_nothing += 1
					return {"type": "nothing"}
				DropType.MONEY:
					consecutive_nothing = 0
					return {"type": "money", "amount": _roll_money(worm_rarity)}
				DropType.ITEM:
					consecutive_nothing = 0
					return {"type": "item", "item": _roll_item()}
				DropType.WORM:
					consecutive_nothing = 0
					return {"type": "worm", "worm": _roll_worm(worm_rarity)}

	consecutive_nothing += 1
	return {"type": "nothing"}

func _force_legendary_drop() -> Dictionary:
	var sub_roll = randi() % 100
	if sub_roll < 40:
		return {"type": "money", "amount": _roll_money(Rarity.Level.LEGENDARY)}
	elif sub_roll < 70:
		return {"type": "item", "item": _roll_item()}
	else:
		return {"type": "worm", "worm": _roll_worm(Rarity.Level.LEGENDARY)}

func _roll_money(rarity: Rarity.Level) -> int:
	var range_vec = MONEY_RANGES[rarity]
	var base = randi_range(range_vec.x, range_vec.y)

	var mult = 1
	if randf() < LUCK_MULTI_CHANCE[rarity]:
		mult = 2
		if randf() < LUCK_TRIPLE_CHANCE[rarity]:
			mult = 3

	return base * mult

func _roll_item() -> ItemData:
	if available_items.is_empty():
		return null
	return available_items[randi() % available_items.size()]

func _roll_worm(rarity: Rarity.Level) -> Worm_Data:
	if worm_pool.is_empty():
		return WormFactory.generate_random_worm(Inventory.templates)
	return WormFactory.generate_worm(rarity, worm_pool)

func _build_result_card(drop: Dictionary, roll_num: int) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 50)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.14, 0.18, 0.9)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(6)
	card.add_theme_stylebox_override("panel", style)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	card.add_child(hbox)

	var roll_label = Label.new()
	roll_label.text = "#%d" % roll_num
	roll_label.add_theme_font_size_override("font_size", 12)
	roll_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	hbox.add_child(roll_label)

	match drop.type:
		"nothing":
			var icon = Label.new()
			icon.text = "X"
			icon.add_theme_font_size_override("font_size", 16)
			icon.add_theme_color_override("font_color", Color(0.6, 0.3, 0.3))
			hbox.add_child(icon)

			var desc = Label.new()
			desc.text = "Nada..."
			desc.add_theme_font_size_override("font_size", 13)
			desc.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			hbox.add_child(desc)

		"money":
			var icon = Label.new()
			icon.text = "$"
			icon.add_theme_font_size_override("font_size", 16)
			icon.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
			hbox.add_child(icon)

			var desc = Label.new()
			desc.text = "+%d¢" % drop.amount
			desc.add_theme_font_size_override("font_size", 13)
			desc.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
			hbox.add_child(desc)

			GlobalManager.add_money(drop.amount)

		"item":
			var icon_rect = TextureRect.new()
			icon_rect.custom_minimum_size = Vector2(32, 32)
			icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			if drop.item and drop.item.icon:
				icon_rect.texture = drop.item.icon
			hbox.add_child(icon_rect)

			var desc = Label.new()
			desc.text = drop.item.item_name if drop.item else "Item desconocido"
			desc.add_theme_font_size_override("font_size", 13)
			hbox.add_child(desc)

			if drop.item:
				ItemInventory.add_item(drop.item)

		"worm":
			var worm_data: Worm_Data = drop.worm
			var icon = Label.new()
			icon.text = "~"
			icon.add_theme_font_size_override("font_size", 16)
			icon.add_theme_color_override("font_color", Rarity.get_rarity_color(worm_data.rarity))
			hbox.add_child(icon)

			var worm_name = worm_data.template.worm_name if worm_data.template else "Gusano"
			var rarity_name = Rarity.get_rarity_name(worm_data.rarity)
			var desc = Label.new()
			desc.text = "%s (%s)" % [worm_name, rarity_name]
			desc.add_theme_font_size_override("font_size", 13)
			desc.add_theme_color_override("font_color", Rarity.get_rarity_color(worm_data.rarity))
			hbox.add_child(desc)

			var added = Inventory.add_worm(worm_data)
			if added:
				_spawn_worm_in_social(worm_data)
			else:
				var warn = Label.new()
				warn.text = " [Inventario lleno]"
				warn.add_theme_font_size_override("font_size", 11)
				warn.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))
				hbox.add_child(warn)

	return card
