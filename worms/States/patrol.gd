extends State

@onready var worm: Worm = $"../.."
@onready var detector: Area2D = $"../../worm_detector"

func enter():
	worm.sprite.play("idle")

func physics_update(delta: float):
	if not worm.in_combat_zone:
		if worm.actual_enemy == null or not is_instance_valid(worm.actual_enemy):
			var enemy = detector.get_available_enemy()
			if enemy and enemy.team_id != worm.team_id:
				worm.actual_enemy = enemy
		
		if worm.actual_enemy != null and not worm.actual_enemy.in_combat and worm.actual_enemy.team_id != worm.team_id:
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
