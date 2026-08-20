extends Node2D

var time: float = 0.0

@export var wave_speed: float = 2.0
@export var wave_height: float = 3.0
@export var water_surface_y: float = 200.0

func _process(delta):
	time += delta
	queue_redraw()

func _draw():
	# Sky
	draw_rect(Rect2(0, 0, 1280, water_surface_y), Color(0.53, 0.81, 0.92))

	# Water gradient (darker as it goes deeper)
	var water_height = 720 - water_surface_y
	var num_bands = 20
	var band_height = water_height / num_bands
	for i in range(num_bands):
		var t = float(i) / num_bands
		var color = Color(0.0, 0.4 - t * 0.3, 0.7 - t * 0.4, 0.9)
		var y = water_surface_y + i * band_height
		draw_rect(Rect2(0, y, 1280, band_height + 1), color)

	# Wave surface
	var points = PackedVector2Array()
	var colors = PackedColorArray()
	for x in range(0, 1281, 4):
		var wave_offset = sin(x * 0.02 + time * wave_speed) * wave_height
		points.append(Vector2(x, water_surface_y + wave_offset))
		colors.append(Color(0.2, 0.5, 0.8))
	for i in range(points.size() - 1):
		draw_line(points[i], points[i + 1], Color(0.3, 0.6, 0.9), 3.0)

	# Sandy bottom
	draw_rect(Rect2(0, 640, 1280, 80), Color(0.76, 0.70, 0.50))

	# Some sand detail
	for i in range(20):
		var sx = hash(i * 73) % 1280
		var sy = 650 + hash(i * 37) % 60
		draw_circle(Vector2(sx, sy), 2, Color(0.65, 0.58, 0.40))
