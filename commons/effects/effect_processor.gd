extends Node
class_name EffectProcessor

static func apply(effect: EffectData, target = null):
	match effect.target:
		EffectData.Target.PLAYER:
			_apply_to_player(effect)
		EffectData.Target.WORM:
			if target is Worm:
				_apply_to_worm(effect, target)
		EffectData.Target.ALL_WORMS:
			_apply_to_all_worms(effect)
		EffectData.Target.GAME_MECHANIC:
			_apply_to_mechanic(effect)

static func _apply_to_player(effect: EffectData):
	match effect.effect_type:
		EffectData.Type.MONEY_MULTIPLIER:
			PlayerEffects.add_money_multiplier(effect.value, effect.duration)
		EffectData.Type.RARITY_BOOST:
			PlayerEffects.add_rarity_boost(effect.value, effect.duration)
		EffectData.Type.EXTRA_SLOTS:
			ItemInventory.unlock_extra_slots(int(effect.value))
		EffectData.Type.SHOP_DISCOUNT:
			Shop.apply_discount(effect.value, effect.duration)
		EffectData.Type.SHOP_EXTRA_ITEMS:
			Shop.add_extra_slots(int(effect.value))

static func _apply_to_worm(effect: EffectData, worm: Worm):
	match effect.effect_type:
		EffectData.Type.STAT_BOOST:
			WormEffects.permanent_boost(worm, effect.stat, effect.value)
		EffectData.Type.RARITY_UPGRADE:
			WormEffects.upgrade_rarity(worm)
		EffectData.Type.SHIELD:
			WormEffects.add_shield(worm, effect.value, effect.duration)
		EffectData.Type.HEAL:
			WormEffects.heal(worm, effect.value)
		EffectData.Type.RESURRECT:
			pass

static func _apply_to_all_worms(effect: EffectData):
	var tree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var worms = tree.get_nodes_in_group("worms")
	for worm in worms:
		if worm is Worm:
			_apply_to_worm(effect, worm)

static func _apply_to_mechanic(effect: EffectData):
	match effect.effect_type:
		EffectData.Type.AUTO_COLLECT:
			PlayerEffects.auto_collect_level += 1
