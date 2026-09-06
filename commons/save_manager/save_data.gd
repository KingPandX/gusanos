extends Resource
class_name SaveData

@export var version: int = 1
@export var money: int = 50
@export var inventory_data: InventorySaveData
@export var items_data: Array[ItemSaveData] = []
@export var upgrades_data: Dictionary = {}
@export var player_persistent: PlayerPersistentSaveData
@export var shop_data: ShopSaveData
@export var global_triggers: Dictionary = {}

static func create_from_game() -> SaveData:
	var data = SaveData.new()
	data.money = GlobalManager.money
	data.inventory_data = InventorySaveData.create_from_game()
	data.items_data = ItemSaveData.create_array_from_game()
	data.upgrades_data = UpgradeSaveData.create_from_game()
	data.player_persistent = PlayerPersistentSaveData.create_from_game()
	data.shop_data = ShopSaveData.create_from_game()
	data.global_triggers = SaveManager.global_triggers.duplicate()
	return data
