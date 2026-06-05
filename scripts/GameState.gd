extends Node

signal money_changed(new_value: float)
signal inventory_changed
signal city_changed(city_id: String)
signal gems_changed(new_value: int)
signal item_sold(amount: float)

const STARTING_MONEY := 50.0
const BACKPACK_CAPACITY := 15.0

var money: float = STARTING_MONEY
var gems: int = 0
var current_city_id: String = "rural"
var inventory: Dictionary = {}

func _ready() -> void:
	emit_signal("money_changed", money)
	emit_signal("city_changed", current_city_id)
	emit_signal("gems_changed", gems)

func change_money(delta: float) -> void:
	money += delta
	emit_signal("money_changed", money)

func change_gems(delta: int) -> void:
	gems = maxi(0, gems + delta)
	emit_signal("gems_changed", gems)

func current_weight() -> float:
	var total := 0.0
	for product_id in inventory:
		var p: Dictionary = Economy.PRODUCTS[product_id]
		total += float(p.peso) * float(inventory[product_id])
	return total

func capacity_left() -> float:
	return BACKPACK_CAPACITY - current_weight()

func add_item(product_id: String, qty: int) -> bool:
	var p: Dictionary = Economy.PRODUCTS[product_id]
	if qty * float(p.peso) > capacity_left() + 0.0001:
		return false
	inventory[product_id] = inventory.get(product_id, 0) + qty
	emit_signal("inventory_changed")
	return true

func remove_item(product_id: String, qty: int) -> bool:
	if inventory.get(product_id, 0) < qty:
		return false
	inventory[product_id] -= qty
	if inventory[product_id] <= 0:
		inventory.erase(product_id)
	emit_signal("inventory_changed")
	return true

func travel_to(city_id: String) -> void:
	current_city_id = city_id
	emit_signal("city_changed", city_id)
	Economy.advance_tick()
