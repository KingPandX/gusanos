extends Sprite2D

@onready var worm: Worm = $".."

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if worm.velocity.x > 0:
		flip_h = false
	elif worm.velocity.x < 0:
		flip_h = true
		
