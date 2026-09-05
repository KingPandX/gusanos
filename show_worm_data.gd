extends Control
class_name Show_Data

var worm_data: Worm_Data = null
var hp = Label.new()
var damage = Label.new()
var rarity = Label.new()
var sizeW = Label.new()
var speed = Label.new()
var attackSPD = Label.new()
var moneySPD = Label.new()
var skills_label = Label.new()

func _ready() -> void:
	$VBoxContainer.add_child(hp)
	$VBoxContainer.add_child(damage)
	$VBoxContainer.add_child(rarity)
	$VBoxContainer.add_child(sizeW)
	$VBoxContainer.add_child(speed)
	$VBoxContainer.add_child(attackSPD)
	$VBoxContainer.add_child(moneySPD)
	$VBoxContainer.add_child(skills_label)

func show_data(_worm_data : Worm_Data):
	worm_data = _worm_data
	show()
	show_worm_data()

func hide_data():
	hide()

func show_worm_data() -> void:
	if worm_data == null:
		return
		
	hp.text = "Vida maxima: " + str(snappedf(worm_data.get_computed_hp_max(), 0.01))
	damage.text = "Daño: " + str(snappedf(worm_data.get_computed_damage(), 0.01))
	rarity.text = "Rareza: " + str(worm_data.rarity)
	sizeW.text = "Tamaño: " + str(snappedf(worm_data.get_computed_size(), 0.01))
	speed.text = "Velocidad: " + str(snappedf(worm_data.get_computed_speed(), 0.01))
	attackSPD.text = "Velocidad ataque: " + str(snappedf(worm_data.get_computed_cooldown_attack(), 0.01))
	moneySPD.text = "Velocidad dinero: " + str(snappedf(worm_data.cooldown_money, 0.01))
	if worm_data.skills.is_empty():
		skills_label.text = "Habilidades: Ninguna"
	else:
		var skill_names: Array[String] = []
		for skill in worm_data.skills:
			skill_names.append(skill.skill_name)
		var text = "Habilidades: " + ", ".join(skill_names)
		if worm_data.stat_multiplier > 1.0:
			text += " | Multiplicador: x%.2f" % worm_data.stat_multiplier
		skills_label.text = text
