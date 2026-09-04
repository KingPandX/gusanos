extends State

@onready var worm: Worm = $"../.."

func physics_update(delta: float):
	if worm.actual_enemy != null and is_instance_valid(worm.actual_enemy):
		transition("Combat")
		return
	
	worm.current_velocity = worm.current_velocity.lerp(
		worm.target_velocity,
		worm.acceleration * delta
	)
	
	if worm.target_velocity == Vector2.ZERO:
		worm.current_velocity = worm.current_velocity.lerp(
			Vector2.ZERO,
			worm.friction * delta
		)
	
	worm.velocity = worm.current_velocity
	worm.move_and_slide()
