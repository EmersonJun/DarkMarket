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
	# id                  nome / categoria / base / peso / raridade / origem (cidades onde se COMPRA)
	"maca":              { "nome": "Carne sem Carimbo",     "categoria": "Alimentos",     "base": 3.0,   "peso": 0.2, "raridade": "Comum",    "origem": ["rural", "favela"] },
	"queijo_canastra":   { "nome": "Queijo Clandestino",    "categoria": "Alimentos",     "base": 45.0,  "peso": 1.2, "raridade": "Incomum",  "origem": ["rural"] },
	"mel_silvestre":     { "nome": "Cachaça sem Selo",      "categoria": "Alimentos",     "base": 18.0,  "peso": 0.5, "raridade": "Incomum",  "origem": ["rural", "fronteira"] },
	"cafe_contrabando":  { "nome": "Café Contrabandeado",   "categoria": "Alimentos",     "base": 8.0,   "peso": 0.3, "raridade": "Comum",    "origem": ["rural"] },
	"camisa_basica":     { "nome": "Camisa Pirata",         "categoria": "Luxo",          "base": 30.0,  "peso": 0.3, "raridade": "Comum",    "origem": ["centro", "favela"] },
	"perfume_urbano":    { "nome": "Perfume Falsificado",   "categoria": "Luxo",          "base": 120.0, "peso": 0.4, "raridade": "Raro",     "origem": ["centro"] },
	"relogio_replica":   { "nome": "Relógio Replicado",     "categoria": "Luxo",          "base": 140.0, "peso": 0.2, "raridade": "Raro",     "origem": ["centro"] },
	"fone_pirata":       { "nome": "Fone Pirata",           "categoria": "Luxo",          "base": 35.0,  "peso": 0.2, "raridade": "Incomum",  "origem": ["centro", "favela"] },
	"tenis_fake":        { "nome": "Tênis Falsificado",     "categoria": "Luxo",          "base": 25.0,  "peso": 0.6, "raridade": "Comum",    "origem": ["favela"] },
	"bacalhau_seco":     { "nome": "Bacalhau Contrabandeado","categoria": "Alimentos",    "base": 80.0,  "peso": 1.0, "raridade": "Incomum",  "origem": ["porto"] },
	"especiarias_raras": { "nome": "Especiarias de Contrabando","categoria": "Alimentos", "base": 65.0,  "peso": 0.2, "raridade": "Raro",     "origem": ["porto", "fronteira"] },
	"perola_surrupiada": { "nome": "Pérola Surrupiada",     "categoria": "Luxo",          "base": 130.0, "peso": 0.05,"raridade": "Raro",     "origem": ["porto"] },
	"caviar_desviado":   { "nome": "Caviar Desviado",       "categoria": "Alimentos",     "base": 300.0, "peso": 0.3, "raridade": "Épico",    "origem": ["porto"] },
	"container_misterio":{ "nome": "Contêiner Lacrado",     "categoria": "Colecionáveis", "base": 350.0, "peso": 3.0, "raridade": "Épico",    "origem": ["porto", "subterraneo"] },
	"tequila_clande":    { "nome": "Tequila Clandestina",   "categoria": "Alimentos",     "base": 30.0,  "peso": 0.7, "raridade": "Incomum",  "origem": ["fronteira"] },
	"charuto_contra":    { "nome": "Charuto Contrabandeado","categoria": "Luxo",          "base": 110.0, "peso": 0.1, "raridade": "Raro",     "origem": ["fronteira"] },
	"moeda_antiga":      { "nome": "Moeda Saqueada",        "categoria": "Antiguidades",  "base": 95.0,  "peso": 0.1, "raridade": "Raro",     "origem": ["historica"] },
	"manuscrito":        { "nome": "Manuscrito Roubado",    "categoria": "Antiguidades",  "base": 280.0, "peso": 0.6, "raridade": "Épico",    "origem": ["historica", "subterraneo"] },
	"reliquia_pedra":    { "nome": "Relíquia Saqueada",     "categoria": "Antiguidades",  "base": 55.0,  "peso": 2.0, "raridade": "Incomum",  "origem": ["historica"] },
	"lampião_velho":     { "nome": "Lampião Surrupiado",    "categoria": "Antiguidades",  "base": 40.0,  "peso": 1.5, "raridade": "Comum",    "origem": ["historica", "rural"] },
	"quadro_roubado":    { "nome": "Quadro Roubado",        "categoria": "Antiguidades",  "base": 600.0, "peso": 2.5, "raridade": "Lendário", "origem": ["historica"] },
	"cristal_roubado":   { "nome": "Cristal Roubado",       "categoria": "Colecionáveis", "base": 550.0, "peso": 0.4, "raridade": "Lendário", "origem": ["subterraneo"] },
	"caveira_ouro":      { "nome": "Caveira de Ouro",       "categoria": "Antiguidades",  "base": 320.0, "peso": 1.2, "raridade": "Épico",    "origem": ["subterraneo"] },
	# Exclusivo de Fornecedor (não aparece no mercado comum)
	"diamante_negro":    { "nome": "Diamante Negro",        "categoria": "Colecionáveis", "base": 1500.0,"peso": 0.1, "raridade": "Mítico",   "origem": [], "fornecedor": true },
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

# --- Origem / comércio por cidade -----------------------------------------

func origin_of(product_id: String) -> Array:
	return PRODUCTS.get(product_id, {}).get("origem", [])

func is_sold_in(city_id: String, product_id: String) -> bool:
	return origin_of(product_id).has(city_id)

func is_supplier_only(product_id: String) -> bool:
	return bool(PRODUCTS.get(product_id, {}).get("fornecedor", false))

# Itens que se COMPRAM nesta cidade (mercado comum).
func products_sold_in(city_id: String) -> Array:
	var out: Array = []
	for pid in PRODUCTS:
		if origin_of(pid).has(city_id):
			out.append(pid)
	return out

# Itens exclusivos cuja origem é só esta cidade (selo "EXCLUSIVO DAQUI").
func is_exclusive_to(city_id: String, product_id: String) -> bool:
	var o: Array = origin_of(product_id)
	return o.size() == 1 and o[0] == city_id

# Melhor cidade para vender: maior price_at entre todas as cidades.
func best_sell_city(product_id: String) -> Dictionary:
	var best_city: String = ""
	var best_price: float = -1.0
	for city_id in CITIES:
		var pr: float = price_at(city_id, product_id)
		if pr > best_price:
			best_price = pr
			best_city = city_id
	return { "city": best_city, "price": best_price }

# Razão preço_aqui / média entre cidades (>1 caro aqui, <1 barato aqui).
func price_trend(city_id: String, product_id: String) -> float:
	var total: float = 0.0
	var n: int = 0
	for c in CITIES:
		total += price_at(c, product_id)
		n += 1
	if n == 0 or total <= 0.0:
		return 1.0
	var avg: float = total / float(n)
	if avg <= 0.0:
		return 1.0
	return price_at(city_id, product_id) / avg
