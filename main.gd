extends Node2D

const WORLD_SIZE := Vector2(2400, 1800)
const TILE := 48
const PlayerScript = preload("res://scripts/player.gd")
const NPCScript = preload("res://scripts/npc.gd")

var player: CharacterBody2D
var npcs: Array[Node2D] = []
var game_time := 8.0
var day := 1
var money := 120
var player_name := "Alex"
var outfit := 0
var current_building := ""
var inside := false
var menu_open := true
var message := "Bienvenido/a a Barrio Abierto."
var message_timer := 4.0
var hud: CanvasLayer
var panel: ColorRect
var clock_label: Label
var money_label: Label
var message_label: Label
var name_edit: LineEdit
var outfit_select: OptionButton
var start_button: Button
var menu_root: Control
var touch_pad: Control
var touch_interact: Button
var touch_pause: Button

func _ready() -> void:
    randomize()
    _build_world()
    _spawn_player()
    _spawn_npcs()
    _build_ui()
    _show_message("Explorá el barrio. Usá el joystick táctil o WASD. E: interactuar.")
    _on_resize()
    get_viewport().size_changed.connect(_on_resize)

func _process(delta: float) -> void:
    if not menu_open:
        game_time += delta * 0.08
        if game_time >= 24.0:
            game_time -= 24.0
            day += 1
            _show_message("Día %d: la ciudad sigue su ritmo." % day)
        _update_lighting()
        _update_hud()
        if message_timer > 0:
            message_timer -= delta
            message_label.visible = true
        else:
            message_label.visible = false
        if Input.is_action_just_pressed("interact"):
            _interact()
        if Input.is_action_just_pressed("pause_menu"):
            _toggle_pause()
    queue_redraw()

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color("#31494a"))
    for x in range(0, int(WORLD_SIZE.x), TILE * 5):
        draw_rect(Rect2(x, 0, TILE * 2, WORLD_SIZE.y), Color("#55585a"))
        draw_rect(Rect2(x - 5, 0, 5, WORLD_SIZE.y), Color("#9a9b8d"))
        for y in range(0, int(WORLD_SIZE.y), 72):
            draw_rect(Rect2(x + 46, y, 3, 28), Color("#d5c89b"))
    for y in range(0, int(WORLD_SIZE.y), TILE * 5):
        draw_rect(Rect2(0, y, WORLD_SIZE.x, TILE * 2), Color("#55585a"))
        draw_rect(Rect2(0, y - 5, WORLD_SIZE.x, 5), Color("#9a9b8d"))
        for x in range(0, int(WORLD_SIZE.x), 72):
            draw_rect(Rect2(x, y + 46, 28, 3), Color("#d5c89b"))
    for x in range(120, int(WORLD_SIZE.x) - 120, 240):
        for y in range(120, int(WORLD_SIZE.y) - 120, 240):
            var r := Rect2(Vector2(x, y), Vector2(135, 125))
            draw_rect(r, Color("#577a55"))
            draw_rect(Rect2(r.position + Vector2(8, 8), r.size - Vector2(16, 16)), Color("#6c8d5e"))
            for t in range(4):
                var p := Vector2(x + 22 + (t % 2) * 82, y + 22 + int(t / 2) * 72)
                draw_rect(Rect2(p, Vector2(13, 13)), Color("#315b3c"))
                draw_rect(Rect2(p + Vector2(3, 3), Vector2(7, 7)), Color("#4f8050"))
    for b in _building_data():
        var pos: Vector2 = b.pos
        var size: Vector2 = b.size
        draw_rect(Rect2(pos + Vector2(8, 10), size), Color("#273435"))
        draw_rect(Rect2(pos + Vector2(0, -12), size), b.color)
        draw_rect(Rect2(pos + Vector2(0, -12), Vector2(size.x, 12)), b.roof)
        for wx in range(int(pos.x + 12), int(pos.x + size.x - 8), 28):
            draw_rect(Rect2(wx, pos.y + 8, 12, 13), Color("#a9d3c8"))
        draw_rect(Rect2(pos + Vector2(size.x * 0.5 - 10, size.y - 25), Vector2(20, 25)), Color("#654a37"))
        draw_rect(Rect2(pos + Vector2(size.x * 0.5 - 12, size.y - 28), Vector2(24, 4)), Color("#d9bc83"))
        draw_string(ThemeDB.fallback_font, pos + Vector2(8, size.y + 8), b.label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#f2ead3"))
    for x in range(0, int(WORLD_SIZE.x), TILE * 5):
        for k in range(4):
            draw_rect(Rect2(x + 8 + k * 11, 84, 7, 26), Color("#d5d5c8"))
            draw_rect(Rect2(x + 8 + k * 11, 324, 7, 26), Color("#d5d5c8"))
    if inside:
        draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color("#6a5142"))
        draw_rect(Rect2(Vector2(240, 180), Vector2(1920, 1440)), Color("#8a7157"))
        draw_rect(Rect2(Vector2(300, 240), Vector2(1800, 1320)), Color("#b8a184"))
        draw_rect(Rect2(Vector2(420, 360), Vector2(260, 100)), Color("#5c817d"))
        draw_string(ThemeDB.fallback_font, Vector2(430, 410), "MOSTRADOR", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)

func _building_data() -> Array:
    return [
        {"pos": Vector2(150,150), "size": Vector2(125,105), "color": Color("#b96e53"), "roof": Color("#8e493f"), "label":"ALMACÉN"},
        {"pos": Vector2(390,150), "size": Vector2(125,105), "color": Color("#c4a46b"), "roof": Color("#8f7549"), "label":"CAFÉ"},
        {"pos": Vector2(630,150), "size": Vector2(125,105), "color": Color("#8b9b9a"), "roof": Color("#596d70"), "label":"CLÍNICA"},
        {"pos": Vector2(870,150), "size": Vector2(125,105), "color": Color("#b6a0c5"), "roof": Color("#7b678f"), "label":"CASA"},
        {"pos": Vector2(150,390), "size": Vector2(125,105), "color": Color("#d0b27a"), "roof": Color("#967748"), "label":"TALLER"},
        {"pos": Vector2(390,390), "size": Vector2(125,105), "color": Color("#c78c72"), "roof": Color("#8b594b"), "label":"BAR"},
        {"pos": Vector2(630,390), "size": Vector2(125,105), "color": Color("#8eac83"), "roof": Color("#597b56"), "label":"VIVIENDA"},
        {"pos": Vector2(870,390), "size": Vector2(125,105), "color": Color("#a9b7c5"), "roof": Color("#697a8c"), "label":"BIBLIOTECA"},
    ]

func _build_world() -> void:
    for edge in [
        [Vector2(WORLD_SIZE.x / 2, -20), Vector2(WORLD_SIZE.x, 40)],
        [Vector2(WORLD_SIZE.x / 2, WORLD_SIZE.y + 20), Vector2(WORLD_SIZE.x, 40)],
        [Vector2(-20, WORLD_SIZE.y / 2), Vector2(40, WORLD_SIZE.y)],
        [Vector2(WORLD_SIZE.x + 20, WORLD_SIZE.y / 2), Vector2(40, WORLD_SIZE.y)]
    ]:
        _add_wall(edge[0], edge[1])
    for b in _building_data():
        _add_wall(b.pos + b.size / 2 + Vector2(0, 6), b.size + Vector2(10, 8))

func _add_wall(pos: Vector2, size: Vector2) -> void:
    var body := StaticBody2D.new()
    body.position = pos
    var shape := CollisionShape2D.new()
    var rect := RectangleShape2D.new()
    rect.size = size
    shape.shape = rect
    body.add_child(shape)
    add_child(body)

func _spawn_player() -> void:
    player = PlayerScript.new()
    player.position = Vector2(330, 310)
    add_child(player)
    var cam := Camera2D.new()
    cam.position_smoothing_enabled = true
    cam.position_smoothing_speed = 6.0
    cam.limit_left = 0
    cam.limit_top = 0
    cam.limit_right = int(WORLD_SIZE.x)
    cam.limit_bottom = int(WORLD_SIZE.y)
    player.add_child(cam)
    cam.make_current()

func _spawn_npcs() -> void:
    var names = ["Mora", "Tito", "Luz", "Ramiro", "Sol", "Nico", "Cami", "Beto", "Dani", "Vera", "Paz", "Lolo"]
    for i in range(names.size()):
        var npc: CharacterBody2D = NPCScript.new()
        npc.npc_name = names[i]
        npc.position = Vector2(200 + (i % 6) * 210, 620 + int(i / 6) * 260)
        npc.personality = i % 4
        add_child(npc)
        npcs.append(npc)

func _build_ui() -> void:
    hud = CanvasLayer.new()
    add_child(hud)
    menu_root = Control.new()
    menu_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    hud.add_child(menu_root)
    var card := ColorRect.new()
    card.color = Color(0.04, 0.07, 0.08, 0.86)
    card.position = Vector2(14, 14)
    card.size = Vector2(260, 92)
    menu_root.add_child(card)
    clock_label = Label.new()
    clock_label.position = Vector2(26, 20)
    clock_label.add_theme_font_size_override("font_size", 18)
    menu_root.add_child(clock_label)
    money_label = Label.new()
    money_label.position = Vector2(26, 47)
    money_label.add_theme_font_size_override("font_size", 16)
    menu_root.add_child(money_label)
    var info := Label.new()
    info.position = Vector2(18, 112)
    info.text = "Joystick: mover · INTERACTUAR: hablar/entrar · ☰: menú"
    info.add_theme_font_size_override("font_size", 13)
    menu_root.add_child(info)
    message_label = Label.new()
    message_label.position = Vector2(18, 150)
    message_label.add_theme_font_size_override("font_size", 15)
    message_label.add_theme_color_override("font_color", Color("#ffe7a3"))
    menu_root.add_child(message_label)

    # Controles táctiles visibles durante el juego.
    touch_pad = Control.new()
    touch_pad.position = Vector2(22, 0)
    touch_pad.size = Vector2(180, 180)
    touch_pad.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
    touch_pad.position = Vector2(22, -205)
    menu_root.add_child(touch_pad)
    _add_move_button(touch_pad, "▲", Vector2(60, 0), Vector2.UP)
    _add_move_button(touch_pad, "▼", Vector2(60, 100), Vector2.DOWN)
    _add_move_button(touch_pad, "◀", Vector2(10, 50), Vector2.LEFT)
    _add_move_button(touch_pad, "▶", Vector2(110, 50), Vector2.RIGHT)

    touch_interact = Button.new()
    touch_interact.text = "INTERACTUAR"
    touch_interact.custom_minimum_size = Vector2(140, 52)
    touch_interact.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
    touch_interact.position = Vector2(-165, -85)
    touch_interact.pressed.connect(_interact)
    menu_root.add_child(touch_interact)

    touch_pause = Button.new()
    touch_pause.text = "☰"
    touch_pause.custom_minimum_size = Vector2(54, 48)
    touch_pause.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
    touch_pause.position = Vector2(-70, 16)
    touch_pause.pressed.connect(_toggle_pause)
    menu_root.add_child(touch_pause)

    panel = ColorRect.new()
    panel.color = Color(0.035, 0.055, 0.065, 0.97)
    panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    menu_root.add_child(panel)
    var box := VBoxContainer.new()
    box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    box.custom_minimum_size = Vector2(340, 300)
    box.position -= Vector2(170, 150)
    panel.add_child(box)
    var title := Label.new()
    title.text = "BARRIO ABIERTO"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 28)
    box.add_child(title)
    var subtitle := Label.new()
    subtitle.text = "Un barrio vivo · explorá a tu ritmo"
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    box.add_child(subtitle)
    var name_label := Label.new()
    name_label.text = "Nombre del personaje"
    box.add_child(name_label)
    name_edit = LineEdit.new()
    name_edit.text = player_name
    name_edit.placeholder_text = "Tu nombre"
    box.add_child(name_edit)
    var outfit_label := Label.new()
    outfit_label.text = "Estilo de ropa"
    box.add_child(outfit_label)
    outfit_select = OptionButton.new()
    for option in ["Callejero", "Deportivo", "Elegante", "Alternativo"]:
        outfit_select.add_item(option)
    outfit_select.select(outfit)
    box.add_child(outfit_select)
    start_button = Button.new()
    start_button.text = "ENTRAR AL BARRIO"
    start_button.custom_minimum_size = Vector2(0, 44)
    start_button.pressed.connect(_start_game)
    box.add_child(start_button)
    var footer := Label.new()
    footer.text = "Controles táctiles incluidos"
    footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    box.add_child(footer)
    _update_hud()

func _add_move_button(parent: Control, label: String, pos: Vector2, direction: Vector2) -> void:
    var button := Button.new()
    button.text = label
    button.position = pos
    button.size = Vector2(48, 48)
    button.modulate = Color(1, 1, 1, 0.82)
    parent.add_child(button)
    button.button_down.connect(func(): player.touch_direction = direction)
    button.button_up.connect(func(): if player.touch_direction == direction: player.touch_direction = Vector2.ZERO)

func _start_game() -> void:
    player_name = name_edit.text.strip_edges()
    if player_name.is_empty():
        player_name = "Alex"
    outfit = outfit_select.selected
    player.set_meta("outfit", outfit)
    player.player_name = player_name
    panel.visible = false
    menu_open = false
    _show_message("¡Buen día, %s! El barrio es tuyo." % player_name)
    _update_hud()

func _update_hud() -> void:
    if not is_instance_valid(clock_label):
        return
    var hour := int(game_time)
    var minute := int((game_time - hour) * 60.0)
    clock_label.text = "Día %d · %02d:%02d" % [day, hour, minute]
    money_label.text = "$ %d · %s" % [money, player_name]
    if is_instance_valid(player):
        player.set_meta("outfit", outfit)
        player.queue_redraw()

func _update_lighting() -> void:
    if game_time < 6.0 or game_time >= 20.0:
        modulate = Color(0.65, 0.72, 0.9)
    elif game_time >= 17.0 and game_time < 20.0:
        modulate = Color(1.0, 0.82, 0.67)
    else:
        modulate = Color.WHITE

func _interact() -> void:
    if menu_open:
        return
    if inside:
        inside = false
        player.position = Vector2(330, 310)
        _show_message("Saliste a la calle.")
        return
    var nearest: Node2D = null
    var nearest_d := 999999.0
    for npc in npcs:
        if is_instance_valid(npc):
            var d := player.global_position.distance_to(npc.global_position)
            if d < nearest_d:
                nearest_d = d
                nearest = npc
    if nearest and nearest_d < 72:
        _show_message("%s: %s" % [nearest.npc_name, nearest.talk(game_time)])
        return
    var nearest_building = null
    nearest_d = 999999.0
    for b in _building_data():
        var center: Vector2 = b.pos + b.size / 2
        var d: float = player.position.distance_to(center)
        if d < nearest_d:
            nearest_d = d
            nearest_building = b
    if nearest_building and nearest_d < 115:
        inside = true
        current_building = nearest_building.label
        player.position = Vector2(1200, 900)
        _show_message("Entraste en %s. Tocá INTERACTUAR para salir." % current_building)
    else:
        _show_message("No hay nadie cerca. Acercate a un vecino o a un edificio.")

func _toggle_pause() -> void:
    menu_open = not menu_open
    panel.visible = menu_open
    if menu_open:
        name_edit.text = player_name
        outfit_select.select(outfit)
        start_button.text = "VOLVER AL BARRIO"
    else:
        _start_game()

func _show_message(value: String) -> void:
    message_timer = 4.0
    if is_instance_valid(message_label):
        message_label.text = value
        message_label.visible = true

func _on_resize() -> void:
    queue_redraw()
