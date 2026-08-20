extends CharacterBody2D

enum CreatureType { EEL, JELLYFISH }

@export var creature_type: CreatureType = CreatureType.EEL
@export var swim_speed: float = 80.0
@export var depth: float = 400.0
@export var direction: float = 1.0

var is_caught = false
var attached_hook = null
var wobble_time: float = 0.0
var blink_time: float = 0.0
var is_electric: bool = true

func _ready():
	add_to_group("fish")
	add_to_group("electric")
	position.y = depth
	if direction < 0:
		scale.x = -1

func _physics_process(delta):
	if is_caught:
		if attached_hook:
			global_position = attached_hook.global_position
		return

	wobble_time += delta * 3.0
	blink_time += delta
	var wobble = sin(wobble_time) * 2.0

	if creature_type == CreatureType.JELLYFISH:
		velocity = Vector2(swim_speed * direction * 0.5, sin(wobble_time * 0.7) * 20.0)
	else:
		velocity = Vector2(swim_speed * direction, wobble * 12.0)

	move_and_slide()
	queue_redraw()

	if global_position.x < -100 or global_position.x > 1380:
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
	return -50

func _draw():
	var blink = int(blink_time * 6.0) % 2 == 0
	var glow_alpha = 0.8 if blink else 0.3
	var base_color = Color(0.2, 0.9, 1.0, glow_alpha)
	var bright_color = Color(0.5, 1.0, 1.0, 1.0) if blink else Color(0.2, 0.6, 0.8, 0.7)

	if creature_type == CreatureType.EEL:
		_draw_eel(base_color, bright_color, blink)
	else:
		_draw_jellyfish(base_color, bright_color, blink)

func _draw_eel(base_color: Color, bright_color: Color, blink: bool):
	# Long sinuous body
	var points = PackedVector2Array()
	for i in range(20):
		var t = float(i) / 19.0
		var x = lerp(-35.0, 35.0, t)
		var y = sin(t * TAU + wobble_time * 2.0) * 5.0
		points.append(Vector2(x, y))

	# Draw body as thick segments
	for i in range(points.size() - 1):
		var width = 6.0 - abs(float(i) - 10.0) * 0.4
		draw_line(points[i], points[i + 1], base_color, width)

	# Electric sparks
	if blink:
		for i in range(3):
			var sx = sin(blink_time * 5.0 + i * 2.0) * 20.0
			var sy = cos(blink_time * 4.0 + i * 1.5) * 8.0
			draw_line(Vector2(sx, sy), Vector2(sx + 5, sy - 4), bright_color, 1.5)
			draw_line(Vector2(sx + 5, sy - 4), Vector2(sx + 2, sy - 8), bright_color, 1.5)

	# Eye
	draw_circle(Vector2(30, -2), 3.0, Color.WHITE)
	draw_circle(Vector2(31, -2), 1.5, Color.BLACK)

	# Electric glow outline
	if blink:
		for i in range(points.size() - 1):
			draw_line(points[i], points[i + 1], Color(1, 1, 1, 0.3), 10.0)

func _draw_jellyfish(base_color: Color, bright_color: Color, blink: bool):
	# Bell/dome
	var bell_points = PackedVector2Array()
	for i in range(13):
		var angle = PI + float(i) / 12.0 * PI
		bell_points.append(Vector2(cos(angle) * 20.0, sin(angle) * 15.0 - 5.0))
	draw_colored_polygon(bell_points, base_color)

	# Inner glow
	if blink:
		var inner_points = PackedVector2Array()
		for i in range(13):
			var angle = PI + float(i) / 12.0 * PI
			inner_points.append(Vector2(cos(angle) * 14.0, sin(angle) * 10.0 - 5.0))
		draw_colored_polygon(inner_points, bright_color)

	# Tentacles
	for i in range(5):
		var tx = lerp(-14.0, 14.0, float(i) / 4.0)
		var tentacle_len = 25.0 + sin(wobble_time + i) * 8.0
		var segments = 6
		var prev = Vector2(tx, 10.0)
		for j in range(segments):
			var st = float(j + 1) / segments
			var nx = tx + sin(wobble_time * 2.0 + i + j * 0.5) * 5.0
			var ny = 10.0 + st * tentacle_len
			var next_pt = Vector2(nx, ny)
			var tentacle_color = bright_color if (blink and j % 2 == 0) else base_color
			draw_line(prev, next_pt, tentacle_color, 1.5)
			prev = next_pt

	# Electric sparks around bell
	if blink:
		for i in range(4):
			var angle = blink_time * 3.0 + i * TAU / 4.0
			var sx = cos(angle) * 24.0
			var sy = sin(angle) * 18.0 - 5.0
			draw_circle(Vector2(sx, sy), 2.0, Color(1, 1, 1, 0.6))
