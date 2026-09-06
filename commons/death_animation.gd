extends Node2D

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var smoke: GPUParticles2D = $Smoke
@onready var stars: GPUParticles2D = $Stars

func _ready() -> void:
	sprite.scale = Vector2(0, 0)
	smoke.emitting = true
	stars.emitting = true

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(sprite, "scale", Vector2(1, 1), 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	await tween.finished

	sprite.play("default")
	await sprite.animation_finished

	var fade_tween := create_tween()
	fade_tween.tween_property(sprite, "scale", Vector2(0, 0), 0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	await fade_tween.finished

	queue_free()
