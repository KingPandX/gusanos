extends Node

const SFX_POOL_SIZE := 20

var _music_player: AudioStreamPlayer
var _music_player_xfade: AudioStreamPlayer
var _current_music: MusicData
var _music_tween: Tween
var _active_tween: Tween

var _sfx_pool: Array[AudioStreamPlayer]
var _sfx_active: Dictionary = {}
var _sfx_last_played: Dictionary = {}
var _sfx_streams: Dictionary = {}

var _looped_players: Dictionary = {}
var _next_loop_id: int = 0
var _music_positions: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_init_music_players()
	_init_sfx_pool()
	_ensure_buses()
	_apply_saved_volumes()

func _apply_saved_volumes() -> void:
	var config = ConfigSave.load_config()
	var music_idx = AudioServer.get_bus_index("Music")
	if music_idx >= 0:
		AudioServer.set_bus_volume_db(music_idx, linear_to_db(config.music_volume))
	var sfx_idx = AudioServer.get_bus_index("SFX")
	if sfx_idx >= 0:
		AudioServer.set_bus_volume_db(sfx_idx, linear_to_db(config.sfx_volume))

func _init_music_players() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = &"Music"
	add_child(_music_player)

	_music_player_xfade = AudioStreamPlayer.new()
	_music_player_xfade.bus = &"Music"
	add_child(_music_player_xfade)

func _init_sfx_pool() -> void:
	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = &"SFX"
		add_child(player)
		_sfx_pool.append(player)

func _ensure_buses() -> void:
	if AudioServer.get_bus_index("Music") == -1:
		var idx := AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, "Music")
		AudioServer.set_bus_send(idx, "Master")
	if AudioServer.get_bus_index("SFX") == -1:
		var idx := AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, "SFX")
		AudioServer.set_bus_send(idx, "Master")

# ── Música ──────────────────────────────────────────────────────

func play_music(track: MusicData, fade_in: float = -1.0) -> void:
	if _current_music == track and _music_player.playing:
		return
	_save_persistent_position()
	var duration := track.default_fade_in if fade_in < 0.0 else fade_in
	_stop_active_tween()
	_current_music = track
	_music_player.stream = track.stream
	if track.loop or track.persistent:
		_music_player.finished.connect(_on_music_finished, CONNECT_ONE_SHOT)
	_music_player.play()
	if track.persistent and _music_positions.has(track):
		_music_player.seek(_music_positions[track])
	if duration > 0.0:
		_music_tween = create_tween()
		_music_tween.tween_property(_music_player, "volume_db", 0.0, duration).from(-80.0)
	else:
		_music_player.volume_db = 0.0

func play_music_abrupt(track: MusicData) -> void:
	_save_persistent_position()
	_stop_active_tween()
	_current_music = track
	_music_player.stream = track.stream
	_music_player.volume_db = 0.0
	if track.loop or track.persistent:
		_music_player.finished.connect(_on_music_finished, CONNECT_ONE_SHOT)
	_music_player.play()
	if track.persistent and _music_positions.has(track):
		_music_player.seek(_music_positions[track])

func stop_music(fade_out: float = -1.0) -> void:
	if not _music_player.playing:
		return
	_save_persistent_position()
	var duration := _current_music.default_fade_out if fade_out < 0.0 and _current_music else fade_out
	_stop_active_tween()
	if duration > 0.0:
		_music_tween = create_tween()
		_music_tween.tween_property(_music_player, "volume_db", -80.0, duration)
		_music_tween.tween_callback(_on_music_stopped)
	else:
		stop_music_abrupt()

func stop_music_abrupt() -> void:
	_save_persistent_position()
	_stop_active_tween()
	_music_player.stop()
	_music_player_xfade.stop()
	_current_music = null

func change_music(new_track: MusicData, crossfade: float = -1.0) -> void:
	if _current_music == new_track and _music_player.playing:
		return
	_save_persistent_position()
	var duration := crossfade if crossfade >= 0.0 else 1.0
	if not _music_player.playing:
		play_music(new_track, duration)
		return
	_stop_active_tween()
	_music_player_xfade.stream = new_track.stream
	_music_player_xfade.volume_db = -80.0
	if new_track.loop or new_track.persistent:
		_music_player_xfade.finished.connect(_on_xfade_finished.bind(new_track), CONNECT_ONE_SHOT)
	_music_player_xfade.play()
	if new_track.persistent and _music_positions.has(new_track):
		_music_player_xfade.seek(_music_positions[new_track])
	_music_tween = create_tween().set_parallel(true)
	_music_tween.tween_property(_music_player, "volume_db", -80.0, duration)
	_music_tween.tween_property(_music_player_xfade, "volume_db", 0.0, duration).from(-80.0)
	_music_tween.chain().tween_callback(_on_crossfade_done.bind(new_track))

func is_music_playing() -> bool:
	return _music_player.playing or _music_player_xfade.playing

func get_current_music() -> MusicData:
	return _current_music

# ── Efectos de Sonido ───────────────────────────────────────────

func play_sfx(sfx_data: SFXData, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	if not sfx_data or not sfx_data.stream:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if sfx_data.cooldown > 0.0 and _sfx_last_played.has(sfx_data):
		if now - _sfx_last_played[sfx_data] < sfx_data.cooldown:
			return
	var active_count := _count_active(sfx_data)
	if active_count >= sfx_data.max_instances:
		_kill_oldest(sfx_data)
	_sfx_last_played[sfx_data] = now
	var player := _get_free_player()
	if not player:
		return
	player.stream = sfx_data.stream
	player.pitch_scale = pitch * sfx_data.default_pitch
	player.volume_db = volume_db
	player.bus = sfx_data.bus
	player.play()
	if not _sfx_streams.has(sfx_data):
		_sfx_streams[sfx_data] = []
	_sfx_streams[sfx_data].append(player)
	player.finished.connect(_on_sfx_finished.bind(sfx_data, player), CONNECT_ONE_SHOT)

func _count_active(sfx_data: SFXData) -> int:
	if not _sfx_streams.has(sfx_data):
		return 0
	return _sfx_streams[sfx_data].size()

func _get_free_player() -> AudioStreamPlayer:
	for player in _sfx_pool:
		if not player.playing:
			return player
	return null

func _kill_oldest(sfx_data: SFXData) -> void:
	if _sfx_streams.has(sfx_data) and _sfx_streams[sfx_data].size() > 0:
		var oldest: AudioStreamPlayer = _sfx_streams[sfx_data].pop_front()
		if oldest and oldest.playing:
			oldest.stop()
			oldest.finished.emit()

func create_sfx_looped(sfx_data: SFXData, volume_db: float = 0.0) -> int:
	if not sfx_data or not sfx_data.stream:
		return -1
	var player := AudioStreamPlayer.new()
	var looped_stream = sfx_data.stream.duplicate()
	if looped_stream is AudioStreamWAV:
		looped_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	else:
		looped_stream.loop = true
	player.stream = looped_stream
	player.bus = sfx_data.bus
	player.volume_db = volume_db
	player.pitch_scale = sfx_data.default_pitch
	add_child(player)
	var id := _next_loop_id
	_next_loop_id += 1
	_looped_players[id] = player
	return id

func play_sfx_looped(id: int) -> void:
	if _looped_players.has(id):
		var player: AudioStreamPlayer = _looped_players[id]
		if is_instance_valid(player):
			player.play()

func stop_sfx_looped(id: int) -> void:
	if _looped_players.has(id):
		var player: AudioStreamPlayer = _looped_players[id]
		if is_instance_valid(player):
			player.stop()

func free_sfx_looped(id: int) -> void:
	if _looped_players.has(id):
		var player: AudioStreamPlayer = _looped_players[id]
		if is_instance_valid(player):
			player.stop()
			player.queue_free()
		_looped_players.erase(id)

func set_sfx_looped_pitch(id: int, pitch: float) -> void:
	if _looped_players.has(id):
		var player: AudioStreamPlayer = _looped_players[id]
		if is_instance_valid(player):
			player.pitch_scale = pitch

func is_sfx_looped_playing(id: int) -> bool:
	if _looped_players.has(id):
		var player: AudioStreamPlayer = _looped_players[id]
		if is_instance_valid(player):
			return player.playing
	return false

func _on_sfx_finished(sfx_data: SFXData, player: AudioStreamPlayer) -> void:
	if _sfx_streams.has(sfx_data):
		_sfx_streams[sfx_data].erase(player)

# ── Helpers ─────────────────────────────────────────────────────

func _stop_active_tween() -> void:
	if _music_tween and _music_tween.is_valid():
		_music_tween.kill()
	_music_tween = null

func _save_persistent_position() -> void:
	if _current_music and _current_music.persistent and _music_player.playing:
		_music_positions[_current_music] = _music_player.get_playback_position()

func _on_music_finished() -> void:
	if _current_music:
		if _current_music.loop:
			_music_player.play()
		if _current_music.persistent:
			_music_positions.erase(_current_music)

func _on_xfade_finished(track: MusicData = null) -> void:
	var finished_track := track if track else _current_music
	if finished_track:
		if finished_track.loop:
			_music_player_xfade.play()
		if finished_track.persistent:
			_music_positions.erase(finished_track)

func _on_crossfade_done(new_track: MusicData) -> void:
	_music_player.stop()
	var temp := _music_player
	_music_player = _music_player_xfade
	_music_player_xfade = temp
	_current_music = new_track

func _on_music_stopped() -> void:
	_current_music = null
