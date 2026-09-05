extends Node

signal upgrade_purchased(upgrade: UpgradeData)
signal upgrades_changed

var upgrades: Array[UpgradeData] = []

func _ready() -> void:
	_load_upgrades()

func _load_upgrades() -> void:
	var dirs = ["res://assets/upgrades/", "res://resources/upgrades/"]
	for path in dirs:
		var dir = DirAccess.open(path)
		if dir == null:
			continue
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var resource = load(path + file_name)
				if resource is UpgradeData:
					upgrades.append(resource)
			file_name = dir.get_next()
	print("Upgrades loaded: %d" % upgrades.size())

func purchase_upgrade(upgrade: UpgradeData) -> bool:
	if not upgrade.can_upgrade():
		return false
	var cost = upgrade.get_current_cost()
	if not GlobalManager.can_afford(cost):
		return false
	GlobalManager.transaction(cost)
	upgrade.apply()
	upgrade_purchased.emit(upgrade)
	upgrades_changed.emit()
	return true

func get_upgrade(upgrade_name: String) -> UpgradeData:
	for upgrade in upgrades:
		if upgrade.upgrade_name == upgrade_name:
			return upgrade
	return null

func get_purchased_upgrades() -> Array[UpgradeData]:
	var purchased: Array[UpgradeData] = []
	for upgrade in upgrades:
		if upgrade.current_level > 0:
			purchased.append(upgrade)
	return purchased
