extends Node

var C_SKY_TOP := Color("161226")
var C_SKY_BOT := Color("08080f")
var C_BG := Color("08080f")
var C_CARD := Color("15131f")
var C_CARD_ALT := Color("221d33")
var C_BORDER := Color("2a2440")
var C_INK := Color("f2eeff")
var C_INK_SOFT := Color("9a93b5")
var C_GREEN := Color("1fe08a")
var C_GREEN_DK := Color("14b06c")
var C_CYAN := Color("19e0c8")
var C_CYAN_DK := Color("12a896")
var C_MAGENTA := Color("ff3dae")
var C_GOLD := Color("ffd24a")
var C_GOLD_DK := Color("d9a93a")
var C_ORANGE := Color("ff9f3d")
var C_ORANGE_DK := Color("e5812a")
var C_BLUE := Color("4f9bff")
var C_BLUE_DK := Color("2f73d6")
var C_RED := Color("ff3d6e")
var C_RED_DK := Color("d62a54")
var C_NEUTRAL := Color("4a4660")
var C_NEUTRAL_DK := Color("36324a")
var C_SHADOW := Color(0, 0, 0, 0.5)

var RARITY := {
	"Comum": Color("b8c0cc"),
	"Incomum": Color("4fd17a"),
	"Raro": Color("4fa3ff"),
	"Épico": Color("c07bff"),
	"Lendário": Color("ffc049"),
	"Mítico": Color("ff5e9e"),
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
	neon(sb, accent, 8, 0.4)
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

func sb_card(color: Color = C_CARD, radius: int = 26) -> StyleBoxFlat:
	var sb := sb_flat(color, radius)
	sb.set_border_width_all(2)
	sb.border_color = C_BORDER
	sb.shadow_color = C_SHADOW
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 6)
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 18
	sb.content_margin_bottom = 18
	return sb

func sb_card_neon(accent: Color, radius: int = 26) -> StyleBoxFlat:
	var sb := sb_flat(C_CARD, radius)
	sb.set_border_width_all(2)
	sb.border_color = accent
	sb.shadow_color = Color(accent.r, accent.g, accent.b, 0.35)
	sb.shadow_size = 14
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

	var normal := _candy_sb(fill, lip, 6)
	var hover := _candy_sb(fill.lightened(0.06), lip, 6)
	var pressed := _candy_sb(fill.darkened(0.04), lip, 2)
	var disabled := _candy_sb(Color(fill.r, fill.g, fill.b, 0.45), Color(lip.r, lip.g, lip.b, 0.45), 6)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.add_theme_stylebox_override("focus", _candy_sb(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0))

func _candy_sb(fill: Color, lip: Color, lip_size: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.set_corner_radius_all(22)
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 16
	sb.content_margin_bottom = 16 + lip_size
	if lip_size > 0 and lip.a > 0.0:
		sb.shadow_color = lip
		sb.shadow_size = 0
		sb.border_width_bottom = lip_size
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
	pb.custom_minimum_size = Vector2(0, 22)
	var bg := sb_flat(C_CARD_ALT, 12)
	bg.content_margin_left = 0
	bg.content_margin_right = 0
	bg.content_margin_top = 0
	bg.content_margin_bottom = 0
	bg.set_border_width_all(2)
	bg.border_color = C_BORDER
	var fg := sb_flat(color, 12)
	fg.content_margin_left = 0
	fg.content_margin_right = 0
	fg.content_margin_top = 0
	fg.content_margin_bottom = 0

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

func bounce(btn: Button) -> void:
	btn.button_down.connect(_bounce_down.bind(btn))
	btn.button_up.connect(_bounce_up.bind(btn))

func _bounce_down(btn: Button) -> void:
	if not is_instance_valid(btn):
		return
	btn.pivot_offset = btn.size * 0.5
	var tw := btn.create_tween()
	tw.tween_property(btn, "scale", Vector2(0.95, 0.95), 0.06)

func _bounce_up(btn: Button) -> void:
	if not is_instance_valid(btn):
		return
	btn.pivot_offset = btn.size * 0.5
	var tw := btn.create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(btn, "scale", Vector2.ONE, 0.35)

func pop(node: Control) -> void:
	if not is_instance_valid(node):
		return
	node.pivot_offset = node.size * 0.5
	node.scale = Vector2(1.15, 1.15)
	var tw := node.create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "scale", Vector2.ONE, 0.4)
