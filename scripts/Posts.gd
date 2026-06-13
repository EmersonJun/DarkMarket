extends Node

signal posts_changed
signal collected(city_id: String, amount: float)
signal upgraded(city_id: String)
signal unlocked(city_id: String)
signal milestone_reached(city_id: String, nivel: int)

var BASE_INCOME := { "rural": 4.0, "centro": 18.0, "porto": 55.0, "historica": 30.0, "favela": 95.0, "fronteira": 180.0, "subterraneo": 380.0 }
# Estritamente crescente pela ORDEM: quanto mais distante a cidade, mais lento o ciclo
# (o carrinho percorre a estrada em 'cycle_time' segundos -> mais distante = mais devagar).
var CYCLE_TIME := { "rural": 5.0, "centro": 7.5, "porto": 10.0, "historica": 13.0, "favela": 16.5, "fronteira": 20.5, "subterraneo": 25.0 }
var BASE_UPGRADE := { "rural": 25.0, "centro": 220.0, "porto": 3200.0, "historica": 1600.0, "favela": 6000.0, "fronteira": 14000.0, "subterraneo": 35000.0 }
var UNLOCK_COST := { "rural": 0.0, "centro": 800.0, "porto": 18000.0, "historica": 140000.0, "favela": 420000.0, "fronteira": 2600000.0, "subterraneo": 16000000.0 }
var BASE_MANAGER := { "rural": 4000.0, "centro": 50000.0, "porto": 1500000.0, "historica": 420000.0, "favela": 1000000.0, "fronteira": 4500000.0, "subterraneo": 17000000.0 }
var ORDER := ["rural", "centro", "porto", "historica", "favela", "fronteira", "subterraneo"]

const COST_GROWTH := 1.205
const MILESTONE_STEP := 10
const MILESTONE_BONUS := 0.30
const CYCLE_GROWTH_PER_LEVEL := 0.008
const CYCLE_MAX_MULT := 3.0

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
				_pay(city_id, true)
		elif p.progress < 1.0:
			p.progress = minf(1.0, p.progress + delta / cycle_time(city_id))

func global_mult() -> float:
	var m := 1.0
	if has_node("/root/Prestige"):
		m *= Prestige.income_mult()
	if boost_seconds_left > 0.0:
		m *= 2.0
	return m

func milestone_mult(nivel: int) -> float:
	var milestones: int = int(nivel) / MILESTONE_STEP
	return pow(1.0 + MILESTONE_BONUS, float(milestones))

func income_per_cycle(city_id: String) -> float:
	var p: Dictionary = posts[city_id]
	var nivel: int = int(p.nivel)
	return float(BASE_INCOME[city_id]) * float(nivel) * milestone_mult(nivel) * global_mult()

func cycle_time(city_id: String) -> float:
	var p: Dictionary = posts[city_id]
	var nivel: int = int(p.nivel)
	var speed_step: float = 1.0 + 0.05 * floorf(float(nivel) / 25.0)
	var speed: float = minf(speed_step, 1.66)
	var growth: float = minf(1.0 + CYCLE_GROWTH_PER_LEVEL * float(nivel - 1), CYCLE_MAX_MULT)
	var prestige_speed: float = Prestige.speed_mult() if has_node("/root/Prestige") else 1.0
	return float(CYCLE_TIME[city_id]) * growth / speed / prestige_speed

func upgrade_cost(city_id: String) -> float:
	var p: Dictionary = posts[city_id]
	var nivel: int = int(p.nivel)
	var base: float = float(BASE_UPGRADE[city_id]) * pow(COST_GROWTH, float(nivel - 1))
	var milestones: int = nivel / MILESTONE_STEP
	base *= pow(1.55, float(milestones))
	return snapped(base, 1.0)

func unlock_cost(city_id: String) -> float:
	return float(UNLOCK_COST[city_id])

func manager_cost(city_id: String) -> float:
	var p: Dictionary = posts[city_id]
	var nivel: int = int(p.nivel)
	return snapped(float(BASE_MANAGER[city_id]) * pow(1.08, maxf(0.0, float(nivel - 5))), 1.0)

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
		_pay(city_id, false)

func _pay(city_id: String, auto: bool) -> void:
	var amount := income_per_cycle(city_id)
	GameState.change_money(amount)
	if not auto:
		GameState.bump_stat("total_collects", 1.0)
	emit_signal("collected", city_id, amount)

func buy_upgrade(city_id: String) -> bool:
	var cost := upgrade_cost(city_id)
	if GameState.money < cost:
		return false
	GameState.change_money(-cost)
	var p: Dictionary = posts[city_id]
	p.nivel = int(p.nivel) + 1
	GameState.bump_stat("post_upgrades_bought", 1.0)
	if int(p.nivel) % MILESTONE_STEP == 0:
		GameState.change_gems(1)
		emit_signal("milestone_reached", city_id, int(p.nivel))
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
	GameState.bump_stat("posts_unlocked", 1.0)
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
	GameState.bump_stat("managers_bought", 1.0)
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

func grant_boost() -> void:
	boost_seconds_left = BOOST_DURATION
	emit_signal("posts_changed")

func can_boost() -> bool:
	return GameState.gems >= BOOST_GEM_COST and boost_seconds_left <= 0.0

func activate_boost() -> bool:
	if not can_boost():
		return false
	GameState.change_gems(-BOOST_GEM_COST)
	boost_seconds_left = BOOST_DURATION
	GameState.bump_stat("boosts_activated", 1.0)
	emit_signal("posts_changed")
	return true

func total_levels() -> int:
	var sum: int = 0
	for city_id in ORDER:
		sum += int(posts[city_id].nivel)
	return sum

func unlocked_count() -> int:
	var n: int = 0
	for city_id in ORDER:
		if posts[city_id].unlocked:
			n += 1
	return n

func managers_count() -> int:
	var n: int = 0
	for city_id in ORDER:
		if posts[city_id].manager:
			n += 1
	return n

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
