extends Node2D

signal line_returned(player: int)
signal fish_caught(player: int, points: int, catch_type: String, fish_length: float)
signal fish_lost(player: int, points: int)

@export var player_number: int = 1
@export var drop_speed: float = 300.0
@export var reel_speed: float = 250.0
@export var water_surface_y: float = 200.0
@export var water_bottom_y: float = 655.0
@export var bottom_wait_time: float = 1.0

var is_casting = false
var is_dropping = false
var is_waiting = false
var is_reeling = false
var hook_y: float = 0.0
var start_y: float = 0.0
var wait_timer: float = 0.0
var caught_fish: Array = []
var current_fish = null
var current_fish_score: int = 0

@onready var line_visual = $LineVisual
@onready var hook = $Hook
@onready var hook_area = $Hook/HookArea

func _ready():
	start_y = water_surface_y
	hook.position.y = start_y
	hook_area.body_entered.connect(_on_hook_caught_fish)
	hook_area.area_entered.connect(_on_hook_entered_area)
	visible = true
	line_visual.visible = false

func cast_line():
	if is_casting:
		return
	is_casting = true
	is_dropping = true
	is_waiting = false
	is_reeling = false
	hook_y = start_y
	hook.position.y = hook_y
	caught_fish.clear()
	current_fish = null
	current_fish_score = 0
	line_visual.visible = true
	hook_area.monitoring = true
	SoundManager.play_splash()

func _process(delta):
	if not is_casting:
		return

	if is_dropping:
		hook_y += drop_speed * delta
		if hook_y >= water_bottom_y:
			hook_y = water_bottom_y
			is_dropping = false
			is_waiting = true
			wait_timer = 0.0

	elif is_waiting:
		wait_timer += delta
		if wait_timer >= bottom_wait_time:
			_start_reeling()

	elif is_reeling:
		hook_y -= reel_speed * delta
		if hook_y <= start_y:
			hook_y = start_y
			is_casting = false
			is_reeling = false
			line_visual.visible = false
			hook_area.monitoring = false
			_finish_cast()

	hook.position.y = hook_y
	_update_line_visual()

func _start_reeling():
	is_waiting = false
	is_dropping = false
	is_reeling = true

func _update_line_visual():
	line_visual.clear_points()
	line_visual.add_point(Vector2(0, start_y - 20))
	line_visual.add_point(Vector2(0, hook_y))

func _on_hook_caught_fish(body):
	if body.is_in_group("fish") and is_casting:
		var fish = body
		if not fish.is_caught:
			var new_score = fish.get_score()

			if is_reeling and current_fish != null:
				if new_score > current_fish_score:
					fish_lost.emit(player_number, current_fish_score)
					current_fish.release()
					current_fish.queue_free()
					caught_fish.erase(current_fish)

					fish.catch(hook)
					caught_fish.append(fish)
					current_fish = fish
					current_fish_score = new_score
					fish_caught.emit(player_number, new_score, _get_catch_type(fish), _get_fish_length(fish))
					SoundManager.play_catch()
			else:
				fish.catch(hook)
				caught_fish.append(fish)
				current_fish = fish
				current_fish_score = new_score
				fish_caught.emit(player_number, new_score, _get_catch_type(fish), _get_fish_length(fish))
				SoundManager.play_catch()
				_start_reeling()

# Only ordinary fish are measured. Electric creatures and the whale, shark and
# squid have no length, so they never count toward the size awards.
func _get_fish_length(body) -> float:
	if body.is_in_group("electric"):
		return 0.0
	if body.has_method("get_fish_length"):
		return body.get_fish_length()
	return 0.0

func _get_catch_type(body) -> String:
	if body.is_in_group("electric"):
		return "electric"
	if body.has_method("get_score") and body.get("WHALE_SCORE") != null:
		return "whale"
	if body.has_method("get_score") and body.get("SHARK_SCORE") != null:
		return "shark"
	if body.has_method("get_score") and body.get("SQUID_SCORE") != null:
		return "squid"
	if body.has_method("get_score") and body.get("fish_size") != null:
		match body.fish_size:
			0: return "small"
			2: return "large"
	return "medium"

func _on_hook_entered_area(area):
	if area.is_in_group("treasure_chest") and is_casting:
		var chest = area.get_parent()
		chest.try_collect()
		_start_reeling()

func _finish_cast():
	for fish in caught_fish:
		fish.queue_free()
	caught_fish.clear()
	current_fish = null
	current_fish_score = 0
	line_returned.emit(player_number)
