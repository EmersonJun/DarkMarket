extends Node

signal contracts_changed

const SLOTS := 3
const TYPES := ["coletar", "vender", "melhorar", "ganhar"]

var active: Array = []
var _next_id: int = 1

func _ready() -> void:
	randomize()
	for i in SLOTS:
		active.append(_new_contract())
	GameState.item_sold.connect(_on_sold)
	Posts.collected.connect(_on_collected)
	Posts.upgraded.connect(_on_upgraded)

func _ref() -> float:
	var total := 0.0
	for city_id in Posts.ORDER:
		if Posts.posts[city_id].unlocked:
			total += Posts.income_per_cycle(city_id)
	return maxf(3.0, total)

func _new_contract() -> Dictionary:
	var tipo: String = TYPES.pick_random()
	var ref: float = _ref()
	var alvo: float = 1.0
	var reward: float = 0.0
	var gems: int = 0
	match tipo:
		"coletar":
			alvo = float(randi_range(10, 25))
			reward = ref * alvo * 0.5
		"vender":
			alvo = float(randi_range(5, 14))
			reward = ref * alvo * 0.7
			gems = 1 if randf() < 0.4 else 0
		"melhorar":
			alvo = float(randi_range(3, 8))
			reward = ref * alvo * 1.6
			gems = 1
		"ganhar":
			alvo = snapped(ref * float(randi_range(30, 80)), 1.0)
			reward = alvo * 0.4
			gems = 1 if randf() < 0.3 else 0
	var c := {
		"id": _next_id,
		"tipo": tipo,
		"alvo": snapped(alvo, 1.0),
		"progresso": 0.0,
		"reward": snapped(maxf(reward, 1.0), 1.0),
		"gems": gems,
		"claimed": false,
	}
	_next_id += 1
	return c

func descricao(c: Dictionary) -> String:
	match String(c.tipo):
		"coletar": return "Colete %d vezes nos postos" % int(c.alvo)
		"vender": return "Venda %d itens (mercado ou negociação)" % int(c.alvo)
		"melhorar": return "Melhore postos %d vezes" % int(c.alvo)
		"ganhar": return "Ganhe R$ %s" % _fmt(c.alvo)
	return "Contrato"

func _fmt(v: float) -> String:
	if v >= 1_000_000.0: return "%.1fM" % (v / 1_000_000.0)
	elif v >= 1000.0: return "%.1fK" % (v / 1000.0)
	return "%.0f" % v

func _advance(tipo: String, n: float) -> void:
	var changed := false
	for c in active:
		if String(c.tipo) == tipo and not c.claimed and float(c.progresso) < float(c.alvo):
			c.progresso = minf(float(c.progresso) + n, float(c.alvo))
			changed = true
	if changed:
		emit_signal("contracts_changed")

func _on_collected(_city: String, amount: float) -> void:
	_advance("coletar", 1.0)
	_advance("ganhar", amount)

func _on_sold(amount: float) -> void:
	_advance("vender", 1.0)
	_advance("ganhar", amount)

func _on_upgraded(_city: String) -> void:
	_advance("melhorar", 1.0)

func is_complete(c: Dictionary) -> bool:
	return float(c.progresso) >= float(c.alvo)

func claim(c: Dictionary) -> bool:
	if not is_complete(c) or c.claimed:
		return false
	GameState.change_money(float(c.reward))
	if int(c.gems) > 0:
		GameState.change_gems(int(c.gems))
	var idx: int = active.find(c)
	if idx >= 0:
		active[idx] = _new_contract()
	emit_signal("contracts_changed")
	return true

func serialize() -> Dictionary:
	return { "active": active.duplicate(true), "next_id": _next_id }

func deserialize(data) -> void:
	if typeof(data) != TYPE_DICTIONARY:
		return
	var arr = data.get("active", [])
	if typeof(arr) == TYPE_ARRAY and arr.size() > 0:
		active.clear()
		for d in arr:
			if typeof(d) != TYPE_DICTIONARY:
				continue
			active.append({
				"id": int(d.get("id", _next_id)),
				"tipo": String(d.get("tipo", "coletar")),
				"alvo": float(d.get("alvo", 1.0)),
				"progresso": float(d.get("progresso", 0.0)),
				"reward": float(d.get("reward", 1.0)),
				"gems": int(d.get("gems", 0)),
				"claimed": false,
			})
		while active.size() < SLOTS:
			active.append(_new_contract())
	_next_id = int(data.get("next_id", _next_id))
	emit_signal("contracts_changed")
