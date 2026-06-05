extends Node

signal roster_changed

const FIRST_NAMES := ["Ana", "Bruno", "Carla", "Diego", "Elena", "Felipe", "Gabi", "Hugo", "Iara", "João", "Kelly", "Lucas", "Marina", "Nando", "Olívia", "Paulo", "Rita", "Sérgio", "Tânia", "Vitor"]
const LAST_NAMES := ["Silva", "Souza", "Costa", "Lima", "Rocha", "Alves", "Pereira", "Gomes", "Martins", "Araújo", "Dias", "Nunes", "Ramos", "Teixeira"]
const CATEGORIES := ["Comprador", "Vendedor", "Motorista", "Analista", "Gerente"]

const RARITY_WEIGHTS := { "Comum": 70.0, "Incomum": 22.0, "Raro": 6.0, "Épico": 1.6, "Lendário": 0.35, "Mítico": 0.05 }
const RARITY_MULT := { "Comum": 1.0, "Incomum": 1.4, "Raro": 2.0, "Épico": 3.2, "Lendário": 5.0, "Mítico": 8.0 }

var hired: Array = []
var candidates: Array = []
var _next_id: int = 1

func _ready() -> void:
	randomize()
	refresh_candidates(4)
	Economy.market_tick.connect(func(): add_work_xp(10.0))

func global_income_multiplier() -> float:
	return 1.0 + total_income_per_hour() / 2000.0

func _roll_attr(mult: float) -> int:
	return clampi(int(randf_range(10.0, 40.0) * mult), 1, 100)

func _roll_rarity() -> String:
	var total: float = 0.0
	for r in RARITY_WEIGHTS:
		total += float(RARITY_WEIGHTS[r])
	var pick: float = randf() * total
	var acc: float = 0.0
	for r in RARITY_WEIGHTS:
		acc += float(RARITY_WEIGHTS[r])
		if pick <= acc:
			return String(r)
	return "Comum"

func _new_employee() -> Dictionary:
	var rar: String = _roll_rarity()
	var mult: float = float(RARITY_MULT[rar])
	var emp := {
		"id": _next_id,
		"nome": "%s %s" % [FIRST_NAMES.pick_random(), LAST_NAMES.pick_random()],
		"categoria": String(CATEGORIES.pick_random()),
		"raridade": rar,
		"nivel": 1,
		"xp": 0.0,
		"atributos": {
			"Negociação": _roll_attr(mult),
			"Velocidade": _roll_attr(mult),
			"Inteligência": _roll_attr(mult),
			"Lealdade": _roll_attr(mult),
		},
	}
	_next_id += 1
	return emp

func refresh_candidates(n: int) -> void:
	candidates.clear()
	for i in n:
		candidates.append(_new_employee())
	emit_signal("roster_changed")

func _primary_attr(cat: String) -> String:
	match cat:
		"Comprador": return "Inteligência"
		"Vendedor": return "Negociação"
		"Motorista": return "Velocidade"
		"Analista": return "Inteligência"
		"Gerente": return "Lealdade"
	return "Inteligência"

func contribution_per_hour(emp: Dictionary) -> float:
	var key: String = _primary_attr(String(emp.categoria))
	var attr: float = float(emp.atributos.get(key, 30))
	var base: float = 50.0 + attr * 6.0
	base *= float(emp.nivel)
	if String(emp.categoria) == "Gerente":
		base *= 0.5
	return base

func salary_per_hour(emp: Dictionary) -> float:
	var mult: float = float(RARITY_MULT[emp.raridade])
	var loyalty: float = float(emp.atributos.get("Lealdade", 0)) / 100.0
	return snapped(40.0 * mult * float(emp.nivel) * (1.0 - 0.3 * loyalty), 1.0)

func manager_multiplier() -> float:
	var m: float = 1.0
	for e in hired:
		if String(e.categoria) == "Gerente":
			var loyalty: float = float(e.atributos.get("Lealdade", 0)) / 100.0
			m += 0.05 * float(e.nivel) * (loyalty + 0.5)
	return m

func total_income_per_hour() -> float:
	var total: float = 0.0
	for e in hired:
		total += contribution_per_hour(e)
	return total * manager_multiplier()

func total_salary_per_hour() -> float:
	var total: float = 0.0
	for e in hired:
		total += salary_per_hour(e)
	return total

func net_income_per_hour() -> float:
	return total_income_per_hour() - total_salary_per_hour()

func hire_cost(emp: Dictionary) -> float:
	var mult: float = float(RARITY_MULT[emp.raridade])
	return snapped(500.0 * mult * (1.0 + 0.2 * float(int(emp.nivel) - 1)), 1.0)

func train_cost(emp: Dictionary) -> float:
	var mult: float = float(RARITY_MULT[emp.raridade])
	return snapped(800.0 * mult * float(emp.nivel), 1.0)

func hire(emp: Dictionary) -> bool:
	var cost: float = hire_cost(emp)
	if GameState.money < cost:
		return false
	GameState.change_money(-cost)
	candidates.erase(emp)
	hired.append(emp)
	emit_signal("roster_changed")
	return true

func fire(emp: Dictionary) -> void:
	hired.erase(emp)
	emit_signal("roster_changed")

func reset() -> void:
	hired.clear()
	refresh_candidates(4)

func train(emp: Dictionary) -> bool:
	var cost: float = train_cost(emp)
	if GameState.money < cost:
		return false
	GameState.change_money(-cost)
	emp.nivel = int(emp.nivel) + 1
	for k in emp.atributos:
		emp.atributos[k] = clampi(int(emp.atributos[k]) + int(randf_range(1.0, 4.0)), 1, 100)
	emit_signal("roster_changed")
	return true

func add_work_xp(amount: float) -> void:
	var leveled: bool = false
	for e in hired:
		e.xp = float(e.xp) + amount
		var needed: float = 100.0 * float(e.nivel)
		while float(e.xp) >= needed:
			e.xp = float(e.xp) - needed
			e.nivel = int(e.nivel) + 1
			leveled = true
			needed = 100.0 * float(e.nivel)
	if leveled:
		emit_signal("roster_changed")

func serialize_hired() -> Array:
	return hired.duplicate(true)

func deserialize_hired(data, next_id_val) -> void:
	hired.clear()
	if typeof(data) == TYPE_ARRAY:
		for d in data:
			if typeof(d) != TYPE_DICTIONARY:
				continue
			var attrs := {}
			var src = d.get("atributos", {})
			if typeof(src) == TYPE_DICTIONARY:
				for k in src:
					attrs[String(k)] = int(src[k])
			hired.append({
				"id": int(d.get("id", _next_id)),
				"nome": String(d.get("nome", "?")),
				"categoria": String(d.get("categoria", "Comprador")),
				"raridade": String(d.get("raridade", "Comum")),
				"nivel": int(d.get("nivel", 1)),
				"xp": float(d.get("xp", 0.0)),
				"atributos": attrs,
			})
	_next_id = int(next_id_val)
	emit_signal("roster_changed")
