extends CharacterBody2D

enum FishSize { SMALL, MEDIUM, LARGE }
enum FishShape { NORMAL, ROUND, LONG, ANGEL, FLAT }

@export var fish_size: FishSize = FishSize.MEDIUM
@export var swim_speed: float = 100.0
@export var depth: float = 400.0
@export var direction: float = 1.0

var fish_shape: FishShape = FishShape.NORMAL
var fish_color: Color = Color.ORANGE
var fin_color: Color = Color.DARK_ORANGE
var is_caught = false
var attached_hook = null
var size_multiplier: float = 1.0
var depth_score: float = 1.0
var speed_score: float = 1.0
var wobble_time: float = 0.0
# Nose to tail tip in local pixels, set when the shape is built
var body_length: float = 0.0

const SIZE_SCALES = {
	FishSize.SMALL: 0.6,
	FishSize.MEDIUM: 1.0,
	FishSize.LARGE: 1.5,
}

const SIZE_POINTS = {
	FishSize.SMALL: 10,
	FishSize.MEDIUM: 25,
	FishSize.LARGE: 50,
}

const FISH_COLORS = [
	Color(1.0, 0.4, 0.1),     # orange
	Color(0.2, 0.6, 1.0),     # blue
	Color(1.0, 0.85, 0.0),    # golden
	Color(0.9, 0.2, 0.3),     # red
	Color(0.4, 0.9, 0.4),     # green
	Color(0.7, 0.3, 0.9),     # purple
	Color(1.0, 0.5, 0.7),     # pink
	Color(0.0, 0.8, 0.8),     # teal
	Color(0.9, 0.9, 0.9),     # silver
	Color(1.0, 0.7, 0.0),     # amber
]

func _ready():
	add_to_group("fish")
	size_multiplier = SIZE_SCALES[fish_size]
	scale = Vector2(size_multiplier, size_multiplier)
	if direction < 0:
		scale.x *= -1
	position.y = depth
	_calculate_scores()
	_randomize_appearance()
	_build_shape()

func _randomize_appearance():
	fish_color = FISH_COLORS[randi() % FISH_COLORS.size()]
	fin_color = fish_color.darkened(0.3)
	fish_shape = randi() % FishShape.size() as FishShape
	wobble_time = randf() * TAU

func _build_shape():
	var body = $Sprite
	var points: PackedVector2Array

	match fish_shape:
		FishShape.NORMAL:
			points = PackedVector2Array([
				Vector2(-20, 0), Vector2(-12, -8), Vector2(0, -10),
				Vector2(14, -7), Vector2(22, 0),
				Vector2(14, 7), Vector2(0, 10), Vector2(-12, 8)
			])
		FishShape.ROUND:
			points = PackedVector2Array([
				Vector2(-14, 0), Vector2(-10, -10), Vector2(0, -13),
				Vector2(10, -10), Vector2(16, 0),
				Vector2(10, 10), Vector2(0, 13), Vector2(-10, 10)
			])
		FishShape.LONG:
			points = PackedVector2Array([
				Vector2(-28, 0), Vector2(-20, -5), Vector2(0, -6),
				Vector2(20, -4), Vector2(30, 0),
				Vector2(20, 4), Vector2(0, 6), Vector2(-20, 5)
			])
		FishShape.ANGEL:
			points = PackedVector2Array([
				Vector2(-12, 0), Vector2(-6, -14), Vector2(4, -18),
				Vector2(12, -8), Vector2(16, 0),
				Vector2(12, 8), Vector2(4, 18), Vector2(-6, 14)
			])
		FishShape.FLAT:
			points = PackedVector2Array([
				Vector2(-22, 0), Vector2(-16, -4), Vector2(0, -5),
				Vector2(18, -3), Vector2(24, 0),
				Vector2(18, 3), Vector2(0, 5), Vector2(-16, 4)
			])

	body.polygon = points
	body.color = fish_color

	# Tail fin
	if has_node("TailFin"):
		$TailFin.queue_free()
	var tail = Polygon2D.new()
	tail.name = "TailFin"
	match fish_shape:
		FishShape.NORMAL:
			tail.polygon = PackedVector2Array([
				Vector2(-20, 0), Vector2(-30, -10), Vector2(-28, 0), Vector2(-30, 10)
			])
		FishShape.ROUND:
			tail.polygon = PackedVector2Array([
				Vector2(-14, 0), Vector2(-24, -8), Vector2(-20, 0), Vector2(-24, 8)
			])
		FishShape.LONG:
			tail.polygon = PackedVector2Array([
				Vector2(-28, 0), Vector2(-40, -8), Vector2(-36, 0), Vector2(-40, 8)
			])
		FishShape.ANGEL:
			tail.polygon = PackedVector2Array([
				Vector2(-12, 0), Vector2(-20, -12), Vector2(-18, 0), Vector2(-20, 12)
			])
		FishShape.FLAT:
			tail.polygon = PackedVector2Array([
				Vector2(-22, 0), Vector2(-32, -6), Vector2(-28, 0), Vector2(-32, 6)
			])
	tail.color = fin_color
	add_child(tail)
	body_length = _measure_length([points, tail.polygon])

	# Dorsal fin for some shapes
	if fish_shape in [FishShape.NORMAL, FishShape.ROUND, FishShape.ANGEL]:
		var dorsal = Polygon2D.new()
		dorsal.name = "DorsalFin"
		match fish_shape:
			FishShape.NORMAL:
				dorsal.polygon = PackedVector2Array([
					Vector2(-4, -10), Vector2(6, -16), Vector2(10, -7)
				])
			FishShape.ROUND:
				dorsal.polygon = PackedVector2Array([
					Vector2(-2, -13), Vector2(5, -20), Vector2(8, -10)
				])
			FishShape.ANGEL:
				dorsal.polygon = PackedVector2Array([
					Vector2(0, -18), Vector2(6, -24), Vector2(8, -14)
				])
		dorsal.color = fin_color
		add_child(dorsal)

	# Eye
	var eye = Polygon2D.new()
	eye.name = "Eye"
	var eye_pos = Vector2(10, -2)
	if fish_shape == FishShape.LONG:
		eye_pos = Vector2(18, -1)
	elif fish_shape == FishShape.ANGEL:
		eye_pos = Vector2(8, -3)
	var eye_points = PackedVector2Array()
	for i in range(8):
		var angle = i * TAU / 8.0
		eye_points.append(eye_pos + Vector2(cos(angle) * 2.5, sin(angle) * 2.5))
	eye.polygon = eye_points
	eye.color = Color.WHITE
	add_child(eye)

	var pupil = Polygon2D.new()
	pupil.name = "Pupil"
	var pupil_points = PackedVector2Array()
	for i in range(8):
		var angle = i * TAU / 8.0
		pupil_points.append(eye_pos + Vector2(1, 0) + Vector2(cos(angle) * 1.2, sin(angle) * 1.2))
	pupil.polygon = pupil_points
	pupil.color = Color.BLACK
	add_child(pupil)

func _measure_length(polygons: Array) -> float:
	var min_x = INF
	var max_x = -INF
	for poly in polygons:
		for point in poly:
			min_x = min(min_x, point.x)
			max_x = max(max_x, point.x)
	return max_x - min_x

# On screen length of this fish, used for the smallest/biggest fish awards
func get_fish_length() -> float:
	return body_length * size_multiplier

func _calculate_scores():
	depth_score = remap(depth, 200.0, 620.0, 1.0, 3.0)
	speed_score = remap(abs(swim_speed), 50.0, 300.0, 1.0, 2.5)

func _physics_process(delta):
	if is_caught:
		if attached_hook:
			global_position = attached_hook.global_position
		return

	wobble_time += delta * 4.0
	var wobble = sin(wobble_time) * 1.5
	velocity = Vector2(swim_speed * direction, wobble * 10.0)
	move_and_slide()

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
	var base = SIZE_POINTS[fish_size]
	var multiplier = depth_score * speed_score
	return int(base * multiplier)
