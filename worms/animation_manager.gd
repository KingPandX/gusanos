extends AnimatedSprite2D

@onready var worm: Worm = $".."

func _process(delta: float) -> void:
	if worm.velocity.x > 0:
		flip_h = true
		offset.x = -worm.worm_data.template.sprite_offset.x
	elif worm.velocity.x < 0:
		flip_h = false
		offset.x = worm.worm_data.template.sprite_offset.x
		
