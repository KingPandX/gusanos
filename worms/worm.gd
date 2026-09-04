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

func _ready() -> void:
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

func _process(delta: float) -> void:
	var speed = current_velocity.length()
	if speed > 5.0:
		bop_timer += delta * bop_speed * (speed / max_speed)
		var bop = sin(bop_timer) * bop_intensity * (speed / max_speed)
		sprite.scale = Vector2(1.0 - bop, 1.0 + bop)
	else:
		sprite.scale = sprite.scale.lerp(Vector2.ONE, delta * 8.0)
		bop_timer = 0.0

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
	set_physics_process(false)
	set_process(false)
	change_direction.stop()
	money.stop()
	target_velocity = Vector2.ZERO
	current_velocity = Vector2.ZERO
	velocity = Vector2.ZERO
	queue_free()


func enter_combat(enemy: Worm) -> void:
	if in_combat:
		return
	actual_enemy = enemy
	$FiniteStateMachine.transition("Combat")
