extends Node

signal inventory_changed
signal item_used(item: ItemData, target)

var items: Array[ItemData] = []

func add_item(item: ItemData) -> bool:
	for existing in items:
		if existing.item_name == item.item_name:
			existing.quantity += item.quantity
			inventory_changed.emit()
			return true
	var new_item = item.duplicate()
	items.append(new_item)
	inventory_changed.emit()
	return true

func remove_item(item_name: String) -> ItemData:
	for i in range(items.size()):
		if items[i].item_name == item_name:
			var item = items[i]
			item.quantity -= 1
			if item.quantity <= 0:
				items.remove_at(i)
			inventory_changed.emit()
			return item
	return null

func get_item(item_name: String) -> ItemData:
	for item in items:
		if item.item_name == item_name:
			return item
	return null

func has_item(item_name: String) -> bool:
	return get_item(item_name) != null

func get_item_quantity(item_name: String) -> int:
	var item = get_item(item_name)
	return item.quantity if item else 0

func use_item_on_worm(item_name: String, worm: Worm) -> bool:
	var item = get_item(item_name)
	if item == null or item.quantity <= 0:
		return false
	if item.target != ItemData.Target.WORM:
		return false
	EffectProcessor.apply(item.effect, worm)
	item.quantity -= 1
	if item.quantity <= 0:
		items.erase(item)
	inventory_changed.emit()
	item_used.emit(item, worm)
	return true

func use_item_on_player(item_name: String) -> bool:
	var item = get_item(item_name)
	if item == null or item.quantity <= 0:
		return false
	if item.target != ItemData.Target.PLAYER:
		return false
	EffectProcessor.apply(item.effect)
	item.quantity -= 1
	if item.quantity <= 0:
		items.erase(item)
	inventory_changed.emit()
	item_used.emit(item, null)
	return true

func unlock_extra_slots(amount: int):
	Inventory.unlocked_slots += amount
	Inventory.inventory_changed.emit()
