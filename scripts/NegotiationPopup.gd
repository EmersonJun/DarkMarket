extends PanelContainer
class_name NegotiationPopup

signal closed

var npc_id: String = ""
var product_id: String = ""
var counter_price: float = 0.0
var has_pressed: bool = false

var COL_CARD := Style.C_CARD_ALT
var COL_ACCENT := Style.C_GREEN
var COL_ACCENT2 := Style.C_ORANGE
var COL_TEXT := Style.C_INK
var COL_MUTED := Style.C_INK_SOFT

var title_lbl: Label
var affinity_lbl: Label
var product_opt: OptionButton
var market_lbl: Label
var interest_lbl: Label
var ask_slider: HSlider
var ask_lbl: Label
var response_lbl: Label
var propose_btn: Button
var accept_counter_btn: Button
var pressure_btn: Button

func configure(p_npc_id: String) -> void:
	npc_id = p_npc_id

func _ready() -> void:
	custom_minimum_size = Vector2(900, 0)
	var panel := Style.sb_card()
	panel.set_border_width_all(4)
	panel.border_color = Style.C_GREEN
	panel.content_margin_left = 36
	panel.content_margin_right = 36
	panel.content_margin_top = 32
	panel.content_margin_bottom = 32
	add_theme_stylebox_override("panel", panel)
	_build_ui()
	_refresh_products()

func _flat(color: Color, radius: int = 16) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 16
	sb.content_margin_bottom = 16
	return sb

func _style_button(btn: Button, fill: Color, font_size: int = 32, min_h: int = 100) -> void:
	Style.style_candy(btn, fill, fill.darkened(0.22), Color.WHITE, font_size, min_h)
	Style.bounce(btn)

func _build_ui() -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	add_child(box)

	var npc: Dictionary = NPCs.NPCS[npc_id]

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 16)
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(head)
	head.add_child(Style.avatar_badge(Style.npc_face_path(npc.arquetipo), Style.ring_color(npc_id), 132))
	var headinfo := VBoxContainer.new()
	headinfo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	headinfo.add_theme_constant_override("separation", 4)
	head.add_child(headinfo)

	title_lbl = Label.new()
	title_lbl.text = npc.nome
	Style.use_display(title_lbl, 40)
	title_lbl.add_theme_color_override("font_color", COL_TEXT)
	headinfo.add_child(title_lbl)

	var arch := Label.new()
	arch.text = npc.arquetipo
	arch.add_theme_font_size_override("font_size", 24)
	arch.add_theme_color_override("font_color", Style.C_CYAN)
	headinfo.add_child(arch)

	var spec := Label.new()
	spec.text = NPCs.specialty(npc_id)
	spec.add_theme_font_size_override("font_size", 22)
	spec.add_theme_color_override("font_color", COL_MUTED)
	spec.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	headinfo.add_child(spec)

	affinity_lbl = Label.new()
	affinity_lbl.add_theme_font_size_override("font_size", 22)
	affinity_lbl.add_theme_color_override("font_color", COL_MUTED)
	headinfo.add_child(affinity_lbl)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	var lbl := Label.new()
	lbl.text = "Vender:"
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_color", COL_TEXT)
	row.add_child(lbl)
	product_opt = OptionButton.new()
	product_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	product_opt.custom_minimum_size = Vector2(0, 80)
	product_opt.add_theme_font_size_override("font_size", 28)
	product_opt.item_selected.connect(_on_product_selected)
	row.add_child(product_opt)

	market_lbl = Label.new()
	market_lbl.add_theme_font_size_override("font_size", 26)
	market_lbl.add_theme_color_override("font_color", COL_MUTED)
	box.add_child(market_lbl)

	interest_lbl = Label.new()
	interest_lbl.add_theme_font_size_override("font_size", 28)
	interest_lbl.add_theme_color_override("font_color", COL_ACCENT)
	box.add_child(interest_lbl)

	ask_lbl = Label.new()
	ask_lbl.add_theme_font_size_override("font_size", 32)
	ask_lbl.add_theme_color_override("font_color", COL_TEXT)
	box.add_child(ask_lbl)

	ask_slider = HSlider.new()
	ask_slider.custom_minimum_size = Vector2(0, 56)
	ask_slider.value_changed.connect(_on_slider_changed)
	box.add_child(ask_slider)

	var bubble_wrap := VBoxContainer.new()
	bubble_wrap.add_theme_constant_override("separation", 0)
	box.add_child(bubble_wrap)
	var tail := Control.new()
	tail.custom_minimum_size = Vector2(0, 16)
	tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([Vector2(54, 16), Vector2(90, 16), Vector2(64, 0)])
	poly.color = Style.C_CARD_ALT
	tail.add_child(poly)
	bubble_wrap.add_child(tail)
	var bubble := PanelContainer.new()
	var bsb := Style.sb_flat(Style.C_CARD_ALT, 22)
	bsb.set_border_width_all(2)
	bsb.border_color = Style.C_CYAN
	bsb.content_margin_left = 22
	bsb.content_margin_right = 22
	bsb.content_margin_top = 16
	bsb.content_margin_bottom = 16
	bubble.add_theme_stylebox_override("panel", bsb)
	bubble_wrap.add_child(bubble)
	response_lbl = Label.new()
	response_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	response_lbl.custom_minimum_size = Vector2(0, 70)
	response_lbl.add_theme_font_size_override("font_size", 27)
	response_lbl.add_theme_color_override("font_color", Style.C_INK)
	response_lbl.text = "..."
	bubble.add_child(response_lbl)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	box.add_child(btn_row)

	propose_btn = Button.new()
	propose_btn.text = "Propor"
	propose_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(propose_btn, COL_ACCENT)
	propose_btn.pressed.connect(_on_propose)
	btn_row.add_child(propose_btn)

	accept_counter_btn = Button.new()
	accept_counter_btn.text = "Aceitar contra"
	accept_counter_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	accept_counter_btn.visible = false
	_style_button(accept_counter_btn, COL_ACCENT2)
	accept_counter_btn.pressed.connect(_on_accept_counter)
	btn_row.add_child(accept_counter_btn)

	var btn_row2 := HBoxContainer.new()
	btn_row2.add_theme_constant_override("separation", 12)
	box.add_child(btn_row2)

	pressure_btn = Button.new()
	pressure_btn.text = "Pressionar"
	pressure_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pressure_btn.visible = false
	_style_button(pressure_btn, Color(0.55, 0.30, 0.30))
	pressure_btn.pressed.connect(_on_pressure)
	btn_row2.add_child(pressure_btn)

	var close_btn := Button.new()
	close_btn.text = "Sair"
	close_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(close_btn, Color(0.28, 0.31, 0.38))
	close_btn.pressed.connect(_close)
	btn_row2.add_child(close_btn)

func _refresh_products() -> void:
	product_opt.clear()
	var ids: Array = GameState.inventory.keys()
	if ids.is_empty():
		market_lbl.text = ""
		interest_lbl.text = ""
		ask_lbl.text = ""
		response_lbl.text = "Sua mochila está vazia. Compre algo antes de negociar."
		propose_btn.disabled = true
		ask_slider.editable = false
		product_id = ""
		_update_affinity_label()
		return
	propose_btn.disabled = false
	ask_slider.editable = true
	for pid in ids:
		var p: Dictionary = Economy.PRODUCTS[pid]
		var qty: int = GameState.inventory[pid]
		product_opt.add_item("%s (x%d)" % [p.nome, qty])
		product_opt.set_item_metadata(product_opt.item_count - 1, pid)
	product_opt.select(0)
	_on_product_selected(0)
	_update_affinity_label()

func _update_affinity_label() -> void:
	var npc: Dictionary = NPCs.NPCS[npc_id]
	affinity_lbl.text = "Relação: %s  (afinidade %d/100)" % [NPCs.tier_name(int(npc.afinidade)), int(npc.afinidade)]

func _on_product_selected(index: int) -> void:
	product_id = product_opt.get_item_metadata(index)
	var market: float = Economy.price_at(GameState.current_city_id, product_id)
	market_lbl.text = "Preço de mercado aqui: R$ %.2f" % market
	interest_lbl.text = "Interesse: %s" % NPCs.interest_label(npc_id, product_id)
	ask_slider.min_value = snapped(market * 0.5, 0.01)
	ask_slider.max_value = snapped(market * 2.0, 0.01)
	ask_slider.step = max(0.01, snapped(market * 0.01, 0.01))
	ask_slider.value = market
	_on_slider_changed(market)
	response_lbl.text = ""
	_hide_counter()

func _on_slider_changed(v: float) -> void:
	var market: float = Economy.price_at(GameState.current_city_id, product_id)
	var pct: float = ((v / market) - 1.0) * 100.0 if market > 0.0 else 0.0
	ask_lbl.text = "Seu pedido: R$ %.2f  (%+.0f%% vs mercado)" % [v, pct]

func _on_propose() -> void:
	if product_id == "":
		return
	var asking: float = ask_slider.value
	var res: Dictionary = NPCs.evaluate_offer(npc_id, product_id, asking)
	match res.result:
		"accept":
			_finalize(asking, 2, "%s topou! \"Fechado por R$ %.2f.\"" % [NPCs.NPCS[npc_id].nome, asking])
		"counter":
			counter_price = res.counter_price
			response_lbl.text = "%s contrapropõe: \"Te pago R$ %.2f, no máximo.\"" % [NPCs.NPCS[npc_id].nome, counter_price]
			_show_counter()
		"refuse":
			response_lbl.text = "%s recusa: \"Caro demais pra mim.\"" % NPCs.NPCS[npc_id].nome
			_hide_counter()

func _on_accept_counter() -> void:
	_finalize(counter_price, 1, "Negócio fechado por R$ %.2f." % counter_price)

func _on_pressure() -> void:
	if has_pressed:
		return
	has_pressed = true
	NPCs.add_affinity(npc_id, -3)
	pressure_btn.disabled = true
	var asking: float = ask_slider.value
	if randf() < 0.5:
		_finalize(asking, 0, "Sob pressão, %s cede: \"Tá bom, R$ %.2f... mas não abuse.\"" % [NPCs.NPCS[npc_id].nome, asking])
	else:
		response_lbl.text = "%s se irrita: \"Não force a barra!\" (afinidade -3)" % NPCs.NPCS[npc_id].nome
		_update_affinity_label()

func _finalize(price: float, affinity_delta: int, msg: String) -> void:
	if GameState.inventory.get(product_id, 0) <= 0:
		return
	GameState.remove_item(product_id, 1)
	var final_price: float = price * Collection.global_sell_multiplier() * Prestige.sell_mult()
	GameState.change_money(final_price)
	GameState.emit_signal("item_sold", final_price)
	if affinity_delta != 0:
		NPCs.add_affinity(npc_id, affinity_delta)
	response_lbl.add_theme_color_override("font_color", Color(0.5, 0.95, 0.55))
	response_lbl.text = msg
	_update_affinity_label()
	_hide_counter()
	await get_tree().create_timer(0.7).timeout
	if not is_instance_valid(self):
		return
	response_lbl.add_theme_color_override("font_color", Color(0.95, 0.9, 0.6))
	if GameState.inventory.is_empty():
		_close()
	else:
		has_pressed = false
		_refresh_products()

func _show_counter() -> void:
	accept_counter_btn.text = "Aceitar R$ %.2f" % counter_price
	accept_counter_btn.visible = true
	pressure_btn.visible = not has_pressed

func _hide_counter() -> void:
	accept_counter_btn.visible = false
	pressure_btn.visible = false

func _close() -> void:
	emit_signal("closed")
	queue_free()
