extends Control

const BAR_HEIGHT: float = 50.0
const INVENTORY_HEIGHT: float = 200.0

signal bar_height_changed(new_height: float)

const SHOP_MENU_SCENE = preload("res://commons/ui/shop_menu.tscn")
const WORM_SELECTOR_SCENE = preload("res://commons/ui/worm_selector/worm_selector.tscn")
const WORM_DETAILS_SCENE = preload("res://commons/ui/worm_details_panel.tscn")
const SLOT_MACHINE_SCENE = preload("res://commons/ui/slot_machine/slot_machine.tscn")
const PAUSE_MENU_SCENE = preload("res://commons/ui/pause_menu.tscn")

@onready var bg: ColorRect = $BG
@onready var main_vbox: VBoxContainer = $MainVBox
@onready var bar_container: HBoxContainer = $MainVBox/BarContainer
@onready var collapse_btn: Button = $MainVBox/BarContainer/CollapseBtn
@onready var money_label: Label = $MainVBox/BarContainer/MoneyLabel
@onready var content_container: HBoxContainer = $MainVBox/BarContainer/ContentContainer
@onready var worm_container: HBoxContainer = $MainVBox/BarContainer/ContentContainer/WormContainer
@onready var shop_btn: Button = $MainVBox/BarContainer/ShopBtn
@onready var slot_btn: Button = $MainVBox/BarContainer/SlotBtn
@onready var give_money_btn: Button = $MainVBox/BarContainer/GiveMoneyBtn
@onready var inventory_btn: Button = $MainVBox/BarContainer/InventoryBtn
@onready var worms_btn: Button = $MainVBox/BarContainer/WormsBtn
@onready var expand_btn: Button = $ExpandBtn
@onready var inventory_panel: PanelContainer = $MainVBox/InventoryPanel
@onready var inventory_scroll: ScrollContainer = $MainVBox/InventoryPanel/VBox/Scroll
@onready var inventory_list: VBoxContainer = $MainVBox/InventoryPanel/VBox/Scroll/InventoryList
@onready var inventory_close_btn: Button = $MainVBox/InventoryPanel/VBox/Header/CloseBtn

var is_collapsed: bool = false
var is_inventory_open: bool = false
var target_y: float = 0.0
var animation_speed: float = 10.0
var displayed_money: int = 0
var shop_menu_instance: Control = null
var worm_selector_instance: WormSelector = null
var worm_details_instance: WormDetailsPanel = null
var slot_machine_instance: Control = null
var pending_item: ItemData = null
var pause_menu_instance: Control = null

func _ready() -> void:
	add_to_group("bottom_bar")
	collapse_btn.pressed.connect(_toggle_collapse)
	expand_btn.pressed.connect(_toggle_collapse)
	shop_btn.pressed.connect(_on_shop_pressed)
	slot_btn.pressed.connect(_on_slot_machine_pressed)
	inventory_btn.pressed.connect(_on_inventory_pressed)
	worms_btn.pressed.connect(_on_worms_pressed)
	inventory_close_btn.pressed.connect(_on_inventory_close)
	give_money_btn.pressed.connect(func(): GlobalManager.add_money(500))
	_create_pause_button()
	GlobalManager.money_changed.connect(_on_money_changed)
	Inventory.inventory_changed.connect(_on_inventory_changed)
	ItemInventory.inventory_changed.connect(_on_item_inventory_changed)
	_update_positions(true)
	_on_money_changed(GlobalManager.money)
	_refresh_worm_display()

func _process(delta: float) -> void:
	main_vbox.position.y = lerp(main_vbox.position.y, target_y, delta * animation_speed)
	bg.position.y = main_vbox.position.y
	var panel_height = INVENTORY_HEIGHT if is_inventory_open else 0.0
	bg.size.y = BAR_HEIGHT + panel_height

func _update_positions(instant: bool = false) -> void:
	var viewport_size = get_viewport_rect().size
	var panel_height = INVENTORY_HEIGHT if is_inventory_open else 0.0
	var total_height = BAR_HEIGHT + panel_height
	if is_collapsed:
		target_y = viewport_size.y
	else:
		target_y = viewport_size.y - total_height
	expand_btn.visible = is_collapsed
	bar_height_changed.emit(total_height if not is_collapsed else 0.0)
	if instant:
		main_vbox.position.y = target_y
		bg.position.y = target_y
		bg.size.y = BAR_HEIGHT + panel_height

func _toggle_collapse() -> void:
	is_collapsed = not is_collapsed
	collapse_btn.text = "▲" if is_collapsed else "▼"
	_update_positions()

func _on_money_changed(new_value: int) -> void:
	var tween = create_tween()
	tween.tween_property(self, "displayed_money", new_value, 0.5).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_method(func(v): money_label.text = "%d¢" % v, displayed_money, new_value, 0.5)

func _on_inventory_changed() -> void:
	_refresh_worm_display()

func _on_item_inventory_changed() -> void:
	if is_inventory_open:
		_refresh_inventory_panel()

func _refresh_worm_display() -> void:
	for child in worm_container.get_children():
		child.queue_free()

	var count = Inventory.worms.size()
	var max_slots = Inventory.unlocked_slots

	var worm_label = Label.new()
	worm_label.text = "Gusanos: %d/%d" % [count, max_slots]
	worm_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	worm_container.add_child(worm_label)

func _on_use_item(item: ItemData) -> void:
	if item.target == ItemData.Target.PLAYER:
		ItemInventory.use_item_on_player(item.item_name)
	elif item.target == ItemData.Target.WORM:
		pending_item = item
		_show_worm_selector()

func _show_worm_selector() -> void:
	if worm_selector_instance == null or not is_instance_valid(worm_selector_instance):
		worm_selector_instance = WORM_SELECTOR_SCENE.instantiate()
		worm_selector_instance.worm_selected.connect(_on_worm_selected)
		worm_selector_instance.selector_closed.connect(_on_selector_closed)
		get_parent().add_child(worm_selector_instance)
	worm_selector_instance.open()

func _on_worm_selected(worm_data: Worm_Data) -> void:
	if pending_item:
		var worm_node = _find_worm_node(worm_data)
		if worm_node:
			ItemInventory.use_item_on_worm(pending_item.item_name, worm_node)
		else:
			var effect = pending_item.effect
			if effect and effect.target == EffectData.Target.WORM:
				match effect.effect_type:
					EffectData.Type.STAT_BOOST:
						WormEffects.permanent_boost_data(worm_data, effect.stat, effect.value, true)
					EffectData.Type.RARITY_UPGRADE:
						WormEffects.upgrade_rarity_data(worm_data)
					EffectData.Type.HEAL:
						worm_data.current_hp = minf(worm_data.current_hp + effect.value, worm_data.get_computed_hp_max())
					_:
						pass
			ItemInventory.remove_item(pending_item.item_name)
			Inventory.inventory_changed.emit()
	pending_item = null

func _on_selector_closed() -> void:
	pending_item = null

func _find_worm_node(worm_data: Worm_Data) -> Worm:
	var tree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	for node in tree.get_nodes_in_group("worms"):
		if node is Worm and node.worm_data == worm_data:
			return node
	return null

func _on_inventory_pressed() -> void:
	is_inventory_open = not is_inventory_open
	inventory_panel.visible = is_inventory_open
	_update_positions()
	if is_inventory_open:
		_refresh_inventory_panel()

func _on_inventory_close() -> void:
	is_inventory_open = false
	inventory_panel.visible = false
	_update_positions()

func _on_worms_pressed() -> void:
	if worm_details_instance == null or not is_instance_valid(worm_details_instance):
		worm_details_instance = WORM_DETAILS_SCENE.instantiate()
		worm_details_instance.panel_closed.connect(_on_worm_details_closed)
		get_parent().add_child(worm_details_instance)
	worm_details_instance.open()

func _on_worm_details_closed() -> void:
	pass

func _refresh_inventory_panel() -> void:
	for child in inventory_list.get_children():
		child.queue_free()

	if ItemInventory.items.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No tienes items"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_font_size_override("font_size", 14)
		inventory_list.add_child(empty_label)
		return

	for item in ItemInventory.items:
		if item.quantity <= 0:
			continue
		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(0, 60)
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.15, 0.17, 0.22, 0.9)
		style.set_corner_radius_all(6)
		style.set_content_margin_all(8)
		card.add_theme_stylebox_override("panel", style)
		inventory_list.add_child(card)

		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		card.add_child(hbox)

		var icon_rect = TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(40, 40)
		icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if item.icon:
			icon_rect.texture = item.icon
		hbox.add_child(icon_rect)

		var info = VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(info)

		var name_label = Label.new()
		name_label.text = "%s x%d" % [item.item_name, item.quantity]
		name_label.add_theme_font_size_override("font_size", 14)
		info.add_child(name_label)

		var desc_label = Label.new()
		desc_label.text = item.description
		desc_label.add_theme_font_size_override("font_size", 11)
		desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		info.add_child(desc_label)

		var target_label = Label.new()
		target_label.text = "Objetivo: Jugador" if item.target == ItemData.Target.PLAYER else "Objetivo: Gusano"
		target_label.add_theme_font_size_override("font_size", 10)
		target_label.add_theme_color_override("font_color", Color(0.5, 0.7, 0.5))
		info.add_child(target_label)

		var use_btn = Button.new()
		use_btn.text = "Usar"
		use_btn.custom_minimum_size = Vector2(60, 0)
		use_btn.pressed.connect(_on_use_item.bind(item))
		hbox.add_child(use_btn)

func _on_shop_pressed() -> void:
	if shop_menu_instance == null:
		shop_menu_instance = SHOP_MENU_SCENE.instantiate()
		shop_menu_instance.shop_closed.connect(_on_shop_menu_closed)
		get_parent().add_child(shop_menu_instance)
	shop_menu_instance.open()

func _on_shop_menu_closed() -> void:
	pass

func _on_slot_machine_pressed() -> void:
	if slot_machine_instance == null or not is_instance_valid(slot_machine_instance):
		slot_machine_instance = SLOT_MACHINE_SCENE.instantiate()
		slot_machine_instance.slot_machine_closed.connect(_on_slot_machine_closed)
		get_parent().add_child(slot_machine_instance)
	slot_machine_instance.open()

func _on_slot_machine_closed() -> void:
	pass

func _create_pause_button() -> void:
	var sep = VSeparator.new()
	bar_container.add_child(sep)
	var pause_btn = Button.new()
	pause_btn.text = "Pausa"
	pause_btn.custom_minimum_size = Vector2(70, 0)
	pause_btn.pressed.connect(_on_pause_pressed)
	bar_container.add_child(pause_btn)

func _on_pause_pressed() -> void:
	if pause_menu_instance == null or not is_instance_valid(pause_menu_instance):
		pause_menu_instance = PAUSE_MENU_SCENE.instantiate()
		get_parent().add_child(pause_menu_instance)
	pause_menu_instance.open()
