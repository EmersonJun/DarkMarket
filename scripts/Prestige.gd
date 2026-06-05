extends Node

signal prestige_changed
signal prestiged(pp_gained: int)

const MIN_MONEY := 1_000_000.0

var pp: int = 0
var total_pp: int = 0
var count: int = 0
var talents: Dictionary = {}

var TALENTS := {
	"margem": { "nome": "Margem Negra", "desc": "+5% na renda dos postos por nível", "base": 1, "growth": 1.6 },
	"rota": { "nome": "Rota Rápida", "desc": "+3% de velocidade dos ciclos por nível", "base": 2, "growth": 1.7 },
	"olho": { "nome": "Olho Vivo", "desc": "+4% no preço de venda por nível", "base": 1, "growth": 1.6 },
	"sangue": { "nome": "Sangue Frio", "desc": "+8% na renda offline por nível", "base": 2, "growth": 1.7 },
	"espolio": { "nome": "Espólio", "desc": "Mantém +2% do patrimônio ao refundar (máx 50%)", "base": 3, "growth": 1.8 },
}
var ORDER := ["margem", "rota", "olho", "sangue", "espolio"]

func _ready() -> void:
	for id in ORDER:
		if not talents.has(id):
			talents[id] = 0

func level(id: String) -> int:
	return int(talents.get(id, 0))

func talent_cost(id: String) -> int:
	var t: Dictionary = TALENTS[id]
	return int(round(float(t.base) * pow(float(t.growth), float(level(id)))))

func can_buy(id: String) -> bool:
	return pp >= talent_cost(id)

func buy_talent(id: String) -> bool:
	if not TALENTS.has(id) or not can_buy(id):
		return false
	pp -= talent_cost(id)
	talents[id] = level(id) + 1
	emit_signal("prestige_changed")
	return true

func income_mult() -> float:
	return 1.0 + float(level("margem")) * 0.05

func speed_mult() -> float:
	return 1.0 + float(level("rota")) * 0.03

func sell_mult() -> float:
	return 1.0 + float(level("olho")) * 0.04

func offline_mult() -> float:
	return 1.0 + float(level("sangue")) * 0.08

func keep_fraction() -> float:
	return minf(float(level("espolio")) * 0.02, 0.5)

func pp_gain(money: float) -> int:
	if money < MIN_MONEY:
		return 0
	return int(floor(5.0 * sqrt(money / MIN_MONEY)))

func can_prestige() -> bool:
	return GameState.money >= MIN_MONEY

func title() -> String:
	if count >= 25: return "Imperador do Submundo"
	elif count >= 15: return "Capo"
	elif count >= 8: return "Chefão"
	elif count >= 3: return "Contrabandista"
	elif count >= 1: return "Comerciante"
	return "Novato"

func do_prestige() -> int:
	var gain: int = pp_gain(GameState.money)
	if gain <= 0:
		return 0
	pp += gain
	total_pp += gain
	count += 1
	var kept: float = GameState.STARTING_MONEY + GameState.money * keep_fraction()
	GameState.money = kept
	GameState.inventory = {}
	Posts.reset()
	Employees.reset()
	Contracts.reset()
	for npc_id in NPCs.NPCS:
		NPCs.NPCS[npc_id].afinidade = 0
	NPCs.NPCS["dona_bete"].afinidade = 15
	GameState.emit_signal("money_changed", GameState.money)
	GameState.emit_signal("inventory_changed")
	GameState.emit_signal("city_changed", GameState.current_city_id)
	emit_signal("prestige_changed")
	emit_signal("prestiged", gain)
	return gain

func serialize() -> Dictionary:
	return { "pp": pp, "total_pp": total_pp, "count": count, "talents": talents.duplicate() }

func deserialize(data) -> void:
	if typeof(data) != TYPE_DICTIONARY:
		return
	pp = int(data.get("pp", 0))
	total_pp = int(data.get("total_pp", 0))
	count = int(data.get("count", 0))
	var t = data.get("talents", {})
	if typeof(t) == TYPE_DICTIONARY:
		for id in ORDER:
			talents[id] = int(t.get(id, 0))
	emit_signal("prestige_changed")
