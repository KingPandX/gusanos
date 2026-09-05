extends Control

signal shop_closed

@onready var bg: ColorRect = $BG
@onready var panel: PanelContainer = $Panel
@onready var timer_label: Label = $Panel/VBox/TopBar/TimerLabel
@onready var renew_btn: Button = $Panel/VBox/TopBar/RenewBtn
@onready var close_btn: Button = $Panel/VBox/Header/CloseBtn
@onready var items_tab: Button = $Panel/VBox/Tabs/ItemsTab
@onready var upgrades_tab: Button = $Panel/VBox/Tabs/UpgradesTab
@onready var scroll: ScrollContainer = $Panel/VBox/Scroll
@onready var content_list: VBoxContainer = $Panel/VBox/Scroll/ContentList
@onready var money_label: Label = $Panel/VBox/Footer/MoneyLabel

var show_upgrades: bool = false
var item_stock: Dictionary = {}

func _ready() -> void:
	bg.gui_input.connect(_on_bg_input)
	close_btn.pressed.connect(_on_close_pressed)
	renew_btn.pressed.connect(_on_renew_pressed)
	items_tab.pressed.connect(_on_items_tab)
	upgrades_tab.pressed.connect(_on_upgrades_tab)
	GlobalManager.money_changed.connect(_on_money_changed)
	Shop.shop_renewed.connect(_on_shop_renewed)
	Shop.timer_updated.connect(_on_timer_updated)
	_update_money_label()

func _process(_delta: float) -> void:
	var time_left = Shop.get_time_left()
	_update_timer_label(time_left)
	_update_renew_button()

func open() -> void:
	visible = true
	Shop.rotate_items()
	_init_stock()
	_refresh_content()
	_update_money_label()

func close() -> void:
	visible = false
	shop_closed.emit()

func _init_stock() -> void:
	item_stock.clear()
	for item in Shop.get_available_items():
		item_stock[item.item_name] = randi_range(1, 3)

func _on_bg_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		close()

func _on_close_pressed() -> void:
	close()

func _on_renew_pressed() -> void:
	if GlobalManager.can_afford(Shop.get_renew_cost()):
		GlobalManager.transaction(Shop.get_renew_cost())
		Shop.renew_shop()
		_update_money_label()

func _on_items_tab() -> void:
	show_upgrades = false
	_update_tab_buttons()
	_refresh_content()

func _on_upgrades_tab() -> void:
	show_upgrades = true
	_update_tab_buttons()
	_refresh_content()

func _on_money_changed(_new_value: int) -> void:
	_update_money_label()

func _on_shop_renewed() -> void:
	_init_stock()
	_refresh_content()
	_update_money_label()

func _on_timer_updated(_time_left: float) -> void:
	pass

func _update_tab_buttons() -> void:
	items_tab.disabled = not show_upgrades
	upgrades_tab.disabled = show_upgrades

func _update_timer_label(time_left: float) -> void:
	var minutes = int(time_left) / 60
	var seconds = int(time_left) % 60
	timer_label.text = "Renovación: %d:%02d" % [minutes, seconds]

func _update_renew_button() -> void:
	renew_btn.text = "Renovar [%d¢]" % Shop.get_renew_cost()

func _update_money_label() -> void:
	money_label.text = "Dinero: %d¢" % GlobalManager.money

func _refresh_content() -> void:
	for child in content_list.get_children():
		child.queue_free()

	if show_upgrades:
		_build_upgrades_list()
	else:
		_build_items_list()

func _build_items_list() -> void:
	var items = Shop.get_available_items()
	if items.is_empty():
		var label = Label.new()
		label.text = "No hay items disponibles"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		content_list.add_child(label)
		return

	for item in items:
		var card = _build_item_card(item)
		content_list.add_child(card)

func _build_item_card(item: ItemData) -> PanelContainer:
	var stock = item_stock.get(item.item_name, 0)

	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 70)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.17, 0.22, 0.9) if stock > 0 else Color(0.1, 0.1, 0.12, 0.7)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(8)
	card.add_theme_stylebox_override("panel", style)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	card.add_child(hbox)

	var icon_rect = TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(48, 48)
	icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if item.icon:
		icon_rect.texture = item.icon
	hbox.add_child(icon_rect)

	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info)

	var name_label = Label.new()
	name_label.text = item.item_name
	name_label.add_theme_font_size_override("font_size", 14)
	info.add_child(name_label)

	var desc_label = Label.new()
	desc_label.text = item.description
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	info.add_child(desc_label)

	var cost_label = Label.new()
	var final_cost = _get_discounted_cost(item.cost)
	cost_label.text = "%d¢" % final_cost
	cost_label.add_theme_font_size_override("font_size", 12)
	cost_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	hbox.add_child(cost_label)

	if stock > 0:
		var stock_label = Label.new()
		stock_label.text = "x%d" % stock
		stock_label.add_theme_font_size_override("font_size", 12)
		stock_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		hbox.add_child(stock_label)

		var buy_btn = Button.new()
		buy_btn.text = "Comprar"
		buy_btn.custom_minimum_size = Vector2(80, 0)
		buy_btn.pressed.connect(_on_buy_item.bind(item))
		hbox.add_child(buy_btn)
	else:
		var sold_out_label = Label.new()
		sold_out_label.text = "Agotado"
		sold_out_label.add_theme_font_size_override("font_size", 14)
		sold_out_label.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))
		hbox.add_child(sold_out_label)

	return card

func _build_upgrades_list() -> void:
	for upgrade in UpgradeManager.upgrades:
		var card = _build_upgrade_card(upgrade)
		content_list.add_child(card)

func _build_upgrade_card(upgrade: UpgradeData) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 70)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.17, 0.22, 0.9)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(8)
	card.add_theme_stylebox_override("panel", style)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	card.add_child(hbox)

	var icon_rect = TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(48, 48)
	icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if upgrade.icon:
		icon_rect.texture = upgrade.icon
	hbox.add_child(icon_rect)

	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info)

	var name_label = Label.new()
	name_label.text = upgrade.upgrade_name
	name_label.add_theme_font_size_override("font_size", 14)
	info.add_child(name_label)

	var level_label = Label.new()
	level_label.text = "Nivel %d/%d" % [upgrade.current_level, upgrade.max_level]
	level_label.add_theme_font_size_override("font_size", 11)
	level_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	info.add_child(level_label)

	var desc_label = Label.new()
	desc_label.text = upgrade.description
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	info.add_child(desc_label)

	if upgrade.can_upgrade():
		var cost_label = Label.new()
		cost_label.text = "%d¢" % upgrade.get_current_cost()
		cost_label.add_theme_font_size_override("font_size", 12)
		cost_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
		hbox.add_child(cost_label)

		var buy_btn = Button.new()
		buy_btn.text = "Mejorar"
		buy_btn.custom_minimum_size = Vector2(80, 0)
		buy_btn.pressed.connect(_on_buy_upgrade.bind(upgrade))
		hbox.add_child(buy_btn)
	else:
		var max_label = Label.new()
		max_label.text = "MAX"
		max_label.add_theme_font_size_override("font_size", 14)
		max_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
		hbox.add_child(max_label)

	return card

func _on_buy_item(item: ItemData) -> void:
	var stock = item_stock.get(item.item_name, 0)
	if stock <= 0:
		return
	var final_cost = _get_discounted_cost(item.cost)
	if GlobalManager.can_afford(final_cost):
		GlobalManager.transaction(final_cost)
		ItemInventory.add_item(item)
		item_stock[item.item_name] = stock - 1
		_update_money_label()
		_refresh_content()

func _on_buy_upgrade(upgrade: UpgradeData) -> void:
	UpgradeManager.purchase_upgrade(upgrade)
	_update_money_label()
	_refresh_content()

func _get_discounted_cost(base_cost: int) -> int:
	var discount = PlayerEffects.get_shop_discount()
	return max(1, round(base_cost * (1.0 - discount)))
