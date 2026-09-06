extends Node

signal shop_renewed
signal timer_updated(time_left: float)

static var discount: float = 0.0
static var discount_timer: float = 0.0
static var extra_slots: int = 0

static var all_items: Array[ItemData] = []
static var available_items: Array[ItemData] = []
static var item_stock: Dictionary = {}
static var renew_cost: int = 50
static var renew_count: int = 0
static var auto_renew_time: float = 300.0
static var auto_renew_timer: float = 300.0
static var items_loaded: bool = false

static func _load_all_items() -> void:
	if items_loaded:
		return
	all_items.clear()
	var dir = DirAccess.open("res://assets/items/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var resource = load("res://assets/items/" + file_name)
				if resource is ItemData:
					all_items.append(resource)
			file_name = dir.get_next()
	items_loaded = true

static func rotate_items(count: int = 4) -> Array[ItemData]:
	if all_items.is_empty():
		_load_all_items()
	available_items.clear()
	item_stock.clear()
	var pool = all_items.duplicate()
	pool.shuffle()
	for i in range(min(count, pool.size())):
		available_items.append(pool[i])
		item_stock[pool[i].item_name] = randi_range(1, 3)
	return available_items

static func get_available_items() -> Array[ItemData]:
	return available_items

static func apply_discount(value: float, duration: float):
	discount = value
	discount_timer = duration

static func add_extra_slots(amount: int):
	extra_slots += amount

static func get_discount() -> float:
	return discount

func renew_shop() -> void:
	renew_count += 1
	renew_cost = 50 * int(pow(2, renew_count))
	auto_renew_timer = auto_renew_time
	rotate_items()
	shop_renewed.emit()

func auto_renew_shop() -> void:
	renew_count = 0
	renew_cost = 50
	auto_renew_timer = auto_renew_time
	rotate_items()
	shop_renewed.emit()

static func get_renew_cost() -> int:
	return renew_cost

static func get_time_left() -> float:
	return auto_renew_timer

func update(delta: float):
	if discount_timer > 0:
		discount_timer -= delta
		if discount_timer <= 0:
			discount = 0.0
			discount_timer = 0.0
	if auto_renew_timer > 0:
		auto_renew_timer -= delta
		timer_updated.emit(auto_renew_timer)
		if auto_renew_timer <= 0:
			auto_renew_shop()
