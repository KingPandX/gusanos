extends Area2D

@onready var controller: Worm = $".."

func _on_body_entered(body: Node2D) -> void:
	if body is Worm and not body.in_combat and body != controller:
		controller.actual_enemy = body

func _on_body_exited(body: Node2D) -> void:
	if body is Worm and controller.actual_enemy == body:
		controller.actual_enemy = null
