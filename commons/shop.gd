extends Node

static var discount: float = 0.0
static var discount_timer: float = 0.0
static var extra_slots: int = 0

static func apply_discount(value: float, duration: float):
	discount = value
	discount_timer = duration

static func add_extra_slots(amount: int):
	extra_slots += amount

static func get_discount() -> float:
	return discount

static func update(delta: float):
	if discount_timer > 0:
		discount_timer -= delta
		if discount_timer <= 0:
			discount = 0.0
			discount_timer = 0.0
