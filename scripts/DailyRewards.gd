extends Node

signal daily_changed

var last_claim_day: String = ""
var day_index: int = 0

var REWARDS := [
	{ "tipo": "money", "mult": 30.0 },
	{ "tipo": "gems", "qtd": 1 },
	{ "tipo": "money", "mult": 60.0 },
	{ "tipo": "boost" },
	{ "tipo": "money", "mult": 110.0 },
	{ "tipo": "gems", "qtd": 2 },
	{ "tipo": "money", "mult": 220.0, "bonus_gems": 1 },
]

func _today() -> String:
	return Time.get_date_string_from_system()

func can_claim() -> bool:
	return last_claim_day != _today()

func current_index() -> int:
	return day_index % REWARDS.size()

func current() -> Dictionary:
	return REWARDS[current_index()]

func _ref_per_second() -> float:
	var r := 50.0
	if has_node("/root/Posts"):
		r += Posts.auto_income_per_second()
	if has_node("/root/Employees"):
		r += Employees.income_per_second()
	return maxf(50.0, r)

func _fmt(v: float) -> String:
	var a := absf(v)
	if a >= 1_000_000_000.0: return "%.2fB" % (v / 1_000_000_000.0)
	elif a >= 1_000_000.0: return "%.2fM" % (v / 1_000_000.0)
	elif a >= 10_000.0: return "%.1fK" % (v / 1_000.0)
	return "%.0f" % v

func reward_text(r: Dictionary) -> String:
	match String(r.tipo):
		"money":
			var t := "R$ " + _fmt(_ref_per_second() * float(r.mult))
			if r.has("bonus_gems"):
				t += " + %d gemas" % int(r.bonus_gems)
			return t
		"gems":
			return "%d gemas" % int(r.qtd)
		"boost":
			return "Boost 2x (5 min)"
	return "?"

func claim() -> bool:
	if not can_claim():
		return false
	var r := current()
	match String(r.tipo):
		"money":
			GameState.change_money(_ref_per_second() * float(r.mult))
			if r.has("bonus_gems"):
				GameState.change_gems(int(r.bonus_gems))
		"gems":
			GameState.change_gems(int(r.qtd))
		"boost":
			if has_node("/root/Posts"):
				Posts.grant_boost()
	last_claim_day = _today()
	day_index = (day_index + 1) % REWARDS.size()
	emit_signal("daily_changed")
	return true

func serialize() -> Dictionary:
	return { "last": last_claim_day, "day": day_index }

func deserialize(data) -> void:
	if typeof(data) != TYPE_DICTIONARY:
		return
	last_claim_day = String(data.get("last", ""))
	day_index = int(data.get("day", 0))
	emit_signal("daily_changed")
