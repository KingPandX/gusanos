extends CharacterBody2D
class_name Worm

@export var worm_data : Worm_Data

# Parametros de fisica
@export var max_speed : float = 80
@export var acceleration : float = 3.0
@export var friction : float = 2.0
@export var turn_speed : float = 2.0

# Estado de movimiento
var target_velocity : Vector2 = Vector2.ZERO
var current_velocity : Vector2 = Vector2.ZERO

@onready var change_direction: Timer = $Change_direction
@onready var money: Timer = $Money

# Estadisticas
var hp : float
var actual_enemy : Worm
var in_combat : bool = false

func _ready() -> void:
	hp = worm_data.hp_max
	new_random_velocity()
	change_direction.timeout.connect(change_patrol_dir)
	money.timeout.connect(add_money)

func add_money():
	var money_to_add : int= round(GlobalManager.BASE_MONEY * worm_data.size)
	GlobalManager.add_money(money_to_add)

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
	hp -= amount
	if hp <= 0.0:
		die()

func die() -> void:
	queue_free()

func enter_combat(enemy: Worm) -> void:
	if in_combat:
		return
	actual_enemy = enemy
	$FiniteStateMachine.transition("Combat")
