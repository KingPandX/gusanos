extends Area2D

@onready var controller: Worm = $".."

var nearby_worms : Array[Worm] = []

func _on_body_entered(body: Node2D) -> void:
	if body is Worm and body != controller and body not in nearby_worms:
		nearby_worms.append(body)

func _on_body_exited(body: Node2D) -> void:
	if body is Worm:
		nearby_worms.erase(body)

func get_available_enemy() -> Worm:
	for worm in nearby_worms:
		if is_instance_valid(worm) and not worm.in_combat and worm != controller:
			return worm
	return null
