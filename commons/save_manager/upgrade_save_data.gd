extends Resource
class_name UpgradeSaveData

static func create_from_game() -> Dictionary:
	var result: Dictionary = {}
	for upgrade in UpgradeManager.upgrades:
		if upgrade.current_level > 0:
			result[upgrade.upgrade_name] = upgrade.current_level
	return result
