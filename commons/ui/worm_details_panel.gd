extends Control
class_name WormDetailsPanel

signal panel_closed

@onready var bg: ColorRect = $BG
@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/VBox/Header/Title
@onready var close_btn: Button = $Panel/VBox/Header/CloseBtn
@onready var scroll: ScrollContainer = $Panel/VBox/Scroll
@onready var worm_list: VBoxContainer = $Panel/VBox/Scroll/WormList

func _ready() -> void:
	bg.gui_input.connect(_on_bg_input)
	close_btn.pressed.connect(_close)
	visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed() -> void:
	if visible:
		_refresh_list()

func open() -> void:
	visible = true
	_refresh_list()

func _close() -> void:
	visible = false
	panel_closed.emit()

func _on_bg_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_close()

func _refresh_list() -> void:
	for child in worm_list.get_children():
		child.queue_free()

	if Inventory.worms.is_empty():
		var label = Label.new()
		label.text = "No hay gusanos en el inventario"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 14)
		worm_list.add_child(label)
		return

	for worm_data in Inventory.worms:
		var card = _build_worm_card(worm_data)
		worm_list.add_child(card)

func _build_worm_card(worm_data: Worm_Data) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 120)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.17, 0.22, 0.95)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", style)

	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 6)
	card.add_child(main_vbox)

	var top_row = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 12)
	main_vbox.add_child(top_row)

	var sprite_container = Control.new()
	sprite_container.custom_minimum_size = Vector2(64, 64)
	top_row.add_child(sprite_container)

	if worm_data.template and worm_data.template.sprite_frames:
		var sprite = AnimatedSprite2D.new()
		sprite.sprite_frames = worm_data.template.sprite_frames
		sprite.offset = Vector2(worm_data.template.sprite_offset.x, worm_data.template.sprite_offset.y)
		sprite.scale = Vector2.ONE * worm_data.get_computed_size() * 0.8
		sprite.play("default")
		sprite.position = Vector2(32, 32)
		sprite_container.add_child(sprite)

	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(info)

	var name_hbox = HBoxContainer.new()
	info.add_child(name_hbox)

	var rarity_color = Rarity.get_rarity_color(worm_data.rarity)
	var name_label = Label.new()
	name_label.text = worm_data.template.worm_name if worm_data.template else "Gusano"
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", rarity_color)
	name_hbox.add_child(name_label)

	var rarity_label = Label.new()
	rarity_label.text = "[%s]" % Rarity.get_rarity_name(worm_data.rarity)
	rarity_label.add_theme_font_size_override("font_size", 12)
	rarity_label.add_theme_color_override("font_color", rarity_color)
	name_hbox.add_child(rarity_label)

	var stats_grid = HBoxContainer.new()
	stats_grid.add_theme_constant_override("separation", 16)
	info.add_child(stats_grid)

	var hp_label = Label.new()
	hp_label.text = "HP: %.0f" % worm_data.get_computed_hp_max()
	hp_label.add_theme_font_size_override("font_size", 11)
	hp_label.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))
	stats_grid.add_child(hp_label)

	var dmg_label = Label.new()
	dmg_label.text = "Daño: %.0f" % worm_data.get_computed_damage()
	dmg_label.add_theme_font_size_override("font_size", 11)
	dmg_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2))
	stats_grid.add_child(dmg_label)

	var spd_label = Label.new()
	spd_label.text = "Vel: %.0f" % worm_data.get_computed_speed()
	spd_label.add_theme_font_size_override("font_size", 11)
	spd_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	stats_grid.add_child(spd_label)

	var cd_label = Label.new()
	cd_label.text = "CD: %.1fs" % worm_data.get_computed_cooldown_attack()
	cd_label.add_theme_font_size_override("font_size", 11)
	cd_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	stats_grid.add_child(cd_label)

	if worm_data.stat_multiplier > 1.0:
		var mult_label = Label.new()
		mult_label.text = "x%.1f" % worm_data.stat_multiplier
		mult_label.add_theme_font_size_override("font_size", 11)
		mult_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.0))
		stats_grid.add_child(mult_label)

	if not worm_data.skills.is_empty():
		var skill_sep = HSeparator.new()
		skill_sep.add_theme_constant_override("separation", 4)
		main_vbox.add_child(skill_sep)

		var skill_container = VBoxContainer.new()
		skill_container.add_theme_constant_override("separation", 4)
		main_vbox.add_child(skill_container)

		for skill in worm_data.skills:
			var skill_box = VBoxContainer.new()
			skill_box.add_theme_constant_override("separation", 1)
			skill_container.add_child(skill_box)

			var skill_header = HBoxContainer.new()
			skill_header.add_theme_constant_override("separation", 4)
			skill_box.add_child(skill_header)

			var dot = Label.new()
			dot.text = "● "
			dot.add_theme_font_size_override("font_size", 9)
			dot.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
			skill_header.add_child(dot)

			var skill_name = Label.new()
			skill_name.text = skill.skill_name
			skill_name.add_theme_font_size_override("font_size", 11)
			skill_name.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
			skill_header.add_child(skill_name)

			var chance_text = skill.get_display_chance()
			if chance_text != "":
				var chance_label = Label.new()
				chance_label.text = chance_text
				chance_label.add_theme_font_size_override("font_size", 9)
				chance_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
				skill_header.add_child(chance_label)

			var desc = Label.new()
			desc.text = skill.description
			desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			desc.add_theme_font_size_override("font_size", 10)
			desc.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
			desc.autowrap_mode = TextServer.AUTOWRAP_WORD
			skill_box.add_child(desc)

	return card
