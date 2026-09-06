class_name KillRewardHandler
extends Node

const STAT_UPGRADE_CHANCE := 0.2
const RARITY_UPGRADE_CHANCE := 0.2

const STAT_BOOST_MIN := 0.05
const STAT_BOOST_MAX := 0.15
const MULTIPLIER_BOOST_MIN := 0.05
const MULTIPLIER_BOOST_MAX := 0.15

static var stat_upgrade_bonus: float = 0.0
static var rarity_upgrade_bonus: float = 0.0

var upgrade_animation_scene: PackedScene = preload("res://commons/upgrade_animation.tscn")

func on_worm_died(killer: Worm, victim: Worm) -> void:
	if not is_instance_valid(killer) or killer.hp <= 0:
		return

	var stat_chance = minf(STAT_UPGRADE_CHANCE + stat_upgrade_bonus, 1.0)
	if randf() < stat_chance:
		var rarity_chance = minf(RARITY_UPGRADE_CHANCE + rarity_upgrade_bonus, 1.0)
		if randf() < rarity_chance:
			WormEffects.upgrade_rarity(killer)
		_apply_stat_boosts(killer)
		_spawn_upgrade_animation(killer)

func _spawn_upgrade_animation(worm: Worm) -> void:
	if not is_instance_valid(worm):
		return
	var anim = upgrade_animation_scene.instantiate()
	anim.global_position = worm.global_position
	worm.get_parent().add_child(anim)

func _apply_stat_boosts(worm: Worm) -> void:
	var hp_boost = randf_range(STAT_BOOST_MIN, STAT_BOOST_MAX)
	var damage_boost = randf_range(STAT_BOOST_MIN, STAT_BOOST_MAX)
	var speed_boost = randf_range(STAT_BOOST_MIN, STAT_BOOST_MAX)
	var size_boost = randf_range(STAT_BOOST_MIN, STAT_BOOST_MAX)
	var cooldown_boost = randf_range(STAT_BOOST_MIN, STAT_BOOST_MAX)
	var multiplier_boost = randf_range(MULTIPLIER_BOOST_MIN, MULTIPLIER_BOOST_MAX)

	WormEffects.permanent_boost(worm, "hp_max", hp_boost)
	WormEffects.permanent_boost(worm, "damage", damage_boost)
	WormEffects.permanent_boost(worm, "speed", speed_boost)
	WormEffects.permanent_boost(worm, "size", size_boost)
	WormEffects.permanent_boost(worm, "cooldown_attack", cooldown_boost)
	worm.worm_data.stat_multiplier += multiplier_boost
