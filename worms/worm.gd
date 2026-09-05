extends CharacterBody2D
class_name Worm

@export var worm_data : Worm_Data

# Parametros de fisica
@export var max_speed : float = 80
@export var acceleration : float = 3.0
@export var friction : float = 2.0
@export var turn_speed : float = 2.0

# Bop
@export var bop_intensity : float = 0.15
@export var bop_speed : float = 8.0
var bop_timer : float = 0.0

# Estado de movimiento
var target_velocity : Vector2 = Vector2.ZERO
var current_velocity : Vector2 = Vector2.ZERO

@onready var change_direction: Timer = $Change_direction
@onready var money: Timer = $Money

var _sprite: AnimatedSprite2D
var sprite: AnimatedSprite2D:
	get:
		if _sprite == null:
			_sprite = $Sprite
		return _sprite

# Estadisticas
var hp : float
var actual_enemy : Worm
var in_combat : bool = false
var in_combat_zone : bool = false
var team_id : int = -1
var area: String = "social"

# Drag and drop
var is_being_dragged: bool = false
var drag_preview: Control = null

# Efectos activos
var active_effects: Array[Dictionary] = []

func _ready() -> void:
	add_to_group("worms")
	hp = worm_data.hp_max
	max_speed = worm_data.speed
	scale = Vector2.ONE * worm_data.size
	if worm_data.template and worm_data.template.sprite_frames:
		sprite.sprite_frames = worm_data.template.sprite_frames
		sprite.offset = Vector2(worm_data.template.sprite_offset.x, worm_data.template.sprite_offset.y)
	new_random_velocity()
	change_direction.timeout.connect(change_patrol_dir)
	money.timeout.connect(add_money)
	money.wait_time = worm_data.cooldown_money
	worm_data.worm = self 

func _process(delta: float) -> void:
	show_Data()
	if is_being_dragged:
		return
	_update_effects(delta)
	var speed = current_velocity.length()
	if speed > 5.0:
		bop_timer += delta * bop_speed * (speed / max_speed)
		var bop = sin(bop_timer) * bop_intensity * (speed / max_speed)
		sprite.scale = Vector2(1.0 - bop, 1.0 + bop)
	else:
		sprite.scale = sprite.scale.lerp(Vector2.ONE, delta * 8.0)
		bop_timer = 0.0
		
func show_Data() -> void:
	if !is_being_dragged:
		print("entrando")
		$ShowWormData.worm_data = worm_data
		$ShowWormData.show_worm_data()
		$ShowWormData.visible = true
	else:
		$ShowWormData.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_on_click_start()

func _on_click_start() -> void:
	if area != "social":
		return
	if DragManager.is_dragging:
		return
	var mouse_pos = get_global_mouse_position()
	var distance = global_position.distance_to(mouse_pos)
	if distance < 50.0:
		_start_drag()

func _start_drag() -> void:
	if DragManager.is_dragging:
		return
	is_being_dragged = true
	DragManager.start_drag(worm_data, DragManager.DragSource.SOCIAL)
	_create_drag_preview()
	visible = false
	set_physics_process(false)
	set_process(false)
	change_direction.stop()
	


func _create_drag_preview() -> void:
	var preview_scene = preload("res://commons/ui/drag_preview.gd")
	drag_preview = Control.new()
	drag_preview.set_script(preview_scene)
	drag_preview.setup(worm_data)
	get_tree().current_scene.add_child(drag_preview)
	DragManager.set_preview(drag_preview)

func _exit_tree() -> void:
	if drag_preview and is_instance_valid(drag_preview):
		drag_preview.queue_free()

func _update_effects(delta: float):
	var i = active_effects.size() - 1
	while i >= 0:
		var effect = active_effects[i]
		effect.timer -= delta
		if effect.timer <= 0:
			active_effects.remove_at(i)
		i -= 1

func add_effect(effect_type: String, value: float, duration: float):
	for effect in active_effects:
		if effect.type == effect_type:
			effect.value = max(effect.value, value)
			effect.timer = max(effect.timer, duration)
			return
	active_effects.append({"type": effect_type, "value": value, "timer": duration})

func remove_effect(effect_type: String):
	for i in range(active_effects.size()):
		if active_effects[i].type == effect_type:
			active_effects.remove_at(i)
			return

func has_effect(effect_type: String) -> bool:
	for effect in active_effects:
		if effect.type == effect_type:
			return true
	return false

func get_effect_value(effect_type: String) -> float:
	for effect in active_effects:
		if effect.type == effect_type:
			return effect.value
	return 0.0

var coin_scene: PackedScene = preload("res://commons/coins/coin.tscn")

func add_money():
	if in_combat_zone:
		return
	var coin_value = round(GlobalManager.BASE_MONEY * worm_data.size)
	var coin = coin_scene.instantiate()
	coin.value = coin_value
	coin.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
	get_parent().add_child(coin)

func change_patrol_dir():
	if randf() < 0.3:
		target_velocity = Vector2.ZERO
	else:
		new_random_velocity()
	change_direction.wait_time = randf_range(0.5, 4)

func new_random_velocity() -> void:
	var new_speed = randf_range(30, max_speed)
	var new_dir = Vector2.from_angle(deg_to_rad(randf_range(0, 360)))
	target_velocity = new_dir * new_speed

func take_damage(amount: float) -> void:
	if has_effect("shield"):
		var shield_value = get_effect_value("shield")
		if shield_value >= amount:
			for effect in active_effects:
				if effect.type == "shield":
					effect.value -= amount
					if effect.value <= 0:
						remove_effect("shield")
					return
		else:
			amount -= shield_value
			remove_effect("shield")
	hp -= amount
	if hp <= 0.0:
		die()

func die() -> void:
	set_physics_process(false)
	set_process(false)
	change_direction.stop()
	money.stop()
	target_velocity = Vector2.ZERO
	current_velocity = Vector2.ZERO
	velocity = Vector2.ZERO
	if area == "combat":
		Inventory.remove_worm_data(worm_data)
	queue_free()

func enter_combat(enemy: Worm) -> void:
	if in_combat:
		return
	actual_enemy = enemy
	$FiniteStateMachine.transition("Combat")

func exit_combat() -> void:
	if not in_combat:
		return
	$FiniteStateMachine.transition("Patrol")
