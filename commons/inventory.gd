extends Node

signal inventory_changed
signal slot_unlocked(new_max: int)
signal worm_area_changed(worm_data: Worm_Data, new_area: String)

var worms : Array[Worm_Data] = []
var worm_areas: Dictionary = {}
var max_slots : int = 3
var unlocked_slots : int = 3
var templates : Array[WormTemplate] = []

const TEMPLATE_PATHS: Array[String] = [
	"res://assets/worms_tamplets/glasses_worm.tres",
	"res://assets/worms_tamplets/golden_worm.tres",
	"res://assets/worms_tamplets/ice_worm.tres",
	"res://assets/worms_tamplets/marine_worm.tres",
	"res://assets/worms_tamplets/obsidian_worm.tres",
	"res://assets/worms_tamplets/tifany_worm.tres",
	"res://assets/worms_tamplets/tooth_worm.tres",
	"res://assets/worms_tamplets/useles_worm.tres",
]

const TEMPLATES = [
	preload("res://assets/worms_tamplets/glasses_worm.tres"),
	preload("res://assets/worms_tamplets/golden_worm.tres"),
	preload("res://assets/worms_tamplets/ice_worm.tres"),
	preload("res://assets/worms_tamplets/marine_worm.tres"),
	preload("res://assets/worms_tamplets/obsidian_worm.tres"),
	preload("res://assets/worms_tamplets/tifany_worm.tres"),
	preload("res://assets/worms_tamplets/tooth_worm.tres"),
	preload("res://assets/worms_tamplets/useles_worm.tres"),
]

func _ready() -> void:
	_load_templates()

func _load_templates() -> void:
	templates.clear()
	for resource in TEMPLATES:
		if resource is WormTemplate:
			templates.append(resource)
	# Fallback: cargar dinámicamente en caso de rutas personalizadas
	_load_templates_from_dirs(["res://assets/worms_tamplets/", "res://resources/templates/"])
	print("Templates loaded: %d" % templates.size())

func _load_templates_from_dirs(dirs: Array) -> void:
	for path in dirs:
		var dir = DirAccess.open(path)
		if dir == null:
			continue
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var resource = load(path + file_name)
				if resource is WormTemplate and not templates.has(resource):
					templates.append(resource)
			file_name = dir.get_next()

func add_worm(worm: Worm_Data, area: String = "social") -> bool:
	if worms.size() >= unlocked_slots:
		return false
	worms.append(worm)
	worm_areas[worm] = area
	inventory_changed.emit()
	return true

func remove_worm(index: int) -> Worm_Data:
	if index < 0 or index >= worms.size():
		return null
	var worm = worms[index]
	worms.remove_at(index)
	worm_areas.erase(worm)
	inventory_changed.emit()
	return worm

func remove_worm_data(worm_data: Worm_Data) -> void:
	if worm_data in worms:
		worms.erase(worm_data)
		worm_areas.erase(worm_data)
		inventory_changed.emit()

func move_worm(worm_data: Worm_Data, new_area: String) -> void:
	if worm_data in worm_areas:
		worm_areas[worm_data] = new_area
		worm_area_changed.emit(worm_data, new_area)

func get_worm_area(worm_data: Worm_Data) -> String:
	return worm_areas.get(worm_data, "social")

func get_worms_in_area(area: String) -> Array[Worm_Data]:
	var result: Array[Worm_Data] = []
	for worm in worms:
		if worm_areas.get(worm, "social") == area:
			result.append(worm)
	return result

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

func unlock_extra_slots(amount: int = 1) -> void:
	unlocked_slots += amount
	slot_unlocked.emit(unlocked_slots)
	inventory_changed.emit()

func get_worm_count() -> int:
	return worms.size()

func get_max_slots() -> int:
	return unlocked_slots
