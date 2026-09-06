extends Resource
class_name StatRange

@export var hp : Vector2 = Vector2(80, 120)
@export var damage : Vector2 = Vector2(10, 20)
@export var cooldown_attack : Vector2 = Vector2(1.0, 1.5)
@export var cooldown_money : Vector2 = Vector2(8.0, 15.0)
@export var speed : Vector2 = Vector2(50, 70)
@export var size : Vector2 = Vector2(0.8, 1.3)

func roll_stats() -> Dictionary:
	return {
		"hp_max": randf_range(hp.x, hp.y),
		"damage": randf_range(damage.x, damage.y),
		"cooldown_attack": randf_range(cooldown_attack.x, cooldown_attack.y),
		"cooldown_money": randf_range(cooldown_money.x, cooldown_money.y),
		"speed": randf_range(speed.x, speed.y),
		"size": randf_range(size.x, size.y),
	}
