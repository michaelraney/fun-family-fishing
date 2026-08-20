extends Node2D

@export var spawn_interval_min: float = 0.4
@export var spawn_interval_max: float = 1.4
@export var min_depth: float = 230.0
@export var max_depth: float = 600.0

var spawn_timer: float = 0.0
var next_spawn_time: float = 0.5
var whale_timer: float = 0.0
var next_whale_time: float = 0.0
var whale_spawned: bool = false
var whale_active: bool = false
var current_whale = null
var shark_spawned: bool = false
var shark_timer: float = 0.0
var next_shark_time: float = 0.0
var squid_spawned: bool = false
var squid_timer: float = 0.0
var next_squid_time: float = 0.0
var fish_scene: PackedScene
var whale_scene: PackedScene
var shark_scene: PackedScene
var squid_scene: PackedScene
var electric_scene: PackedScene

func _ready():
	fish_scene = preload("res://scenes/fish.tscn")
	whale_scene = preload("res://scenes/whale.tscn")
	shark_scene = preload("res://scenes/shark.tscn")
	squid_scene = preload("res://scenes/squid.tscn")
	electric_scene = preload("res://scenes/electric_creature.tscn")
	next_spawn_time = randf_range(spawn_interval_min, spawn_interval_max)
	next_whale_time = randf_range(10.0, 50.0)
	next_shark_time = randf_range(30.0, 90.0)
	next_squid_time = randf_range(20.0, 80.0)
	# Spawn a few fish immediately so the water isn't empty
	_spawn_initial_fish.call_deferred()

func _spawn_initial_fish():
	for i in range(8):
		_spawn_fish_at_random_x()

func _process(delta):
	spawn_timer += delta
	if spawn_timer >= next_spawn_time:
		spawn_timer = 0.0
		next_spawn_time = randf_range(spawn_interval_min, spawn_interval_max)
		spawn_fish()

	if not whale_spawned:
		whale_timer += delta
		if whale_timer >= next_whale_time:
			whale_spawned = true
			_spawn_whale()

	if not shark_spawned:
		shark_timer += delta
		if shark_timer >= next_shark_time:
			shark_spawned = true
			_spawn_shark()

	if not squid_spawned:
		squid_timer += delta
		if squid_timer >= next_squid_time:
			squid_spawned = true
			_spawn_squid()

	if whale_active:
		if current_whale == null or not is_instance_valid(current_whale):
			_whale_gone()

func spawn_fish():
	# 12% chance to spawn an electric creature instead
	if randf() < 0.12:
		_spawn_electric()
		return

	var fish = fish_scene.instantiate()
	_configure_fish(fish)

	if fish.direction > 0:
		fish.position.x = -50
	else:
		fish.position.x = 1330

	get_parent().add_child(fish)

func _spawn_electric():
	var creature = electric_scene.instantiate()
	creature.creature_type = randi() % 2
	creature.depth = randf_range(min_depth, max_depth)
	creature.swim_speed = randf_range(40.0, 150.0)
	var dir = 1.0 if randf() > 0.5 else -1.0
	creature.direction = dir
	if dir > 0:
		creature.position.x = -50
	else:
		creature.position.x = 1330
	get_parent().add_child(creature)

func _spawn_fish_at_random_x():
	var fish = fish_scene.instantiate()
	_configure_fish(fish)
	fish.position.x = randf_range(100, 1180)
	get_parent().add_child(fish)

func _spawn_whale():
	var whale = whale_scene.instantiate()
	whale.depth = randf_range(480.0, 580.0)
	whale.swim_speed = randf_range(30.0, 55.0)
	var dir = 1.0 if randf() > 0.5 else -1.0
	whale.direction = dir
	if dir > 0:
		whale.position.x = -200
	else:
		whale.position.x = 1480
	get_parent().add_child(whale)
	current_whale = whale
	whale_active = true
	_apply_speed_boost(1.1)

func _whale_gone():
	whale_active = false
	current_whale = null
	_apply_speed_boost(0.9)

func _apply_speed_boost(multiplier: float):
	for node in get_tree().get_nodes_in_group("fish"):
		if node != current_whale and not node.is_caught:
			node.swim_speed *= multiplier

func _spawn_shark():
	var shark = shark_scene.instantiate()
	shark.depth = randf_range(300.0, 500.0)
	shark.swim_speed = randf_range(60.0, 90.0)
	var dir = 1.0 if randf() > 0.5 else -1.0
	shark.direction = dir
	if dir > 0:
		shark.position.x = -150
	else:
		shark.position.x = 1430
	get_parent().add_child(shark)

func _spawn_squid():
	# Unlike the whale and shark, the squid materializes anywhere on the board
	# rather than swimming in from an edge.
	var squid = squid_scene.instantiate()
	squid.position.x = randf_range(150.0, 1130.0)
	squid.depth = randf_range(270.0, 580.0)
	squid.swim_speed = randf_range(35.0, 60.0)
	get_parent().add_child(squid)

func reset_whale():
	whale_spawned = false
	whale_active = false
	whale_timer = 0.0
	next_whale_time = randf_range(10.0, 50.0)
	if current_whale and is_instance_valid(current_whale):
		current_whale.queue_free()
	current_whale = null
	shark_spawned = false
	shark_timer = 0.0
	next_shark_time = randf_range(30.0, 90.0)
	squid_spawned = false
	squid_timer = 0.0
	next_squid_time = randf_range(20.0, 80.0)

func _configure_fish(fish):
	var size_roll = randf()
	if size_roll < 0.45:
		fish.fish_size = fish.FishSize.SMALL
	elif size_roll < 0.8:
		fish.fish_size = fish.FishSize.MEDIUM
	else:
		fish.fish_size = fish.FishSize.LARGE

	fish.depth = randf_range(min_depth, max_depth)

	var speed_base = randf_range(50.0, 300.0)
	var direction = 1.0 if randf() > 0.5 else -1.0
	fish.swim_speed = speed_base
	fish.direction = direction
