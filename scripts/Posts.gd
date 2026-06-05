extends Node

signal posts_changed
signal collected(city_id: String, amount: float)
signal upgraded(city_id: String)
signal unlocked(city_id: String)

var BASE_INCOME := { "rural": 3.0, "centro": 12.0, "porto": 40.0, "historica": 22.0, "favela": 70.0, "fronteira": 130.0, "subterraneo": 250.0 }
var CYCLE_TIME := { "rural": 3.0, "centro": 3.5, "porto": 4.2, "historica": 3.4, "favela": 3.6, "fronteira": 4.0, "subterraneo": 4.5 }
var BASE_UPGRADE := { "rural": 18.0, "centro": 150.0, "porto": 2200.0, "historica": 1100.0, "favela": 4000.0, "fronteira": 9000.0, "subterraneo": 22000.0 }
var UNLOCK_COST := { "rural": 0.0, "centro": 600.0, "porto": 12000.0, "historica": 90000.0, "favela": 250000.0, "fronteira": 1500000.0, "subterraneo": 9000000.0 }
var BASE_MANAGER := { "rural": 2500.0, "centro": 30000.0, "porto": 900000.0, "historica": 260000.0, "favela": 600000.0, "fronteira": 2500000.0, "subterraneo": 9000000.0 }
var ORDER := ["rural", "centro", "porto", "historica", "favela", "fronteira", "subterraneo"]

var posts: Dictionary = {}

var boost_seconds_left: float = 0.0

func _ready() -> void:
	for city_id in ORDER:
		posts[city_id] = {
			"nivel": 1,
			"manager": false,
			"progress": 0.0,
			"unlocked": city_id == "rural",
		}
	set_process(true)

func _process(delta: float) -> void:
	if boost_seconds_left > 0.0:
		boost_seconds_left = maxf(0.0, boost_seconds_left - delta)
	for city_id in ORDER:
		var p: Dictionary = posts[city_id]
		if not p.unlocked:
			continue
		if p.manager:
			p.progress += delta / cycle_time(city_id)
			while p.progress >= 1.0:
				p.progress -= 1.0
				_pay(city_id)
		elif p.progress < 1.0:
			p.progress = minf(1.0, p.progress + delta / cycle_time(city_id))

func global_mult() -> float:
	var m := 1.0
	if has_node("/root/Employees"):
		m *= Employees.global_income_multiplier()
	if has_node("/root/Prestige"):
		m *= Prestige.income_mult()
	if boost_seconds_left > 0.0:
		m *= 2.0
	return m

func income_per_cycle(city_id: String) -> float:
	var p: Dictionary = posts[city_id]
	return float(BASE_INCOME[city_id]) * float(p.nivel) * global_mult()

func cycle_time(city_id: String) -> float:

	var p: Dictionary = posts[city_id]
	var speed: float = 1.0 + 0.04 * floorf(float(p.nivel) / 25.0)
	var prestige_speed: float = Prestige.speed_mult() if has_node("/root/Prestige") else 1.0
	return float(CYCLE_TIME[city_id]) / minf(speed, 1.66) / prestige_speed

func upgrade_cost(city_id: String) -> float:
	var p: Dictionary = posts[city_id]
	return snapped(float(BASE_UPGRADE[city_id]) * pow(1.16, float(p.nivel) - 1.0), 1.0)

func unlock_cost(city_id: String) -> float:
	return float(UNLOCK_COST[city_id])

func manager_cost(city_id: String) -> float:
	return float(BASE_MANAGER[city_id])

func is_ready(city_id: String) -> bool:
	var p: Dictionary = posts[city_id]
	return p.unlocked and not p.manager and p.progress >= 1.0

func auto_income_per_second() -> float:
	var total := 0.0
	for city_id in ORDER:
		var p: Dictionary = posts[city_id]
		if p.unlocked and p.manager:
			total += income_per_cycle(city_id) / cycle_time(city_id)
	return total

func collect(city_id: String) -> void:
	if is_ready(city_id):
		posts[city_id].progress = 0.0
		_pay(city_id)

func _pay(city_id: String) -> void:
	var amount := income_per_cycle(city_id)
	GameState.change_money(amount)
	emit_signal("collected", city_id, amount)

func buy_upgrade(city_id: String) -> bool:
	var cost := upgrade_cost(city_id)
	if GameState.money < cost:
		return false
	GameState.change_money(-cost)
	posts[city_id].nivel = int(posts[city_id].nivel) + 1
	if int(posts[city_id].nivel) % 10 == 0:
		GameState.change_gems(1)
	emit_signal("upgraded", city_id)
	emit_signal("posts_changed")
	return true

func buy_unlock(city_id: String) -> bool:
	var p: Dictionary = posts[city_id]
	if p.unlocked:
		return false
	var cost := unlock_cost(city_id)
	if GameState.money < cost:
		return false
	GameState.change_money(-cost)
	p.unlocked = true
	GameState.change_gems(2)
	emit_signal("unlocked", city_id)
	emit_signal("posts_changed")
	return true

func buy_manager(city_id: String) -> bool:
	var p: Dictionary = posts[city_id]
	if not p.unlocked or p.manager:
		return false
	var cost := manager_cost(city_id)
	if GameState.money < cost:
		return false
	GameState.change_money(-cost)
	p.manager = true
	emit_signal("posts_changed")
	return true

func reset() -> void:
	boost_seconds_left = 0.0
	for city_id in ORDER:
		posts[city_id].nivel = 1
		posts[city_id].manager = false
		posts[city_id].progress = 0.0
		posts[city_id].unlocked = city_id == "rural"
	emit_signal("posts_changed")

const BOOST_GEM_COST := 5
const BOOST_DURATION := 300.0

func can_boost() -> bool:
	return GameState.gems >= BOOST_GEM_COST and boost_seconds_left <= 0.0

func activate_boost() -> bool:
	if not can_boost():
		return false
	GameState.change_gems(-BOOST_GEM_COST)
	boost_seconds_left = BOOST_DURATION
	emit_signal("posts_changed")
	return true

func serialize() -> Dictionary:
	var out := {}
	for city_id in ORDER:
		var p: Dictionary = posts[city_id]
		out[city_id] = { "nivel": int(p.nivel), "manager": bool(p.manager), "unlocked": bool(p.unlocked) }
	return { "posts": out, "boost": boost_seconds_left }

func deserialize(data) -> void:
	if typeof(data) != TYPE_DICTIONARY:
		return
	var src = data.get("posts", {})
	if typeof(src) == TYPE_DICTIONARY:
		for city_id in ORDER:
			if src.has(city_id) and typeof(src[city_id]) == TYPE_DICTIONARY:
				var s: Dictionary = src[city_id]
				posts[city_id].nivel = int(s.get("nivel", 1))
				posts[city_id].manager = bool(s.get("manager", false))
				posts[city_id].unlocked = bool(s.get("unlocked", city_id == "rural"))
				posts[city_id].progress = 0.0
	boost_seconds_left = float(data.get("boost", 0.0))
	emit_signal("posts_changed")
