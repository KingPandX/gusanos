extends Resource
class_name Worm_Data

@export var template : WormTemplate
@export var rarity : Rarity.Level

@export var hp_max : float
@export var damage : float
@export var cooldown_attack : float
@export var cooldown_money : float
@export var size : float = 1
@export var speed : float = 60

var worm: Worm
