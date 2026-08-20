extends Node2D

signal bonus_collected(player: int, points: int)

@export var player_number: int = 1
@export var open_duration: float = 3.0
@export var min_open_interval: float = 16.0
@export var max_open_interval: float = 32.0

var is_open: bool = false
var open_timer: float = 0.0
var next_open_timer: float = 0.0
var next_open_time: float = 10.0
var collected: bool = false
var glow_time: float = 0.0

@onready var chest_area: Area2D = $ChestArea

func _ready():
	next_open_time = randf_range(min_open_interval, max_open_interval)
	chest_area.monitoring = false
	chest_area.monitorable = true
	chest_area.add_to_group("treasure_chest")

func _process(delta):
	glow_time += delta

	if not is_open:
		next_open_timer += delta
		if next_open_timer >= next_open_time:
			_open_chest()
	else:
		open_timer += delta
		if open_timer >= open_duration:
			_close_chest()

	queue_redraw()

func _open_chest():
	is_open = true
	collected = false
	open_timer = 0.0
	chest_area.monitoring = true
	SoundManager.play_chest_open()

func _close_chest():
	is_open = false
	next_open_timer = 0.0
	next_open_time = randf_range(min_open_interval, max_open_interval)
	chest_area.monitoring = false

func try_collect():
	if is_open and not collected:
		collected = true
		chest_area.monitoring = false
		var bonus_points = 300
		bonus_collected.emit(player_number, bonus_points)
		_close_chest()

func _draw():
	# Chest body
	var chest_color = Color(0.55, 0.3, 0.1) if not is_open else Color(0.7, 0.4, 0.1)
	draw_rect(Rect2(-18, -10, 36, 22), chest_color)

	# Metal bands
	var band_color = Color(0.75, 0.65, 0.0)
	draw_rect(Rect2(-18, -10, 36, 3), band_color)
	draw_rect(Rect2(-18, 5, 36, 3), band_color)
	draw_rect(Rect2(-2, -10, 4, 22), band_color)

	# Lock
	draw_rect(Rect2(-3, -2, 6, 6), Color(0.8, 0.7, 0.0))

	if is_open:
		# Open lid
		draw_rect(Rect2(-18, -24, 36, 14), Color(0.6, 0.35, 0.1))
		draw_rect(Rect2(-18, -24, 36, 3), band_color)

		# Glow/sparkle from inside
		var glow_alpha = (sin(glow_time * 6.0) + 1.0) * 0.3 + 0.3
		draw_rect(Rect2(-12, -10, 24, 8), Color(1.0, 0.9, 0.2, glow_alpha))

		# Sparkles
		for i in range(3):
			var sx = sin(glow_time * 3.0 + i * 2.1) * 10.0
			var sy = -14.0 + sin(glow_time * 4.0 + i * 1.7) * 4.0
			var spark_alpha = (sin(glow_time * 5.0 + i * 1.3) + 1.0) * 0.4
			draw_circle(Vector2(sx, sy), 2.0, Color(1.0, 1.0, 0.5, spark_alpha))
	else:
		# Closed lid
		draw_rect(Rect2(-18, -14, 36, 6), Color(0.5, 0.28, 0.08))
		draw_rect(Rect2(-18, -14, 36, 3), band_color)
