extends Area2D
class_name CombatZone

signal worm_entered_zone(worm: Worm)
signal worm_exited_zone(worm: Worm)
signal worm_died(worm: Worm)
signal worm_removed_from_combat(worm: Worm)
signal combat_activated
signal combat_deactivated

@export var auto_start_combat: bool = true
@export var min_worms_to_start: int = 2

var worms_in_zone: Array[Worm] = []
var combat_active: bool = false

func _ready() -> void:
	add_to_group("combat_zones")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if combat_active:
		_check_dead_worms()
		_assign_targets_to_all()

func _check_dead_worms() -> void:
	var changed = false
	for worm in worms_in_zone.duplicate():
		if not is_instance_valid(worm) or worm.hp <= 0:
			worm_died.emit(worm)
			worms_in_zone.erase(worm)
			changed = true
	
	if changed:
		_check_combat_end()

func _on_body_entered(body: Node2D) -> void:
	if body is Worm and body not in worms_in_zone:
		worms_in_zone.append(body)
		body.in_combat_zone = true
		body.team_id = -1
		worm_entered_zone.emit(body)
		_check_auto_combat()

func _on_body_exited(body: Node2D) -> void:
	if body is Worm:
		worms_in_zone.erase(body)
		body.in_combat_zone = false
		body.team_id = -1
		worm_exited_zone.emit(body)
		_check_combat_end()

func _check_auto_combat() -> void:
	if auto_start_combat and not combat_active:
		if worms_in_zone.size() >= min_worms_to_start:
			activate_combat()

func _check_combat_end() -> void:
	if combat_active:
		var alive_worms = _get_alive_worms()
		if alive_worms.size() < min_worms_to_start:
			deactivate_combat()

func activate_combat() -> void:
	if combat_active:
		return
	combat_active = true
	combat_activated.emit()

func deactivate_combat() -> void:
	if not combat_active:
		return
	combat_active = false
	_stop_all_combats()
	combat_deactivated.emit()

func _assign_targets_to_all() -> void:
	for worm in worms_in_zone:
		if is_instance_valid(worm) and worm.hp > 0:
			if worm.actual_enemy == null or not is_instance_valid(worm.actual_enemy) or worm.actual_enemy.hp <= 0 or worm.actual_enemy == worm:
				var enemy = _find_enemy(worm)
				if enemy:
					worm.enter_combat(enemy)

func _stop_all_combats() -> void:
	for worm in worms_in_zone:
		if is_instance_valid(worm):
			worm.exit_combat()

func remove_worm(worm: Worm) -> void:
	if worm in worms_in_zone:
		worms_in_zone.erase(worm)
		worm.in_combat_zone = false
		worm.exit_combat()
		worm_removed_from_combat.emit(worm)
		_check_combat_end()

func remove_worm_from_combat(worm: Worm) -> void:
	remove_worm(worm)

func _find_enemy(worm: Worm) -> Worm:
	var enemies: Array[Worm] = []
	for other in worms_in_zone:
		if is_instance_valid(other) and other.hp > 0 and other != worm:
			enemies.append(other)
	
	if enemies.is_empty():
		return null
	
	return enemies[randi() % enemies.size()]

func _get_alive_worms() -> Array[Worm]:
	return worms_in_zone.filter(func(w): return is_instance_valid(w) and w.hp > 0)

func get_worms_in_zone() -> Array[Worm]:
	return _get_alive_worms()

func is_worm_in_zone(worm: Worm) -> bool:
	return worm in worms_in_zone

func get_winner() -> Worm:
	var alive = _get_alive_worms()
	if alive.size() == 1:
		return alive[0]
	return null
