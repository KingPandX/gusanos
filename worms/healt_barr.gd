extends ProgressBar

@export var color_full: Color = Color.GREEN
@export var color_low: Color = Color.RED

@onready var worm: Worm = $".."

var tween : Tween

func _ready() -> void:
	visible = false
	call_deferred("_init_bar")

func _init_bar() -> void:
	if not is_inside_tree() or not is_instance_valid(worm):
		return
	worm.on_take_damage.connect(_on_take_damage)
	worm.on_hp_changed.connect(_on_update)
	_update()

func _update() -> void:
	if not is_instance_valid(worm) or not is_instance_valid(worm.worm_data):
		return
	var max_hp = worm.worm_data.get_computed_hp_max()
	max_value = max_hp
	value = worm.hp
	_update_color(worm.hp)
	visible = worm.hp < max_hp - 0.1

func _on_take_damage(new_value: float) -> void:
	visible = true
	var max_hp = worm.worm_data.get_computed_hp_max()
	max_value = max_hp
	if tween and tween.is_running():
		tween.kill()
	var target_color := _get_color_for_value(new_value)
	tween = create_tween().set_parallel(true)
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(self, "value", new_value, 0.45)
	tween.tween_property(self, "modulate", target_color, 0.45)

func _on_update(_new_value: float) -> void:
	call_deferred("_update")

func _get_color_for_value(current_val: float) -> Color:
	var health_ratio := clampf(current_val / max_value, 0.0, 1.0)
	return color_low.lerp(color_full, health_ratio)

func _update_color(current_val: float) -> void:
	modulate = _get_color_for_value(current_val)
