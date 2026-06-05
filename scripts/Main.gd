extends Control

var NAV := [
	{ "id": "inicio", "label": "Império" },
	{ "id": "mercado", "label": "Mercado" },
	{ "id": "negociar", "label": "Negociar" },
	{ "id": "equipe", "label": "Equipe" },
	{ "id": "colecao", "label": "Coleção" },
	{ "id": "mais", "label": "Mais" },
]
var EXTRA_PAGES := ["contratos", "prestigio", "mochila", "noticias", "viajar"]

var COL_BG: Color
var COL_CARD: Color
var COL_PANEL: Color
var COL_ACCENT: Color
var COL_ACCENT2: Color
var COL_TEXT: Color
var COL_MUTED: Color

var bg_tex: TextureRect
var bg_gradient: Gradient
var money_label: Label
var rate_label: Label
var gems_label: Label
var pages_holder: Control
var pages := {}
var page_vbox := {}
var nav_buttons := {}
var current_page: String = "inicio"
var toast_label: Label
var overlay: Control
var post_widgets := {}

func _ready() -> void:
	COL_BG = Style.C_BG
	COL_CARD = Style.C_CARD
	COL_PANEL = Style.C_CARD_ALT
	COL_ACCENT = Style.C_GREEN
	COL_ACCENT2 = Style.C_ORANGE
	COL_TEXT = Style.C_INK
	COL_MUTED = Style.C_INK_SOFT

	_setup_window()
	_build_ui()
	_build_overlay()
	GameState.money_changed.connect(_on_money_changed)
	GameState.gems_changed.connect(_on_gems_changed)
	GameState.inventory_changed.connect(_refresh_all)
	GameState.city_changed.connect(_on_city_changed)
	Economy.market_tick.connect(_refresh_all)
	News.news_changed.connect(_refresh_news)
	NPCs.affinity_changed.connect(func(_id): _refresh_npcs())
	Employees.roster_changed.connect(_refresh_employees)
	Collection.collection_changed.connect(_refresh_collection)
	Posts.posts_changed.connect(_refresh_home)
	Posts.collected.connect(_on_collected)
	Contracts.contracts_changed.connect(_refresh_contratos)
	Prestige.prestige_changed.connect(_refresh_prestigio)
	Prestige.prestiged.connect(_on_prestiged)
	_on_money_changed(GameState.money)
	_on_gems_changed(GameState.gems)
	_on_city_changed(GameState.current_city_id)
	_toast("Toque num posto cheio para coletar. Melhore para crescer!")
	set_process(true)
	_maybe_welcome()

func _process(_delta: float) -> void:
	if current_page != "inicio":
		return

	var money := GameState.money
	var t := Time.get_ticks_msec() / 1000.0
	var pulse := 0.55 + 0.45 * (0.5 + 0.5 * sin(t * 6.0))
	for city_id in post_widgets:
		var w: Dictionary = post_widgets[city_id]
		var p: Dictionary = Posts.posts[city_id]
		var ready := Posts.is_ready(city_id)
		if is_instance_valid(w.bar):
			w.bar.value = p.progress * 100.0
		if is_instance_valid(w.ready_lbl):
			w.ready_lbl.visible = ready
			if ready:
				w.ready_lbl.modulate.a = pulse
		if is_instance_valid(w.cart) and is_instance_valid(w.prog):
			var pw: float = w.prog.size.x
			w.cart.position = Vector2((pw - 64.0) * float(p.progress), (w.prog.size.y - 64.0) * 0.5)
		if w.has("up_btn") and is_instance_valid(w.up_btn):
			w.up_btn.disabled = money < float(w.up_cost)
		if w.has("mg_btn") and is_instance_valid(w.mg_btn):
			w.mg_btn.disabled = money < float(w.mg_cost)
		if w.has("unlock_btn") and is_instance_valid(w.unlock_btn):
			w.unlock_btn.disabled = money < float(w.unlock_cost)
	if rate_label:
		rate_label.text = "R$ %s/s" % _fmt_money(Posts.auto_income_per_second())

func _setup_window() -> void:
	var win := get_window()
	win.min_size = Vector2i(360, 640)
	win.size = Vector2i(540, 960)
	var screen := DisplayServer.get_primary_screen()
	var screen_size := DisplayServer.screen_get_size(screen)
	var screen_pos := DisplayServer.screen_get_position(screen)
	win.position = screen_pos + (screen_size - win.size) / 2
	var root := get_tree().root
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	root.content_scale_size = Vector2i(1080, 1920)

func _flat(color: Color, radius: int = 20, border_col: Color = Color(0, 0, 0, 0), border: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 18
	sb.content_margin_bottom = 18
	if border > 0:
		sb.set_border_width_all(border)
		sb.border_color = border_col
	return sb

func _card(border_col: Color = Color(0, 0, 0, 0), border: int = 0) -> PanelContainer:
	var c := PanelContainer.new()
	var sb := Style.sb_card()
	if border > 0:
		sb.set_border_width_all(border)
		sb.border_color = border_col
	c.add_theme_stylebox_override("panel", sb)
	return c

func _style_button(btn: Button, fill: Color, fg: Color = Color(1, 1, 1), font_size: int = 32, min_h: int = 96) -> void:
	Style.style_candy(btn, fill, fill.darkened(0.22), fg, font_size, min_h)
	Style.bounce(btn)

func _rarity_chip(rarity: String) -> Label:
	return Style.chip(rarity, Style.rarity_color(rarity), Style.C_BG)

func _build_ui() -> void:
	bg_gradient = Gradient.new()
	bg_gradient.set_color(0, Style.C_SKY_TOP)
	bg_gradient.set_color(1, Style.C_BG)
	var gtex := GradientTexture2D.new()
	gtex.gradient = bg_gradient
	gtex.fill_from = Vector2(0, 0)
	gtex.fill_to = Vector2(0, 1)
	gtex.width = 8
	gtex.height = 256
	bg_tex = TextureRect.new()
	bg_tex.texture = gtex
	bg_tex.stretch_mode = TextureRect.STRETCH_SCALE
	bg_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg_tex)
	add_child(Style.make_vignette())

	var screen := VBoxContainer.new()
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.add_theme_constant_override("separation", 0)
	add_child(screen)

	screen.add_child(_build_header())

	var content_margin := MarginContainer.new()
	content_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_margin.add_theme_constant_override("margin_left", 24)
	content_margin.add_theme_constant_override("margin_right", 24)
	content_margin.add_theme_constant_override("margin_top", 8)
	content_margin.add_theme_constant_override("margin_bottom", 4)
	screen.add_child(content_margin)

	pages_holder = Control.new()
	pages_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pages_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_margin.add_child(pages_holder)

	for entry in NAV:
		_make_page(entry.id)
	for pid in EXTRA_PAGES:
		_make_page(pid)

	screen.add_child(_build_toast())
	screen.add_child(_build_bottom_nav())
	_show_page("inicio")

func _build_header() -> Control:
	var header := MarginContainer.new()
	header.add_theme_constant_override("margin_left", 28)
	header.add_theme_constant_override("margin_right", 28)
	header.add_theme_constant_override("margin_top", 40)
	header.add_theme_constant_override("margin_bottom", 12)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	header.add_child(row)

	var money_pill := PanelContainer.new()
	money_pill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var msb := Style.sb_pill(Style.C_CARD)
	msb.set_border_width_all(2)
	msb.border_color = Style.C_CYAN
	Style.neon(msb, Style.C_CYAN, 10, 0.35)
	msb.content_margin_top = 10
	msb.content_margin_bottom = 10
	money_pill.add_theme_stylebox_override("panel", msb)
	var mh := HBoxContainer.new()
	mh.add_theme_constant_override("separation", 10)
	money_pill.add_child(mh)
	mh.add_child(_icon("res://art/ui/coin.svg", 58))
	var mv := VBoxContainer.new()
	mv.add_theme_constant_override("separation", 0)
	mh.add_child(mv)
	money_label = Label.new()
	money_label.text = "R$ 0"
	Style.use_display(money_label, 42)
	money_label.add_theme_color_override("font_color", Style.C_INK)
	mv.add_child(money_label)
	rate_label = Label.new()
	rate_label.text = "R$ 0/s"
	rate_label.add_theme_font_size_override("font_size", 22)
	rate_label.add_theme_color_override("font_color", Style.C_GREEN)
	mv.add_child(rate_label)
	row.add_child(money_pill)

	var gem_pill := PanelContainer.new()
	var gsb := Style.sb_pill(Style.C_CARD)
	gsb.set_border_width_all(2)
	gsb.border_color = Style.C_GOLD
	Style.neon(gsb, Style.C_GOLD, 10, 0.35)
	gem_pill.add_theme_stylebox_override("panel", gsb)
	var gh := HBoxContainer.new()
	gh.add_theme_constant_override("separation", 8)
	gem_pill.add_child(gh)
	gh.add_child(_icon("res://art/ui/gem.svg", 52))
	gems_label = Label.new()
	gems_label.text = "0"
	Style.use_display(gems_label, 36)
	gems_label.add_theme_color_override("font_color", Style.C_INK)
	gh.add_child(gems_label)
	row.add_child(gem_pill)
	return header

func _icon(path: String, size: int) -> TextureRect:
	var t := TextureRect.new()
	if ResourceLoader.exists(path):
		t.texture = load(path)
	t.custom_minimum_size = Vector2(size, size)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return t

func _build_toast() -> Control:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 24)
	m.add_theme_constant_override("margin_right", 24)
	m.add_theme_constant_override("margin_top", 2)
	m.add_theme_constant_override("margin_bottom", 8)
	var panel := PanelContainer.new()
	var sb := Style.sb_flat(Style.C_CARD, 18)
	sb.shadow_color = Style.C_SHADOW
	sb.shadow_size = 6
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", sb)
	m.add_child(panel)
	toast_label = Label.new()
	toast_label.add_theme_font_size_override("font_size", 25)
	toast_label.add_theme_color_override("font_color", Style.C_INK_SOFT)
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_label.custom_minimum_size = Vector2(0, 52)
	toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(toast_label)
	return m

func _build_bottom_nav() -> PanelContainer:
	var nav := PanelContainer.new()
	var sb := Style.sb_flat(Style.C_CARD, 0)
	sb.shadow_color = Style.C_SHADOW
	sb.shadow_size = 14
	sb.shadow_offset = Vector2(0, -4)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	nav.add_theme_stylebox_override("panel", sb)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 4)
	nav.add_child(hb)
	for entry in NAV:
		var btn := Button.new()
		btn.text = entry.label
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.toggle_mode = true
		_style_nav_button(btn, entry.id == current_page)
		btn.pressed.connect(_show_page.bind(entry.id))
		hb.add_child(btn)
		nav_buttons[entry.id] = btn
	return nav

func _style_nav_button(btn: Button, active: bool) -> void:
	btn.custom_minimum_size = Vector2(0, 120)
	Style.use_display(btn, 20)
	btn.clip_text = true
	var fg := Style.C_BG if active else Style.C_INK_SOFT
	btn.add_theme_color_override("font_color", fg)
	btn.add_theme_color_override("font_hover_color", Style.C_INK)
	btn.add_theme_color_override("font_pressed_color", fg)
	var transp := _nav_sb(Color(0, 0, 0, 0))
	if active:
		var on := _nav_sb(Style.C_CYAN)
		Style.neon(on, Style.C_CYAN, 12, 0.5)
		btn.add_theme_stylebox_override("normal", on)
		btn.add_theme_stylebox_override("hover", on)
		btn.add_theme_stylebox_override("pressed", on)
	else:
		btn.add_theme_stylebox_override("normal", transp)
		btn.add_theme_stylebox_override("hover", _nav_sb(Style.C_CARD_ALT))
		btn.add_theme_stylebox_override("pressed", transp)
	btn.add_theme_stylebox_override("focus", transp)

func _nav_sb(color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(18)
	sb.content_margin_left = 4
	sb.content_margin_right = 4
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	return sb

func _make_page(id: String) -> void:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 16)
	scroll.add_child(v)
	pages_holder.add_child(scroll)
	pages[id] = scroll
	page_vbox[id] = v

func _show_page(id: String) -> void:
	current_page = id
	for pid in pages:
		pages[pid].visible = (pid == id)
	var nav_active := id
	if EXTRA_PAGES.has(id):
		nav_active = "mais"
	for pid in nav_buttons:
		_style_nav_button(nav_buttons[pid], pid == nav_active)
		nav_buttons[pid].button_pressed = (pid == nav_active)
	_refresh_all()

func _build_overlay() -> void:
	overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

func _on_money_changed(v: float) -> void:
	if money_label:
		money_label.text = "R$ %s" % _fmt_money(v)

func _on_gems_changed(v: int) -> void:
	if gems_label:
		gems_label.text = str(v)

func _on_city_changed(_id: String) -> void:
	var c: Dictionary = Economy.CITIES[GameState.current_city_id]
	if bg_gradient:
		bg_gradient.set_color(0, Style.C_SKY_TOP.lerp(c.cor.darkened(0.45), 0.5))
		bg_gradient.set_color(1, Style.C_BG)
	_refresh_all()

func _refresh_all() -> void:
	_refresh_home()
	_refresh_market()
	_refresh_inventory()
	_refresh_npcs()
	_refresh_news()
	_refresh_travel()
	_refresh_employees()
	_refresh_collection()
	_refresh_contratos()
	_refresh_prestigio()
	_refresh_mais()

func _refresh_home() -> void:
	if not page_vbox.has("inicio"):
		return
	var v: VBoxContainer = page_vbox["inicio"]
	_clear(v)
	post_widgets.clear()
	for city_id in Posts.ORDER:
		v.add_child(_post_card(city_id))

	var boost := Button.new()
	if Posts.boost_seconds_left > 0.0:
		boost.text = "BOOST 2× ATIVO (%ds)" % int(Posts.boost_seconds_left)
		_style_button(boost, Style.C_NEUTRAL, Color.WHITE, 26, 80)
		boost.disabled = true
	else:
		boost.text = "Ativar Boost 2× — 5 gemas"
		_style_button(boost, Style.C_BLUE, Color.WHITE, 26, 80)
		boost.disabled = not Posts.can_boost()
		boost.pressed.connect(func(): Posts.activate_boost())
	v.add_child(boost)

func _empty_sb() -> StyleBoxEmpty:
	return StyleBoxEmpty.new()

func _make_passthrough(node: Node) -> void:
	if node is Button:
		return
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_make_passthrough(child)

func _post_card(city_id: String) -> PanelContainer:
	var p: Dictionary = Posts.posts[city_id]
	var c: Dictionary = Economy.CITIES[city_id]
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", Style.sb_card_neon(c.cor.lerp(Style.C_CYAN, 0.25)))
	post_widgets[city_id] = { "bar": null, "cart": null, "prog": null, "card": card, "ready_lbl": null }

	var collect := Button.new()
	collect.flat = true
	collect.focus_mode = Control.FOCUS_NONE
	collect.add_theme_stylebox_override("normal", _empty_sb())
	collect.add_theme_stylebox_override("hover", _empty_sb())
	collect.add_theme_stylebox_override("pressed", _empty_sb())
	collect.add_theme_stylebox_override("focus", _empty_sb())
	collect.pressed.connect(_try_collect.bind(city_id))
	card.add_child(collect)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	card.add_child(box)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	box.add_child(top)
	top.add_child(_icon("res://art/mascot.svg", 96))
	var namebox := VBoxContainer.new()
	namebox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	namebox.add_theme_constant_override("separation", 2)
	top.add_child(namebox)
	var nm := Label.new()
	nm.text = c.nome
	Style.use_display(nm, 34)
	nm.add_theme_color_override("font_color", Style.C_INK)
	namebox.add_child(nm)
	if p.unlocked:
		namebox.add_child(Style.chip("Nível %d" % int(p.nivel), Style.C_BLUE))

	if not p.unlocked:
		var lock := HBoxContainer.new()
		lock.add_theme_constant_override("separation", 10)
		lock.add_child(_icon("res://art/ui/lock.svg", 56))
		var ub := Button.new()
		ub.text = "Desbloquear — R$ %s" % _fmt_money(Posts.unlock_cost(city_id))
		ub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_style_button(ub, Style.C_ORANGE, Color.WHITE, 28, 92)
		ub.disabled = GameState.money < Posts.unlock_cost(city_id)
		ub.pressed.connect(func(): Posts.buy_unlock(city_id))
		lock.add_child(ub)
		box.add_child(lock)
		post_widgets[city_id]["unlock_btn"] = ub
		post_widgets[city_id]["unlock_cost"] = Posts.unlock_cost(city_id)
		_make_passthrough(box)
		return card

	var prog := Control.new()
	prog.custom_minimum_size = Vector2(0, 84)
	box.add_child(prog)
	var bar := Style.progress(0, 100, c.cor.lerp(Style.C_GREEN, 0.4))
	bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	bar.offset_top = 14
	bar.offset_bottom = -14
	prog.add_child(bar)
	var cart := _icon("res://art/ui/cart.svg", 64)
	prog.add_child(cart)
	var ready_lbl := Label.new()
	ready_lbl.text = "TOQUE PARA COLETAR"
	ready_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	ready_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ready_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	Style.use_display(ready_lbl, 26)
	ready_lbl.add_theme_color_override("font_color", Style.C_BG)
	ready_lbl.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.7))
	ready_lbl.add_theme_constant_override("outline_size", 6)
	ready_lbl.visible = false
	prog.add_child(ready_lbl)
	post_widgets[city_id].bar = bar
	post_widgets[city_id].cart = cart
	post_widgets[city_id].prog = prog
	post_widgets[city_id].ready_lbl = ready_lbl

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	var ucost := Posts.upgrade_cost(city_id)
	var up := Button.new()
	up.text = "Melhorar  R$ %s\n+R$ %s/ciclo" % [_fmt_money(ucost), _fmt_money(Posts.income_per_cycle(city_id))]
	up.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(up, Style.C_GREEN, Color.WHITE, 24, 96)
	up.disabled = GameState.money < ucost
	up.pressed.connect(func(): Posts.buy_upgrade(city_id))
	row.add_child(up)
	post_widgets[city_id]["up_btn"] = up
	post_widgets[city_id]["up_cost"] = ucost
	if p.manager:
		var auto := Style.chip("AUTO", Style.C_GREEN)
		auto.custom_minimum_size = Vector2(150, 0)
		auto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		auto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(auto)
	else:
		var mcost := Posts.manager_cost(city_id)
		var mg := Button.new()
		mg.text = "Gerente\nR$ %s" % _fmt_money(mcost)
		mg.custom_minimum_size = Vector2(230, 0)
		_style_button(mg, Style.C_ORANGE, Color.WHITE, 24, 96)
		mg.disabled = GameState.money < mcost
		mg.pressed.connect(func(): Posts.buy_manager(city_id))
		row.add_child(mg)
		post_widgets[city_id]["mg_btn"] = mg
		post_widgets[city_id]["mg_cost"] = mcost

	_make_passthrough(box)
	return card

func _try_collect(city_id: String) -> void:
	if Posts.is_ready(city_id):
		Posts.collect(city_id)

func _on_collected(city_id: String, amount: float) -> void:
	if not post_widgets.has(city_id):
		return
	var w: Dictionary = post_widgets[city_id]
	if is_instance_valid(w.card):
		Style.pop(w.card)
		var gp: Vector2 = w.card.global_position + Vector2(w.card.size.x * 0.5, 20)
		_float_text("+R$ %s" % _fmt_money(amount), gp, Style.C_GREEN)

func _city_banner() -> PanelContainer:
	var c: Dictionary = Economy.CITIES[GameState.current_city_id]
	var accent: Color = c.cor.lerp(Style.C_CYAN, 0.3)
	var pc := PanelContainer.new()
	var sb := Style.sb_flat(Style.C_CARD, 18)
	sb.set_border_width_all(2)
	sb.border_color = accent
	Style.neon(sb, accent, 8, 0.3)
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	pc.add_theme_stylebox_override("panel", sb)
	var lbl := Label.new()
	lbl.text = c.nome
	Style.use_display(lbl, 30)
	lbl.add_theme_color_override("font_color", accent)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pc.add_child(lbl)
	return pc

func _float_text(text: String, gpos: Vector2, color: Color) -> void:
	var lbl := Label.new()
	lbl.text = text
	Style.use_display(lbl, 40)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_outline_color", Color.WHITE)
	lbl.add_theme_constant_override("outline_size", 8)
	lbl.position = gpos - Vector2(60, 0)
	lbl.z_index = 50
	overlay.add_child(lbl)
	var tw := lbl.create_tween().set_parallel(true)
	tw.tween_property(lbl, "position:y", gpos.y - 120.0, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.9)
	tw.chain().tween_callback(lbl.queue_free)

func _refresh_mais() -> void:
	if not page_vbox.has("mais"):
		return
	var v: VBoxContainer = page_vbox["mais"]
	_clear(v)
	var done: int = 0
	for c in Contracts.active:
		if Contracts.is_complete(c):
			done += 1
	var contratos_label: String = "Contratos"
	if done > 0:
		contratos_label = "Contratos  (%d pronto%s!)" % [done, "s" if done > 1 else ""]
	var prest_label: String = "Prestígio"
	if Prestige.can_prestige():
		prest_label = "Prestígio  (+%d disponível!)" % Prestige.pp_gain(GameState.money)
	var items := [
		{ "id": "prestigio", "label": prest_label, "hot": Prestige.can_prestige() },
		{ "id": "contratos", "label": contratos_label, "hot": done > 0 },
		{ "id": "viajar", "label": "Viajar entre cidades", "hot": false },
		{ "id": "mochila", "label": "Mochila", "hot": false },
		{ "id": "noticias", "label": "Notícias do mercado", "hot": false },
	]
	for it in items:
		var b := Button.new()
		b.text = it.label
		var hot: bool = it.hot
		var fill: Color = (Style.C_MAGENTA if it.id == "prestigio" else Style.C_GREEN) if hot else Style.C_CARD_ALT
		var fg: Color = Color.WHITE if hot else Style.C_INK
		_style_button(b, fill, fg, 30, 104)
		b.pressed.connect(_show_page.bind(it.id))
		v.add_child(b)

func _refresh_contratos() -> void:
	if not page_vbox.has("contratos"):
		return
	var v: VBoxContainer = page_vbox["contratos"]
	_clear(v)
	v.add_child(_section_label("Contratos do submundo"))
	for c in Contracts.active:
		var card := _card()
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 8)
		card.add_child(box)
		var desc := Label.new()
		desc.text = Contracts.descricao(c)
		Style.use_display(desc, 28)
		desc.add_theme_color_override("font_color", Style.C_INK)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(desc)
		box.add_child(Style.progress(int(c.progresso), int(c.alvo), Style.C_CYAN))
		var info := HBoxContainer.new()
		var prog := Label.new()
		prog.text = "%d / %d" % [int(c.progresso), int(c.alvo)]
		prog.add_theme_font_size_override("font_size", 22)
		prog.add_theme_color_override("font_color", Style.C_INK_SOFT)
		prog.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_child(prog)
		var rew := Label.new()
		var rtxt := "Recompensa: R$ %s" % _fmt_money(float(c.reward))
		if int(c.gems) > 0:
			rtxt += "  + %d gemas" % int(c.gems)
		rew.text = rtxt
		Style.use_display(rew, 22)
		rew.add_theme_color_override("font_color", Style.C_GOLD)
		info.add_child(rew)
		box.add_child(info)
		var claim := Button.new()
		claim.text = "Coletar recompensa" if Contracts.is_complete(c) else "Em andamento"
		claim.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_style_button(claim, Style.C_GREEN if Contracts.is_complete(c) else Style.C_NEUTRAL, Color.WHITE, 26, 88)
		claim.disabled = not Contracts.is_complete(c)
		claim.pressed.connect(_claim_contract.bind(c))
		box.add_child(claim)
		v.add_child(card)

func _claim_contract(c: Dictionary) -> void:
	if Contracts.claim(c):
		_toast("Contrato concluído! Recompensa coletada.")

func _refresh_prestigio() -> void:
	if not page_vbox.has("prestigio"):
		return
	var v: VBoxContainer = page_vbox["prestigio"]
	_clear(v)

	var head := _card(Style.C_MAGENTA, 4)
	var hb := VBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	head.add_child(hb)
	var t := Label.new()
	t.text = "%s — Prestígio %d" % [Prestige.title(), Prestige.count]
	Style.use_display(t, 34)
	t.add_theme_color_override("font_color", Style.C_MAGENTA)
	hb.add_child(t)
	hb.add_child(_kv("Pontos disponíveis", str(Prestige.pp), Style.C_GOLD))
	hb.add_child(_kv("Total acumulado", str(Prestige.total_pp), Style.C_INK_SOFT))
	v.add_child(head)

	var bonus := _card()
	var bb := VBoxContainer.new()
	bb.add_theme_constant_override("separation", 4)
	bonus.add_child(bb)
	bb.add_child(_section_label("Bônus permanentes"))
	bb.add_child(_kv("Renda dos postos", "+%d%%" % int(round((Prestige.income_mult() - 1.0) * 100.0)), Style.C_GREEN))
	bb.add_child(_kv("Velocidade dos ciclos", "+%d%%" % int(round((Prestige.speed_mult() - 1.0) * 100.0)), Style.C_CYAN))
	bb.add_child(_kv("Preço de venda", "+%d%%" % int(round((Prestige.sell_mult() - 1.0) * 100.0)), Style.C_ORANGE))
	bb.add_child(_kv("Renda offline", "+%d%%" % int(round((Prestige.offline_mult() - 1.0) * 100.0)), Style.C_GREEN))
	bb.add_child(_kv("Espólio mantido", "%d%%" % int(round(Prestige.keep_fraction() * 100.0)), Style.C_GOLD))
	v.add_child(bonus)

	var refound := _card(Style.C_MAGENTA, 3)
	var rb := VBoxContainer.new()
	rb.add_theme_constant_override("separation", 8)
	refound.add_child(rb)
	rb.add_child(_section_label("Refundar o Império"))
	var explain := Label.new()
	explain.text = "Recomeça do zero (postos, equipe, dinheiro), mas ganha Pontos de Prestígio para gastar em bônus permanentes. Coleção e gemas são mantidas."
	explain.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explain.add_theme_font_size_override("font_size", 23)
	explain.add_theme_color_override("font_color", Style.C_INK_SOFT)
	rb.add_child(explain)
	var pbtn := Button.new()
	if Prestige.can_prestige():
		pbtn.text = "Refundar — ganhar %d Pontos" % Prestige.pp_gain(GameState.money)
	else:
		pbtn.text = "Precisa de R$ %s" % _fmt_money(Prestige.MIN_MONEY)
	pbtn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(pbtn, Style.C_MAGENTA, Color.WHITE, 28, 108)
	pbtn.disabled = not Prestige.can_prestige()
	pbtn.pressed.connect(_confirm_prestige)
	rb.add_child(pbtn)
	v.add_child(refound)

	v.add_child(_section_label("Talentos"))
	for id in Prestige.ORDER:
		var info: Dictionary = Prestige.TALENTS[id]
		var card := _card()
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 6)
		card.add_child(box)
		var row := HBoxContainer.new()
		var nm := Label.new()
		nm.text = info.nome
		Style.use_display(nm, 28)
		nm.add_theme_color_override("font_color", Style.C_INK)
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(nm)
		row.add_child(Style.chip("Nível %d" % Prestige.level(id), Style.C_BLUE))
		box.add_child(row)
		var d := Label.new()
		d.text = info.desc
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.add_theme_font_size_override("font_size", 22)
		d.add_theme_color_override("font_color", Style.C_INK_SOFT)
		box.add_child(d)
		var cost: int = Prestige.talent_cost(id)
		var buy := Button.new()
		buy.text = "Comprar — %d PP" % cost
		buy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_style_button(buy, Style.C_GREEN, Color.WHITE, 24, 86)
		buy.disabled = not Prestige.can_buy(id)
		buy.pressed.connect(_buy_talent.bind(id))
		box.add_child(buy)
		v.add_child(card)

func _buy_talent(id: String) -> void:
	if Prestige.buy_talent(id):
		_toast("Talento aprimorado.")
	else:
		_toast("Pontos de Prestígio insuficientes.")

func _confirm_prestige() -> void:
	var parts := _modal_panel(Style.C_MAGENTA)
	var dim: ColorRect = parts[0]
	var box: VBoxContainer = parts[1]
	var ti := Style.title("Refundar o Império?", 38, Style.C_INK)
	ti.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(ti)
	box.add_child(_centered_line("Você ganhará %d Pontos de Prestígio, mas recomeça do zero." % Prestige.pp_gain(GameState.money), 26, Style.C_INK_SOFT))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	var cancel := Button.new()
	cancel.text = "Cancelar"
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(cancel, Style.C_NEUTRAL, Color.WHITE, 30, 100)
	cancel.pressed.connect(dim.queue_free)
	row.add_child(cancel)
	var ok := Button.new()
	ok.text = "Refundar"
	ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(ok, Style.C_MAGENTA, Color.WHITE, 30, 100)
	ok.pressed.connect(_do_prestige_now.bind(dim))
	row.add_child(ok)

func _do_prestige_now(dim: ColorRect) -> void:
	if is_instance_valid(dim):
		dim.queue_free()
	Prestige.do_prestige()

func _on_prestiged(pp_gained: int) -> void:
	var parts := _modal_panel(Style.C_GOLD)
	var dim: ColorRect = parts[0]
	var box: VBoxContainer = parts[1]
	var ti := Style.title("Império Refundado!", 42, Style.C_GOLD)
	ti.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(ti)
	box.add_child(_centered_line("Novo título: %s" % Prestige.title(), 28, Style.C_INK))
	var big := Style.title("+%d Pontos de Prestígio" % pp_gained, 48, Style.C_MAGENTA)
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(big)
	var btn := Button.new()
	btn.text = "Continuar"
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(btn, Style.C_GREEN, Color.WHITE, 34, 108)
	btn.pressed.connect(dim.queue_free)
	box.add_child(btn)
	_show_page("inicio")

func _refresh_market() -> void:
	var v: VBoxContainer = page_vbox["mercado"]
	_clear(v)
	v.add_child(_city_banner())
	for product_id in Economy.PRODUCTS:
		var p: Dictionary = Economy.PRODUCTS[product_id]
		var price: float = Economy.price_at(GameState.current_city_id, product_id)
		var hot: bool = Economy.has_event_for(GameState.current_city_id, product_id)
		var owned: int = GameState.inventory.get(product_id, 0)

		var card := _card()
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 14)
		card.add_child(hb)

		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_constant_override("separation", 6)
		hb.add_child(info)

		var name_lbl := Label.new()
		name_lbl.text = p.nome
		Style.use_display(name_lbl, 34)
		name_lbl.add_theme_color_override("font_color", Style.C_INK)
		info.add_child(name_lbl)

		var chips := HBoxContainer.new()
		chips.add_theme_constant_override("separation", 8)
		chips.add_child(_rarity_chip(p.raridade))
		if hot:
			chips.add_child(Style.chip("EM ALTA", Style.C_ORANGE))
		if owned > 0:
			chips.add_child(Style.chip("tem %d" % owned, Style.C_CARD_ALT, Style.C_INK_SOFT))
		info.add_child(chips)

		var sub := Label.new()
		sub.text = "R$ %s" % _fmt_money(price)
		Style.use_display(sub, 30)
		sub.add_theme_color_override("font_color", Style.C_GREEN)
		info.add_child(sub)

		var btns := VBoxContainer.new()
		btns.add_theme_constant_override("separation", 8)
		hb.add_child(btns)
		var buy := Button.new()
		buy.text = "Comprar"
		buy.custom_minimum_size = Vector2(190, 0)
		_style_button(buy, Style.C_GREEN, Color.WHITE, 28, 78)
		buy.disabled = GameState.money < price or GameState.capacity_left() < float(p.peso)
		buy.pressed.connect(_buy.bind(product_id))
		btns.add_child(buy)
		var sell := Button.new()
		sell.text = "Vender"
		sell.custom_minimum_size = Vector2(190, 0)
		_style_button(sell, Style.C_ORANGE, Color.WHITE, 28, 78)
		sell.disabled = owned <= 0
		sell.pressed.connect(_sell.bind(product_id))
		btns.add_child(sell)

		v.add_child(card)

func _refresh_inventory() -> void:
	var v: VBoxContainer = page_vbox["mochila"]
	_clear(v)
	if GameState.inventory.is_empty():
		v.add_child(_empty_label("Mochila vazia. Compre algo no Mercado."))
	else:
		for product_id in GameState.inventory:
			var p: Dictionary = Economy.PRODUCTS[product_id]
			var qty: int = GameState.inventory[product_id]
			var price: float = Economy.price_at(GameState.current_city_id, product_id)
			var card := _card()
			var box := VBoxContainer.new()
			box.add_theme_constant_override("separation", 6)
			card.add_child(box)
			var t := Label.new()
			t.text = "%d × %s" % [qty, p.nome]
			Style.use_display(t, 32)
			t.add_theme_color_override("font_color", Style.C_INK)
			box.add_child(t)
			var chips := HBoxContainer.new()
			chips.add_theme_constant_override("separation", 8)
			chips.add_child(_rarity_chip(p.raridade))
			box.add_child(chips)
			var s := Label.new()
			s.text = "Vale R$ %s cada · total R$ %s" % [_fmt_money(price), _fmt_money(price * qty)]
			s.add_theme_font_size_override("font_size", 25)
			s.add_theme_color_override("font_color", Style.C_INK_SOFT)
			box.add_child(s)
			v.add_child(card)
	var sep := Control.new()
	sep.custom_minimum_size = Vector2(0, 16)
	v.add_child(sep)
	var idle_btn := Button.new()
	idle_btn.text = "Simular 6h offline (teste)"
	_style_button(idle_btn, Style.C_NEUTRAL, Color.WHITE, 26, 82)
	idle_btn.pressed.connect(_debug_idle.bind(6.0))
	v.add_child(idle_btn)
	var wipe_btn := Button.new()
	wipe_btn.text = "Reiniciar progresso"
	_style_button(wipe_btn, Style.C_RED, Color.WHITE, 26, 78)
	wipe_btn.pressed.connect(_confirm_wipe)
	v.add_child(wipe_btn)

func _refresh_npcs() -> void:
	if not page_vbox.has("negociar"):
		return
	var v: VBoxContainer = page_vbox["negociar"]
	_clear(v)
	v.add_child(_city_banner())
	var present: Array = NPCs.present_in_city(GameState.current_city_id)
	if present.is_empty():
		v.add_child(_empty_label("Nenhum comerciante por aqui agora."))
		return
	for npc_id in present:
		var npc: Dictionary = NPCs.NPCS[npc_id]
		var card := _card()
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 14)
		hb.alignment = BoxContainer.ALIGNMENT_CENTER
		card.add_child(hb)

		var ring := Style.ring_color(npc_id)
		hb.add_child(Style.avatar_badge(Style.npc_face_path(npc.arquetipo), ring, 116))
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_constant_override("separation", 6)
		hb.add_child(info)
		var nome := Label.new()
		nome.text = npc.nome
		Style.use_display(nome, 32)
		nome.add_theme_color_override("font_color", Style.C_INK)
		info.add_child(nome)
		var chips := HBoxContainer.new()
		chips.add_theme_constant_override("separation", 8)
		chips.add_child(Style.chip(npc.arquetipo, Style.C_BLUE))
		info.add_child(chips)
		var spec := Label.new()
		spec.text = NPCs.specialty(npc_id)
		spec.add_theme_font_size_override("font_size", 22)
		spec.add_theme_color_override("font_color", Style.C_CYAN)
		spec.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_child(spec)
		var rel := Label.new()
		rel.text = "%s · %d/100" % [NPCs.tier_name(int(npc.afinidade)), int(npc.afinidade)]
		rel.add_theme_font_size_override("font_size", 21)
		rel.add_theme_color_override("font_color", Style.C_INK_SOFT)
		info.add_child(rel)
		var btn := Button.new()
		btn.text = "Negociar"
		btn.custom_minimum_size = Vector2(190, 0)
		_style_button(btn, Style.C_GREEN, Color.WHITE, 26, 96)
		btn.pressed.connect(_open_negotiation.bind(npc_id))
		hb.add_child(btn)
		v.add_child(card)

func _refresh_news() -> void:
	if not page_vbox.has("noticias"):
		return
	var v: VBoxContainer = page_vbox["noticias"]
	_clear(v)
	if News.active_events.is_empty():
		v.add_child(_empty_label("Nenhuma notícia no rádio agora."))
		return
	for ev in News.active_events:
		var ativo: bool = ev.status == "ativo"
		var border := Style.C_ORANGE if ativo else Style.C_CARD_ALT
		var card := _card(border, 4)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 8)
		card.add_child(box)
		var titulo := Label.new()
		titulo.text = ev.template.titulo
		Style.use_display(titulo, 30)
		titulo.add_theme_color_override("font_color", Style.C_INK)
		box.add_child(titulo)
		box.add_child(Style.chip("ATIVO" if ativo else "EM BREVE", Style.C_ORANGE if ativo else Style.C_NEUTRAL))
		var desc := Label.new()
		desc.text = ev.template.descricao
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.add_theme_font_size_override("font_size", 25)
		desc.add_theme_color_override("font_color", Style.C_INK)
		box.add_child(desc)
		var cidades := PackedStringArray()
		for cid in ev.template.cidades:
			cidades.append(Economy.CITIES[cid].nome)
		var timing := ("começa em %d viagens" % ev.ticks_para_inicio) if not ativo else ("acaba em %d viagens" % ev.ticks_restantes)
		var meta := Label.new()
		meta.text = "%s · %s" % [", ".join(cidades), timing]
		meta.add_theme_font_size_override("font_size", 22)
		meta.add_theme_color_override("font_color", Style.C_INK_SOFT)
		box.add_child(meta)
		v.add_child(card)

func _refresh_travel() -> void:
	if not page_vbox.has("viajar"):
		return
	var v: VBoxContainer = page_vbox["viajar"]
	_clear(v)
	for city_id in Economy.CITIES:
		if city_id == GameState.current_city_id:
			continue
		var c: Dictionary = Economy.CITIES[city_id]
		var btn := Button.new()
		btn.text = "Viajar para %s" % c.nome
		_style_button(btn, c.cor.lerp(Color.WHITE, 0.1), Color.WHITE, 32, 110)
		btn.pressed.connect(_travel.bind(city_id))
		v.add_child(btn)

func _refresh_employees() -> void:
	if not page_vbox.has("equipe"):
		return
	var v: VBoxContainer = page_vbox["equipe"]
	_clear(v)

	var inc: float = Employees.total_income_per_hour()
	var sal: float = Employees.total_salary_per_hour()
	var net: float = inc - sal
	var sumcard := _card()
	var sb := VBoxContainer.new()
	sb.add_theme_constant_override("separation", 6)
	sumcard.add_child(sb)
	sb.add_child(_kv("Renda da equipe", "+R$ %s/h" % _fmt_money(inc), Style.C_GREEN))
	sb.add_child(_kv("Salários", "-R$ %s/h" % _fmt_money(sal), Style.C_INK_SOFT))
	sb.add_child(_kv("Líquido", "+R$ %s/h" % _fmt_money(maxf(0.0, net)), Style.C_ORANGE))
	v.add_child(sumcard)

	v.add_child(_section_label("Sua equipe (%d)" % Employees.hired.size()))
	if Employees.hired.is_empty():
		v.add_child(_empty_label("Nenhum funcionário ainda. Contrate abaixo para gerar renda passiva (online e offline)."))
	else:
		for emp in Employees.hired:
			v.add_child(_employee_card(emp, true))

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	var hl := _section_label("Disponíveis")
	hl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(hl)
	var rbtn := Button.new()
	rbtn.text = "Atualizar"
	rbtn.custom_minimum_size = Vector2(210, 0)
	_style_button(rbtn, Style.C_NEUTRAL, Color.WHITE, 24, 64)
	rbtn.pressed.connect(func(): Employees.refresh_candidates(4))
	head.add_child(rbtn)
	v.add_child(head)
	for emp in Employees.candidates:
		v.add_child(_employee_card(emp, false))

func _kv(k: String, val: String, val_color: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	var a := Label.new()
	a.text = k
	a.add_theme_font_size_override("font_size", 26)
	a.add_theme_color_override("font_color", Style.C_INK_SOFT)
	a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(a)
	var b := Label.new()
	b.text = val
	Style.use_display(b, 28)
	b.add_theme_color_override("font_color", val_color)
	row.add_child(b)
	return row

func _refresh_collection() -> void:
	if not page_vbox.has("colecao"):
		return
	var v: VBoxContainer = page_vbox["colecao"]
	_clear(v)

	var card := _card()
	var sb := VBoxContainer.new()
	sb.add_theme_constant_override("separation", 8)
	card.add_child(sb)
	sb.add_child(_kv("Produtos", "%d / %d" % [Collection.discovered_products(), Collection.total_products()], Style.C_INK))
	sb.add_child(_kv("NPCs", "%d / %d" % [Collection.discovered_npcs(), Collection.total_npcs()], Style.C_INK))
	sb.add_child(_kv("Cidades", "%d / %d" % [Collection.discovered_cities(), Collection.total_cities()], Style.C_INK))
	var bonus_pct: int = int(round((Collection.global_sell_multiplier() - 1.0) * 100.0))
	sb.add_child(_kv("Bônus de coleção", "+%d%% em vendas" % bonus_pct, Style.C_ORANGE))
	v.add_child(card)

	for cat in Collection.categories():
		var done: int = Collection.category_discovered(cat)
		var tot: int = Collection.products_in_category(cat).size()
		var complete: bool = Collection.category_complete(cat)
		var catcard := _card()
		var cb := VBoxContainer.new()
		cb.add_theme_constant_override("separation", 8)
		catcard.add_child(cb)
		var head := HBoxContainer.new()
		var ht := Label.new()
		ht.text = cat
		Style.use_display(ht, 28)
		ht.add_theme_color_override("font_color", Style.C_INK)
		ht.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_child(ht)
		head.add_child(Style.chip("%d/%d" % [done, tot], Style.C_GREEN if complete else Style.C_CARD_ALT, Color.WHITE if complete else Style.C_INK_SOFT))
		cb.add_child(head)
		cb.add_child(Style.progress(done, tot, Style.C_GREEN))
		var names := PackedStringArray()
		for pid in Collection.products_in_category(cat):
			if Collection.products.has(pid):
				names.append(String(Economy.PRODUCTS[pid].nome))
			else:
				names.append("???")
		var nl := Label.new()
		nl.text = ", ".join(names)
		nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nl.add_theme_font_size_override("font_size", 22)
		nl.add_theme_color_override("font_color", Style.C_INK_SOFT)
		cb.add_child(nl)
		v.add_child(catcard)

func _section_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	Style.use_display(lbl, 30)
	lbl.add_theme_color_override("font_color", Style.C_INK)
	return lbl

func _employee_card(emp: Dictionary, is_hired: bool) -> PanelContainer:
	var card := _card(Style.rarity_color(emp.raridade), 3)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	card.add_child(box)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(header)
	header.add_child(Style.avatar_badge(Style.emp_face_path(String(emp.categoria)), Style.rarity_color(String(emp.raridade)), 96))
	var hinfo := VBoxContainer.new()
	hinfo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hinfo.add_theme_constant_override("separation", 4)
	header.add_child(hinfo)
	var nome := Label.new()
	nome.text = String(emp.nome)
	Style.use_display(nome, 30)
	nome.add_theme_color_override("font_color", Style.C_INK)
	hinfo.add_child(nome)
	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", 8)
	chips.add_child(Style.chip(String(emp.categoria), Style.C_BLUE))
	chips.add_child(_rarity_chip(String(emp.raridade)))
	chips.add_child(Style.chip("Nível %d" % int(emp.nivel), Style.C_CARD_ALT, Style.C_INK_SOFT))
	hinfo.add_child(chips)

	var a = emp.atributos
	var attrs := Label.new()
	attrs.text = "Neg %d · Vel %d · Int %d · Leal %d" % [int(a.get("Negociação", 0)), int(a.get("Velocidade", 0)), int(a.get("Inteligência", 0)), int(a.get("Lealdade", 0))]
	attrs.add_theme_font_size_override("font_size", 22)
	attrs.add_theme_color_override("font_color", Style.C_INK_SOFT)
	box.add_child(attrs)

	var econ := Label.new()
	econ.text = "Rende +R$ %s/h · Salário -R$ %s/h" % [_fmt_money(Employees.contribution_per_hour(emp)), _fmt_money(Employees.salary_per_hour(emp))]
	econ.add_theme_font_size_override("font_size", 22)
	econ.add_theme_color_override("font_color", Style.C_GREEN)
	box.add_child(econ)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	if is_hired:
		var tcost: float = Employees.train_cost(emp)
		var tbtn := Button.new()
		tbtn.text = "Treinar (R$ %s)" % _fmt_money(tcost)
		tbtn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_style_button(tbtn, Style.C_GREEN, Color.WHITE, 26, 84)
		tbtn.disabled = GameState.money < tcost
		tbtn.pressed.connect(_train_emp.bind(emp))
		row.add_child(tbtn)
		var fbtn := Button.new()
		fbtn.text = "Demitir"
		fbtn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_style_button(fbtn, Style.C_RED, Color.WHITE, 26, 84)
		fbtn.pressed.connect(_fire_emp.bind(emp))
		row.add_child(fbtn)
	else:
		var hcost: float = Employees.hire_cost(emp)
		var hbtn := Button.new()
		hbtn.text = "Contratar (R$ %s)" % _fmt_money(hcost)
		hbtn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_style_button(hbtn, Style.C_GREEN, Color.WHITE, 28, 90)
		hbtn.disabled = GameState.money < hcost
		hbtn.pressed.connect(_hire_emp.bind(emp))
		row.add_child(hbtn)
	return card

func _hire_emp(emp: Dictionary) -> void:
	if Employees.hire(emp):
		_toast("Contratou %s." % emp.nome)
	else:
		_toast("Dinheiro insuficiente para contratar.")

func _fire_emp(emp: Dictionary) -> void:
	Employees.fire(emp)
	_toast("Demitiu %s." % emp.nome)

func _train_emp(emp: Dictionary) -> void:
	if Employees.train(emp):
		_toast("Treinou %s. Agora nível %d." % [emp.nome, int(emp.nivel)])
	else:
		_toast("Dinheiro insuficiente para treinar.")

func _buy(product_id: String) -> void:
	var price: float = Economy.price_at(GameState.current_city_id, product_id)
	if GameState.money < price:
		_toast("Dinheiro insuficiente para %s." % Economy.PRODUCTS[product_id].nome)
		return
	if not GameState.add_item(product_id, 1):
		_toast("Sem espaço na mochila.")
		return
	GameState.change_money(-price)
	_toast("Comprou 1 × %s por R$ %s." % [Economy.PRODUCTS[product_id].nome, _fmt_money(price)])

func _sell(product_id: String) -> void:
	if GameState.inventory.get(product_id, 0) <= 0:
		return
	var price: float = Economy.price_at(GameState.current_city_id, product_id) * Collection.global_sell_multiplier() * Prestige.sell_mult()
	GameState.remove_item(product_id, 1)
	GameState.change_money(price)
	GameState.emit_signal("item_sold", price)
	_toast("Vendeu 1 × %s por R$ %s." % [Economy.PRODUCTS[product_id].nome, _fmt_money(price)])

func _travel(city_id: String) -> void:
	_toast("Viajou para %s. Mercado oscilou." % Economy.CITIES[city_id].nome)
	GameState.travel_to(city_id)
	_show_page("mercado")

func _open_negotiation(npc_id: String) -> void:
	for c in overlay.get_children():
		c.queue_free()
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)

	var popup := NegotiationPopup.new()
	popup.configure(npc_id)
	popup.closed.connect(_on_popup_closed.bind(dim))
	center.add_child(popup)

func _on_popup_closed(dim: ColorRect) -> void:
	if is_instance_valid(dim):
		dim.queue_free()

func _maybe_welcome() -> void:
	if SaveSystem.pending_report.is_empty():
		return
	var r: Dictionary = SaveSystem.pending_report
	SaveSystem.pending_report = {}
	_show_welcome(r)

func _modal_panel(border_col: Color) -> Array:

	for c in overlay.get_children():
		c.queue_free()
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(860, 0)
	var sb := Style.sb_card()
	sb.set_border_width_all(4)
	sb.border_color = border_col
	sb.content_margin_left = 36
	sb.content_margin_right = 36
	sb.content_margin_top = 32
	sb.content_margin_bottom = 32
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)
	return [dim, box]

func _show_welcome(r: Dictionary) -> void:
	var parts := _modal_panel(Style.C_GREEN)
	var dim: ColorRect = parts[0]
	var box: VBoxContainer = parts[1]

	var wt := Style.title("Bem-vindo de volta!", 44, Style.C_INK)
	wt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(wt)

	var secs: int = int(r.get("away_seconds", 0))
	var h: int = secs / 3600
	var m: int = (secs % 3600) / 60
	var away: String = ("%dh %dmin" % [h, m]) if h > 0 else ("%dmin" % m)
	box.add_child(_centered_line("Você ficou fora: %s" % away, 28, Style.C_INK_SOFT))
	box.add_child(_centered_line("Seus negócios renderam", 28, Style.C_INK_SOFT))
	var income: float = float(r.get("income", 0.0))
	var big := Style.title("+ R$ %s" % _fmt_money(income), 54, Style.C_ORANGE)
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(big)
	var ticks: int = int(r.get("ticks", 0))
	if ticks > 0:
		box.add_child(_centered_line("O mercado avançou %d ciclos." % ticks, 24, Style.C_INK_SOFT))
	if bool(r.get("capped", false)):
		box.add_child(_centered_line("(ganhos limitados a %d h offline)" % int(SaveSystem.IDLE_CAP_HOURS), 22, Style.C_ORANGE))

	var btn := Button.new()
	btn.text = "Coletar"
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(btn, Style.C_GREEN, Color.WHITE, 36, 110)
	btn.pressed.connect(dim.queue_free)
	box.add_child(btn)

func _centered_line(text: String, size: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return lbl

func _debug_idle(hours: float) -> void:
	var income: float = Posts.auto_income_per_second() * hours * 3600.0
	var ticks: int = clampi(int(hours * 3600.0 / 900.0), 0, 48)
	for i in ticks:
		Economy.advance_tick()
	GameState.change_money(income)
	_show_welcome({
		"away_seconds": int(hours * 3600.0),
		"income": income,
		"ticks": ticks,
		"capped": hours > SaveSystem.IDLE_CAP_HOURS,
	})

func _confirm_wipe() -> void:
	var parts := _modal_panel(Style.C_RED)
	var dim: ColorRect = parts[0]
	var box: VBoxContainer = parts[1]
	var t := Style.title("Reiniciar progresso?", 40, Style.C_INK)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(t)
	box.add_child(_centered_line("Isso apaga o save e recomeça do zero. Não dá para desfazer.", 26, Style.C_INK_SOFT))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	var cancel := Button.new()
	cancel.text = "Cancelar"
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(cancel, Style.C_NEUTRAL, Color.WHITE, 30, 100)
	cancel.pressed.connect(dim.queue_free)
	row.add_child(cancel)
	var confirm := Button.new()
	confirm.text = "Apagar"
	confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(confirm, Style.C_RED, Color.WHITE, 30, 100)
	confirm.pressed.connect(_do_wipe)
	row.add_child(confirm)

func _do_wipe() -> void:
	SaveSystem.wipe()
	GameState.money = GameState.STARTING_MONEY
	GameState.inventory = {}
	GameState.current_city_id = "rural"
	for npc_id in NPCs.NPCS:
		NPCs.NPCS[npc_id].afinidade = 0
	NPCs.NPCS["dona_bete"].afinidade = 15
	for c in overlay.get_children():
		c.queue_free()
	GameState.emit_signal("money_changed", GameState.money)
	GameState.emit_signal("city_changed", GameState.current_city_id)
	GameState.emit_signal("inventory_changed")
	_show_page("mercado")
	_toast("Progresso reiniciado.")

func _clear(node: Node) -> void:
	for c in node.get_children():
		c.queue_free()

func _empty_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 27)
	lbl.add_theme_color_override("font_color", Style.C_INK_SOFT)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return lbl

func _toast(msg: String) -> void:
	if toast_label:
		toast_label.text = msg

func _fmt_money(v: float) -> String:
	var a := absf(v)
	if a >= 1_000_000_000_000.0:
		return "%.2fT" % (v / 1_000_000_000_000.0)
	elif a >= 1_000_000_000.0:
		return "%.2fB" % (v / 1_000_000_000.0)
	elif a >= 1_000_000.0:
		return "%.2fM" % (v / 1_000_000.0)
	elif a >= 10_000.0:
		return "%.1fK" % (v / 1_000.0)
	else:
		return "%.2f" % v
