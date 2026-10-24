extends CharacterBody2D

var npc_name := "Vecino"
var personality := 0
var speed := 35.0
var target := Vector2.ZERO
var wait_time := 0.0
var palette := [Color("#7ba5d4"), Color("#d48c78"), Color("#8fb17a"), Color("#b79ad4")]
var shirt := Color("#7ba5d4")

func _ready() -> void:
    shirt = palette[personality % palette.size()]
    target = position + Vector2(randf_range(-90, 90), randf_range(-90, 90))
    var shape := CollisionShape2D.new()
    var capsule := CapsuleShape2D.new()
    capsule.radius = 9
    capsule.height = 22
    shape.shape = capsule
    add_child(shape)
    collision_layer = 1
    collision_mask = 1

func _physics_process(delta: float) -> void:
    wait_time -= delta
    if wait_time <= 0:
        target = position + Vector2(randf_range(-110, 110), randf_range(-90, 90))
        wait_time = randf_range(1.5, 4.5)
    var direction := global_position.direction_to(target)
    velocity = Vector2.ZERO if global_position.distance_to(target) < 8 else direction * speed
    move_and_slide()

func talk(hour: float) -> String:
    if hour < 6 or hour >= 22:
        return "Perdón, estoy volviendo a casa. Mañana nos vemos."
    match personality:
        0:
            return ["¿Viste el café nuevo de la esquina?", "Hoy está lindo para caminar.", "Dicen que buscan gente en el taller."][randi() % 3]
        1:
            return ["El colectivo viene tardísimo, como siempre.", "¿Probaste las empanadas del almacén?", "Cuidá tus cosas y disfrutá el barrio."][randi() % 3]
        2:
            return ["Estoy yendo a hacer unos mandados.", "A la tarde se llena la plaza.", "Este barrio tiene historias para rato."][randi() % 3]
        _:
            return ["¿Todo bien? Nos vemos por ahí.", "A la noche baja mucho el movimiento.", "La biblioteca abre temprano."][randi() % 3]

func _draw() -> void:
    draw_rect(Rect2(-10, 5, 20, 7), Color(0, 0, 0, 0.22))
    draw_rect(Rect2(-7, 2, 5, 5), Color("#302c31"))
    draw_rect(Rect2(2, 2, 5, 5), Color("#302c31"))
    draw_rect(Rect2(-8, -9, 16, 13), shirt)
    draw_rect(Rect2(-7, -17, 14, 11), Color("#d8a27e"))
    draw_rect(Rect2(-8, -20, 16, 5), Color("#4b3930"))
    draw_rect(Rect2(2, -13, 3, 3), Color("#282a31"))
