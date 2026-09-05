extends State

@onready var worm: Worm = $"../.."
const HIT = preload("uid://ckxcjiic847q1")


const ATTACK_RANGE : float = 70.0
var attack_cooldown : float = 0.0
var ramp_timer : float = 0.0
const RAMP_INTERVAL : float = 1.0

func enter():
	attack_cooldown = 0.0
	ramp_timer = 0.0
	worm.in_combat = true
	for skill in worm.worm_data.skills:
		skill.on_combat_start(worm)
	worm.sprite.play("idle")

func exit():
	worm.in_combat = false
	worm.actual_enemy = null
	for skill in worm.worm_data.skills:
		skill.on_combat_end(worm)
	if not worm.in_combat_zone:
		worm.hp = worm.worm_data.get_computed_hp_max()

func physics_update(delta: float):
	if worm.in_combat_zone:
		var combat_zone = _find_combat_zone()
		if combat_zone and not combat_zone.combat_active:
			transition("Patrol")
			return
	
	if worm.actual_enemy == null or not is_instance_valid(worm.actual_enemy) or worm.actual_enemy.hp <= 0:
		transition("Patrol")
		return
	
	var enemy = worm.actual_enemy
	
	ramp_timer += delta
	if ramp_timer >= RAMP_INTERVAL:
		ramp_timer -= RAMP_INTERVAL
		for skill in worm.worm_data.skills:
			skill.on_combat_tick(worm)
	
	var distance = worm.global_position.distance_to(enemy.global_position)
	var direction_to_enemy = (enemy.global_position - worm.global_position).normalized()
	
	if distance > ATTACK_RANGE:
		worm.target_velocity = direction_to_enemy * worm.max_speed
	else:
		worm.target_velocity = Vector2.ZERO
		attack_cooldown -= delta
		if attack_cooldown <= 0.0:
			worm.sprite.play("attack")
			var base_damage = worm.worm_data.get_computed_damage()
			var bonus := 0.0
			for skill in worm.worm_data.skills:
				bonus += skill.get_damage_multiplier(worm)
			var raw_damage = base_damage * (1.0 + bonus)
			
			var reduction := 0.0
			for skill in enemy.worm_data.skills:
				reduction += skill.get_incoming_damage_reduction(enemy, worm, raw_damage)
			var final_damage = raw_damage * (1.0 - reduction)
			
			enemy.take_damage(final_damage, worm)
			
			var slow := 0.0
			for skill in enemy.worm_data.skills:
				slow += skill.get_attack_cooldown_slow(enemy)
			attack_cooldown = worm.worm_data.get_computed_cooldown_attack() * (1.0 + slow)
			
			for skill in worm.worm_data.skills:
				skill.on_deal_damage(worm, final_damage)
			AudioManager.play_sfx(HIT, randf_range(0.4,0.8))
	
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
