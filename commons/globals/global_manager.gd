extends Node

signal money_changed(new_value: int)

const BASE_MONEY : int = 3
var money: int = 0

func add_money(amount: int) -> void:
	if amount <= 0:
		return
	money += amount
	money_changed.emit(money)

func can_afford(cost: int) -> bool:
	return money >= cost

func transaction(cost: int) -> bool:
	if !can_afford(cost):
		return false
	
	money -= cost
	money_changed.emit(money)
	return true
