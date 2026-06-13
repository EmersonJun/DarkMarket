extends Control

var NAV := [
	{ "id": "inicio", "label": "Império" },
	{ "id": "mercado", "label": "Mercado" },
	{ "id": "negociar", "label": "Negociar" },
	{ "id": "equipe", "label": "Equipe" },
	{ "id": "colecao", "label": "Coleção" },
	{ "id": "mais", "label": "Mais" },
]
var EXTRA_PAGES := ["contratos", "prestigio", "mochila", "noticias", "viajar", "estatisticas"]

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
var coin_icon: TextureRect
var gem_icon: TextureRect
var display_money: float = 0.0
var prestige_bar: ProgressBar
var prestige_strip_lbl: Label
var pages_holder: Control
var pages := {}
var page_vbox := {}
var nav_buttons := {}
var nav_icons := {}
var nav_labels := {}
var nav_badges := {}
var current_page: String = "inicio"
var toast_label: Label
var overlay: Control
var post_widgets := {}
var mascot: TextureRect
var mascot_wrap: Control
var _mascot_time: float = 0.0
var _mascot_busy: bool = false
var market_filter: String = "Tudo"

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
	DailyRewards.daily_changed.connect(_refresh_mais)
	GameState.item_sold.connect(_on_item_sold)
	GameState.stats_changed.connect(_on_stats_changed)
	Posts.milestone_reached.connect(_on_milestone)
	Posts.unlocked.connect(_on_unlocked)
	display_money = GameState.money
	_on_money_changed(GameState.money)
	_on_gems_changed(GameState.gems)
	_on_city_changed(GameState.current_city_id)
	_toast("Toque num posto cheio para coletar. Melhore para crescer!")
	set_process(true)
	_maybe_welcome()
	_maybe_daily()

func _process(delta: float) -> void:
	# Header sempre visivel: count-up suave do dinheiro, taxa, faixa de prestigio.
	if money_label:
		var target := GameState.money
		display_money = lerp(display_money, target, clampf(delta * 9.0, 0.0, 1.0))
		if absf(display_money - target) < 0.5:
			display_money = target
		money_label.text = "R$ %s" % _fmt_money(display_money)
	if rate_label:
		rate_label.text = "R$ %s/s" % _fmt_money(Posts.auto_income_per_second() + Employees.income_per_second())
	_update_prestige_strip()
	_animate_mascot(delta)
	_update_nav_badges()

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
		if is_instance_valid(w.cart) and is_instance_valid(w.bar):
			var road: Control = w.bar
			var cx: float = road.position.x + (road.size.x - 64.0) * float(p.progress)
			var cy: float = road.position.y + road.size.y * 0.5 - 32.0
			# Carrinho roda/sacode mais devagar nas cidades distantes (ciclo maior).
			var ct: float = Posts.cycle_time(city_id)
			var bob: float = sin(t * (6.0 / maxf(ct, 1.0))) * 4.0
			w.cart.position = Vector2(cx, cy + bob)
		if w.has("up_btn") and is_instance_valid(w.up_btn):
			w.up_btn.disabled = money < float(w.up_cost)
		if w.has("mg_btn") and is_instance_valid(w.mg_btn):
			w.mg_btn.disabled = money < float(w.mg_cost)
		if w.has("unlock_btn") and is_instance_valid(w.unlock_btn):
			w.unlock_btn.disabled = money < float(w.unlock_cost)

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
	_build_background_fx()
	add_child(Style.make_vignette())

	var screen := VBoxContainer.new()
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.add_theme_constant_override("separation", 0)
	add_child(screen)

	screen.add_child(_build_header())
	screen.add_child(_build_prestige_strip())

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
	_build_mascot()
	_show_page("inicio")

func _build_background_fx() -> void:
	# Glow dourado de "lampiao" + fagulhas subindo (vida de feira noturna).
	var glow := Style.make_lamp_glow(Style.C_LAMP, 0.16)
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(glow)

	var dot := Gradient.new()
	dot.set_color(0, Color(Style.C_LAMP.r, Style.C_LAMP.g, Style.C_LAMP.b, 0.9))
	dot.set_color(1, Color(Style.C_LAMP.r, Style.C_LAMP.g, Style.C_LAMP.b, 0.0))
	var dtex := GradientTexture2D.new()
	dtex.gradient = dot
	dtex.fill = GradientTexture2D.FILL_RADIAL
	dtex.fill_from = Vector2(0.5, 0.5)
	dtex.fill_to = Vector2(1.0, 0.5)
	dtex.width = 24
	dtex.height = 24

	var emitter := CPUParticles2D.new()
	emitter.texture = dtex
	emitter.amount = 22
	emitter.lifetime = 7.0
	emitter.preprocess = 4.0
	emitter.position = Vector2(540, 2000)
	emitter.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	emitter.emission_rect_extents = Vector2(560, 30)
	emitter.direction = Vector2(0, -1)
	emitter.spread = 18.0
	emitter.gravity = Vector2(0, -22)
	emitter.initial_velocity_min = 24.0
	emitter.initial_velocity_max = 64.0
	emitter.scale_amount_min = 0.4
	emitter.scale_amount_max = 1.1
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 0.0))
	ramp.set_color(1, Color(1, 1, 1, 0.0))
	ramp.add_point(0.5, Color(1, 1, 1, 0.5))
	emitter.color_ramp = ramp
	emitter.z_index = -1
	add_child(emitter)

func _build_prestige_strip() -> Control:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 28)
	m.add_theme_constant_override("margin_right", 28)
	m.add_theme_constant_override("margin_top", 0)
	m.add_theme_constant_override("margin_bottom", 6)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	m.add_child(row)
	prestige_strip_lbl = Label.new()
	prestige_strip_lbl.text = "Próx. Prestígio"
	Style.use_display(prestige_strip_lbl, 18)
	prestige_strip_lbl.add_theme_color_override("font_color", Style.C_INK_SOFT)
	row.add_child(prestige_strip_lbl)
	prestige_bar = Style.progress(0, 100, Style.C_MAGENTA)
	prestige_bar.custom_minimum_size = Vector2(0, 16)
	prestige_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prestige_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(prestige_bar)
	return m

func _build_mascot() -> void:
	mascot_wrap = Control.new()
	mascot_wrap.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	mascot_wrap.offset_left = -178
	mascot_wrap.offset_top = -340
	mascot_wrap.offset_right = -18
	mascot_wrap.offset_bottom = -180
	mascot_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(mascot_wrap)
	mascot = _icon("res://art/mascot.svg", 150)
	mascot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mascot.modulate.a = 0.97
	mascot_wrap.add_child(mascot)

func _animate_mascot(delta: float) -> void:
	if not is_instance_valid(mascot):
		return
	_mascot_time += delta
	if not _mascot_busy:
		var amp := 14.0 if _any_post_ready() else 7.0
		mascot.position.y = sin(_mascot_time * 2.2) * amp
		mascot.rotation_degrees = sin(_mascot_time * 1.3) * 3.0

func _any_post_ready() -> bool:
	for city_id in Posts.ORDER:
		if Posts.is_ready(city_id):
			return true
	return false

func _mascot_react(_kind: String = "celebrate") -> void:
	if not is_instance_valid(mascot_wrap) or not is_instance_valid(mascot):
		return
	_mascot_busy = true
	mascot.rotation_degrees = 0.0
	Style.pop(mascot_wrap, 1.3)
	var tw := mascot.create_tween()
	tw.tween_property(mascot, "position:y", -46.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(mascot, "position:y", 0.0, 0.34).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.tween_callback(_mascot_done)

func _mascot_done() -> void:
	_mascot_busy = false

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
	coin_icon = _icon("res://art/ui/coin.svg", 58)
	mh.add_child(coin_icon)
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
	gem_icon = _icon("res://art/ui/gem.svg", 52)
	gh.add_child(gem_icon)
	gems_label = Label.new()
	gems_label.text = "0"
	Style.use_display(gems_label, 36)
	gems_label.add_theme_color_override("font_color", Style.C_INK)
	gh.add_child(gems_label)
	var gem_plus := Button.new()
	gem_plus.text = "+"
	gem_plus.custom_minimum_size = Vector2(58, 58)
	_style_button(gem_plus, Style.C_GOLD, Style.C_BG, 36, 58)
	gem_plus.pressed.connect(_show_gem_shop)
	gh.add_child(gem_plus)
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
		hb.add_child(_make_nav_item(entry))
	return nav

func _make_nav_item(entry: Dictionary) -> Control:
	var holder := Control.new()
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	holder.custom_minimum_size = Vector2(0, 124)
	var btn := Button.new()
	btn.toggle_mode = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.pressed.connect(_show_page.bind(entry.id))
	holder.add_child(btn)
	nav_buttons[entry.id] = btn

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(vb)
	var icon := _icon("res://art/ui/nav_%s.svg" % entry.id, 60)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(icon)
	nav_icons[entry.id] = icon

	var badge := _make_badge()
	badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	badge.offset_left = -34
	badge.offset_top = 14
	badge.offset_right = -10
	badge.offset_bottom = 38
	holder.add_child(badge)
	nav_badges[entry.id] = badge

	_style_nav_item(entry.id, entry.id == current_page)
	return holder

func _make_badge() -> Control:
	var b := Panel.new()
	b.custom_minimum_size = Vector2(24, 24)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Style.C_RED
	sb.set_corner_radius_all(12)
	sb.set_border_width_all(3)
	sb.border_color = Style.C_INK
	Style.neon(sb, Style.C_RED, 8, 0.6)
	b.add_theme_stylebox_override("panel", sb)
	b.visible = false
	return b

func _style_nav_item(id: String, active: bool) -> void:
	var btn: Button = nav_buttons.get(id)
	if not is_instance_valid(btn):
		return
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
	var fg := Style.C_BG if active else Style.C_INK_SOFT
	if nav_icons.has(id) and is_instance_valid(nav_icons[id]):
		nav_icons[id].modulate = fg
		if active:
			Style.pop(nav_icons[id], 1.2)

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
		_style_nav_item(pid, pid == nav_active)
		nav_buttons[pid].button_pressed = (pid == nav_active)
	_refresh_all()

func _build_overlay() -> void:
	overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

func _on_money_changed(v: float) -> void:
	# Texto e animado suavemente em _process (count-up). Snap so na primeira vez.
	if money_label and display_money <= 0.0:
		display_money = v
		money_label.text = "R$ %s" % _fmt_money(v)

func _on_gems_changed(v: int) -> void:
	if gems_label:
		gems_label.text = str(v)
	if is_instance_valid(gem_icon):
		Style.jiggle(gem_icon)

func _update_prestige_strip() -> void:
	if not is_instance_valid(prestige_bar):
		return
	var frac := clampf(GameState.money / Prestige.MIN_MONEY, 0.0, 1.0)
	prestige_bar.value = frac * 100.0
	if not is_instance_valid(prestige_strip_lbl):
		return
	if Prestige.can_prestige():
		prestige_strip_lbl.text = "Prestígio pronto!"
		prestige_strip_lbl.add_theme_color_override("font_color", Style.C_MAGENTA)
	else:
		prestige_strip_lbl.text = "Próx. Prestígio"
		prestige_strip_lbl.add_theme_color_override("font_color", Style.C_INK_SOFT)

func _update_nav_badges() -> void:
	if not nav_badges.has("mais") or not is_instance_valid(nav_badges["mais"]):
		return
	var done := 0
	for c in Contracts.active:
		if Contracts.is_complete(c):
			done += 1
	nav_badges["mais"].visible = DailyRewards.can_claim() or Prestige.can_prestige() or done > 0

func _show_gem_shop() -> void:
	var parts := _modal_panel(Style.C_GOLD)
	var dim: ColorRect = parts[0]
	var box: VBoxContainer = parts[1]
	var ti := Style.title("Gemas", 40, Style.C_GOLD)
	ti.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(ti)
	box.add_child(_centered_line("Gemas aceleram seu império: boosts e desbloqueios.", 24, Style.C_INK_SOFT))
	var ad := Button.new()
	ad.text = "Assistir anúncio  +2 gemas"
	ad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(ad, Style.C_GREEN, Color.WHITE, 30, 104)
	ad.pressed.connect(_watch_ad_for_gems.bind(dim))
	box.add_child(ad)
	var boost := Button.new()
	if Posts.can_boost():
		boost.text = "Ativar Boost 2× (5 gemas)"
		_style_button(boost, Style.C_BLUE, Color.WHITE, 30, 104)
		boost.pressed.connect(_activate_boost_from_shop.bind(dim))
	else:
		boost.text = "Boost indisponível agora"
		_style_button(boost, Style.C_NEUTRAL, Color.WHITE, 30, 104)
		boost.disabled = true
	boost.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(boost)
	var close := Button.new()
	close.text = "Fechar"
	close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(close, Style.C_NEUTRAL, Color.WHITE, 28, 92)
	close.pressed.connect(dim.queue_free)
	box.add_child(close)

func _watch_ad_for_gems(dim: ColorRect) -> void:
	# Stub de anúncio recompensado (a integrar com SDK): concede gemas e conta a métrica.
	GameState.change_gems(2)
	GameState.bump_stat("ads_watched", 1.0)
	if has_node("/root/Audio"):
		Audio.levelup()
	if is_instance_valid(dim):
		dim.queue_free()
	_mascot_react()
	_toast("Anúncio assistido! +2 gemas.")

func _activate_boost_from_shop(dim: ColorRect) -> void:
	if Posts.activate_boost():
		_toast("Boost 2× ativado por 5 min!")
	else:
		_toast("Precisa de 5 gemas.")
	if is_instance_valid(dim):
		dim.queue_free()

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
	_refresh_stats()

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

# Emblema de cenario para a estrada. Forma/posicao variam por cidade (distancia d).
func _path_deco(d: int, col: Color, i: int, n: int) -> Control:
	var sz := 16.0
	var shape := ColorRect.new()
	shape.color = col
	shape.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var anchor: float = (float(i) + 0.5) / float(n)
	shape.anchor_left = anchor
	shape.anchor_right = anchor
	shape.anchor_top = 0.0
	shape.anchor_bottom = 0.0
	shape.offset_left = -sz * 0.5
	shape.offset_right = sz * 0.5
	shape.offset_top = 14.0
	shape.offset_bottom = 14.0 + sz
	if d % 2 == 1:
		shape.pivot_offset = Vector2(sz * 0.5, sz * 0.5)
		shape.rotation_degrees = 45.0
	return shape

func _post_card(city_id: String) -> PanelContainer:
	var p: Dictionary = Posts.posts[city_id]
	var c: Dictionary = Economy.CITIES[city_id]
	var d: int = Posts.ORDER.find(city_id)
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
	var chiprow := HBoxContainer.new()
	chiprow.add_theme_constant_override("separation", 6)
	if p.unlocked:
		chiprow.add_child(Style.chip("Nível %d" % int(p.nivel), Style.C_BLUE))
	chiprow.add_child(Style.chip("Rota %d" % (d + 1), c.cor.lerp(Style.C_CYAN, 0.4), Style.C_BG))
	namebox.add_child(chiprow)

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
		Style.shine_sweep(ub)
		lock.add_child(ub)
		box.add_child(lock)
		post_widgets[city_id]["unlock_btn"] = ub
		post_widgets[city_id]["unlock_cost"] = Posts.unlock_cost(city_id)
		_make_passthrough(box)
		return card

	var band_col: Color = c.cor.darkened(0.58)
	var road_col: Color = c.cor.lerp(Style.C_GOLD, 0.30)
	var deco_col: Color = c.cor.lerp(Style.C_INK, 0.45)

	var prog := Control.new()
	prog.custom_minimum_size = Vector2(0, 104 + mini(d, 6) * 6)
	box.add_child(prog)

	# Terreno tematico (banda) -- cor distinta por cidade
	var band := Panel.new()
	band.set_anchors_preset(Control.PRESET_FULL_RECT)
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bsb := StyleBoxFlat.new()
	bsb.bg_color = band_col
	bsb.set_corner_radius_all(18)
	bsb.set_border_width_all(2)
	bsb.border_color = c.cor.lerp(Style.C_BG, 0.25)
	band.add_theme_stylebox_override("panel", bsb)
	prog.add_child(band)

	# Cenario: d+3 emblemas (forma/cor/quantidade variam por cidade)
	var deco_n: int = d + 3
	for i in deco_n:
		prog.add_child(_path_deco(d, deco_col, i, deco_n))

	# Estrada (barra de progresso) na parte de baixo
	var bar := Style.progress(0, 100, road_col)
	bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_left = 12
	bar.offset_right = -12
	bar.offset_top = -42
	bar.offset_bottom = -16
	prog.add_child(bar)

	var cart := _icon("res://art/ui/cart.svg", 64)
	cart.modulate = Color.WHITE.lerp(c.cor, 0.3)
	prog.add_child(cart)
	var ready_lbl := Label.new()
	ready_lbl.text = "★ TOQUE PARA COLETAR ★"
	ready_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	ready_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ready_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	Style.use_display(ready_lbl, 27)
	ready_lbl.add_theme_color_override("font_color", Style.C_BG)
	ready_lbl.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.7))
	ready_lbl.add_theme_constant_override("outline_size", 6)
	ready_lbl.visible = false
	prog.add_child(ready_lbl)
	Style.breathe(ready_lbl, 0.06, 0.5)
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
		var autobox := HBoxContainer.new()
		autobox.add_theme_constant_override("separation", 6)
		autobox.custom_minimum_size = Vector2(150, 0)
		autobox.alignment = BoxContainer.ALIGNMENT_CENTER
		autobox.add_child(Style.avatar_badge(Style.emp_face_path("Gerente"), Style.C_GREEN, 70))
		var auto := Style.chip("AUTO", Style.C_GREEN)
		auto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		autobox.add_child(auto)
		row.add_child(autobox)
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
		var from_pos: Vector2 = w.card.global_position + w.card.size * 0.5
		var to_pos: Vector2 = _wallet_pos()
		Style.coin_burst(overlay, from_pos, to_pos, 8, _on_coin_landed)

func _wallet_pos() -> Vector2:
	if is_instance_valid(coin_icon):
		return coin_icon.global_position + coin_icon.size * 0.5
	return Vector2(120, 90)

func _on_coin_landed() -> void:
	if is_instance_valid(coin_icon):
		Style.jiggle(coin_icon)

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
	var daily_hot: bool = DailyRewards.can_claim()
	var daily_label: String = "Recompensa diária  (pronta!)" if daily_hot else "Recompensa diária"
	var diario := Button.new()
	diario.text = daily_label
	_style_button(diario, Style.C_GOLD if daily_hot else Style.C_CARD_ALT, Style.C_BG if daily_hot else Style.C_INK, 30, 104)
	diario.pressed.connect(_show_daily)
	v.add_child(diario)
	var items := [
		{ "id": "prestigio", "label": prest_label, "hot": Prestige.can_prestige() },
		{ "id": "contratos", "label": contratos_label, "hot": done > 0 },
		{ "id": "estatisticas", "label": "Estatísticas do Império", "hot": false },
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
		var done: bool = Contracts.is_complete(c)
		var card := _card(Style.C_GREEN if done else Color(0, 0, 0, 0), 3 if done else 0)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 8)
		card.add_child(box)
		var hrow := HBoxContainer.new()
		hrow.add_theme_constant_override("separation", 12)
		hrow.add_child(_icon(_contract_icon_path(String(c.tipo)), 56))
		var desc := Label.new()
		desc.text = Contracts.descricao(c)
		Style.use_display(desc, 27)
		desc.add_theme_color_override("font_color", Style.C_INK)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hrow.add_child(desc)
		box.add_child(hrow)
		box.add_child(Style.progress(int(c.progresso), int(c.alvo), Style.C_CYAN))
		var info := HBoxContainer.new()
		info.add_theme_constant_override("separation", 8)
		var prog := Label.new()
		prog.text = "%d / %d" % [int(c.progresso), int(c.alvo)]
		Style.use_display(prog, 22)
		prog.add_theme_color_override("font_color", Style.C_INK_SOFT)
		prog.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_child(prog)
		info.add_child(Style.stat_pill("res://art/ui/coin.svg", _fmt_money(float(c.reward)), Style.C_GOLD))
		if int(c.gems) > 0:
			info.add_child(Style.stat_pill("res://art/ui/gem.svg", "%d" % int(c.gems), Style.C_CYAN))
		box.add_child(info)
		var claim := Button.new()
		claim.text = "Coletar" if done else "Em andamento"
		claim.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_style_button(claim, Style.C_GREEN if done else Style.C_NEUTRAL, Color.WHITE, 26, 88)
		if done:
			Style.set_btn_icon(claim, "res://art/ui/ic_check.svg", 32)
		claim.disabled = not done
		claim.pressed.connect(_claim_contract.bind(c))
		box.add_child(claim)
		v.add_child(card)

func _contract_icon_path(tipo: String) -> String:
	match tipo:
		"coletar": return "res://art/ui/cart.svg"
		"vender": return "res://art/ui/ic_sell.svg"
		"melhorar": return "res://art/ui/ic_train.svg"
		"ganhar": return "res://art/ui/coin.svg"
	return "res://art/ui/ic_check.svg"

func _claim_contract(c: Dictionary) -> void:
	if Contracts.claim(c):
		_toast("Contrato concluído! Recompensa coletada.")
		_celebrate(Style.C_GREEN)

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
	Style.set_btn_icon(pbtn, "res://art/ui/nav_inicio.svg", 34)
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
		Style.set_btn_icon(buy, "res://art/ui/ic_train.svg", 28)
		buy.disabled = not Prestige.can_buy(id)
		buy.pressed.connect(_buy_talent.bind(id))
		box.add_child(buy)
		v.add_child(card)

func _buy_talent(id: String) -> void:
	if Prestige.buy_talent(id):
		_toast("Talento aprimorado.")
		if has_node("/root/Audio"):
			Audio.levelup()
	else:
		_toast("Pontos de Prestígio insuficientes.")
		if has_node("/root/Audio"):
			Audio.error()

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
	var c := overlay.size * 0.5
	if c == Vector2.ZERO:
		c = Vector2(540, 760)
	Style.confetti(overlay, Vector2(c.x, c.y - 160), 40)
	if has_node("/root/Audio"):
		Audio.levelup()
	_mascot_react()

func _refresh_market() -> void:
	var v: VBoxContainer = page_vbox["mercado"]
	_clear(v)
	v.add_child(_city_banner())
	v.add_child(_market_filter_row())
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	v.add_child(grid)
	# Mostra: itens vendidos AQUI (compra) + itens que voce possui (venda em qualquer lugar).
	var shown := {}
	for pid in Economy.products_sold_in(GameState.current_city_id):
		shown[pid] = true
	for pid in GameState.inventory:
		shown[pid] = true
	var any := false
	for product_id in Economy.PRODUCTS:
		if not shown.has(product_id):
			continue
		var p: Dictionary = Economy.PRODUCTS[product_id]
		if market_filter != "Tudo" and String(p.categoria) != market_filter:
			continue
		grid.add_child(_market_tile(product_id))
		any = true
	if not any:
		v.add_child(_empty_label("Nada nesta categoria aqui. Troque de cidade (aba Viajar) ou de categoria."))

func _market_filter_row() -> Control:
	var cats := ["Tudo", "Alimentos", "Luxo", "Colecionáveis", "Antiguidades"]
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 8)
	for cat in cats:
		var active: bool = market_filter == cat
		var b := Button.new()
		b.text = cat
		_style_button(b, Style.C_CYAN if active else Style.C_CARD_ALT, Style.C_BG if active else Style.C_INK_SOFT, 22, 60)
		b.pressed.connect(_set_market_filter.bind(cat))
		flow.add_child(b)
	return flow

func _set_market_filter(cat: String) -> void:
	market_filter = cat
	_refresh_market()

func _hcenter(node: Control) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(node)
	return h

func _market_tile(product_id: String) -> Control:
	var p: Dictionary = Economy.PRODUCTS[product_id]
	var city := GameState.current_city_id
	var price: float = Economy.price_at(city, product_id)
	var hot: bool = Economy.has_event_for(city, product_id)
	var owned: int = GameState.inventory.get(product_id, 0)
	var sold_here: bool = Economy.is_sold_in(city, product_id)
	var rarcol: Color = Style.rarity_color(p.raridade)

	var tile := Style.tile_panel(rarcol)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	tile.add_child(box)

	var topchips := HBoxContainer.new()
	topchips.alignment = BoxContainer.ALIGNMENT_CENTER
	topchips.add_theme_constant_override("separation", 6)
	if Economy.is_exclusive_to(city, product_id):
		topchips.add_child(Style.chip("EXCLUSIVO", Style.C_MAGENTA))
	if hot:
		topchips.add_child(Style.chip("EM ALTA", Style.C_ORANGE))
	var tchip := _trend_chip(Economy.price_trend(city, product_id))
	if tchip != null:
		topchips.add_child(tchip)
	if topchips.get_child_count() > 0:
		box.add_child(topchips)

	box.add_child(_tappable_thumb(product_id, rarcol, 132))

	var name_lbl := Label.new()
	name_lbl.text = p.nome
	Style.use_display(name_lbl, 26)
	name_lbl.add_theme_color_override("font_color", Style.C_INK)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.custom_minimum_size = Vector2(0, 60)
	box.add_child(name_lbl)

	var chips := HBoxContainer.new()
	chips.alignment = BoxContainer.ALIGNMENT_CENTER
	chips.add_theme_constant_override("separation", 6)
	chips.add_child(_rarity_chip(p.raridade))
	if owned > 0:
		chips.add_child(Style.chip("x%d" % owned, Style.C_CARD_ALT, Style.C_INK_SOFT))
	box.add_child(chips)

	box.add_child(_hcenter(Style.price_ribbon(_fmt_money(price), Style.C_GREEN)))

	var hint := _profit_hint_label(product_id, price)
	if hint != null:
		box.add_child(hint)

	if sold_here:
		var buy := Button.new()
		buy.text = "Comprar"
		buy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_style_button(buy, Style.C_GREEN, Color.WHITE, 24, 78)
		Style.set_btn_icon(buy, "res://art/ui/ic_buy.svg", 32)
		buy.disabled = GameState.money < price or GameState.capacity_left() < float(p.peso)
		buy.pressed.connect(_buy.bind(product_id))
		box.add_child(buy)

	if owned > 0:
		var sell := Button.new()
		sell.text = "Vender tudo"
		sell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_style_button(sell, Style.C_ORANGE, Color.WHITE, 22, 70)
		Style.set_btn_icon(sell, "res://art/ui/ic_sell.svg", 28)
		sell.pressed.connect(_sell_all.bind(product_id))
		box.add_child(sell)

	return tile

func _tappable_thumb(product_id: String, accent: Color, size: int) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(0, size + 12)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tf := Style.thumb_frame(Style.item_texture(product_id), accent, size)
	tf.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cc.add_child(tf)
	holder.add_child(cc)
	var tap := Button.new()
	tap.flat = true
	tap.focus_mode = Control.FOCUS_NONE
	tap.set_anchors_preset(Control.PRESET_FULL_RECT)
	tap.add_theme_stylebox_override("normal", _empty_sb())
	tap.add_theme_stylebox_override("hover", _empty_sb())
	tap.add_theme_stylebox_override("pressed", _empty_sb())
	tap.add_theme_stylebox_override("focus", _empty_sb())
	tap.pressed.connect(_item_detail_modal.bind(product_id))
	holder.add_child(tap)
	return holder

func _trend_chip(trend: float) -> Control:
	if trend <= 0.92:
		return Style.chip("BARATO", Style.C_GREEN, Style.C_BG)
	elif trend >= 1.08:
		return Style.chip("CARO", Style.C_ORANGE, Style.C_BG)
	return null

func _profit_hint_label(product_id: String, price_here: float) -> Control:
	var best: Dictionary = Economy.best_sell_city(product_id)
	if String(best.city) == "" or String(best.city) == GameState.current_city_id:
		return null
	if price_here <= 0.0:
		return null
	var pct: int = int(round((float(best.price) / price_here - 1.0) * 100.0))
	if pct < 4:
		return null
	var lbl := Label.new()
	lbl.text = "Vender em %s  +%d%%" % [Economy.CITIES[best.city].nome, pct]
	lbl.add_theme_font_size_override("font_size", 19)
	lbl.add_theme_color_override("font_color", Style.C_CYAN)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return lbl

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
			var rc: Color = Style.rarity_color(p.raridade)
			var card := _card(rc, 2)
			var hb := HBoxContainer.new()
			hb.add_theme_constant_override("separation", 14)
			card.add_child(hb)
			hb.add_child(Style.thumb_frame(Style.item_texture(product_id), rc, 88))
			var box := VBoxContainer.new()
			box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			box.add_theme_constant_override("separation", 6)
			hb.add_child(box)
			var t := Label.new()
			t.text = p.nome
			Style.use_display(t, 28)
			t.add_theme_color_override("font_color", Style.C_INK)
			box.add_child(t)
			var chips := HBoxContainer.new()
			chips.add_theme_constant_override("separation", 6)
			chips.add_child(_rarity_chip(p.raridade))
			chips.add_child(Style.chip("x%d" % qty, Style.C_CARD_ALT, Style.C_INK_SOFT))
			box.add_child(chips)
			box.add_child(Style.stat_pill("res://art/ui/coin.svg", "%s · total %s" % [_fmt_money(price), _fmt_money(price * qty)], Style.C_GREEN))
			v.add_child(card)
	var sep := Control.new()
	sep.custom_minimum_size = Vector2(0, 16)
	v.add_child(sep)
	var idle_btn := Button.new()
	idle_btn.text = "Simular 6h offline (teste)"
	_style_button(idle_btn, Style.C_NEUTRAL, Color.WHITE, 26, 82)
	Style.set_btn_icon(idle_btn, "res://art/ui/ic_clock.svg", 30)
	idle_btn.pressed.connect(_debug_idle.bind(6.0))
	v.add_child(idle_btn)
	var wipe_btn := Button.new()
	wipe_btn.text = "Reiniciar progresso"
	_style_button(wipe_btn, Style.C_RED, Color.WHITE, 26, 78)
	Style.set_btn_icon(wipe_btn, "res://art/ui/ic_fire.svg", 28)
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
		chips.add_theme_constant_override("separation", 6)
		chips.add_child(Style.chip(npc.arquetipo, Style.C_BLUE))
		chips.add_child(Style.chip(NPCs.tier_name(int(npc.afinidade)), Style.C_MAGENTA))
		info.add_child(chips)
		var spec := Label.new()
		spec.text = NPCs.specialty(npc_id)
		spec.add_theme_font_size_override("font_size", 22)
		spec.add_theme_color_override("font_color", Style.C_CYAN)
		spec.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_child(spec)
		info.add_child(Style.attr_bar("♥", int(npc.afinidade), Style.C_MAGENTA))
		var fn: String = NPCs.npc_function(npc_id)
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(200, 0)
		match fn:
			"fornecedor":
				btn.text = "Comprar"
				_style_button(btn, Style.C_BLUE, Color.WHITE, 26, 96)
				Style.set_btn_icon(btn, "res://art/ui/ic_buy.svg", 32)
				btn.pressed.connect(_open_supplier.bind(npc_id))
			"informante":
				btn.text = "Dica"
				_style_button(btn, Style.C_CYAN, Style.C_BG, 26, 96)
				Style.set_btn_icon(btn, "res://art/ui/ic_clock.svg", 30)
				btn.pressed.connect(_buy_tip.bind(npc_id))
			"atacadista":
				btn.text = "Vender lote"
				_style_button(btn, Style.C_ORANGE, Color.WHITE, 24, 96)
				Style.set_btn_icon(btn, "res://art/ui/ic_sell.svg", 30)
				btn.pressed.connect(_open_bulk_sell.bind(npc_id))
			"colecionador":
				btn.text = "Ofertar"
				_style_button(btn, Style.C_MAGENTA, Color.WHITE, 26, 96)
				Style.set_btn_icon(btn, "res://art/ui/ic_sell.svg", 30)
				btn.pressed.connect(_open_negotiation.bind(npc_id))
			_:
				btn.text = "Negociar"
				_style_button(btn, Style.C_GREEN, Color.WHITE, 26, 96)
				Style.set_btn_icon(btn, "res://art/ui/ic_sell.svg", 32)
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
		var trow := HBoxContainer.new()
		trow.add_theme_constant_override("separation", 10)
		var nic := _icon("res://art/ui/ic_clock.svg", 36)
		nic.modulate = Style.C_ORANGE if ativo else Style.C_INK_SOFT
		trow.add_child(nic)
		var titulo := Label.new()
		titulo.text = ev.template.titulo
		Style.use_display(titulo, 30)
		titulo.add_theme_color_override("font_color", Style.C_INK)
		titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		trow.add_child(titulo)
		trow.add_child(Style.chip("ATIVO" if ativo else "EM BREVE", Style.C_ORANGE if ativo else Style.C_NEUTRAL))
		box.add_child(trow)
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
	var sf := HFlowContainer.new()
	sf.add_theme_constant_override("h_separation", 10)
	sf.add_theme_constant_override("v_separation", 10)
	sumcard.add_child(sf)
	sf.add_child(Style.stat_pill("res://art/ui/coin.svg", "+R$ %s/h" % _fmt_money(inc), Style.C_GREEN))
	sf.add_child(Style.stat_pill("res://art/ui/coin.svg", "−R$ %s/h" % _fmt_money(sal), Style.C_RED))
	sf.add_child(Style.stat_pill("res://art/ui/coin.svg", "= R$ %s/h" % _fmt_money(maxf(0.0, net)), Style.C_GOLD))
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
	Style.set_btn_icon(rbtn, "res://art/ui/ic_refresh.svg", 28)
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
		var album := HFlowContainer.new()
		album.add_theme_constant_override("h_separation", 8)
		album.add_theme_constant_override("v_separation", 8)
		for pid in Collection.products_in_category(cat):
			album.add_child(_collection_thumb(String(pid), Collection.products.has(pid)))
		cb.add_child(album)
		v.add_child(catcard)

func _section_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	Style.use_display(lbl, 30)
	lbl.add_theme_color_override("font_color", Style.C_INK)
	return lbl

func _section_icon(text: String, icon_path: String, color: Color = Style.C_INK) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var ic := _icon(icon_path, 38)
	ic.modulate = color
	row.add_child(ic)
	var lbl := Label.new()
	lbl.text = text
	Style.use_display(lbl, 30)
	lbl.add_theme_color_override("font_color", Style.C_INK)
	row.add_child(lbl)
	return row

func _collection_thumb(pid: String, discovered: bool) -> Control:
	if discovered and Economy.PRODUCTS.has(pid):
		var rc: Color = Style.rarity_color(Economy.PRODUCTS[pid].raridade)
		return Style.thumb_frame(Style.item_texture(pid), rc, 76)
	var lock_tex: Texture2D = load("res://art/ui/lock.svg") if ResourceLoader.exists("res://art/ui/lock.svg") else null
	var tf := Style.thumb_frame(lock_tex, Style.C_NEUTRAL, 76)
	tf.modulate = Color(1, 1, 1, 0.45)
	return tf

func _emp_avatar(emp: Dictionary) -> Control:
	var rarcol: Color = Style.rarity_color(String(emp.raridade))
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(104, 104)
	var av := Style.avatar_badge(Style.emp_face_path(String(emp.categoria)), rarcol, 100)
	av.set_anchors_preset(Control.PRESET_TOP_LEFT)
	holder.add_child(av)
	var badge := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Style.C_GOLD
	sb.set_corner_radius_all(14)
	sb.set_border_width_all(3)
	sb.border_color = Style.C_BG
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	badge.add_theme_stylebox_override("panel", sb)
	var bl := Label.new()
	bl.text = "Nv %d" % int(emp.nivel)
	Style.use_display(bl, 18)
	bl.add_theme_color_override("font_color", Style.C_BG)
	badge.add_child(bl)
	badge.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	badge.offset_left = -64
	badge.offset_top = -34
	badge.offset_right = 8
	badge.offset_bottom = 4
	holder.add_child(badge)
	return holder

func _employee_card(emp: Dictionary, is_hired: bool) -> PanelContainer:
	var rarcol: Color = Style.rarity_color(String(emp.raridade))
	var card := _card(rarcol, 3)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	card.add_child(box)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	box.add_child(header)
	header.add_child(_emp_avatar(emp))
	var hinfo := VBoxContainer.new()
	hinfo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hinfo.add_theme_constant_override("separation", 6)
	header.add_child(hinfo)
	var nome := Label.new()
	nome.text = String(emp.nome)
	Style.use_display(nome, 30)
	nome.add_theme_color_override("font_color", Style.C_INK)
	hinfo.add_child(nome)
	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", 6)
	chips.add_child(Style.chip(String(emp.categoria), Style.C_BLUE))
	chips.add_child(_rarity_chip(String(emp.raridade)))
	hinfo.add_child(chips)
	# Renda x salario em pilulas
	var econrow := HBoxContainer.new()
	econrow.add_theme_constant_override("separation", 8)
	econrow.add_child(Style.stat_pill("res://art/ui/coin.svg", "+%s" % _fmt_money(Employees.contribution_per_hour(emp)), Style.C_GREEN))
	econrow.add_child(Style.stat_pill("res://art/ui/coin.svg", "−%s" % _fmt_money(Employees.salary_per_hour(emp)), Style.C_RED))
	hinfo.add_child(econrow)

	var a = emp.atributos
	box.add_child(Style.attr_bar("Neg", int(a.get("Negociação", 0)), Style.C_MAGENTA))
	box.add_child(Style.attr_bar("Vel", int(a.get("Velocidade", 0)), Style.C_CYAN))
	box.add_child(Style.attr_bar("Int", int(a.get("Inteligência", 0)), Style.C_BLUE))
	box.add_child(Style.attr_bar("Leal", int(a.get("Lealdade", 0)), Style.C_GOLD))

	# Barra de XP ate o proximo nivel
	var needed: float = 100.0 * float(int(emp.nivel))
	var xpbar := Style.progress(int(float(emp.get("xp", 0.0))), int(maxf(1.0, needed)), Style.C_GREEN)
	xpbar.custom_minimum_size = Vector2(0, 14)
	box.add_child(xpbar)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	if is_hired:
		var tcost: float = Employees.train_cost(emp)
		var tbtn := Button.new()
		tbtn.text = "Treinar  R$ %s" % _fmt_money(tcost)
		tbtn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_style_button(tbtn, Style.C_GREEN, Color.WHITE, 24, 84)
		Style.set_btn_icon(tbtn, "res://art/ui/ic_train.svg", 30)
		tbtn.disabled = GameState.money < tcost
		tbtn.pressed.connect(_train_emp.bind(emp))
		row.add_child(tbtn)
		var fbtn := Button.new()
		fbtn.custom_minimum_size = Vector2(96, 0)
		_style_button(fbtn, Style.C_RED, Color.WHITE, 24, 84)
		Style.set_btn_icon(fbtn, "res://art/ui/ic_fire.svg", 30)
		fbtn.pressed.connect(_fire_emp.bind(emp))
		row.add_child(fbtn)
	else:
		var hcost: float = Employees.hire_cost(emp)
		var hbtn := Button.new()
		hbtn.text = "Contratar  R$ %s" % _fmt_money(hcost)
		hbtn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_style_button(hbtn, Style.C_GREEN, Color.WHITE, 26, 90)
		Style.set_btn_icon(hbtn, "res://art/ui/ic_hire.svg", 32)
		hbtn.disabled = GameState.money < hcost
		hbtn.pressed.connect(_hire_emp.bind(emp))
		row.add_child(hbtn)
	return card

func _hire_emp(emp: Dictionary) -> void:
	if Employees.hire(emp):
		_toast("Contratou %s." % emp.nome)
		_celebrate(Style.C_GREEN)
	else:
		_toast("Dinheiro insuficiente para contratar.")
		if has_node("/root/Audio"):
			Audio.error()

func _fire_emp(emp: Dictionary) -> void:
	Employees.fire(emp)
	_toast("Demitiu %s." % emp.nome)

func _train_emp(emp: Dictionary) -> void:
	if Employees.train(emp):
		_toast("Treinou %s. Agora nível %d." % [emp.nome, int(emp.nivel)])
		if has_node("/root/Audio"):
			Audio.collect()
	else:
		_toast("Dinheiro insuficiente para treinar.")
		if has_node("/root/Audio"):
			Audio.error()

func _buy(product_id: String) -> void:
	_buy_qty(product_id, 1)

func _sell(product_id: String) -> void:
	_sell_qty(product_id, 1)

func _sell_all(product_id: String) -> void:
	var q: int = _sell_qty(product_id, GameState.inventory.get(product_id, 0))
	if q > 0:
		_sell_burst(q)

func _max_buyable(product_id: String) -> int:
	var p: Dictionary = Economy.PRODUCTS[product_id]
	var price: float = Economy.price_at(GameState.current_city_id, product_id)
	var by_money: int = int(GameState.money / price) if price > 0.0 else 0
	var peso: float = float(p.peso)
	var by_cap: int = int(GameState.capacity_left() / peso) if peso > 0.0 else 9999
	return maxi(0, mini(by_money, by_cap))

func _buy_qty(product_id: String, n: int) -> int:
	var price: float = Economy.price_at(GameState.current_city_id, product_id)
	var q: int = mini(n, _max_buyable(product_id))
	if q <= 0:
		_toast("Sem dinheiro ou espaço para %s." % Economy.PRODUCTS[product_id].nome)
		if has_node("/root/Audio"):
			Audio.error()
		return 0
	if not GameState.add_item(product_id, q):
		if has_node("/root/Audio"):
			Audio.error()
		return 0
	GameState.change_money(-price * q)
	_toast("Comprou %d × %s por R$ %s." % [q, Economy.PRODUCTS[product_id].nome, _fmt_money(price * q)])
	return q

func _sell_qty(product_id: String, n: int) -> int:
	var owned: int = GameState.inventory.get(product_id, 0)
	var q: int = mini(n, owned)
	if q <= 0:
		return 0
	var unit: float = Economy.price_at(GameState.current_city_id, product_id) * Collection.global_sell_multiplier() * Prestige.sell_mult()
	var total: float = unit * q
	GameState.remove_item(product_id, q)
	GameState.change_money(total)
	GameState.emit_signal("item_sold", total)
	_toast("Vendeu %d × %s por R$ %s." % [q, Economy.PRODUCTS[product_id].nome, _fmt_money(total)])
	return q

func _sell_burst(qty: int) -> void:
	var n: int = clampi(4 + qty, 4, 16)
	Style.coin_burst(overlay, _screen_center(), _wallet_pos(), n, _on_coin_landed)

func _screen_center() -> Vector2:
	var c: Vector2 = overlay.size * 0.5
	if c == Vector2.ZERO:
		c = Vector2(540, 820)
	return c

func _item_detail_modal(product_id: String) -> void:
	var p: Dictionary = Economy.PRODUCTS[product_id]
	var city := GameState.current_city_id
	var price: float = Economy.price_at(city, product_id)
	var owned: int = GameState.inventory.get(product_id, 0)
	var sold_here: bool = Economy.is_sold_in(city, product_id)
	var rarcol: Color = Style.rarity_color(p.raridade)
	var parts := _modal_panel(rarcol)
	var dim: ColorRect = parts[0]
	var box: VBoxContainer = parts[1]

	box.add_child(_hcenter(Style.thumb_frame(Style.item_texture(product_id), rarcol, 150)))
	var nm := Style.title(String(p.nome), 36, Style.C_INK)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(nm)

	var chips := HBoxContainer.new()
	chips.alignment = BoxContainer.ALIGNMENT_CENTER
	chips.add_theme_constant_override("separation", 6)
	chips.add_child(_rarity_chip(String(p.raridade)))
	chips.add_child(Style.chip(String(p.categoria), Style.C_BLUE))
	if owned > 0:
		chips.add_child(Style.chip("tem %d" % owned, Style.C_CARD_ALT, Style.C_INK_SOFT))
	box.add_child(chips)

	box.add_child(_hcenter(Style.price_ribbon(_fmt_money(price), Style.C_GREEN)))
	var best: Dictionary = Economy.best_sell_city(product_id)
	if String(best.city) != "" and price > 0.0:
		var pct: int = int(round((float(best.price) / price - 1.0) * 100.0))
		var where: String = "aqui mesmo" if String(best.city) == city else "%s (+%d%%)" % [Economy.CITIES[best.city].nome, pct]
		box.add_child(_centered_line("Melhor venda: %s" % where, 24, Style.C_CYAN))

	if sold_here:
		box.add_child(_centered_line("Comprar", 24, Style.C_INK_SOFT))
		var buyrow := HBoxContainer.new()
		buyrow.add_theme_constant_override("separation", 10)
		buyrow.alignment = BoxContainer.ALIGNMENT_CENTER
		for n in [1, 10]:
			var b := Button.new()
			b.text = "x%d" % n
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_style_button(b, Style.C_GREEN, Color.WHITE, 26, 84)
			b.disabled = _max_buyable(product_id) < n
			b.pressed.connect(_detail_buy.bind(product_id, n))
			buyrow.add_child(b)
		var bmax := Button.new()
		bmax.text = "Máx"
		bmax.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_style_button(bmax, Style.C_GREEN, Color.WHITE, 26, 84)
		bmax.disabled = _max_buyable(product_id) <= 0
		bmax.pressed.connect(_detail_buy.bind(product_id, 9999))
		buyrow.add_child(bmax)
		box.add_child(buyrow)

	if owned > 0:
		box.add_child(_centered_line("Vender", 24, Style.C_INK_SOFT))
		var sellrow := HBoxContainer.new()
		sellrow.add_theme_constant_override("separation", 10)
		sellrow.alignment = BoxContainer.ALIGNMENT_CENTER
		for n in [1, 10]:
			var s := Button.new()
			s.text = "x%d" % n
			s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_style_button(s, Style.C_ORANGE, Color.WHITE, 26, 84)
			s.disabled = owned < n
			s.pressed.connect(_detail_sell.bind(product_id, n))
			sellrow.add_child(s)
		var sall := Button.new()
		sall.text = "Tudo"
		sall.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_style_button(sall, Style.C_ORANGE, Color.WHITE, 26, 84)
		sall.pressed.connect(_detail_sell.bind(product_id, 9999))
		sellrow.add_child(sall)
		box.add_child(sellrow)

	var close := Button.new()
	close.text = "Fechar"
	close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(close, Style.C_NEUTRAL, Color.WHITE, 26, 84)
	close.pressed.connect(dim.queue_free)
	box.add_child(close)

func _detail_buy(product_id: String, n: int) -> void:
	if _buy_qty(product_id, n) > 0:
		_item_detail_modal(product_id)

func _detail_sell(product_id: String, n: int) -> void:
	var q: int = _sell_qty(product_id, n)
	if q > 0:
		_item_detail_modal(product_id)
		_sell_burst(q)

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

# --- Fornecedor: comprar itens exclusivos da cidade -----------------------
func _open_supplier(npc_id: String) -> void:
	var npc: Dictionary = NPCs.NPCS[npc_id]
	var parts := _modal_panel(Style.C_BLUE)
	var dim: ColorRect = parts[0]
	var box: VBoxContainer = parts[1]
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_child(Style.avatar_badge(Style.npc_face_path(npc.arquetipo), Style.C_BLUE, 96))
	var ht := VBoxContainer.new()
	ht.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ht.add_child(Style.title(String(npc.nome), 32, Style.C_INK))
	ht.add_child(_centered_line("Mercadoria exclusiva — revenda longe daqui!", 20, Style.C_INK_SOFT))
	head.add_child(ht)
	box.add_child(head)

	var stock: Array = NPCs.supplier_stock(npc_id)
	if stock.is_empty():
		box.add_child(_centered_line("Sem mercadoria nova agora. Volte depois.", 24, Style.C_INK_SOFT))
	for pid in stock:
		box.add_child(_supplier_row(npc_id, String(pid)))

	var close := Button.new()
	close.text = "Sair"
	close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(close, Style.C_NEUTRAL, Color.WHITE, 26, 84)
	close.pressed.connect(dim.queue_free)
	box.add_child(close)

func _supplier_row(npc_id: String, product_id: String) -> Control:
	var p: Dictionary = Economy.PRODUCTS[product_id]
	var rc: Color = Style.rarity_color(p.raridade)
	var price: float = NPCs.supplier_price(npc_id, product_id)
	var card := _card(rc, 2)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	card.add_child(hb)
	hb.add_child(Style.thumb_frame(Style.item_texture(product_id), rc, 80))
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 4)
	hb.add_child(info)
	info.add_child(Style.title(String(p.nome), 26, Style.C_INK))
	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", 6)
	chips.add_child(_rarity_chip(String(p.raridade)))
	info.add_child(chips)
	info.add_child(Style.price_ribbon(_fmt_money(price), Style.C_BLUE))
	var buy := Button.new()
	buy.text = "Comprar"
	buy.custom_minimum_size = Vector2(170, 0)
	_style_button(buy, Style.C_GREEN, Color.WHITE, 24, 88)
	Style.set_btn_icon(buy, "res://art/ui/ic_buy.svg", 30)
	buy.disabled = GameState.money < price or GameState.capacity_left() < float(p.peso)
	buy.pressed.connect(_buy_from_supplier.bind(npc_id, product_id))
	hb.add_child(buy)
	return card

func _buy_from_supplier(npc_id: String, product_id: String) -> void:
	var price: float = NPCs.supplier_price(npc_id, product_id)
	var p: Dictionary = Economy.PRODUCTS[product_id]
	if GameState.money < price:
		_toast("Dinheiro insuficiente.")
		if has_node("/root/Audio"):
			Audio.error()
		return
	if not GameState.add_item(product_id, 1):
		_toast("Sem espaço na mochila.")
		if has_node("/root/Audio"):
			Audio.error()
		return
	GameState.change_money(-price)
	NPCs.add_affinity(npc_id, 1)
	if has_node("/root/Audio"):
		Audio.unlock()
	_toast("Comprou %s do fornecedor!" % p.nome)
	_open_supplier(npc_id)
	Style.confetti(overlay, _screen_center() + Vector2(0, -120), 18)

# --- Informante: dica paga ------------------------------------------------
func _buy_tip(npc_id: String) -> void:
	var npc: Dictionary = NPCs.NPCS[npc_id]
	var cost: int = 1  # 1 gema
	var parts := _modal_panel(Style.C_CYAN)
	var dim: ColorRect = parts[0]
	var box: VBoxContainer = parts[1]
	box.add_child(_hcenter(Style.avatar_badge(Style.npc_face_path(npc.arquetipo), Style.C_CYAN, 96)))
	box.add_child(_centered_line("%s sussurra..." % String(npc.nome), 26, Style.C_INK))
	var tip: String = _make_tip()
	box.add_child(_centered_line(tip, 26, Style.C_GOLD))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	var pay := Button.new()
	pay.text = "Pagar 1 gema pela dica"
	pay.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(pay, Style.C_GOLD if GameState.gems >= cost else Style.C_NEUTRAL, Style.C_BG if GameState.gems >= cost else Style.C_INK, 24, 88)
	pay.disabled = GameState.gems < cost
	pay.pressed.connect(_confirm_tip.bind(npc_id, dim))
	row.add_child(pay)
	var no := Button.new()
	no.text = "Agora não"
	no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(no, Style.C_NEUTRAL, Color.WHITE, 24, 88)
	no.pressed.connect(dim.queue_free)
	row.add_child(no)

func _make_tip() -> String:
	# Dica: melhor cidade p/ vender um item que voce tem; senao, evento ativo.
	var owned: Array = GameState.inventory.keys()
	if not owned.is_empty():
		var pid: String = String(owned[randi() % owned.size()])
		var best: Dictionary = Economy.best_sell_city(pid)
		if String(best.city) != "":
			return "%s está caro em %s — venda lá!" % [Economy.PRODUCTS[pid].nome, Economy.CITIES[best.city].nome]
	if has_node("/root/News") and not News.active_events.is_empty():
		var ev = News.active_events[0]
		return "Fica de olho: %s" % String(ev.template.titulo)
	return "Compre barato na origem e venda onde o preço sobe."

func _confirm_tip(npc_id: String, dim: ColorRect) -> void:
	if GameState.gems < 1:
		return
	GameState.change_gems(-1)
	NPCs.add_affinity(npc_id, 1)
	if has_node("/root/Audio"):
		Audio.levelup()
	if is_instance_valid(dim):
		dim.queue_free()
	_toast("Dica anotada! Use a seu favor.")

# --- Atacadista: vender em lote com bônus de volume -----------------------
func _open_bulk_sell(npc_id: String) -> void:
	var npc: Dictionary = NPCs.NPCS[npc_id]
	var parts := _modal_panel(Style.C_ORANGE)
	var dim: ColorRect = parts[0]
	var box: VBoxContainer = parts[1]
	box.add_child(_hcenter(Style.avatar_badge(Style.npc_face_path(npc.arquetipo), Style.C_ORANGE, 96)))
	box.add_child(Style.title(String(npc.nome), 30, Style.C_INK))
	box.add_child(_centered_line("Compra em lote — quanto mais, maior o bônus!", 22, Style.C_INK_SOFT))
	if GameState.inventory.is_empty():
		box.add_child(_centered_line("Sua mochila está vazia.", 24, Style.C_INK_SOFT))
	else:
		for pid in GameState.inventory:
			box.add_child(_bulk_row(npc_id, String(pid), dim))
	var close := Button.new()
	close.text = "Sair"
	close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(close, Style.C_NEUTRAL, Color.WHITE, 26, 84)
	close.pressed.connect(dim.queue_free)
	box.add_child(close)

func _bulk_row(npc_id: String, product_id: String, dim: ColorRect) -> Control:
	var p: Dictionary = Economy.PRODUCTS[product_id]
	var qty: int = GameState.inventory.get(product_id, 0)
	var rc: Color = Style.rarity_color(p.raridade)
	var unit: float = Economy.price_at(GameState.current_city_id, product_id) * Collection.global_sell_multiplier() * Prestige.sell_mult()
	var bonus: float = NPCs.bulk_bonus(npc_id, qty)
	var total: float = unit * qty * (1.0 + bonus)
	var card := _card(rc, 2)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	card.add_child(hb)
	hb.add_child(Style.thumb_frame(Style.item_texture(product_id), rc, 78))
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 4)
	hb.add_child(info)
	info.add_child(Style.title("%d × %s" % [qty, String(p.nome)], 24, Style.C_INK))
	info.add_child(Style.chip("bônus +%d%%" % int(round(bonus * 100.0)), Style.C_GREEN))
	info.add_child(Style.price_ribbon(_fmt_money(total), Style.C_ORANGE))
	var sell := Button.new()
	sell.text = "Vender"
	sell.custom_minimum_size = Vector2(160, 0)
	_style_button(sell, Style.C_ORANGE, Color.WHITE, 24, 86)
	Style.set_btn_icon(sell, "res://art/ui/ic_sell.svg", 28)
	sell.pressed.connect(_do_bulk_sell.bind(npc_id, product_id, dim))
	hb.add_child(sell)
	return card

func _do_bulk_sell(npc_id: String, product_id: String, dim: ColorRect) -> void:
	var qty: int = GameState.inventory.get(product_id, 0)
	if qty <= 0:
		return
	var unit: float = Economy.price_at(GameState.current_city_id, product_id) * Collection.global_sell_multiplier() * Prestige.sell_mult()
	var bonus: float = NPCs.bulk_bonus(npc_id, qty)
	var total: float = unit * qty * (1.0 + bonus)
	GameState.remove_item(product_id, qty)
	GameState.change_money(total)
	GameState.emit_signal("item_sold", total)
	NPCs.add_affinity(npc_id, 2)
	_toast("Vendeu %d × %s por R$ %s (+%d%%)." % [qty, Economy.PRODUCTS[product_id].nome, _fmt_money(total), int(round(bonus * 100.0))])
	if is_instance_valid(dim):
		_open_bulk_sell(npc_id)
	_sell_burst(clampi(qty, 6, 16))

func _maybe_welcome() -> void:
	if SaveSystem.pending_report.is_empty():
		return
	var r: Dictionary = SaveSystem.pending_report
	SaveSystem.pending_report = {}
	_show_welcome(r)

func _maybe_daily() -> void:
	if not DailyRewards.can_claim():
		return
	if overlay.get_child_count() > 0:
		return
	_show_daily()

func _show_daily() -> void:
	if not DailyRewards.can_claim():
		_toast("Você já coletou a recompensa de hoje. Volte amanhã!")
		return
	var parts := _modal_panel(Style.C_GOLD)
	var dim: ColorRect = parts[0]
	var box: VBoxContainer = parts[1]
	var ti := Style.title("Recompensa Diária", 40, Style.C_GOLD)
	ti.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(ti)
	var track := HBoxContainer.new()
	track.alignment = BoxContainer.ALIGNMENT_CENTER
	track.add_theme_constant_override("separation", 6)
	box.add_child(track)
	for i in DailyRewards.REWARDS.size():
		var active: bool = i == DailyRewards.current_index()
		track.add_child(Style.chip("D%d" % (i + 1), Style.C_GOLD if active else Style.C_CARD_ALT, Style.C_BG if active else Style.C_INK_SOFT))
	box.add_child(_centered_line("Recompensa de hoje:", 26, Style.C_INK_SOFT))
	var rew := Style.title(DailyRewards.reward_text(DailyRewards.current()), 38, Style.C_GREEN)
	rew.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(rew)
	var btn := Button.new()
	btn.text = "Coletar"
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(btn, Style.C_GREEN, Color.WHITE, 34, 108)
	btn.pressed.connect(_claim_daily.bind(dim))
	box.add_child(btn)

func _claim_daily(dim: ColorRect) -> void:
	DailyRewards.claim()
	if is_instance_valid(dim):
		dim.queue_free()
	_toast("Recompensa diária coletada!")
	_celebrate(Style.C_GOLD)

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
	if income > 0.0:
		Style.count_up(big, 0.0, income, _fmt_welcome_income, 0.9)
		if has_node("/root/Audio"):
			Audio.levelup()
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

func _on_item_sold(amount: float) -> void:
	GameState.bump_stat("items_sold", 1.0)
	GameState.set_stat_max("best_sale", amount)
	if has_node("/root/Audio"):
		Audio.coin()
	if is_instance_valid(coin_icon):
		Style.jiggle(coin_icon)

func _on_stats_changed() -> void:
	if current_page == "estatisticas":
		_refresh_stats()

func _on_milestone(city_id: String, nivel: int) -> void:
	var c: Dictionary = Economy.CITIES[city_id]
	_toast("%s atingiu nível %d! Bônus permanente +30%% renda. (+1 gema)" % [c.nome, nivel])
	_celebrate(Style.C_GOLD)

func _on_unlocked(city_id: String) -> void:
	var c: Dictionary = Economy.CITIES[city_id]
	_toast("%s desbloqueado! Novo posto no império. (+2 gemas)" % c.nome)
	if has_node("/root/Audio"):
		Audio.unlock()
	_celebrate(Style.C_ORANGE)

# Festa: confete + flash + pulo do mascote. Usado em marcos, desbloqueios e prestigio.
func _celebrate(_color: Color = Color.WHITE) -> void:
	if not is_instance_valid(overlay):
		return
	var center := overlay.size * 0.5
	if center == Vector2.ZERO:
		center = Vector2(540, 760)
	Style.screen_flash(overlay, Color(1, 1, 1, 0.35))
	Style.confetti(overlay, Vector2(center.x, center.y - 120), 30)
	if has_node("/root/Audio"):
		Audio.levelup()
	_mascot_react()

func _fmt_seconds(secs: float) -> String:
	var s: int = int(secs)
	var d: int = s / 86400
	var h: int = (s % 86400) / 3600
	var m: int = (s % 3600) / 60
	if d > 0:
		return "%dd %dh %dmin" % [d, h, m]
	if h > 0:
		return "%dh %dmin" % [h, m]
	return "%dmin" % m

func _stats_card(rows: Array) -> PanelContainer:
	var card := _card()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	card.add_child(box)
	for r in rows:
		box.add_child(_kv(String(r[0]), String(r[1]), r[2] if r.size() > 2 else Style.C_INK))
	return card

func _refresh_stats() -> void:
	if not page_vbox.has("estatisticas"):
		return
	var v: VBoxContainer = page_vbox["estatisticas"]
	_clear(v)
	var s: Dictionary = GameState.stats

	v.add_child(_section_icon("Dinheiro", "res://art/ui/coin.svg", Style.C_GOLD))
	v.add_child(_stats_card([
		["Saldo atual", "R$ %s" % _fmt_money(GameState.money), Style.C_GREEN],
		["Maior saldo já alcançado", "R$ %s" % _fmt_money(float(s.get("highest_money", 0.0))), Style.C_GOLD],
		["Total ganho na vida", "R$ %s" % _fmt_money(float(s.get("total_earned", 0.0))), Style.C_GREEN],
		["Total gasto na vida", "R$ %s" % _fmt_money(float(s.get("total_spent", 0.0))), Style.C_ORANGE],
		["Melhor venda única", "R$ %s" % _fmt_money(float(s.get("best_sale", 0.0))), Style.C_MAGENTA],
		["Renda passiva /s", "R$ %s/s" % _fmt_money(Posts.auto_income_per_second() + Employees.income_per_second()), Style.C_CYAN],
	]))

	v.add_child(_section_icon("Postos & Carrinhos", "res://art/ui/cart.svg", Style.C_CYAN))
	v.add_child(_stats_card([
		["Postos desbloqueados", "%d / %d" % [Posts.unlocked_count(), Posts.ORDER.size()], Style.C_INK],
		["Soma dos níveis de postos", str(Posts.total_levels()), Style.C_CYAN],
		["Melhorias compradas", str(int(s.get("post_upgrades_bought", 0))), Style.C_GREEN],
		["Coletas manuais feitas", str(int(s.get("total_collects", 0))), Style.C_INK],
		["Gerentes contratados", "%d / %d" % [Posts.managers_count(), Posts.ORDER.size()], Style.C_ORANGE],
		["Boosts ativados", str(int(s.get("boosts_activated", 0))), Style.C_MAGENTA],
	]))

	v.add_child(_section_icon("Equipe", "res://art/ui/nav_equipe.svg", Style.C_BLUE))
	var hired_count: int = Employees.hired.size()
	var next_cost: float = 0.0
	if Employees.candidates.size() > 0:
		next_cost = Employees.hire_cost(Employees.candidates[0])
	v.add_child(_stats_card([
		["Funcionários atuais", str(hired_count), Style.C_INK],
		["Contratações na vida", str(int(s.get("employees_hired_total", 0))), Style.C_GREEN],
		["Demissões na vida", str(int(s.get("employees_fired_total", 0))), Style.C_ORANGE],
		["Treinamentos pagos", str(int(s.get("trainings_bought", 0))), Style.C_CYAN],
		["Renda da equipe", "+R$ %s/h" % _fmt_money(Employees.total_income_per_hour()), Style.C_GREEN],
		["Folha salarial", "-R$ %s/h" % _fmt_money(Employees.total_salary_per_hour()), Style.C_INK_SOFT],
		["Próximo contrato (tier %d)" % hired_count, "R$ %s" % _fmt_money(next_cost), Style.C_GOLD],
	]))

	v.add_child(_section_icon("Mercado & Negociação", "res://art/ui/ic_sell.svg", Style.C_GREEN))
	v.add_child(_stats_card([
		["Itens comprados", str(int(s.get("items_bought", 0))), Style.C_INK],
		["Itens vendidos", str(int(s.get("items_sold", 0))), Style.C_GREEN],
		["Negociações fechadas", str(int(s.get("negotiations_won", 0))), Style.C_CYAN],
		["Negociações perdidas", str(int(s.get("negotiations_lost", 0))), Style.C_ORANGE],
		["Viagens feitas", str(int(s.get("travels_made", 0))), Style.C_BLUE],
		["Ciclos de mercado", str(int(s.get("ticks_witnessed", 0))), Style.C_INK_SOFT],
	]))

	v.add_child(_section_icon("Coleção & Mundo", "res://art/ui/nav_colecao.svg", Style.C_ORANGE))
	v.add_child(_stats_card([
		["Produtos descobertos", "%d / %d" % [Collection.discovered_products(), Collection.total_products()], Style.C_INK],
		["NPCs descobertos", "%d / %d" % [Collection.discovered_npcs(), Collection.total_npcs()], Style.C_INK],
		["Cidades descobertas", "%d / %d" % [Collection.discovered_cities(), Collection.total_cities()], Style.C_INK],
		["Bônus de coleção", "+%d%%" % int(round((Collection.global_sell_multiplier() - 1.0) * 100.0)), Style.C_ORANGE],
	]))

	v.add_child(_section_icon("Prestígio & Endgame", "res://art/ui/nav_inicio.svg", Style.C_MAGENTA))
	v.add_child(_stats_card([
		["Título atual", Prestige.title(), Style.C_MAGENTA],
		["Refundações feitas", str(int(s.get("prestige_count", Prestige.count))), Style.C_MAGENTA],
		["Talentos comprados", str(int(s.get("talents_bought", 0))), Style.C_CYAN],
		["Pontos de Prestígio totais", str(Prestige.total_pp), Style.C_GOLD],
		["Contratos concluídos", str(int(s.get("contracts_completed", 0))), Style.C_GREEN],
	]))

	v.add_child(_section_icon("Tempo & Gemas", "res://art/ui/ic_clock.svg", Style.C_CYAN))
	var start_unix: float = float(s.get("first_play_unix", Time.get_unix_time_from_system()))
	var days: int = int((Time.get_unix_time_from_system() - start_unix) / 86400.0)
	v.add_child(_stats_card([
		["Tempo jogado", _fmt_seconds(float(s.get("playtime_seconds", 0.0))), Style.C_CYAN],
		["Dias desde o início", str(maxi(0, days)), Style.C_INK],
		["Gemas atuais", str(GameState.gems), Style.C_GOLD],
		["Gemas ganhas na vida", str(int(s.get("gems_earned", 0))), Style.C_GOLD],
		["Gemas gastas na vida", str(int(s.get("gems_spent", 0))), Style.C_INK_SOFT],
		["Anúncios assistidos", str(int(s.get("ads_watched", 0))), Style.C_BLUE],
	]))

func _centered_line(text: String, size: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return lbl

func _debug_idle(hours: float) -> void:
	var secs: float = hours * 3600.0
	var income: float = Posts.auto_income_per_second() * secs * Prestige.offline_mult()
	income += Employees.income_per_second() * secs * Prestige.income_mult() * Prestige.offline_mult()
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

func _fmt_welcome_income(v: float) -> String:
	return "+ R$ %s" % _fmt_money(v)

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
