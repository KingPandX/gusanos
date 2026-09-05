extends Control

const BAR_HEIGHT: float = 50.0
const SLOT_SIZE: float = 32.0

@onready var bg: ColorRect = $BG
@onready var bar_container: HBoxContainer = $BarContainer
@onready var collapse_btn: Button = $BarContainer/CollapseBtn
@onready var money_label: Label = $BarContainer/MoneyLabel
@onready var content_container: HBoxContainer = $BarContainer/ContentContainer
@onready var shop_btn: Button = $BarContainer/ShopBtn
@onready var slot_btn: Button = $BarContainer/SlotBtn
@onready var give_money_btn: Button = $BarContainer/GiveMoneyBtn
@onready var expand_btn: Button = $ExpandBtn

var is_collapsed: bool = false
var target_y: float = 0.0
var animation_speed: float = 10.0
var displayed_money: int = 0

func _ready() -> void:
	collapse_btn.pressed.connect(_toggle_collapse)
	expand_btn.pressed.connect(_toggle_collapse)
	shop_btn.pressed.connect(_on_shop_pressed)
	slot_btn.pressed.connect(_on_slot_machine_pressed)
	give_money_btn.pressed.connect(func(): GlobalManager.add_money(500))
	GlobalManager.money_changed.connect(_on_money_changed)
	Inventory.inventory_changed.connect(_on_inventory_changed)
	_update_target_y(true)
	_on_money_changed(GlobalManager.money)
	_on_inventory_changed()

func _process(delta: float) -> void:
	bar_container.position.y = lerp(bar_container.position.y, target_y, delta * animation_speed)
	bg.position.y = bar_container.position.y

func _update_target_y(instant: bool = false) -> void:
	var viewport_size = get_viewport_rect().size
	target_y = viewport_size.y - BAR_HEIGHT if not is_collapsed else viewport_size.y
	expand_btn.visible = is_collapsed
	if instant:
		bar_container.position.y = target_y
		bg.position.y = target_y
		expand_btn.visible = is_collapsed

func _toggle_collapse() -> void:
	is_collapsed = not is_collapsed
	collapse_btn.text = "▲" if is_collapsed else "▼"
	_update_target_y()

func _on_money_changed(new_value: int) -> void:
	var tween = create_tween()
	tween.tween_property(self, "displayed_money", new_value, 0.5).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_method(func(v): money_label.text = "%d¢" % v, displayed_money, new_value, 0.5)

func _on_inventory_changed() -> void:
	_refresh_inventory_display()

func _refresh_inventory_display() -> void:
	for child in content_container.get_children():
		child.queue_free()

	var count = Inventory.worms.size()
	var max_slots = Inventory.unlocked_slots

	var inventory_label = Label.new()
	inventory_label.text = "Gusanos: %d/%d" % [count, max_slots]
	inventory_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	content_container.add_child(inventory_label)

	for i in range(min(count, max_slots)):
		var worm_data = Inventory.worms[i]
		var slot = PanelContainer.new()
		slot.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
		var style = StyleBoxFlat.new()
		style.bg_color = Rarity.get_rarity_color(worm_data.rarity)
		style.bg_color.a = 0.3
		style.border_color = Rarity.get_rarity_color(worm_data.rarity)
		style.set_border_width_all(2)
		style.set_corner_radius_all(4)
		slot.add_theme_stylebox_override("panel", style)
		content_container.add_child(slot)

		var slot_label = Label.new()
		slot_label.text = worm_data.template.worm_name[0] if worm_data.template else "?"
		slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot_label.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
		slot_label.add_theme_color_override("font_color", Rarity.get_rarity_color(worm_data.rarity))
		slot.add_child(slot_label)

	for _i in range(count, max_slots):
		var slot = PanelContainer.new()
		slot.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.2, 0.2, 0.2, 0.3)
		style.border_color = Color(0.4, 0.4, 0.4, 0.3)
		style.set_border_width_all(1)
		style.set_corner_radius_all(4)
		slot.add_theme_stylebox_override("panel", style)
		content_container.add_child(slot)

		var slot_label = Label.new()
		slot_label.text = "+"
		slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot_label.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
		slot_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		slot.add_child(slot_label)

func _on_shop_pressed() -> void:
	print("Tienda - por implementar")

func _on_slot_machine_pressed() -> void:
	print("Tragamonedas - por implementar")
