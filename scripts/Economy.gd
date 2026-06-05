extends Node

signal market_tick

var CITIES := {
	"rural":         { "nome": "Sertão Esquecido",    "cor": Color(0.40, 0.65, 0.35) },
	"centro":        { "nome": "Camelódromo",         "cor": Color(0.30, 0.55, 0.80) },
	"porto":         { "nome": "Cais Sombrio",        "cor": Color(0.20, 0.45, 0.60) },
	"historica":     { "nome": "Cidade Velha",        "cor": Color(0.65, 0.50, 0.30) },
	"favela":        { "nome": "Boca do Morro",       "cor": Color(0.80, 0.40, 0.32) },
	"fronteira":     { "nome": "Fronteira Seca",      "cor": Color(0.72, 0.58, 0.28) },
	"subterraneo":   { "nome": "Subterrâneo",         "cor": Color(0.50, 0.32, 0.70) },
}

const PRODUCTS := {
	"maca":              { "nome": "Carne sem Carimbo",     "categoria": "Alimentos",     "base": 3.0,   "peso": 0.2, "raridade": "Comum" },
	"queijo_canastra":   { "nome": "Queijo Clandestino",    "categoria": "Alimentos",     "base": 45.0,  "peso": 1.2, "raridade": "Incomum" },
	"mel_silvestre":     { "nome": "Cachaça sem Selo",      "categoria": "Alimentos",     "base": 18.0,  "peso": 0.5, "raridade": "Incomum" },
	"camisa_basica":     { "nome": "Camisa Pirata",         "categoria": "Luxo",          "base": 30.0,  "peso": 0.3, "raridade": "Comum" },
	"perfume_urbano":    { "nome": "Perfume Falsificado",   "categoria": "Luxo",          "base": 120.0, "peso": 0.4, "raridade": "Raro" },
	"bacalhau_seco":     { "nome": "Bacalhau Contrabandeado","categoria": "Alimentos",    "base": 80.0,  "peso": 1.0, "raridade": "Incomum" },
	"especiarias_raras": { "nome": "Especiarias de Contrabando","categoria": "Alimentos", "base": 65.0,  "peso": 0.2, "raridade": "Raro" },
	"container_misterio":{ "nome": "Contêiner Lacrado",     "categoria": "Colecionáveis", "base": 350.0, "peso": 3.0, "raridade": "Épico" },
	"moeda_antiga":      { "nome": "Moeda Saqueada",        "categoria": "Antiguidades",  "base": 95.0,  "peso": 0.1, "raridade": "Raro" },
	"manuscrito":        { "nome": "Manuscrito Roubado",    "categoria": "Antiguidades",  "base": 280.0, "peso": 0.6, "raridade": "Épico" },
	"reliquia_pedra":    { "nome": "Relíquia Saqueada",     "categoria": "Antiguidades",  "base": 55.0,  "peso": 2.0, "raridade": "Incomum" },
	"lampião_velho":     { "nome": "Lampião Surrupiado",    "categoria": "Antiguidades",  "base": 40.0,  "peso": 1.5, "raridade": "Comum" },
}

const CITY_CATEGORY_MOD := {
	"rural":       { "Alimentos": 0.55, "Luxo": 1.30, "Colecionáveis": 1.20, "Antiguidades": 1.10 },
	"centro":      { "Alimentos": 1.10, "Luxo": 0.75, "Colecionáveis": 1.00, "Antiguidades": 1.05 },
	"porto":       { "Alimentos": 0.85, "Luxo": 1.00, "Colecionáveis": 0.90, "Antiguidades": 1.15 },
	"historica":   { "Alimentos": 1.20, "Luxo": 1.10, "Colecionáveis": 1.25, "Antiguidades": 0.65 },
	"favela":      { "Alimentos": 1.15, "Luxo": 0.85, "Colecionáveis": 1.05, "Antiguidades": 0.95 },
	"fronteira":   { "Alimentos": 0.90, "Luxo": 1.25, "Colecionáveis": 1.10, "Antiguidades": 1.20 },
	"subterraneo": { "Alimentos": 0.80, "Luxo": 1.30, "Colecionáveis": 1.40, "Antiguidades": 1.35 },
}

var prices: Dictionary = {}
var tick_count: int = 0

func _ready() -> void:
	randomize()

	call_deferred("_initial_compute")

func _initial_compute() -> void:
	_recompute_all_prices()
	emit_signal("market_tick")

func advance_tick() -> void:
	tick_count += 1

	if has_node("/root/News"):
		News.advance_for_tick()
	_recompute_all_prices()
	emit_signal("market_tick")

func _recompute_all_prices() -> void:
	for city_id in CITIES:
		prices[city_id] = {}
		for product_id in PRODUCTS:
			prices[city_id][product_id] = _compute_price(city_id, product_id)

func _compute_price(city_id: String, product_id: String) -> float:
	var p: Dictionary = PRODUCTS[product_id]
	var base: float = p.base
	var cat: String = p.categoria
	var mod_city: float = CITY_CATEGORY_MOD[city_id].get(cat, 1.0)

	var seed := hash("%s:%s:%d" % [city_id, product_id, tick_count])
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var mod_demanda := rng.randf_range(0.85, 1.20)
	var mod_oferta := rng.randf_range(0.85, 1.15)
	var ruido := rng.randf_range(-0.05, 0.05)

	var rarity_table := {
		"Comum": 1.0, "Incomum": 1.05, "Raro": 1.15, "Épico": 1.30, "Lendário": 1.60, "Mítico": 2.00,
	}
	var rarity_mult: float = rarity_table.get(p.raridade, 1.0)

	var mod_evento: float = 1.0
	if has_node("/root/News"):
		mod_evento = News.event_modifier(city_id, cat)

	var price: float = base * mod_city * mod_demanda * mod_oferta * mod_evento * (1.0 + ruido) * rarity_mult
	return snapped(price, 0.01)

func has_event_for(city_id: String, product_id: String) -> bool:
	if not has_node("/root/News"):
		return false
	var cat: String = PRODUCTS[product_id].categoria
	return News.has_active_event_for(city_id, cat)

func price_at(city_id: String, product_id: String) -> float:
	return prices.get(city_id, {}).get(product_id, _compute_price(city_id, product_id))
