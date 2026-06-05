extends Control

func _ready() -> void:
	_setup_window()
	_build()

func _setup_window() -> void:
	var win := get_window()
	win.min_size = Vector2i(360, 640)
	if win.size.x < 480:
		win.size = Vector2i(540, 960)
	var root := get_tree().root
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	root.content_scale_size = Vector2i(1080, 1920)

func _build() -> void:

	var grad := Gradient.new()
	grad.set_color(0, Style.C_SKY_TOP)
	grad.set_color(1, Style.C_BG)
	var gtex := GradientTexture2D.new()
	gtex.gradient = grad
	gtex.fill_to = Vector2(0, 1)
	gtex.height = 256
	var bg := TextureRect.new()
	bg.texture = gtex
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	add_child(Style.make_vignette())

	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 18)
	var pad := MarginContainer.new()
	pad.set_anchors_preset(Control.PRESET_FULL_RECT)
	pad.add_theme_constant_override("margin_left", 80)
	pad.add_theme_constant_override("margin_right", 80)
	pad.add_child(col)
	add_child(pad)

	var mascot := TextureRect.new()
	if ResourceLoader.exists("res://art/mascot.svg"):
		mascot.texture = load("res://art/mascot.svg")
	mascot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mascot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mascot.custom_minimum_size = Vector2(0, 460)
	mascot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(mascot)
	_bob(mascot)

	var l1 := _word("MERCADO", 100, Color.WHITE)
	var l2 := _word("NEGRO", 112, Style.C_GOLD)
	col.add_child(l1)
	col.add_child(l2)

	var tag := Label.new()
	tag.text = "Todo império começa no escuro"
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.add_theme_font_size_override("font_size", 32)
	tag.add_theme_color_override("font_color", Style.C_INK_SOFT)
	col.add_child(tag)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 24)
	col.add_child(spacer)

	var start := Style.primary_button("Toque para começar", 38, 120)
	start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start.custom_minimum_size = Vector2(620, 120)
	start.pressed.connect(_start)
	col.add_child(start)

func _word(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Style.use_display(l, size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color("05050a"))
	l.add_theme_constant_override("outline_size", 16)
	return l

func _bob(node: Control) -> void:
	node.pivot_offset = Vector2(node.custom_minimum_size.x * 0.5, 230)
	var tw := node.create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(node, "position:y", 14.0, 1.4).as_relative()
	tw.tween_property(node, "position:y", -14.0, 1.4).as_relative()

func _start() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
