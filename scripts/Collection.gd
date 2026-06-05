extends Node

signal collection_changed

var products: Dictionary = {}
var npcs: Dictionary = {}
var events: Dictionary = {}
var cities: Dictionary = {}

func _ready() -> void:
	GameState.city_changed.connect(_on_city)
	GameState.inventory_changed.connect(_on_inventory)
	News.news_changed.connect(_on_news)

	_on_city(GameState.current_city_id)
	_on_inventory()
	_on_news()

func _on_city(city_id: String) -> void:
	var changed: bool = false
	if not cities.has(city_id):
		cities[city_id] = true
		changed = true
	for npc_id in NPCs.present_in_city(city_id):
		if not npcs.has(npc_id):
			npcs[npc_id] = true
			changed = true
	if changed:
		emit_signal("collection_changed")

func _on_inventory() -> void:
	var changed: bool = false
	for pid in GameState.inventory:
		if not products.has(pid):
			products[pid] = true
			changed = true
	if changed:
		emit_signal("collection_changed")

func _on_news() -> void:
	var changed: bool = false
	for ev in News.active_events:
		var id: String = String(ev.template.id)
		if not events.has(id):
			events[id] = true
			changed = true
	if changed:
		emit_signal("collection_changed")

func categories() -> Array:
	var out: Array = []
	for pid in Economy.PRODUCTS:
		var cat: String = String(Economy.PRODUCTS[pid].categoria)
		if not out.has(cat):
			out.append(cat)
	return out

func products_in_category(cat: String) -> Array:
	var out: Array = []
	for pid in Economy.PRODUCTS:
		if String(Economy.PRODUCTS[pid].categoria) == cat:
			out.append(pid)
	return out

func category_discovered(cat: String) -> int:
	var n: int = 0
	for pid in products_in_category(cat):
		if products.has(pid):
			n += 1
	return n

func category_complete(cat: String) -> bool:
	var list: Array = products_in_category(cat)
	return list.size() > 0 and category_discovered(cat) == list.size()

func completed_categories() -> int:
	var n: int = 0
	for cat in categories():
		if category_complete(cat):
			n += 1
	return n

func global_sell_multiplier() -> float:
	return 1.0 + 0.05 * float(completed_categories())

func discovered_products() -> int: return products.size()
func total_products() -> int: return Economy.PRODUCTS.size()
func discovered_npcs() -> int: return npcs.size()
func total_npcs() -> int: return NPCs.NPCS.size()
func discovered_events() -> int: return events.size()
func total_events() -> int: return News.EVENT_TEMPLATES.size()
func discovered_cities() -> int: return cities.size()
func total_cities() -> int: return Economy.CITIES.size()

func serialize() -> Dictionary:
	return {
		"products": products.keys(),
		"npcs": npcs.keys(),
		"events": events.keys(),
		"cities": cities.keys(),
	}

func deserialize(data) -> void:
	if typeof(data) != TYPE_DICTIONARY:
		return
	_load_set(products, data.get("products", []))
	_load_set(npcs, data.get("npcs", []))
	_load_set(events, data.get("events", []))
	_load_set(cities, data.get("cities", []))
	emit_signal("collection_changed")

func _load_set(target: Dictionary, arr) -> void:
	if typeof(arr) == TYPE_ARRAY:
		for k in arr:
			target[String(k)] = true
