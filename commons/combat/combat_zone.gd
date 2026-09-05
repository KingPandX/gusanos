extends Area2D
class_name CombatZone

signal worm_entered_zone(worm: Worm)
signal worm_exited_zone(worm: Worm)
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
		var alive_teams = _get_alive_teams()
		if alive_teams.size() <= 1:
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
	
	var shuffled = worms_in_zone.duplicate()
	shuffled.shuffle()
	
	for worm in shuffled:
		if not is_instance_valid(worm):
			continue
		
		var assigned = false
		
		if team_id_counter > 0 and randf() < 0.3:
			var random_team = teams.keys()[randi() % teams.keys().size()]
			teams[random_team].append(worm)
			worm.team_id = random_team
			assigned = true
		
		if not assigned:
			teams[team_id_counter] = [worm]
			worm.team_id = team_id_counter
			team_id_counter += 1

func _start_all_combats() -> void:
	for worm in worms_in_zone:
		if is_instance_valid(worm) and not worm.in_combat:
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
		if is_instance_valid(other) and other != worm and other.team_id != worm.team_id:
			enemies.append(other)
	
	if enemies.is_empty():
		return null
	
	return enemies[randi() % enemies.size()]

func _remove_worm_from_teams(worm: Worm) -> void:
	for team_id in teams:
		teams[team_id].erase(worm)
		if teams[team_id].is_empty():
			teams.erase(team_id)

func _get_alive_teams() -> Array:
	var alive_teams: Array = []
	for team_id in teams:
		var alive_worms: Array = []
		for worm in teams[team_id]:
			if is_instance_valid(worm) and worm.hp > 0:
				alive_worms.append(worm)
		if not alive_worms.is_empty():
			alive_teams.append(team_id)
	return alive_teams

func get_worms_in_zone() -> Array[Worm]:
	return worms_in_zone.filter(func(w): return is_instance_valid(w))

func is_worm_in_zone(worm: Worm) -> bool:
	return worm in worms_in_zone
