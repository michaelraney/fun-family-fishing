extends CharacterBody2D

@export var swim_speed: float = 45.0
@export var depth: float = 420.0

var time: float = 0.0
var is_caught: bool = false
var attached_hook = null
# Set in _ready from the spawn position: the squid heads for the far side.
var direction: float = 1.0
var fade_time: float = 0.0
var is_fading: bool = true

const SQUID_SCORE = 105
const FADE_DURATION = 3.0
const BOARD_WIDTH = 1280.0
# Drawn 5% smaller than its full size (shrinks the hitbox to match)
const BASE_SCALE = 0.95

func _ready():
	position.y = depth
	# Materializes anywhere on the board, so it swims toward whichever side is
	# farther away and has the longest run of water ahead of it.
	direction = 1.0 if position.x < BOARD_WIDTH * 0.5 else -1.0
	scale = Vector2(BASE_SCALE, BASE_SCALE)
	if direction < 0:
		scale.x = -BASE_SCALE
	# Untouchable while fading in: off the fish layer and out of the "fish"
	# group, so a hook passing through it cannot catch it yet.
	set_collision_layer_value(2, false)
	modulate.a = 0.0
	SoundManager.play_squid_squeal()

func _physics_process(delta):
	if is_caught:
		if attached_hook:
			global_position = attached_hook.global_position
		return

	time += delta

	if is_fading:
		fade_time += delta
		modulate.a = min(fade_time / FADE_DURATION, 1.0)
		if fade_time >= FADE_DURATION:
			_finish_fade_in()
		queue_redraw()
		return

	var wobble = sin(time * 1.5) * 0.4
	velocity = Vector2(swim_speed * direction, wobble * 10.0)
	move_and_slide()
	queue_redraw()

	if (direction > 0 and global_position.x > 1550) or (direction < 0 and global_position.x < -300):
		queue_free()

func _finish_fade_in():
	is_fading = false
	modulate.a = 1.0
	set_collision_layer_value(2, true)
	add_to_group("fish")

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
	return int(SQUID_SCORE * depth_multiplier)

func _draw():
	var body_color = Color(1.0, 0.45, 0.72)
	var light_color = Color(1.0, 0.74, 0.87)
	var dark_color = Color(0.82, 0.24, 0.55)

	var t = time if not is_caught else 0.0

	# Eight arms and two long tentacles, trailing behind the head
	for i in range(10):
		var is_tentacle = i >= 8
		var length = 175.0 if is_tentacle else 95.0 + float(i % 3) * 20.0
		var spread = remap(float(i), 0.0, 9.0, -32.0, 32.0)
		var phase = t * 3.0 + float(i) * 0.7
		var points = PackedVector2Array()
		for s in range(8):
			var f = float(s) / 7.0
			var x = -58.0 - length * f
			var y = spread * f + sin(phase + f * 3.4) * (8.0 + 10.0 * f)
			points.append(Vector2(x, y))
		var arm_color = dark_color if is_tentacle else (body_color if i % 2 == 0 else light_color)
		draw_polyline(points, arm_color, 9.0 if is_tentacle else 6.0)
		# Suckered club on the tips of the two long tentacles
		if is_tentacle:
			var tip = points[7]
			draw_circle(tip, 9.0, dark_color)
			draw_circle(tip + Vector2(6, 0), 3.0, light_color)

	# Mantle - a long cone tapering to a point at the front
	var mantle = PackedVector2Array()
	for s in range(9):
		var f = float(s) / 8.0
		mantle.append(Vector2(-20.0 + f * 122.0, -42.0 * (1.0 - f * f * 0.93)))
	for s in range(9):
		var f = 1.0 - float(s) / 8.0
		mantle.append(Vector2(-20.0 + f * 122.0, 42.0 * (1.0 - f * f * 0.93)))
	draw_colored_polygon(mantle, body_color)

	# Lighter underside
	var belly = PackedVector2Array()
	for s in range(9):
		var f = float(s) / 8.0
		belly.append(Vector2(-16.0 + f * 108.0, 6.0 - 26.0 * (1.0 - f * f * 0.93)))
	for s in range(9):
		var f = 1.0 - float(s) / 8.0
		belly.append(Vector2(-16.0 + f * 108.0, 6.0 + 26.0 * (1.0 - f * f * 0.93)))
	draw_colored_polygon(belly, light_color)

	# Tail fins at the mantle tip
	var fin_wave = sin(t * 2.5) * 7.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(66, -10), Vector2(94, -36 + fin_wave), Vector2(114, -6), Vector2(88, -4)
	]), dark_color)
	draw_colored_polygon(PackedVector2Array([
		Vector2(66, 10), Vector2(94, 36 - fin_wave), Vector2(114, 6), Vector2(88, 4)
	]), dark_color)

	# Chromatophore speckles along the mantle
	for i in range(6):
		var sx = -6.0 + float(i) * 16.0
		var sy = -18.0 + float(i % 3) * 15.0
		draw_circle(Vector2(sx, sy), 3.5, dark_color)

	# Head
	draw_circle(Vector2(-38, 0), 34.0, body_color)

	# Big squid eye
	draw_circle(Vector2(-48, -11), 14.0, Color.WHITE)
	draw_circle(Vector2(-50, -11), 7.5, Color(0.1, 0.05, 0.1))
	draw_circle(Vector2(-53, -14), 3.0, Color.WHITE)

	# Beak
	draw_colored_polygon(PackedVector2Array([
		Vector2(-62, 14), Vector2(-74, 22), Vector2(-58, 24)
	]), dark_color)
