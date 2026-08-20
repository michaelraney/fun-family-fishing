extends CharacterBody2D

@export var swim_speed: float = 70.0
@export var direction: float = 1.0
@export var depth: float = 400.0

var time: float = 0.0
var is_caught: bool = false
var attached_hook = null

const SHARK_SCORE = 157.5

func _ready():
	add_to_group("fish")
	position.y = depth
	if direction < 0:
		scale.x = -1
	SoundManager.play_shark()

func _physics_process(delta):
	if is_caught:
		if attached_hook:
			global_position = attached_hook.global_position
		return

	time += delta
	var wobble = sin(time * 1.2) * 0.3
	velocity = Vector2(swim_speed * direction, wobble * 6.0)
	move_and_slide()
	queue_redraw()

	if (direction > 0 and global_position.x > 1500) or (direction < 0 and global_position.x < -220):
		queue_free()

func catch(hook):
	is_caught = true
	attached_hook = hook
	set_collision_layer_value(1, false)
	set_collision_layer_value(2, false)

func release():
	is_caught = false
	attached_hook = null

func get_score() -> int:
	var depth_multiplier = remap(global_position.y, 200.0, 620.0, 1.0, 3.0)
	return int(SHARK_SCORE * depth_multiplier)

func _draw():
	var body_color = Color(0.4, 0.45, 0.5)
	var belly_color = Color(0.75, 0.75, 0.8)

	# Body - sleek torpedo shape
	var body_points = PackedVector2Array()
	for i in range(20):
		var angle = i * TAU / 20.0
		var rx = 60.0
		var ry = 18.0
		body_points.append(Vector2(cos(angle) * rx, sin(angle) * ry))
	draw_colored_polygon(body_points, body_color)

	# Belly (lighter underside)
	var belly_points = PackedVector2Array()
	for i in range(20):
		var angle = i * TAU / 20.0
		var rx = 50.0
		var ry = 10.0
		belly_points.append(Vector2(cos(angle) * rx, sin(angle) * ry + 6))
	draw_colored_polygon(belly_points, belly_color)

	# Dorsal fin (iconic triangle)
	var dorsal = PackedVector2Array([
		Vector2(-5, -18), Vector2(10, -38), Vector2(20, -18)
	])
	draw_colored_polygon(dorsal, body_color.darkened(0.15))

	# Tail fin
	var t = time if not is_caught else 0.0
	var tail_wave = sin(t * 4.0) * 4.0
	var tail = PackedVector2Array([
		Vector2(-60, 0),
		Vector2(-80, -18 + tail_wave),
		Vector2(-68, 0),
		Vector2(-80, 18 + tail_wave),
	])
	draw_colored_polygon(tail, body_color.darkened(0.2))

	# Pectoral fins
	var pec_left = PackedVector2Array([
		Vector2(10, 12), Vector2(0, 28), Vector2(20, 22)
	])
	draw_colored_polygon(pec_left, body_color.darkened(0.1))

	# Snout point
	var snout = PackedVector2Array([
		Vector2(60, 0), Vector2(50, -6), Vector2(50, 6)
	])
	draw_colored_polygon(snout, body_color)

	# Eye - menacing
	draw_circle(Vector2(40, -6), 4.0, Color(0.9, 0.9, 0.0))
	draw_circle(Vector2(40, -6), 2.0, Color(0.1, 0.1, 0.1))

	# Mouth/teeth line
	draw_line(Vector2(35, 6), Vector2(55, 4), Color(0.2, 0.2, 0.2), 1.5)
	# Teeth
	for i in range(5):
		var tx = 38.0 + i * 4.0
		draw_line(Vector2(tx, 6), Vector2(tx, 10), Color.WHITE, 1.5)

	# Gill slits
	for i in range(3):
		var gx = 25.0 + i * 5.0
		draw_line(Vector2(gx, -4), Vector2(gx, 8), Color(0.3, 0.3, 0.35), 1.0)
