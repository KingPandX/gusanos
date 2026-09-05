extends ProgressBar

@export var color_full: Color = Color.GREEN   # Color A (Vida llena)
@export var color_low: Color = Color.RED      # Color B (Vida baja)

@onready var worm: Worm = $".."

var tween : Tween

func _ready() -> void:
	max_value = worm.worm_data.hp_max
	value = worm.hp
	
	if value > max_value - 0.1:
		visible = true
	else:
		visible = false
	_update_color(value)
	
	worm.on_take_damage.connect(_on_take_damage)

func _on_take_damage(new_value : float) -> void:
	visible = new_value < max_value
	
	if tween and tween.is_running():
		tween.kill()
		
	var target_color := _get_color_for_value(new_value)
	
	tween = create_tween().set_parallel(true)
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	
	# Anima el valor de la barra y el modulado de color
	tween.tween_property(self, "value", new_value, 0.45)
	tween.tween_property(self, "modulate", target_color, 0.45)

func _get_color_for_value(current_val: float) -> Color:
	var health_ratio := clampf(current_val / max_value, 0.0, 1.0)
	return color_low.lerp(color_full, health_ratio)

func _update_color(current_val: float) -> void:
	modulate = _get_color_for_value(current_val)
