extends CharacterBody2D

var speed := 190.0
var player_name := "Alex"
var touch_direction := Vector2.ZERO

func _ready() -> void:
    collision_layer = 1
    collision_mask = 1
    var shape := CollisionShape2D.new()
    var capsule := CapsuleShape2D.new()
    capsule.radius = 10
    capsule.height = 24
    shape.shape = capsule
    add_child(shape)

func _physics_process(_delta: float) -> void:
    var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    if direction == Vector2.ZERO:
        direction = touch_direction
    velocity = direction * speed
    move_and_slide()

func _draw() -> void:
    var outfit := int(get_meta("outfit", 0))
    var colors = [Color("#e6b64f"), Color("#4f9bd4"), Color("#d8d4cb"), Color("#c66c9b")]
    var shirt: Color = colors[clampi(outfit, 0, colors.size() - 1)]
    draw_rect(Rect2(-12, 5, 24, 8), Color(0, 0, 0, 0.25))
    draw_rect(Rect2(-8, 3, 6, 5), Color("#302c31"))
    draw_rect(Rect2(2, 3, 6, 5), Color("#302c31"))
    draw_rect(Rect2(-9, -8, 18, 14), shirt)
    draw_rect(Rect2(-7, -17, 14, 12), Color("#d9a17b"))
    draw_rect(Rect2(-8, -20, 16, 6), Color("#4a302b"))
    draw_rect(Rect2(2, -13, 3, 3), Color("#292b31"))
    draw_rect(Rect2(-6, -6, 4, 4), shirt.lightened(0.2))
