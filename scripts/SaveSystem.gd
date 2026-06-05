extends Node

const SAVE_PATH := "user://mercado_save.json"
const IDLE_CAP_HOURS := 12.0
const SECONDS_PER_TICK := 900.0
const MAX_OFFLINE_TICKS := 48

var pending_report: Dictionary = {}
var _save_timer: Timer

func _ready() -> void:
	_save_timer = Timer.new()
	_save_timer.one_shot = true
	_save_timer.wait_time = 1.0
	_save_timer.timeout.connect(save_game)
	add_child(_save_timer)

	load_game()

	GameState.inventory_changed.connect(_request_save)
	GameState.city_changed.connect(func(_c): _request_save())
	NPCs.affinity_changed.connect(func(_id): _request_save())
	News.news_changed.connect(_request_save)
	Employees.roster_changed.connect(_request_save)
	Collection.collection_changed.connect(_request_save)
	Posts.posts_changed.connect(_request_save)
	Contracts.contracts_changed.connect(_request_save)
	Prestige.prestige_changed.connect(_request_save)
	DailyRewards.daily_changed.connect(_request_save)
	get_window().close_requested.connect(_on_close_requested)

	var periodic := Timer.new()
	periodic.wait_time = 20.0
	periodic.timeout.connect(save_game)
	add_child(periodic)
	periodic.start()

func _request_save() -> void:
	if _save_timer:
		_save_timer.start()

func _on_close_requested() -> void:
	save_game()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		save_game()

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_game() -> void:
	var data := {
		"version": 1,
		"last_played": Time.get_unix_time_from_system(),
		"money": GameState.money,
		"gems": GameState.gems,
		"city": GameState.current_city_id,
		"inventory": GameState.inventory.duplicate(),
		"tick": Economy.tick_count,
		"news": News.serialize(),
		"affinity": _collect_affinity(),
		"employees": Employees.serialize_hired(),
		"emp_next_id": Employees._next_id,
		"collection": Collection.serialize(),
		"posts": Posts.serialize(),
		"contracts": Contracts.serialize(),
		"prestige": Prestige.serialize(),
		"daily": DailyRewards.serialize(),
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(data))
	f.close()

func _collect_affinity() -> Dictionary:
	var out := {}
	for npc_id in NPCs.NPCS:
		out[npc_id] = int(NPCs.NPCS[npc_id].afinidade)
	return out

func load_game() -> void:
	if not has_save():
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var text := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var data: Dictionary = parsed

	GameState.money = float(data.get("money", GameState.money))
	GameState.gems = int(data.get("gems", GameState.gems))
	GameState.current_city_id = String(data.get("city", GameState.current_city_id))

	var inv = data.get("inventory", {})
	var new_inv := {}
	if typeof(inv) == TYPE_DICTIONARY:
		for k in inv:
			new_inv[String(k)] = int(inv[k])
	GameState.inventory = new_inv

	Economy.tick_count = int(data.get("tick", Economy.tick_count))

	if data.has("news"):
		News.deserialize(data.get("news", []))

	var aff = data.get("affinity", {})
	if typeof(aff) == TYPE_DICTIONARY:
		for npc_id in aff:
			if NPCs.NPCS.has(npc_id):
				NPCs.NPCS[npc_id].afinidade = int(aff[npc_id])

	Employees.deserialize_hired(data.get("employees", []), int(data.get("emp_next_id", Employees._next_id)))

	if data.has("collection"):
		Collection.deserialize(data.get("collection", {}))

	if data.has("posts"):
		Posts.deserialize(data.get("posts", {}))

	if data.has("contracts"):
		Contracts.deserialize(data.get("contracts", {}))

	if data.has("prestige"):
		Prestige.deserialize(data.get("prestige", {}))

	if data.has("daily"):
		DailyRewards.deserialize(data.get("daily", {}))

	_compute_idle(float(data.get("last_played", Time.get_unix_time_from_system())))

func _compute_idle(last_played: float) -> void:
	var now := Time.get_unix_time_from_system()
	var elapsed: float = maxf(0.0, now - last_played)
	var cap_seconds: float = IDLE_CAP_HOURS * 3600.0
	var capped: bool = elapsed > cap_seconds
	var eff: float = minf(elapsed, cap_seconds)

	var income: float = Posts.auto_income_per_second() * eff * Prestige.offline_mult()
	income += Employees.income_per_second() * eff * Prestige.income_mult() * Prestige.offline_mult()

	var ticks: int = clampi(int(eff / SECONDS_PER_TICK), 0, MAX_OFFLINE_TICKS)
	for i in ticks:
		Economy.advance_tick()

	if income > 0.0:
		GameState.money += income

	if elapsed >= 60.0:
		pending_report = {
			"away_seconds": elapsed,
			"income": income,
			"ticks": ticks,
			"capped": capped,
		}

func wipe() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)
