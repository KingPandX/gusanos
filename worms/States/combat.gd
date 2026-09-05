extends State

@onready var worm: Worm = $"../.."

const ATTACK_RANGE : float = 70.0
var attack_cooldown : float = 0.0

func enter():
	attack_cooldown = 0.0
	worm.in_combat = true
	worm.sprite.play("idle")

func exit():
	worm.in_combat = false
	worm.actual_enemy = null
	if not worm.in_combat_zone:
		worm.hp = worm.worm_data.hp_max

func physics_update(delta: float):
	if worm.in_combat_zone:
		var combat_zone = _find_combat_zone()
		if combat_zone and not combat_zone.combat_active:
			transition("Patrol")
			return
	
	if worm.actual_enemy == null or not is_instance_valid(worm.actual_enemy) or worm.actual_enemy.hp <= 0:
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

func _find_combat_zone() -> CombatZone:
	var zones = get_tree().get_nodes_in_group("combat_zones")
	for zone in zones:
		if zone is CombatZone and zone.is_worm_in_zone(worm):
			return zone
	return null
