extends Node

signal affinity_changed(npc_id: String)

var NPCS := {
	"dona_bete": {
		"nome": "Dona Sombra", "cidade": "rural", "arquetipo": "Contrabandista Veterano",
		"paciencia": 0.75, "ganancia": 0.30,
		"gosta": ["Alimentos"], "odeia": [], "afinidade": 15,
	},
	"seu_pedro": {
		"nome": "Seu Faísca", "cidade": "rural", "arquetipo": "Receptador de Iguarias",
		"paciencia": 0.55, "ganancia": 0.25,
		"gosta": ["Alimentos"], "odeia": ["Antiguidades"], "afinidade": 0,
	},
	"ze_atacado": {
		"nome": "Zé Caveira", "cidade": "rural", "arquetipo": "Atravessador",
		"paciencia": 0.40, "ganancia": 0.55,
		"gosta": [], "odeia": [], "afinidade": 0,
	},
	"marta_lux": {
		"nome": "Madame Lúcia", "cidade": "centro", "arquetipo": "Comprador Discreto",
		"paciencia": 0.50, "ganancia": 0.20,
		"gosta": ["Luxo", "Colecionáveis"], "odeia": [], "afinidade": 0,
	},
	"gina_collect": {
		"nome": "Gina Navalha", "cidade": "centro", "arquetipo": "Colecionador Clandestino",
		"paciencia": 0.65, "ganancia": 0.35,
		"gosta": ["Colecionáveis"], "odeia": [], "afinidade": 0,
	},
	"ricardo_centro": {
		"nome": "Ricardão", "cidade": "centro", "arquetipo": "Atravessador",
		"paciencia": 0.35, "ganancia": 0.60,
		"gosta": [], "odeia": [], "afinidade": 0,
	},
	"capitao_mar": {
		"nome": "Capitão Breu", "cidade": "porto", "arquetipo": "Receptador de Relíquias",
		"paciencia": 0.70, "ganancia": 0.30,
		"gosta": ["Antiguidades"], "odeia": [], "afinidade": 0,
	},
	"yara_invest": {
		"nome": "Yara Escuta", "cidade": "porto", "arquetipo": "Informante",
		"paciencia": 0.60, "ganancia": 0.40,
		"gosta": ["Luxo"], "odeia": [], "afinidade": 0,
	},
	"prof_helena": {
		"nome": "A Doutora", "cidade": "historica", "arquetipo": "Receptador de Relíquias",
		"paciencia": 0.80, "ganancia": 0.25,
		"gosta": ["Antiguidades"], "odeia": ["Eletrônicos"], "afinidade": 0,
	},
	"old_tomas": {
		"nome": "Velho Corvo", "cidade": "historica", "arquetipo": "Colecionador Clandestino",
		"paciencia": 0.70, "ganancia": 0.45,
		"gosta": ["Antiguidades", "Colecionáveis"], "odeia": [], "afinidade": 0,
	},
	"mano_leo": {
		"nome": "Mano Léo", "cidade": "favela", "arquetipo": "Atravessador",
		"paciencia": 0.45, "ganancia": 0.55,
		"gosta": ["Alimentos"], "odeia": [], "afinidade": 0,
	},
	"tia_dolores": {
		"nome": "Tia Dolores", "cidade": "favela", "arquetipo": "Receptador de Iguarias",
		"paciencia": 0.70, "ganancia": 0.30,
		"gosta": ["Alimentos"], "odeia": ["Antiguidades"], "afinidade": 0,
	},
	"coronel_sosa": {
		"nome": "Coronel Sosa", "cidade": "fronteira", "arquetipo": "Contrabandista Veterano",
		"paciencia": 0.80, "ganancia": 0.35,
		"gosta": ["Luxo"], "odeia": [], "afinidade": 0,
	},
	"la_guera": {
		"nome": "La Güera", "cidade": "fronteira", "arquetipo": "Comprador Discreto",
		"paciencia": 0.50, "ganancia": 0.25,
		"gosta": ["Luxo", "Colecionáveis"], "odeia": [], "afinidade": 0,
	},
	"o_espanhol": {
		"nome": "O Espanhol", "cidade": "subterraneo", "arquetipo": "Receptador de Relíquias",
		"paciencia": 0.75, "ganancia": 0.40,
		"gosta": ["Antiguidades"], "odeia": [], "afinidade": 0,
	},
	"bruxa_subsolo": {
		"nome": "Bruxa do Subsolo", "cidade": "subterraneo", "arquetipo": "Colecionador Clandestino",
		"paciencia": 0.65, "ganancia": 0.50,
		"gosta": ["Colecionáveis", "Antiguidades"], "odeia": [], "afinidade": 0,
	},
	"sussurro": {
		"nome": "Sussurro", "cidade": "subterraneo", "arquetipo": "Informante",
		"paciencia": 0.60, "ganancia": 0.45,
		"gosta": ["Luxo"], "odeia": [], "afinidade": 0,
	},
	"doca_porto": {
		"nome": "Doca", "cidade": "porto", "arquetipo": "Atravessador",
		"paciencia": 0.40, "ganancia": 0.55,
		"gosta": ["Alimentos"], "odeia": [], "afinidade": 0,
	},
	"velho_chico": {
		"nome": "Velho Chico", "cidade": "porto", "arquetipo": "Contrabandista Veterano",
		"paciencia": 0.85, "ganancia": 0.30,
		"gosta": ["Antiguidades"], "odeia": [], "afinidade": 0,
	},
	"ciganinha": {
		"nome": "Ciganinha", "cidade": "rural", "arquetipo": "Comprador Discreto",
		"paciencia": 0.55, "ganancia": 0.25,
		"gosta": ["Luxo", "Colecionáveis"], "odeia": [], "afinidade": 0,
	},
	"russo_centro": {
		"nome": "O Russo", "cidade": "centro", "arquetipo": "Informante",
		"paciencia": 0.60, "ganancia": 0.45,
		"gosta": ["Luxo"], "odeia": [], "afinidade": 0,
	},
	"frei_bento": {
		"nome": "Frei Bento", "cidade": "historica", "arquetipo": "Receptador de Relíquias",
		"paciencia": 0.80, "ganancia": 0.20,
		"gosta": ["Antiguidades"], "odeia": ["Luxo"], "afinidade": 0,
	},
	# --- Fornecedores: VENDEM itens exclusivos da cidade (compra-do-NPC) ---
	"forn_rural": {
		"nome": "Velho Tonho", "cidade": "rural", "arquetipo": "Fornecedor",
		"paciencia": 0.70, "ganancia": 0.35, "gosta": [], "odeia": [], "afinidade": 0,
	},
	"forn_centro": {
		"nome": "Madame X", "cidade": "centro", "arquetipo": "Fornecedor",
		"paciencia": 0.60, "ganancia": 0.40, "gosta": [], "odeia": [], "afinidade": 0,
	},
	"forn_porto": {
		"nome": "O Capataz", "cidade": "porto", "arquetipo": "Fornecedor",
		"paciencia": 0.65, "ganancia": 0.38, "gosta": [], "odeia": [], "afinidade": 0,
	},
	"forn_historica": {
		"nome": "O Antiquário", "cidade": "historica", "arquetipo": "Fornecedor",
		"paciencia": 0.75, "ganancia": 0.32, "gosta": [], "odeia": [], "afinidade": 0,
	},
	"forn_favela": {
		"nome": "O Patrão", "cidade": "favela", "arquetipo": "Fornecedor",
		"paciencia": 0.50, "ganancia": 0.45, "gosta": [], "odeia": [], "afinidade": 0,
	},
	"forn_fronteira": {
		"nome": "El Jefe", "cidade": "fronteira", "arquetipo": "Fornecedor",
		"paciencia": 0.70, "ganancia": 0.40, "gosta": [], "odeia": [], "afinidade": 0,
	},
	"forn_subterraneo": {
		"nome": "O Arquiteto", "cidade": "subterraneo", "arquetipo": "Fornecedor",
		"paciencia": 0.80, "ganancia": 0.50, "gosta": [], "odeia": [], "afinidade": 0,
	},
	# --- Atacadistas: compram em LOTE com bônus de volume ---
	"atac_fronteira": {
		"nome": "Gordo Atacado", "cidade": "fronteira", "arquetipo": "Atacadista",
		"paciencia": 0.45, "ganancia": 0.50, "gosta": [], "odeia": [], "afinidade": 0,
	},
	"atac_historica": {
		"nome": "Dona Feira", "cidade": "historica", "arquetipo": "Atacadista",
		"paciencia": 0.55, "ganancia": 0.40, "gosta": ["Alimentos"], "odeia": [], "afinidade": 0,
	},
}

func specialty(npc_id: String) -> String:
	var arch: String = String(NPCS[npc_id].arquetipo)
	match arch:
		"Contrabandista Veterano": return "Negocia de tudo, com paciência"
		"Receptador de Iguarias": return "Compra Alimentos — paga acima"
		"Atravessador": return "Compra em lote — bônus por volume"
		"Comprador Discreto": return "Quer Luxo e Colecionáveis"
		"Colecionador Clandestino": return "Paga PRÊMIO por itens Raros+"
		"Receptador de Relíquias": return "Quer Antiguidades — paga acima"
		"Informante": return "Vende dicas de mercado"
		"Fornecedor": return "VENDE itens exclusivos daqui"
		"Atacadista": return "Compra em LOTE — bônus por volume"
	return "Negocia diversos itens"

# Função de UI deste NPC: como o jogador interage com ele.
func npc_function(npc_id: String) -> String:
	match String(NPCS[npc_id].arquetipo):
		"Fornecedor": return "fornecedor"
		"Informante": return "informante"
		"Atacadista", "Atravessador": return "atacadista"
		"Colecionador Clandestino": return "colecionador"
	return "vender"

# Itens que o Fornecedor desta cidade vende (exclusivos/raros + Mítico no subterrâneo).
func supplier_stock(npc_id: String) -> Array:
	var city: String = String(NPCS[npc_id].cidade)
	var raros := ["Raro", "Épico", "Lendário"]
	var out: Array = []
	for pid in Economy.PRODUCTS:
		var p: Dictionary = Economy.PRODUCTS[pid]
		if Economy.origin_of(pid).has(city) and raros.has(String(p.raridade)):
			out.append(pid)
	if city == "subterraneo":
		out.append("diamante_negro")
	return out

# Preço de compra no Fornecedor: prêmio sobre o mercado, com desconto por afinidade.
func supplier_price(npc_id: String, product_id: String) -> float:
	var npc: Dictionary = NPCS[npc_id]
	var base_price: float = Economy.price_at(String(npc.cidade), product_id)
	var disc: float = clampf(float(npc.afinidade) * 0.0025, 0.0, 0.25)
	return snapped(base_price * 1.25 * (1.0 - disc), 1.0)

# Bônus de volume do Atacadista/Atravessador (até +30%).
func bulk_bonus(npc_id: String, qty: int) -> float:
	if npc_function(npc_id) != "atacadista":
		return 0.0
	return clampf(0.02 * float(qty), 0.0, 0.30)

# Prêmio do Colecionador para Raros+ (multiplicador extra no preço-alvo).
func is_collector(npc_id: String) -> bool:
	return npc_function(npc_id) == "colecionador"

const RAROS := ["Raro", "Épico", "Lendário", "Mítico"]

func present_in_city(city_id: String) -> Array:
	var out: Array = []
	for npc_id in NPCS:
		if NPCS[npc_id].cidade == city_id:
			out.append(npc_id)
	return out

func tier_name(afinidade: int) -> String:
	if afinidade <= 20: return "Estranho"
	elif afinidade <= 40: return "Conhecido"
	elif afinidade <= 60: return "Cliente"
	elif afinidade <= 80: return "Amigo"
	elif afinidade <= 95: return "Parceiro"
	else: return "Mentor"

func _affinity_margin(afinidade: int) -> float:
	if afinidade <= 20: return 0.0
	elif afinidade <= 40: return 0.02
	elif afinidade <= 60: return 0.05
	elif afinidade <= 80: return 0.08
	elif afinidade <= 95: return 0.12
	else: return 0.15

func _tolerancia(npc: Dictionary) -> float:
	return lerpf(0.05, 0.25, float(npc.paciencia))

func compute_bias(npc_id: String, product_id: String) -> float:
	var npc: Dictionary = NPCS[npc_id]
	var p: Dictionary = Economy.PRODUCTS[product_id]
	var cat: String = p.categoria
	var rar: String = p.raridade
	var bias: float = 0.0

	if npc.gosta.has(cat):
		bias += 0.20
	if npc.odeia.has(cat):
		bias -= 0.25

	match npc.arquetipo:
		"Colecionador Clandestino":
			if RAROS.has(rar):
				bias += 0.35
		"Receptador de Relíquias":
			if cat == "Antiguidades":
				bias += 0.25
		"Receptador de Iguarias":
			if cat == "Alimentos":
				bias += 0.18
		"Comprador Discreto":
			if cat == "Luxo" or cat == "Colecionáveis":
				bias += 0.15
		"Atravessador":
			bias -= 0.08

	bias += _affinity_margin(int(npc.afinidade))
	bias -= float(npc.ganancia) * 0.10
	return bias

func interest_label(npc_id: String, product_id: String) -> String:
	var b: float = compute_bias(npc_id, product_id)
	if b >= 0.15: return "Muito interessado"
	elif b >= 0.03: return "Interessado"
	elif b >= -0.06: return "Neutro"
	else: return "Desinteressado"

func evaluate_offer(npc_id: String, product_id: String, asking: float) -> Dictionary:
	var npc: Dictionary = NPCS[npc_id]
	var market: float = Economy.price_at(GameState.current_city_id, product_id)
	var bias: float = compute_bias(npc_id, product_id)
	var p_alvo: float = market * (1.0 + bias)
	var tol: float = _tolerancia(npc)
	var max_aceita: float = p_alvo * (1.0 + tol)

	var result := {
		"result": "refuse", "counter_price": p_alvo,
		"p_alvo": p_alvo, "market": market, "max_aceita": max_aceita,
	}

	if asking <= p_alvo:

		result.result = "accept"
	elif asking <= max_aceita:

		var span: float = max_aceita - p_alvo
		var centralidade: float = 1.0 if span <= 0.0 else 1.0 - (asking - p_alvo) / span
		if randf() < 0.40 + 0.50 * centralidade:
			result.result = "accept"
		else:
			result.result = "counter"
			result.counter_price = snapped((asking + p_alvo) * 0.5, 0.01)
	elif asking <= p_alvo * (1.0 + tol * 2.0):

		result.result = "counter"
		result.counter_price = snapped((asking + p_alvo) * 0.5, 0.01)
	else:
		result.result = "refuse"

	return result

func add_affinity(npc_id: String, delta: int) -> void:
	var npc: Dictionary = NPCS[npc_id]
	npc.afinidade = clampi(int(npc.afinidade) + delta, 0, 100)
	emit_signal("affinity_changed", npc_id)

# --- Combo de bons negócios (sessão) --------------------------------------
var deal_combo: int = 0

func register_good_deal() -> int:
	deal_combo += 1
	return deal_combo

func break_combo() -> void:
	deal_combo = 0

# Bônus de R$ por combo (até +30%).
func combo_bonus_frac() -> float:
	return clampf(0.03 * float(deal_combo), 0.0, 0.30)
