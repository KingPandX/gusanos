extends Control


var worm_data: Worm_Data = null
var hp = Label.new()
var damage = Label.new()
var rarity = Label.new()
var sizeW = Label.new()
var speed = Label.new()
var attackSPD = Label.new()
var moneySPD = Label.new()

func _ready() -> void:
	$VBoxContainer.add_child(hp)
	$VBoxContainer.add_child(damage)
	$VBoxContainer.add_child(rarity)
	$VBoxContainer.add_child(sizeW)
	$VBoxContainer.add_child(speed)
	$VBoxContainer.add_child(attackSPD)
	$VBoxContainer.add_child(moneySPD)

func show_worm_data() -> void:
	if worm_data == null:
		return
		
	hp.text = "Vida maxima: " + str(worm_data.hp_max)
	damage.text = "Daño: " + str(worm_data.damage)
	rarity.text = "Rareza: " + str(worm_data.rarity)
	sizeW.text = "Tamaño: " + str(worm_data.size)
	speed.text = "Velocidad: " + str(worm_data.speed)
	attackSPD.text = "Velocidad ataque: " + str(worm_data.cooldown_attack)
	moneySPD.text = "Velocidad dinero: " + str(worm_data.cooldown_money)
