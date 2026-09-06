extends Resource
class_name ShopSaveData

@export var available_item_paths: Array[String] = []
@export var item_stock: Dictionary = {}
@export var renew_count: int = 0
@export var renew_cost: int = 50
@export var auto_renew_timer: float = 300.0
@export var discount: float = 0.0
@export var discount_timer: float = 0.0

static func create_from_game() -> ShopSaveData:
	var data = ShopSaveData.new()
	for item in Shop.available_items:
		if item.resource_path:
			data.available_item_paths.append(item.resource_path)
	data.item_stock = Shop.item_stock.duplicate()
	data.renew_count = Shop.renew_count
	data.renew_cost = Shop.renew_cost
	data.auto_renew_timer = Shop.auto_renew_timer
	data.discount = Shop.discount
	data.discount_timer = Shop.discount_timer
	return data
