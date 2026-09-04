extends Node

signal inventory_changed
signal slot_unlocked(new_max: int)

var worms : Array[Worm_Data] = []
var max_slots : int = 3
var unlocked_slots : int = 3
var templates : Array[WormTemplate] = []

func _ready() -> void:
	_load_templates()

func _load_templates() -> void:
	var template_paths = [
		"res://assets/worms_tamplets/test.tres",
	]
	for path in template_paths:
		var resource = load(path)
		if resource is WormTemplate:
			templates.append(resource)
	
	if templates.is_empty():
		var dirs = ["res://assets/worms_tamplets/", "res://resources/templates/"]
		for path in dirs:
			var dir = DirAccess.open(path)
			if dir == null:
				continue
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if file_name.ends_with(".tres"):
					var resource = load(path + file_name)
					if resource is WormTemplate:
						templates.append(resource)
				file_name = dir.get_next()
	
	print("Templates loaded: %d" % templates.size())

func add_worm(worm: Worm_Data) -> bool:
	if worms.size() >= unlocked_slots:
		return false
	worms.append(worm)
	inventory_changed.emit()
	return true

func remove_worm(index: int) -> Worm_Data:
	if index < 0 or index >= worms.size():
		return null
	var worm = worms[index]
	worms.remove_at(index)
	inventory_changed.emit()
	return worm

func can_add() -> bool:
	return worms.size() < unlocked_slots

func get_slot_cost() -> int:
	return Rarity.get_slot_cost(unlocked_slots)

func unlock_slot() -> bool:
	var cost = get_slot_cost()
	if cost < 0 or not GlobalManager.can_afford(cost):
		return false
	GlobalManager.transaction(cost)
	unlocked_slots += 1
	slot_unlocked.emit(unlocked_slots)
	return true

func get_worm_count() -> int:
	return worms.size()

func get_max_slots() -> int:
	return unlocked_slots
