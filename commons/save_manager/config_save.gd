extends Resource
class_name ConfigSave

@export var music_volume: float = 1.0
@export var sfx_volume: float = 1.0

const CONFIG_PATH: String = "user://config.tres"

static func save_config(config: ConfigSave) -> void:
	ResourceSaver.save(config, CONFIG_PATH)

static func load_config() -> ConfigSave:
	if not FileAccess.file_exists(CONFIG_PATH):
		return ConfigSave.new()
	return ResourceLoader.load(CONFIG_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as ConfigSave
