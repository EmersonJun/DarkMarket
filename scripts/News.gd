extends Node

signal news_changed

const EVENT_TEMPLATES := [
	{
		"id": "festival_milho",
		"titulo": "Mutirão na Roça",
		"descricao": "O Sertão Esquecido escoa mercadoria fresca. Comida valoriza aqui e na Cidade Velha.",
		"cidades": ["rural", "historica"],
		"mods": { "Alimentos": 1.80 },
		"pre_aviso_ticks": 1,
		"duracao_ticks": 4,
	},
	{
		"id": "crise_tech",
		"titulo": "Batida Policial",
		"descricao": "A polícia apertou o cerco. Luxo e colecionáveis despencam — hora de estocar barato.",
		"cidades": ["centro", "porto", "historica", "rural"],
		"mods": { "Luxo": 0.65, "Colecionáveis": 0.75 },
		"pre_aviso_ticks": 1,
		"duracao_ticks": 5,
	},
	{
		"id": "feira_internacional",
		"titulo": "Navio Contrabandeado Atracou",
		"descricao": "Carga ilegal chega ao Cais Sombrio. Relíquias e luxo disparam de preço.",
		"cidades": ["porto"],
		"mods": { "Antiguidades": 1.60, "Luxo": 1.40 },
		"pre_aviso_ticks": 1,
		"duracao_ticks": 4,
	},
	{
		"id": "descoberta_arqueologica",
		"titulo": "Saque Arqueológico",
		"descricao": "Túmulos violados despejam relíquias roubadas no mercado. Antiguidades nas alturas.",
		"cidades": ["historica", "centro"],
		"mods": { "Antiguidades": 2.10 },
		"pre_aviso_ticks": 2,
		"duracao_ticks": 3,
	},
	{
		"id": "black_friday",
		"titulo": "Saldão do Camelódromo",
		"descricao": "O Camelódromo desovou o estoque. Compre barato aqui e repasse caro fora.",
		"cidades": ["centro"],
		"mods": { "Luxo": 0.55, "Colecionáveis": 0.70, "Alimentos": 0.85 },
		"pre_aviso_ticks": 1,
		"duracao_ticks": 3,
	},
	{
		"id": "carnaval_portuario",
		"titulo": "Farra no Cais",
		"descricao": "Noite agitada no Cais Sombrio. Bebida e luxo vendem a peso de ouro.",
		"cidades": ["porto"],
		"mods": { "Alimentos": 1.55, "Luxo": 1.50 },
		"pre_aviso_ticks": 1,
		"duracao_ticks": 4,
	},
	{
		"id": "boom_industrial",
		"titulo": "Encomenda do Chefão",
		"descricao": "Um figurão quer relíquias pesadas e some com elas. Antiguidades em alta.",
		"cidades": ["rural", "porto"],
		"mods": { "Antiguidades": 1.45 },
		"pre_aviso_ticks": 1,
		"duracao_ticks": 3,
	},
	{
		"id": "convencao_colecionadores",
		"titulo": "Leilão Clandestino",
		"descricao": "Colecionadores clandestinos disputam raridades a peso de ouro.",
		"cidades": ["centro", "historica"],
		"mods": { "Colecionáveis": 2.30 },
		"pre_aviso_ticks": 2,
		"duracao_ticks": 3,
	},
]

var active_events: Array = []

func _ready() -> void:

	_spawn_event("festival_milho")

func advance_for_tick() -> void:

	var still_active: Array = []
	for ev in active_events:
		if ev.status == "pre":
			ev.ticks_para_inicio -= 1
			if ev.ticks_para_inicio <= 0:
				ev.status = "ativo"
			still_active.append(ev)
		elif ev.status == "ativo":
			ev.ticks_restantes -= 1
			if ev.ticks_restantes > 0:
				still_active.append(ev)
	active_events = still_active

	if active_events.size() < 3 and randf() < 0.25:
		var template = EVENT_TEMPLATES.pick_random()

		var ja_ativo := false
		for ev in active_events:
			if ev.template.id == template.id:
				ja_ativo = true
				break
		if not ja_ativo:
			_spawn_event(template.id)

	emit_signal("news_changed")

func _spawn_event(template_id: String) -> void:
	var template: Dictionary = {}
	for t in EVENT_TEMPLATES:
		if t.id == template_id:
			template = t
			break
	if template.is_empty():
		return
	active_events.append({
		"template": template,
		"ticks_para_inicio": template.pre_aviso_ticks,
		"ticks_restantes": template.duracao_ticks,
		"status": "pre",
	})
	emit_signal("news_changed")

func event_modifier(city_id: String, categoria: String) -> float:
	var mult := 1.0
	for ev in active_events:
		if ev.status != "ativo":
			continue
		if not ev.template.cidades.has(city_id):
			continue
		if ev.template.mods.has(categoria):
			mult *= float(ev.template.mods[categoria])
	return mult

func has_active_event_for(city_id: String, categoria: String) -> bool:
	for ev in active_events:
		if ev.status == "ativo" and ev.template.cidades.has(city_id) and ev.template.mods.has(categoria):
			return true
	return false

func _template_by_id(id: String) -> Dictionary:
	for t in EVENT_TEMPLATES:
		if t.id == id:
			return t
	return {}

func serialize() -> Array:
	var out: Array = []
	for ev in active_events:
		out.append({
			"id": ev.template.id,
			"pre": int(ev.ticks_para_inicio),
			"rest": int(ev.ticks_restantes),
			"status": String(ev.status),
		})
	return out

func deserialize(data) -> void:
	active_events.clear()
	if typeof(data) != TYPE_ARRAY:
		emit_signal("news_changed")
		return
	for d in data:
		if typeof(d) != TYPE_DICTIONARY:
			continue
		var t: Dictionary = _template_by_id(String(d.get("id", "")))
		if t.is_empty():
			continue
		active_events.append({
			"template": t,
			"ticks_para_inicio": int(d.get("pre", 0)),
			"ticks_restantes": int(d.get("rest", 0)),
			"status": String(d.get("status", "ativo")),
		})
	emit_signal("news_changed")
