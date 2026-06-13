extends Node

signal money_changed(new_value: float)
signal inventory_changed
signal city_changed(city_id: String)
signal gems_changed(new_value: int)
signal item_sold(amount: float)
signal stats_changed

const STARTING_MONEY := 50.0
const BACKPACK_CAPACITY := 15.0

var money: float = STARTING_MONEY
var gems: int = 0
var current_city_id: String = "rural"
var inventory: Dictionary = {}

var stats: Dictionary = {
	"total_earned": 0.0,
	"total_spent": 0.0,
	"items_bought": 0,
	"items_sold": 0,
	"best_sale": 0.0,
	"total_collects": 0,
	"post_upgrades_bought": 0,
	"posts_unlocked": 1,
	"managers_bought": 0,
	"employees_hired_total": 0,
	"employees_fired_total": 0,
	"trainings_bought": 0,
	"negotiations_won": 0,
	"negotiations_lost": 0,
	"travels_made": 0,
	"ticks_witnessed": 0,
	"prestige_count": 0,
	"talents_bought": 0,
	"contracts_completed": 0,
	"ads_watched": 0,
	"boosts_activated": 0,
	"gems_earned": 0,
	"gems_spent": 0,
	"daily_streak_best": 0,
	"playtime_seconds": 0.0,
	"first_play_unix": 0.0,
	"highest_money": 0.0,
}

func _ready() -> void:
	if float(stats.first_play_unix) <= 0.0:
		stats.first_play_unix = Time.get_unix_time_from_system()
	emit_signal("money_changed", money)
	emit_signal("city_changed", current_city_id)
	emit_signal("gems_changed", gems)
	set_process(true)

func _process(delta: float) -> void:
	stats.playtime_seconds = float(stats.playtime_seconds) + delta

func bump_stat(key: String, delta: float = 1.0) -> void:
	if not stats.has(key):
		stats[key] = 0
	var current = stats[key]
	if typeof(current) == TYPE_FLOAT:
		stats[key] = float(current) + delta
	else:
		stats[key] = int(current) + int(delta)
	emit_signal("stats_changed")

func set_stat_max(key: String, value: float) -> void:
	if not stats.has(key):
		stats[key] = 0.0
	if value > float(stats[key]):
		stats[key] = value
		emit_signal("stats_changed")

func change_money(delta: float) -> void:
	money += delta
	if delta > 0.0:
		stats.total_earned = float(stats.total_earned) + delta
	elif delta < 0.0:
		stats.total_spent = float(stats.total_spent) + (-delta)
	if money > float(stats.highest_money):
		stats.highest_money = money
	emit_signal("money_changed", money)

func change_gems(delta: int) -> void:
	gems = maxi(0, gems + delta)
	if delta > 0:
		stats.gems_earned = int(stats.gems_earned) + delta
	elif delta < 0:
		stats.gems_spent = int(stats.gems_spent) + (-delta)
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
	stats.items_bought = int(stats.items_bought) + qty
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
	if city_id != current_city_id:
		stats.travels_made = int(stats.travels_made) + 1
	current_city_id = city_id
	emit_signal("city_changed", city_id)
	Economy.advance_tick()

func serialize_stats() -> Dictionary:
	return stats.duplicate(true)

func deserialize_stats(data) -> void:
	if typeof(data) != TYPE_DICTIONARY:
		return
	for k in data:
		stats[String(k)] = data[k]
	if float(stats.get("first_play_unix", 0.0)) <= 0.0:
		stats.first_play_unix = Time.get_unix_time_from_system()
	emit_signal("stats_changed")
