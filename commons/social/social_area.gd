extends Control

signal worm_added_to_social(worm: Worm)
signal worm_removed_from_social(worm: Worm)

var social_worms: Array[Worm] = []
var worm_scene: PackedScene = preload("res://worms/worm.tscn")
var worm_drop_scene: PackedScene = preload("res://commons/social/worm_drop.tscn")
var active_drops: Array = []

const BASE_SPAWN_INTERVAL: float = 20.0
const MIN_SPAWN_INTERVAL: float = 3.0
const REDUCTION_PER_LEVEL: float = 2.0
const MAX_DROPS_OFFSET: int = 2

var drop_timer: Timer

func _ready() -> void:
	add_to_group("social_area")
	_setup_drop_timer()
	spawn_worm_drop()

func _setup_drop_timer() -> void:
	drop_timer = Timer.new()
	drop_timer.one_shot = false
	drop_timer.wait_time = _get_spawn_interval()
	drop_timer.timeout.connect(_on_drop_timer_timeout)
	add_child(drop_timer)
	drop_timer.start()

func _get_spawn_interval() -> float:
	var level = PlayerEffects.drop_frequency_level
	return maxf(MIN_SPAWN_INTERVAL, BASE_SPAWN_INTERVAL - (level * REDUCTION_PER_LEVEL))

func _on_drop_timer_timeout() -> void:
	var max_drops = Inventory.unlocked_slots + MAX_DROPS_OFFSET
	if active_drops.size() < max_drops:
		spawn_worm_drop()
	drop_timer.wait_time = _get_spawn_interval()

func spawn_worm_drop() -> void:
	var rarity = Rarity.roll_rarity()
	var drop = worm_drop_scene.instantiate()
	drop.setup(rarity)
	drop.position = _get_random_position()
	drop.drop_collected.connect(_on_drop_collected)
	$WormsContainer.add_child(drop)
	active_drops.append(drop)
	drop.tree_exiting.connect(func(): active_drops.erase(drop))

func _on_drop_collected(_rarity: Rarity.Level) -> void:
	pass

func spawn_social_worm(worm_data: Worm_Data, pos: Vector2 = Vector2.ZERO) -> Worm:
	var worm_instance = worm_scene.instantiate()
	worm_instance.worm_data = worm_data
	worm_instance.area = "social"

	if pos == Vector2.ZERO:
		pos = _get_random_position()

	worm_instance.position = pos
	$WormsContainer.add_child(worm_instance)

	var sprite = worm_instance.get_node("Sprite")
	if sprite:
		var color = Rarity.get_rarity_color(worm_data.rarity)
		sprite.modulate = color

	social_worms.append(worm_instance)
	worm_instance.tree_exiting.connect(_on_worm_removed.bind(worm_instance))
	worm_added_to_social.emit(worm_instance)

	return worm_instance

func remove_social_worm(worm: Worm) -> void:
	if worm in social_worms:
		social_worms.erase(worm)
		worm_removed_from_social.emit(worm)
		worm.queue_free()

func _on_worm_removed(worm: Worm) -> void:
	social_worms.erase(worm)

func _get_random_position() -> Vector2:
	var viewport_size = get_viewport_rect().size
	return Vector2(
		randf_range(50, viewport_size.x - 250),
		randf_range(50, viewport_size.y - 50)
	)

func get_worms_in_social() -> Array[Worm]:
	return social_worms.filter(func(w): return is_instance_valid(w))

func is_point_in_social(point: Vector2) -> bool:
	return get_viewport_rect().has_point(point)
