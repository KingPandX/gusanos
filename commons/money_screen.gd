extends Label

var displayed_value : int = 0

func _ready() -> void:
	GlobalManager.money_changed.connect(_on_money_changed)
	var start_value = GlobalManager.money
	var tween = create_tween()
	tween.tween_property(self, "displayed_value", start_value, 0.5).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_method(_update_text, 0, start_value, 0.5)

func _on_money_changed(new_value: int) -> void:
	var tween = create_tween()
	tween.tween_property(self, "displayed_value", new_value, 0.5).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_method(_update_text, displayed_value, new_value, 0.5)

func _update_text(value: int) -> void:
	text = "%d¢" % value
