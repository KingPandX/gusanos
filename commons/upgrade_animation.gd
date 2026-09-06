extends Node2D
@onready var gpu_particles_2d: GPUParticles2D = $GPUParticles2D

const NIVEL = preload("uid://dgrlhey0teltf")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	AudioManager.play_sfx(NIVEL,randf_range(0.8,1.2))
	gpu_particles_2d.emitting = true
	gpu_particles_2d.finished.connect(queue_free)
