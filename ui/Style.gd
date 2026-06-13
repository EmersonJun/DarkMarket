extends Node

# Paleta: feira noturna / mercado paralelo. Dark, porem mais quente e convidativa,
# com dourado como cor-heroi de recompensa (DNA Idle Miner sobre tema escuro).
var C_SKY_TOP := Color("2b1d44")
var C_SKY_BOT := Color("0e0a18")
var C_BG := Color("0e0a18")
var C_CARD := Color("1b1730")
var C_CARD_ALT := Color("2a2342")
var C_BORDER := Color("3a3060")
var C_INK := Color("f7f2ff")
var C_INK_SOFT := Color("a79fc4")
var C_GREEN := Color("2bf09a")
var C_GREEN_DK := Color("14b06c")
var C_CYAN := Color("2ce6cf")
var C_CYAN_DK := Color("12a896")
var C_MAGENTA := Color("ff4fb8")
var C_GOLD := Color("ffd24a")
var C_GOLD_DK := Color("d99a2a")
var C_ORANGE := Color("ffa83d")
var C_ORANGE_DK := Color("e5812a")
var C_BLUE := Color("5aa6ff")
var C_BLUE_DK := Color("2f73d6")
var C_RED := Color("ff4f74")
var C_RED_DK := Color("d62a54")
var C_NEUTRAL := Color("564f74")
var C_NEUTRAL_DK := Color("3a3552")
var C_SHADOW := Color(0, 0, 0, 0.55)
var C_LAMP := Color("ffb74a")

var RARITY := {
	"Comum": Color("c2cad6"),
	"Incomum": Color("5fe08a"),
	"Raro": Color("5ab0ff"),
	"Épico": Color("c98bff"),
	"Lendário": Color("ffc94a"),
	"Mítico": Color("ff6ea8"),
}

var font_display: Font
var font_body: Font

func _ready() -> void:
	font_display = _try_font("res://ui/fonts/Baloo2.ttf")
	font_body = _try_font("res://ui/fonts/Nunito.ttf")
	_apply_root_theme()

func _try_font(path: String) -> Font:
	if ResourceLoader.exists(path):
		return load(path)
	return null

func _apply_root_theme() -> void:
	var t := Theme.new()
	if font_body:
		t.default_font = font_body
	t.default_font_size = 30
	get_tree().root.theme = t

func use_display(lbl: Control, size: int = -1) -> void:
	if font_display:
		lbl.add_theme_font_override("font", font_display)
	if size > 0:
		lbl.add_theme_font_size_override("font_size", size)

func rarity_color(r: String) -> Color:
	return RARITY.get(r, C_INK_SOFT)

var ARCHETYPE_SLUG := {
	"Contrabandista Veterano": "veterano",
	"Receptador de Iguarias": "iguarias",
	"Atravessador": "atravessador",
	"Comprador Discreto": "discreto",
	"Colecionador Clandestino": "colecionador",
	"Receptador de Relíquias": "reliquias",
	"Informante": "informante",
}

func npc_face_path(arquetipo: String) -> String:
	var slug: String = ARCHETYPE_SLUG.get(arquetipo, "veterano")
	return "res://art/avatars/npc_%s.svg" % slug

var EMP_SLUG := {
	"Comprador": "comprador",
	"Vendedor": "vendedor",
	"Motorista": "motorista",
	"Analista": "analista",
	"Gerente": "gerente",
}

func emp_face_path(categoria: String) -> String:
	var slug: String = EMP_SLUG.get(categoria, "comprador")
	return "res://art/avatars/emp_%s.svg" % slug

func ring_color(seed_str: String) -> Color:
	var pal := [C_CYAN, C_MAGENTA, C_GOLD, C_GREEN, C_BLUE, C_ORANGE]
	return pal[absi(hash(seed_str)) % pal.size()]

func avatar_badge(face_path: String, accent: Color, size: int = 100) -> PanelContainer:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(size, size)
	var sb := StyleBoxFlat.new()
	sb.bg_color = C_CARD_ALT
	sb.set_corner_radius_all(int(size / 2))
	sb.set_border_width_all(3)
	sb.border_color = accent
	neon(sb, accent, 10, 0.45)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	p.add_theme_stylebox_override("panel", sb)
	var t := TextureRect.new()
	if ResourceLoader.exists(face_path):
		t.texture = load(face_path)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	p.add_child(t)
	return p

func sb_flat(color: Color, radius: int = 20) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 18
	sb.content_margin_bottom = 18
	return sb

func sb_card(color: Color = C_CARD, radius: int = 28) -> StyleBoxFlat:
	var sb := sb_flat(color, radius)
	sb.set_border_width_all(2)
	sb.border_color = C_BORDER
	sb.shadow_color = C_SHADOW
	sb.shadow_size = 12
	sb.shadow_offset = Vector2(0, 7)
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 18
	sb.content_margin_bottom = 18
	return sb

func sb_card_neon(accent: Color, radius: int = 28) -> StyleBoxFlat:
	var sb := sb_flat(C_CARD, radius)
	sb.set_border_width_all(3)
	sb.border_color = accent
	sb.shadow_color = Color(accent.r, accent.g, accent.b, 0.40)
	sb.shadow_size = 18
	sb.shadow_offset = Vector2(0, 0)
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 18
	sb.content_margin_bottom = 18
	return sb

func neon(sb: StyleBoxFlat, color: Color, size: int = 12, alpha: float = 0.45) -> StyleBoxFlat:
	sb.shadow_color = Color(color.r, color.g, color.b, alpha)
	sb.shadow_size = size
	sb.shadow_offset = Vector2(0, 0)
	return sb

func sb_pill(color: Color, radius: int = 40) -> StyleBoxFlat:
	var sb := sb_flat(color, radius)
	sb.content_margin_left = 26
	sb.content_margin_right = 26
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	return sb

func make_vignette() -> TextureRect:
	var g := Gradient.new()
	g.set_color(0, Color(0, 0, 0, 0))
	g.set_color(1, Color(0, 0, 0, 0.55))
	g.set_offset(0, 0.45)
	g.set_offset(1, 1.0)
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 1.0)
	tex.width = 256
	tex.height = 256
	var tr := TextureRect.new()
	tr.texture = tex
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr

# Glow dourado radial de "lampiao" para por atras do conteudo (vida de feira noturna).
func make_lamp_glow(color: Color = C_LAMP, intensity: float = 0.22) -> TextureRect:
	var g := Gradient.new()
	g.set_color(0, Color(color.r, color.g, color.b, intensity))
	g.set_color(1, Color(color.r, color.g, color.b, 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 1.0)
	tex.width = 256
	tex.height = 256
	var tr := TextureRect.new()
	tr.texture = tex
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr

func candy_button(text: String, fill: Color, lip: Color, font_size: int = 32, min_h: int = 100) -> Button:
	var btn := Button.new()
	btn.text = text
	style_candy(btn, fill, lip, Color.WHITE, font_size, min_h)
	bounce(btn)
	return btn

func style_candy(btn: Button, fill: Color, lip: Color, fg: Color = Color.WHITE, font_size: int = 32, min_h: int = 100) -> void:
	if min_h > 0:
		btn.custom_minimum_size = Vector2(0, min_h)
	btn.add_theme_font_size_override("font_size", font_size)
	if font_display:
		btn.add_theme_font_override("font", font_display)
	btn.add_theme_color_override("font_color", fg)
	btn.add_theme_color_override("font_hover_color", fg)
	btn.add_theme_color_override("font_pressed_color", fg)
	btn.add_theme_color_override("font_disabled_color", Color(fg.r, fg.g, fg.b, 0.5))
	# Contorno escuro p/ leitura "candy" (estilo idle game).
	btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.45))
	btn.add_theme_constant_override("outline_size", 6)

	var normal := _candy_sb(fill, lip, 7)
	var hover := _candy_sb(fill.lightened(0.08), lip, 7)
	var pressed := _candy_sb(fill.darkened(0.05), lip, 2)
	var disabled := _candy_sb(Color(fill.r, fill.g, fill.b, 0.4), Color(lip.r, lip.g, lip.b, 0.4), 7)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.add_theme_stylebox_override("focus", _candy_sb(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0))

func _candy_sb(fill: Color, lip: Color, lip_size: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.set_corner_radius_all(26)
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 16
	sb.content_margin_bottom = 16 + lip_size
	if lip_size > 0 and lip.a > 0.0:
		# "Labio" 3D embaixo + leve realce no topo (gloss).
		sb.border_width_bottom = lip_size
		sb.border_width_top = 3
		sb.border_color = lip
	return sb

func primary_button(text: String, fs: int = 32, h: int = 100) -> Button:
	return candy_button(text, C_GREEN, C_GREEN_DK, fs, h)

func action_button(text: String, fs: int = 32, h: int = 100) -> Button:
	return candy_button(text, C_ORANGE, C_ORANGE_DK, fs, h)

func info_button(text: String, fs: int = 32, h: int = 100) -> Button:
	return candy_button(text, C_BLUE, C_BLUE_DK, fs, h)

func neutral_button(text: String, fs: int = 30, h: int = 90) -> Button:
	return candy_button(text, C_NEUTRAL, C_NEUTRAL_DK, fs, h)

func danger_button(text: String, fs: int = 30, h: int = 90) -> Button:
	return candy_button(text, C_RED, C_RED_DK, fs, h)

func title(text: String, size: int = 44, color: Color = C_INK) -> Label:
	var l := Label.new()
	l.text = text
	use_display(l, size)
	l.add_theme_color_override("font_color", color)
	return l

func body(text: String, size: int = 26, color: Color = C_INK) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func chip(text: String, color: Color, text_color: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 22)
	l.add_theme_color_override("font_color", text_color)
	var sb := sb_flat(color, 18)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	l.add_theme_stylebox_override("normal", sb)
	return l

func progress(value: int, maxv: int, color: Color) -> ProgressBar:
	var pb := ProgressBar.new()
	pb.min_value = 0
	pb.max_value = maxv if maxv > 0 else 1
	pb.value = value
	pb.show_percentage = false
	pb.custom_minimum_size = Vector2(0, 26)
	var bg := sb_flat(C_BG.lightened(0.04), 14)
	bg.content_margin_left = 0
	bg.content_margin_right = 0
	bg.content_margin_top = 0
	bg.content_margin_bottom = 0
	bg.set_border_width_all(2)
	bg.border_color = C_BORDER
	var fg := sb_flat(color, 14)
	fg.content_margin_left = 0
	fg.content_margin_right = 0
	fg.content_margin_top = 0
	fg.content_margin_bottom = 0
	# Gloss: linha clara no topo + glow neon.
	fg.border_width_top = 6
	fg.border_color = color.lightened(0.45)
	fg.shadow_color = Color(color.r, color.g, color.b, 0.5)
	fg.shadow_size = 8
	fg.shadow_offset = Vector2(0, 0)
	pb.add_theme_stylebox_override("background", bg)
	pb.add_theme_stylebox_override("fill", fg)
	return pb

func gradient_texture(top: Color, bottom: Color) -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, top)
	g.set_color(1, bottom)
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0, 1)
	tex.width = 8
	tex.height = 256
	return tex

# ---------------------------------------------------------------------------
# JUICE / animacoes
# ---------------------------------------------------------------------------

func bounce(btn: Button) -> void:
	btn.button_down.connect(_bounce_down.bind(btn))
	btn.button_up.connect(_bounce_up.bind(btn))
	if not btn.pressed.is_connected(_btn_click_sfx):
		btn.pressed.connect(_btn_click_sfx)

func _btn_click_sfx() -> void:
	if has_node("/root/Audio"):
		Audio.click()

func _bounce_down(btn: Button) -> void:
	if not is_instance_valid(btn):
		return
	btn.pivot_offset = btn.size * 0.5
	var tw := btn.create_tween()
	tw.tween_property(btn, "scale", Vector2(0.94, 0.94), 0.06)

func _bounce_up(btn: Button) -> void:
	if not is_instance_valid(btn):
		return
	btn.pivot_offset = btn.size * 0.5
	var tw := btn.create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(btn, "scale", Vector2.ONE, 0.35)

func pop(node: Control, strength: float = 1.15) -> void:
	if not is_instance_valid(node):
		return
	node.pivot_offset = node.size * 0.5
	node.scale = Vector2(strength, strength)
	var tw := node.create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "scale", Vector2.ONE, 0.4)

# Pulso continuo (respiracao) para chamar atencao em CTAs prontos.
func breathe(node: Control, amount: float = 0.05, dur: float = 0.7) -> void:
	if not is_instance_valid(node):
		return
	node.pivot_offset = node.size * 0.5
	var tw := node.create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(node, "scale", Vector2(1.0 + amount, 1.0 + amount), dur)
	tw.tween_property(node, "scale", Vector2.ONE, dur)

# Balanco leve (rotacao) - bom para o mascote ocioso.
func idle_wiggle(node: Control, deg: float = 4.0, dur: float = 1.2) -> void:
	if not is_instance_valid(node):
		return
	node.pivot_offset = node.size * 0.5
	var tw := node.create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(node, "rotation_degrees", -deg, dur)
	tw.tween_property(node, "rotation_degrees", deg, dur)

# Jiggle rapido (ex: icone de moeda quando o saldo muda).
func jiggle(node: Control) -> void:
	if not is_instance_valid(node):
		return
	node.pivot_offset = node.size * 0.5
	var tw := node.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "scale", Vector2(1.25, 1.25), 0.08)
	tw.tween_property(node, "scale", Vector2.ONE, 0.22)

# Anel pulsante de destaque (ex: posto pronto). Loopa alpha + escala.
func pulse_ring(node: Control, dur: float = 0.6) -> void:
	if not is_instance_valid(node):
		return
	node.pivot_offset = node.size * 0.5
	var tw := node.create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(node, "scale", Vector2(1.08, 1.08), dur)
	tw.parallel().tween_property(node, "modulate:a", 0.55, dur)
	tw.tween_property(node, "scale", Vector2.ONE, dur)
	tw.parallel().tween_property(node, "modulate:a", 1.0, dur)

# Count-up numerico para reveals (modal de recompensa etc). fmt recebe float -> String.
func count_up(label: Label, from: float, to: float, fmt: Callable, dur: float = 0.5) -> void:
	if not is_instance_valid(label):
		return
	var tw := label.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_method(_apply_count.bind(label, fmt), from, to, dur)

func _apply_count(v: float, label: Label, fmt: Callable) -> void:
	if is_instance_valid(label):
		label.text = String(fmt.call(v))

# Sweep de brilho diagonal periodico sobre um botao/painel habilitado.
func shine_sweep(ctrl: Control, period: float = 2.8) -> void:
	if not is_instance_valid(ctrl):
		return
	ctrl.clip_contents = true
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.5, Color(1, 1, 1, 0.18))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(1, 0)
	tex.width = 64
	tex.height = 8
	var sheen := TextureRect.new()
	sheen.texture = tex
	sheen.stretch_mode = TextureRect.STRETCH_SCALE
	sheen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sheen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sheen.rotation_degrees = 18.0
	sheen.size = Vector2(90, 240)
	sheen.position = Vector2(-160, -60)
	ctrl.add_child(sheen)
	_run_sheen(sheen, ctrl, period)

func _run_sheen(sheen: TextureRect, ctrl: Control, period: float) -> void:
	if not is_instance_valid(sheen) or not is_instance_valid(ctrl):
		return
	var w: float = maxf(ctrl.size.x, 120.0)
	sheen.position = Vector2(-160, -60)
	var tw := sheen.create_tween()
	tw.tween_interval(randf_range(0.2, period))
	tw.tween_property(sheen, "position:x", w + 60.0, 0.55).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(_run_sheen.bind(sheen, ctrl, period))

# Rajada de moedas que arcam de from_pos ate to_pos (carteira). Toca SFX por moeda.
func coin_burst(overlay: Control, from_pos: Vector2, to_pos: Vector2, count: int = 8, on_each: Callable = Callable()) -> void:
	if not is_instance_valid(overlay):
		return
	var coin_path := "res://art/ui/coin.svg"
	var tex: Texture2D = load(coin_path) if ResourceLoader.exists(coin_path) else null
	for i in count:
		var c := TextureRect.new()
		if tex:
			c.texture = tex
		c.custom_minimum_size = Vector2(44, 44)
		c.size = Vector2(44, 44)
		c.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		c.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.z_index = 60
		var jitter := Vector2(randf_range(-50, 50), randf_range(-40, 20))
		var start := from_pos - Vector2(22, 22) + jitter
		c.global_position = start
		overlay.add_child(c)
		var ctrl_pt := start.lerp(to_pos, 0.4) + Vector2(randf_range(-60, 60), randf_range(-160, -70))
		var endp := to_pos - Vector2(22, 22)
		var dur := randf_range(0.42, 0.62)
		var delay := i * 0.035
		var tw := c.create_tween().set_parallel(false)
		tw.tween_interval(delay)
		tw.tween_method(_move_coin.bind(c, start, ctrl_pt, endp), 0.0, 1.0, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.parallel().tween_property(c, "scale", Vector2(1.3, 1.3), dur * 0.5)
		tw.tween_callback(_coin_landed.bind(on_each))
		tw.tween_property(c, "scale", Vector2(0.2, 0.2), 0.12)
		tw.parallel().tween_property(c, "modulate:a", 0.0, 0.12)
		tw.tween_callback(c.queue_free)

func _move_coin(t: float, c: TextureRect, a: Vector2, b: Vector2, endp: Vector2) -> void:
	if is_instance_valid(c):
		c.global_position = _bezier2(a, b, endp, t)

func _coin_landed(on_each: Callable) -> void:
	if on_each.is_valid():
		on_each.call()
	if has_node("/root/Audio"):
		Audio.coin()

func _bezier2(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
	var ab := a.lerp(b, t)
	var bc := b.lerp(c, t)
	return ab.lerp(bc, t)

# Explosao de confete colorido a partir de uma posicao (marcos, level-up, diaria).
func confetti(overlay: Control, pos: Vector2, count: int = 26) -> void:
	if not is_instance_valid(overlay):
		return
	var cols := [C_GREEN, C_CYAN, C_MAGENTA, C_GOLD, C_ORANGE, C_BLUE]
	for i in count:
		var p := ColorRect.new()
		p.color = cols[randi() % cols.size()]
		var sz := randf_range(10, 20)
		p.size = Vector2(sz, sz * randf_range(0.5, 1.0))
		p.position = pos
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.z_index = 70
		p.pivot_offset = p.size * 0.5
		overlay.add_child(p)
		var ang := randf_range(-PI, 0.0)
		var speed := randf_range(260, 620)
		var vel := Vector2(cos(ang), sin(ang)) * speed
		var life := randf_range(0.7, 1.15)
		_confetti_fly(p, pos, vel, life)
		var rt := p.create_tween()
		rt.tween_property(p, "rotation_degrees", randf_range(180, 540), life)

func _confetti_fly(p: ColorRect, origin: Vector2, vel: Vector2, life: float) -> void:
	var tw := p.create_tween()
	tw.tween_method(_move_confetti.bind(p, origin, vel, 900.0), 0.0, life, life)
	tw.parallel().tween_property(p, "modulate:a", 0.0, life).set_delay(life * 0.55)
	tw.tween_callback(p.queue_free)

func _move_confetti(t: float, p: ColorRect, origin: Vector2, vel: Vector2, grav: float) -> void:
	if is_instance_valid(p):
		p.position = origin + vel * t + Vector2(0, 0.5 * grav * t * t)

# Flash branco rapido em tela cheia (impacto de marco). Parent = overlay full rect.
func screen_flash(overlay: Control, color: Color = Color(1, 1, 1, 0.5)) -> void:
	if not is_instance_valid(overlay):
		return
	var r := ColorRect.new()
	r.color = color
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.z_index = 80
	overlay.add_child(r)
	var tw := r.create_tween()
	tw.tween_property(r, "modulate:a", 0.0, 0.35)
	tw.tween_callback(r.queue_free)

# ---------------------------------------------------------------------------
# LOJA / ITENS / CARDS (iteracao 2)
# ---------------------------------------------------------------------------

# Miniaturas dos produtos. Mapeia id (com acento) -> slug do arquivo.
var ITEM_SLUG := {
	"maca": "carne",
	"queijo_canastra": "queijo",
	"mel_silvestre": "cachaca",
	"camisa_basica": "camisa",
	"perfume_urbano": "perfume",
	"bacalhau_seco": "bacalhau",
	"especiarias_raras": "especiarias",
	"container_misterio": "container",
	"moeda_antiga": "moeda",
	"manuscrito": "manuscrito",
	"reliquia_pedra": "reliquia",
	"lampião_velho": "lampiao",
}

func item_icon_path(pid: String) -> String:
	return "res://art/items/%s.svg" % String(ITEM_SLUG.get(pid, "container"))

func item_texture(pid: String) -> Texture2D:
	var path := item_icon_path(pid)
	if ResourceLoader.exists(path):
		return load(path)
	return null

# Coloca um icone (branco) num botao, ao lado do texto. Bom p/ acoes.
func set_btn_icon(btn: Button, path: String, size: int = 40) -> void:
	if ResourceLoader.exists(path):
		btn.icon = load(path)
		btn.add_theme_constant_override("icon_max_width", size)
		btn.expand_icon = false
		btn.add_theme_constant_override("h_separation", 12)

# Painel-tile quadrado com moldura neon (prateleira de loja, thumbs).
func tile_panel(accent: Color) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := sb_card_neon(accent, 24)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 16
	sb.content_margin_bottom = 16
	p.add_theme_stylebox_override("panel", sb)
	return p

# Moldura redonda p/ thumb de item (inset escuro + borda da raridade).
func thumb_frame(tex: Texture2D, accent: Color, size: int = 120) -> PanelContainer:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(size, size)
	var sb := StyleBoxFlat.new()
	sb.bg_color = C_BG.lightened(0.04)
	sb.set_corner_radius_all(20)
	sb.set_border_width_all(3)
	sb.border_color = accent
	neon(sb, accent, 8, 0.35)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	p.add_theme_stylebox_override("panel", sb)
	var t := TextureRect.new()
	if tex:
		t.texture = tex
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(t)
	return p

# Etiqueta de preco estilo loja (pilula com moeda).
func price_ribbon(text: String, color: Color = C_GREEN) -> PanelContainer:
	var pill := PanelContainer.new()
	var sb := sb_flat(color, 14)
	sb.content_margin_left = 14
	sb.content_margin_right = 16
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	pill.add_theme_stylebox_override("panel", sb)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	pill.add_child(h)
	if ResourceLoader.exists("res://art/ui/coin.svg"):
		var ic := TextureRect.new()
		ic.texture = load("res://art/ui/coin.svg")
		ic.custom_minimum_size = Vector2(26, 26)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		h.add_child(ic)
	var l := Label.new()
	l.text = text
	use_display(l, 25)
	l.add_theme_color_override("font_color", C_BG)
	h.add_child(l)
	return pill

# Barra de atributo rotulada (equipe). value 0..100.
func attr_bar(label: String, value: int, color: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var l := Label.new()
	l.text = label
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", C_INK_SOFT)
	l.custom_minimum_size = Vector2(48, 0)
	row.add_child(l)
	var pb := progress(clampi(value, 0, 100), 100, color)
	pb.custom_minimum_size = Vector2(0, 16)
	pb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(pb)
	var v := Label.new()
	v.text = str(value)
	use_display(v, 18)
	v.add_theme_color_override("font_color", C_INK)
	v.custom_minimum_size = Vector2(36, 0)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(v)
	return row

# Pilula compacta "icone + valor" (renda, salario, recompensa).
func stat_pill(icon_path: String, text: String, color: Color, text_color: Color = Color.WHITE) -> PanelContainer:
	var pill := PanelContainer.new()
	var sb := sb_flat(C_CARD_ALT, 14)
	sb.set_border_width_all(2)
	sb.border_color = color
	sb.content_margin_left = 12
	sb.content_margin_right = 14
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	pill.add_theme_stylebox_override("panel", sb)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	pill.add_child(h)
	if ResourceLoader.exists(icon_path):
		var ic := TextureRect.new()
		ic.texture = load(icon_path)
		ic.custom_minimum_size = Vector2(26, 26)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.modulate = color
		h.add_child(ic)
	var l := Label.new()
	l.text = text
	use_display(l, 22)
	l.add_theme_color_override("font_color", text_color)
	h.add_child(l)
	return pill
