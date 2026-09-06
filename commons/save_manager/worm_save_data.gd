extends Resource
class_name WormSaveData

@export var template_path: String = ""
@export var rarity: int = 0
@export var hp_max: float = 100.0
@export var current_hp: float = 100.0
@export var damage: float = 10.0
@export var cooldown_attack: float = 1.0
@export var cooldown_money: float = 10.0
@export var size: float = 1.0
@export var speed: float = 60.0
@export var stat_multiplier: float = 1.0
@export var combat_stacks: int = 0
@export var skill_script_paths: Array[String] = []
@export var area: String = "social"
@export var position: Vector2 = Vector2.ZERO

static func create_from_worm(worm_data: Worm_Data) -> WormSaveData:
	if worm_data == null:
		return null
	var data = WormSaveData.new()

	if worm_data.template:
		data.template_path = worm_data.template.resource_path

	data.rarity = worm_data.rarity as int
	data.hp_max = worm_data.hp_max
	data.current_hp = worm_data.current_hp
	data.damage = worm_data.damage
	data.cooldown_attack = worm_data.cooldown_attack
	data.cooldown_money = worm_data.cooldown_money
	data.size = worm_data.size
	data.speed = worm_data.speed
	data.stat_multiplier = worm_data.stat_multiplier
	data.combat_stacks = worm_data.combat_stacks

	for skill in worm_data.skills:
		if skill:
			var script = skill.get_script()
			if script:
				data.skill_script_paths.append(script.resource_path)

	data.area = Inventory.get_worm_area(worm_data)

	var tree = Engine.get_main_loop() as SceneTree
	if tree:
		for node in tree.get_nodes_in_group("worms"):
			if node is Worm and node.worm_data == worm_data:
				data.position = node.global_position
				break

	return data

func to_worm_data() -> Worm_Data:
	if template_path.is_empty():
		return null
	var template = load(template_path) as WormTemplate
	if template == null:
		return null

	var worm_data = Worm_Data.new()
	worm_data.template = template
	worm_data.rarity = rarity as Rarity.Level
	worm_data.hp_max = hp_max
	worm_data.current_hp = current_hp
	worm_data.damage = damage
	worm_data.cooldown_attack = cooldown_attack
	worm_data.cooldown_money = cooldown_money
	worm_data.size = size
	worm_data.speed = speed
	worm_data.stat_multiplier = stat_multiplier
	worm_data.combat_stacks = combat_stacks

	for path in skill_script_paths:
		var script = load(path) as GDScript
		if script:
			var skill = script.new() as SkillData
			if skill:
				worm_data.skills.append(skill)

	return worm_data
