extends Resource
class_name ItemSaveData

@export var item_path: String = ""
@export var quantity: int = 1

static func create_from_item(item: ItemData) -> ItemSaveData:
	if item == null:
		return null
	var data = ItemSaveData.new()
	if item.resource_path:
		data.item_path = item.resource_path
	else:
		for dir_path in ["res://assets/items/", "res://resources/items/"]:
			var dir = DirAccess.open(dir_path)
			if dir == null:
				continue
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if file_name.ends_with(".tres"):
					var loaded = load(dir_path + file_name)
					if loaded is ItemData and loaded.item_name == item.item_name:
						data.item_path = dir_path + file_name
						break
				file_name = dir.get_next()
			if not data.item_path.is_empty():
				break
	data.quantity = item.quantity
	return data

static func create_array_from_game() -> Array[ItemSaveData]:
	var result: Array[ItemSaveData] = []
	for item in ItemInventory.items:
		if item.quantity > 0:
			var save = create_from_item(item)
			if save:
				result.append(save)
	return result

func to_item_data() -> ItemData:
	if item_path.is_empty():
		return null
	var item = load(item_path) as ItemData
	if item == null:
		return null
	var dup = item.duplicate() as ItemData
	dup.quantity = quantity
	return dup
