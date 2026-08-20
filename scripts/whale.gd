extends CharacterBody2D

@export var swim_speed: float = 40.0
@export var direction: float = 1.0
@export var depth: float = 550.0

var time: float = 0.0
var is_caught: bool = false
var attached_hook = null

const WHALE_SCORE = 105

func _ready():
	add_to_group("fish")
	position.y = depth
	if direction < 0:
		scale.x = -1
	SoundManager.play_whale()

func _physics_process(delta):
	if is_caught:
		if attached_hook:
			global_position = attached_hook.global_position
		return

	time += delta
	var wobble = sin(time * 0.8) * 0.5
	velocity = Vector2(swim_speed * direction, wobble * 8.0)
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
	return int(WHALE_SCORE * depth_multiplier)

func _draw():
	var body_color = Color(0.2, 0.3, 0.5)
	var belly_color = Color(0.5, 0.6, 0.7)

	# Body shape
	var body_points = PackedVector2Array()
	for i in range(24):
		var angle = i * TAU / 24.0
		body_points.append(Vector2(cos(angle) * 80.0, sin(angle) * 30.0))
	draw_colored_polygon(body_points, body_color)

	# Belly
	var belly_points = PackedVector2Array()
	for i in range(24):
		var angle = i * TAU / 24.0
		belly_points.append(Vector2(cos(angle) * 70.0 - 5, sin(angle) * 18.0 + 8))
	draw_colored_polygon(belly_points, belly_color)

	# Tail fin
	var t = time if not is_caught else 0.0
	var tail_wave = sin(t * 3.0) * 5.0
	var tail_points = PackedVector2Array([
		Vector2(-80, 0),
		Vector2(-110, -25 + tail_wave),
		Vector2(-95, 0),
		Vector2(-110, 25 + tail_wave),
	])
	draw_colored_polygon(tail_points, body_color.darkened(0.2))

	# Dorsal fin
	draw_colored_polygon(PackedVector2Array([
		Vector2(10, -28), Vector2(25, -40), Vector2(35, -28)
	]), body_color.darkened(0.1))

	# Pectoral fin
	draw_colored_polygon(PackedVector2Array([
		Vector2(10, 15), Vector2(0, 35), Vector2(25, 25), Vector2(20, 15)
	]), body_color.darkened(0.15))

	# Eye
	draw_circle(Vector2(55, -5), 5.0, Color.WHITE)
	draw_circle(Vector2(56, -5), 2.5, Color(0.1, 0.1, 0.1))

	# Mouth
	draw_line(Vector2(65, 5), Vector2(78, 2), Color(0.1, 0.2, 0.3), 2.0)

	# Bubbles
	var bubble_alpha = (sin(t * 2.0) + 1.0) * 0.2
	if bubble_alpha > 0.2:
		draw_circle(Vector2(30, -38), 3.0, Color(0.7, 0.9, 1.0, bubble_alpha))
		draw_circle(Vector2(35, -46), 2.0, Color(0.7, 0.9, 1.0, bubble_alpha * 0.7))
		draw_circle(Vector2(28, -52), 1.5, Color(0.7, 0.9, 1.0, bubble_alpha * 0.5))
