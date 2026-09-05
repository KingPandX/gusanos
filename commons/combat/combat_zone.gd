extends Area2D
class_name CombatZone

signal worm_entered_zone(worm: Worm)
signal worm_exited_zone(worm: Worm)
signal worm_died(worm: Worm)
signal combat_activated
signal combat_deactivated

@export var auto_start_combat: bool = true
@export var min_worms_to_start: int = 2

var worms_in_zone: Array[Worm] = []
var teams: Dictionary = {}
var combat_active: bool = false
var team_id_counter: int = 0

func _ready() -> void:
	add_to_group("combat_zones")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if combat_active:
		_check_dead_worms()

func _check_dead_worms() -> void:
	var changed = false
	for worm in worms_in_zone.duplicate():
		if not is_instance_valid(worm) or worm.hp <= 0:
			worm_died.emit(worm)
			_remove_worm_from_teams(worm)
			worms_in_zone.erase(worm)
			changed = true
	
	if changed:
		_reassign_teams()
		_check_combat_end()

func _on_body_entered(body: Node2D) -> void:
	if body is Worm and body not in worms_in_zone:
		worms_in_zone.append(body)
		body.in_combat_zone = true
		worm_entered_zone.emit(body)
		_check_auto_combat()

func _on_body_exited(body: Node2D) -> void:
	if body is Worm:
		worms_in_zone.erase(body)
		body.in_combat_zone = false
		worm_exited_zone.emit(body)
		_remove_worm_from_teams(body)
		_check_combat_end()

func _check_auto_combat() -> void:
	if auto_start_combat and not combat_active:
		if worms_in_zone.size() >= min_worms_to_start:
			activate_combat()

func _check_combat_end() -> void:
	if combat_active:
		var alive_worms = worms_in_zone.filter(func(w): return is_instance_valid(w) and w.hp > 0)
		if alive_worms.size() < min_worms_to_start:
			deactivate_combat()

func activate_combat() -> void:
	if combat_active:
		return
	combat_active = true
	_assign_teams()
	_start_all_combats()
	combat_activated.emit()

func deactivate_combat() -> void:
	if not combat_active:
		return
	combat_active = false
	_stop_all_combats()
	combat_deactivated.emit()

func _assign_teams() -> void:
	teams.clear()
	team_id_counter = 0
	
	var alive_worms = worms_in_zone.filter(func(w): return is_instance_valid(w) and w.hp > 0)
	alive_worms.shuffle()
	
	for worm in alive_worms:
		var assigned = false
		
		if team_id_counter > 0 and randf() < 0.3:
			var team_keys = teams.keys()
			var random_team = team_keys[randi() % team_keys.size()]
			teams[random_team].append(worm)
			worm.team_id = random_team
			assigned = true
		
		if not assigned:
			teams[team_id_counter] = [worm]
			worm.team_id = team_id_counter
			team_id_counter += 1

func _reassign_teams() -> void:
	var alive_worms = worms_in_zone.filter(func(w): return is_instance_valid(w) and w.hp > 0)
	if alive_worms.size() < min_worms_to_start:
		return
	
	_assign_teams()
	_start_all_combats()

func _start_all_combats() -> void:
	for worm in worms_in_zone:
		if is_instance_valid(worm) and worm.hp > 0 and not worm.in_combat:
			var enemy = _find_enemy(worm)
			if enemy:
				worm.enter_combat(enemy)

func _stop_all_combats() -> void:
	for worm in worms_in_zone:
		if is_instance_valid(worm):
			worm.exit_combat()

func _find_enemy(worm: Worm) -> Worm:
	var enemies: Array[Worm] = []
	for other in worms_in_zone:
		if is_instance_valid(other) and other.hp > 0 and other != worm and other.team_id != worm.team_id:
			enemies.append(other)
	
	if enemies.is_empty():
		return null
	
	return enemies[randi() % enemies.size()]

func _remove_worm_from_teams(worm: Worm) -> void:
	for team_id in teams:
		teams[team_id].erase(worm)
	if teams.has(worm.team_id) and teams[worm.team_id].is_empty():
		teams.erase(worm.team_id)

func get_worms_in_zone() -> Array[Worm]:
	return worms_in_zone.filter(func(w): return is_instance_valid(w) and w.hp > 0)

func is_worm_in_zone(worm: Worm) -> bool:
	return worm in worms_in_zone
