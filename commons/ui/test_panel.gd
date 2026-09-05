extends Control

@onready var items_list: VBoxContainer = $VBoxContainer/ScrollContainer/ItemsList
@onready var spawn_button: Button = $VBoxContainer/Buttons/SpawnButton
@onready var give_money_button: Button = $VBoxContainer/Buttons/GiveMoneyButton
@onready var spawn_social_button: Button = $VBoxContainer/Buttons/SpawnSocialButton
@onready var worm_selector: Control = $WormSelector

var item_buttons: Dictionary = {}
var selected_item_name: String = ""

func _ready() -> void:
	spawn_button.pressed.connect(_on_spawn_pressed)
	give_money_button.pressed.connect(_on_give_money_pressed)
	spawn_social_button.pressed.connect(_on_spawn_social_pressed)
	worm_selector.worm_selected.connect(_on_worm_selected)
	
	ItemInventory.inventory_changed.connect(_on_inventory_changed)
	_refresh_items_list()

func _on_spawn_pressed() -> void:
	var spawner = get_tree().get_first_node_in_group("combat_spawner")
	if spawner:
		spawner.spawn_worm()

func _on_spawn_social_pressed() -> void:
	var social_area = get_tree().get_first_node_in_group("social_area")
	if social_area:
		if Inventory.templates.is_empty():
			print("ERROR: No templates loaded!")
			return
		var worm_data = WormFactory.generate_random_worm(Inventory.templates)
		if worm_data and Inventory.add_worm(worm_data, "social"):
			social_area.spawn_social_worm(worm_data)

func _on_give_money_pressed() -> void:
	GlobalManager.add_money(500)

func _on_inventory_changed() -> void:
	_refresh_items_list()

func _refresh_items_list() -> void:
	for child in items_list.get_children():
		child.queue_free()
	
	item_buttons.clear()
	
	for item in ItemInventory.items:
		var btn = Button.new()
		btn.text = "%s (x%d) - $%d" % [item.item_name, item.quantity, item.cost]
		btn.custom_minimum_size = Vector2(0, 40)
		btn.pressed.connect(_on_item_button_pressed.bind(item.item_name))
		items_list.add_child(btn)
		item_buttons[item.item_name] = btn
	
	_add_shop_items()

func _add_shop_items() -> void:
	var shop_label = Label.new()
	shop_label.text = "--- Tienda ---"
	shop_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	items_list.add_child(shop_label)
	
	var dir = DirAccess.open("res://assets/items/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var item = load("res://assets/items/" + file_name)
				if item is ItemData:
					var btn = Button.new()
					btn.text = "Comprar: %s - $%d" % [item.item_name, item.cost]
					btn.custom_minimum_size = Vector2(0, 40)
					btn.pressed.connect(_on_buy_item_pressed.bind(item))
					items_list.add_child(btn)
			file_name = dir.get_next()

func _on_item_button_pressed(item_name: String) -> void:
	selected_item_name = item_name
	var item = ItemInventory.get_item(item_name)
	if item and item.target == ItemData.Target.WORM:
		worm_selector.open()
	elif item and item.target == ItemData.Target.PLAYER:
		ItemInventory.use_item_on_player(item_name)
		_refresh_items_list()

func _on_buy_item_pressed(item: ItemData) -> void:
	if GlobalManager.can_afford(item.cost):
		GlobalManager.transaction(item.cost)
		ItemInventory.add_item(item)
		_refresh_items_list()

func _on_worm_selected(worm: Worm) -> void:
	if selected_item_name != "":
		ItemInventory.use_item_on_worm(selected_item_name, worm)
		selected_item_name = ""
		_refresh_items_list()
