extends Resource
class_name InventorySaveData

@export var unlocked_slots: int = 3
@export var worms: Array[WormSaveData] = []

static func create_from_game() -> InventorySaveData:
	var data = InventorySaveData.new()
	data.unlocked_slots = Inventory.unlocked_slots
	for worm in Inventory.worms:
		var worm_save = WormSaveData.create_from_worm(worm)
		if worm_save:
			data.worms.append(worm_save)
	return data
