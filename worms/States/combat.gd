extends State

@onready var worm: Worm = $"../.."
@onready var detector: Area2D = $"../../worm_detector"

const ATTACK_RANGE : float = 70.0
var attack_cooldown : float = 0.0

func enter():
	attack_cooldown = 0.0
	worm.in_combat = true
	worm.sprite.play("idle")
	if worm.actual_enemy != null and is_instance_valid(worm.actual_enemy):
		worm.actual_enemy.enter_combat(worm)

func exit():
	worm.in_combat = false
	worm.actual_enemy = null
	worm.hp = worm.worm_data.hp_max

func physics_update(delta: float):
	if worm.actual_enemy == null or not is_instance_valid(worm.actual_enemy):
		var enemy = detector.get_available_enemy()
		if enemy:
			worm.actual_enemy = enemy
		else:
			transition("Patrol")
			return
	
	if worm.actual_enemy.actual_enemy != worm:
		var enemy = detector.get_available_enemy()
		if enemy and enemy != worm.actual_enemy:
			worm.actual_enemy.enter_combat(worm)
		else:
			transition("Patrol")
			return
	
	var distance = worm.global_position.distance_to(worm.actual_enemy.global_position)
	var direction_to_enemy = (worm.actual_enemy.global_position - worm.global_position).normalized()
	
	if distance > ATTACK_RANGE:
		worm.target_velocity = direction_to_enemy * worm.max_speed
	else:
		worm.target_velocity = Vector2.ZERO
		attack_cooldown -= delta
		if attack_cooldown <= 0.0:
			worm.sprite.play("attack")
			worm.actual_enemy.take_damage(worm.worm_data.damage)
			attack_cooldown = worm.worm_data.cooldown_attack
	
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
