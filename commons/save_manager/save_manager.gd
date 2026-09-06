extends Node

signal game_saved
signal game_loaded
signal game_deleted

const SAVE_PATH: String = "user://savegame.tres"
const AUTO_SAVE_INTERVAL: float = 120.0

var global_triggers: Dictionary = {}
var _auto_save_timer: Timer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_auto_save()

func _setup_auto_save() -> void:
	_auto_save_timer = Timer.new()
	_auto_save_timer.wait_time = AUTO_SAVE_INTERVAL
	_auto_save_timer.one_shot = false
	_auto_save_timer.timeout.connect(_on_auto_save)
	add_child(_auto_save_timer)
	_auto_save_timer.start()

func _on_auto_save() -> void:
	if has_save():
		save_game()

func save_game() -> void:
	var save_data = SaveData.create_from_game()
	var error = ResourceSaver.save(save_data, SAVE_PATH)
	if error == OK:
		print("[SaveManager] Partida guardada correctamente")
		game_saved.emit()
	else:
		print("[SaveManager] Error al guardar: %s" % error_string(error))

func load_game() -> void:
	if not has_save():
		print("[SaveManager] No hay partida guardada")
		return
	var save_data = ResourceLoader.load(SAVE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as SaveData
	if save_data == null:
		print("[SaveManager] Error al cargar la partida")
		return
	_apply_save_data(save_data)
	print("[SaveManager] Partida cargada correctamente")
	game_loaded.emit()

func _apply_save_data(save_data: SaveData) -> void:
	GlobalManager.money = save_data.money
	GlobalManager.money_changed.emit(GlobalManager.money)

	Inventory.worms.clear()
	Inventory.worm_areas.clear()
	Inventory.unlocked_slots = save_data.inventory_data.unlocked_slots

	var worms_to_spawn_social: Array[Dictionary] = []
	var worms_to_spawn_combat: Array[Dictionary] = []

	for worm_save in save_data.inventory_data.worms:
		var worm_data = worm_save.to_worm_data()
		if worm_data == null:
			continue
		Inventory.worms.append(worm_data)
		Inventory.worm_areas[worm_data] = worm_save.area
		if worm_save.area == "social":
			worms_to_spawn_social.append({"data": worm_data, "position": worm_save.position})
		elif worm_save.area == "combat":
			worms_to_spawn_combat.append({"data": worm_data, "position": worm_save.position})

	Inventory.inventory_changed.emit()

	ItemInventory.items.clear()
	for item_save in save_data.items_data:
		var item_data = item_save.to_item_data()
		if item_data:
			ItemInventory.items.append(item_data)
	ItemInventory.inventory_changed.emit()

	for upgrade in UpgradeManager.upgrades:
		if save_data.upgrades_data.has(upgrade.upgrade_name):
			upgrade.current_level = save_data.upgrades_data[upgrade.upgrade_name]
	UpgradeManager.upgrades_changed.emit()

	var pp = save_data.player_persistent
	PlayerEffects.auto_collect_level = pp.auto_collect_level
	PlayerEffects.drop_frequency_level = pp.drop_frequency_level
	PlayerEffects.rarity_spawn_boost = pp.rarity_spawn_boost
	PlayerEffects.shop_discount_level = pp.shop_discount_level

	var sd = save_data.shop_data
	Shop.renew_count = sd.renew_count
	Shop.renew_cost = sd.renew_cost
	Shop.auto_renew_timer = sd.auto_renew_timer
	Shop.discount = sd.discount
	Shop.discount_timer = sd.discount_timer
	Shop.available_items.clear()
	for path in sd.available_item_paths:
		var item = load(path) as ItemData
		if item:
			Shop.available_items.append(item)
	Shop.item_stock = sd.item_stock.duplicate()

	global_triggers = save_data.global_triggers.duplicate()

	_spawn_saved_worms(worms_to_spawn_social, worms_to_spawn_combat)

func _spawn_saved_worms(social_list: Array, combat_list: Array) -> void:
	var tree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	await tree.process_frame
	await tree.process_frame

	for entry in social_list:
		var social_area = tree.get_first_node_in_group("social_area")
		if social_area:
			social_area.spawn_social_worm(entry["data"], entry["position"])

	for entry in combat_list:
		var spawner = tree.get_first_node_in_group("combat_spawner")
		if spawner:
			spawner.spawn_specific_worm(entry["data"], entry["position"])

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)
		print("[SaveManager] Partida borrada")
	_reset_game()
	game_deleted.emit()

func _reset_game() -> void:
	GlobalManager.money = 50
	GlobalManager.money_changed.emit(GlobalManager.money)

	Inventory.worms.clear()
	Inventory.worm_areas.clear()
	Inventory.unlocked_slots = 3
	Inventory.inventory_changed.emit()

	ItemInventory.items.clear()
	ItemInventory.inventory_changed.emit()

	for upgrade in UpgradeManager.upgrades:
		upgrade.current_level = 0
	UpgradeManager.upgrades_changed.emit()

	PlayerEffects.auto_collect_level = 0
	PlayerEffects.drop_frequency_level = 0
	PlayerEffects.rarity_spawn_boost = 0.0
	PlayerEffects.shop_discount_level = 0

	Shop.renew_count = 0
	Shop.renew_cost = 50
	Shop.auto_renew_timer = Shop.auto_renew_time
	Shop.discount = 0.0
	Shop.discount_timer = 0.0
	Shop.available_items.clear()
	Shop.item_stock.clear()

	global_triggers.clear()

	var tree = Engine.get_main_loop() as SceneTree
	if tree:
		for node in tree.get_nodes_in_group("worms"):
			if node is Worm:
				node.queue_free()

func get_trigger(key: String, default = null):
	return global_triggers.get(key, default)

func set_trigger(key: String, value) -> void:
	global_triggers[key] = value
