extends Node2D

const MAX_CASTS = 10
const NUM_PLAYERS = 3
const GAME_TIME = 120.0
const FORFEIT_TIME = 45.0

# End of round bonuses
const FINISH_BONUS = 100
const BEAST_BONUS = 100
const TREASURE_BONUS = 100
const NO_SHOCK_BONUS = 100
const SMALLEST_FISH_BONUS = 100
const BIGGEST_FISH_BONUS = 100
const BEAST_TYPES = ["whale", "shark", "squid"]

var casts_remaining = [MAX_CASTS, MAX_CASTS, MAX_CASTS]
var scores = [0, 0, 0]
var game_over = false
var time_remaining: float = GAME_TIME
var has_cast = [false, false, false]
var forfeited = [false, false, false]

# Round stats feeding the end of game bonuses
var finish_order: Array = []
var beasts_caught = [{}, {}, {}]
var chests_collected = [0, 0, 0]
var electric_hits = [0, 0, 0]
# Length of the shortest and longest ordinary fish each player landed (0 = none)
var smallest_fish = [0.0, 0.0, 0.0]
var biggest_fish = [0.0, 0.0, 0.0]

@onready var fishing_lines = [$FishingLine1, $FishingLine2, $FishingLine3]
@onready var fish_spawner = $FishSpawner
@onready var ui = $UI

var cast_actions = ["player1_cast", "player2_cast", "player3_cast"]

func _ready():
	for i in range(NUM_PLAYERS):
		ui.update_score(i + 1, scores[i])
		ui.update_casts(i + 1, casts_remaining[i])
		fishing_lines[i].fish_lost.connect(_on_fish_lost)
	ui.update_timer(time_remaining)

func _process(delta):
	if game_over:
		return
	time_remaining -= delta
	if time_remaining <= 0.0:
		time_remaining = 0.0
		end_game()
	ui.update_timer(time_remaining)

	var elapsed = GAME_TIME - time_remaining
	if elapsed >= FORFEIT_TIME:
		var any_forfeited = false
		for i in range(NUM_PLAYERS):
			if not has_cast[i] and not forfeited[i]:
				forfeited[i] = true
				casts_remaining[i] = 0
				ui.update_casts(i + 1, 0)
				ui.flash_forfeit(i + 1)
				any_forfeited = true
		if any_forfeited:
			check_game_over()

func _input(event):
	if game_over:
		if ui.blocks_restart():
			return
		if event is InputEventKey and event.pressed:
			if event.keycode != KEY_A and event.keycode != KEY_G and event.keycode != KEY_L:
				restart_game()
		return

	for i in range(NUM_PLAYERS):
		if event.is_action_pressed(cast_actions[i]):
			if not forfeited[i] and casts_remaining[i] > 0 and not fishing_lines[i].is_casting:
				has_cast[i] = true
				casts_remaining[i] -= 1
				ui.update_casts(i + 1, casts_remaining[i])
				fishing_lines[i].cast_line()

func add_score(player: int, points: int, catch_type: String = "medium", fish_length: float = 0.0):
	if game_over:
		return
	if points == 0:
		return
	if fish_length > 0.0:
		var i = player - 1
		if smallest_fish[i] == 0.0 or fish_length < smallest_fish[i]:
			smallest_fish[i] = fish_length
		if fish_length > biggest_fish[i]:
			biggest_fish[i] = fish_length
	if catch_type == "electric":
		electric_hits[player - 1] += 1
		scores[player - 1] = max(0, scores[player - 1] + points)
		ui.update_score(player, scores[player - 1])
		ui.flash_score(player, points, catch_type)
		return
	if points < 0:
		return
	if catch_type in BEAST_TYPES:
		beasts_caught[player - 1][catch_type] = true
	scores[player - 1] += points
	ui.update_score(player, scores[player - 1])
	ui.flash_score(player, points, catch_type)

func add_treasure_score(player: int, points: int):
	if points <= 0 or game_over:
		return
	chests_collected[player - 1] += 1
	scores[player - 1] += points
	ui.update_score(player, scores[player - 1])
	ui.flash_score(player, points, "treasure")

func _on_fish_lost(player: int, points: int):
	if game_over:
		return
	scores[player - 1] = max(0, scores[player - 1] - points)
	ui.update_score(player, scores[player - 1])
	ui.flash_lost(player, points)

func check_game_over():
	for i in range(NUM_PLAYERS):
		if casts_remaining[i] > 0:
			return
		if fishing_lines[i].is_casting:
			return
	end_game()

func end_game():
	if game_over:
		return
	game_over = true
	_record_finishers()

	var bonuses = _build_bonuses()
	var base_scores = scores.duplicate()
	var final_scores = []
	for i in range(NUM_PLAYERS):
		var total = base_scores[i]
		for bonus in bonuses[i]:
			total += int(bonus["points"])
		final_scores.append(total)
	scores = final_scores.duplicate()
	ui.show_bonus_round(base_scores, bonuses, final_scores)

# A player finishes once their last cast has been reeled back in. Forfeiting
# players lose their casts rather than finishing them, so they never qualify.
func _record_finishers():
	for i in range(NUM_PLAYERS):
		if forfeited[i] or finish_order.has(i):
			continue
		if casts_remaining[i] == 0 and not fishing_lines[i].is_casting:
			finish_order.append(i)

func _build_bonuses() -> Array:
	var bonuses = []
	for i in range(NUM_PLAYERS):
		bonuses.append([])

	# The first player to finish their casts scores for every player they beat.
	# Forfeiting players never finished, so beating them earns nothing.
	if not finish_order.is_empty():
		var first = finish_order[0]
		var players_beaten = 0
		for i in range(NUM_PLAYERS):
			if i != first and not forfeited[i]:
				players_beaten += 1
		if players_beaten > 0:
			bonuses[first].append({
				"label": "FIRST DONE!",
				"points": FINISH_BONUS * players_beaten,
			})

	for i in range(NUM_PLAYERS):
		# A player who forfeits the round earns no bonuses at all
		if forfeited[i]:
			continue
		if beasts_caught[i].size() == BEAST_TYPES.size():
			bonuses[i].append({"label": "ALL 3 BEASTS!", "points": BEAST_BONUS})
		if chests_collected[i] > 1:
			bonuses[i].append({"label": "TREASURE HUNTER!", "points": TREASURE_BONUS})
		if electric_hits[i] == 0:
			bonuses[i].append({"label": "SHOCK FREE!", "points": NO_SHOCK_BONUS})

	# Size awards go to whoever landed the shortest and the longest ordinary fish.
	# Everyone matching the winning length collects, so ties are paid in full.
	var shortest = _best_length(smallest_fish, true)
	var longest = _best_length(biggest_fish, false)
	for i in range(NUM_PLAYERS):
		if forfeited[i]:
			continue
		if shortest > 0.0 and is_equal_approx(smallest_fish[i], shortest):
			bonuses[i].append({"label": "SMALLEST FISH!", "points": SMALLEST_FISH_BONUS})
		if longest > 0.0 and is_equal_approx(biggest_fish[i], longest):
			bonuses[i].append({"label": "BIGGEST FISH!", "points": BIGGEST_FISH_BONUS})

	return bonuses

# Shortest or longest length across every player still in the game. Players who
# forfeited or never landed a fish are skipped. Returns 0.0 if nobody qualifies.
func _best_length(lengths: Array, want_shortest: bool) -> float:
	var best = 0.0
	for i in range(NUM_PLAYERS):
		if forfeited[i] or lengths[i] <= 0.0:
			continue
		if best == 0.0:
			best = lengths[i]
		elif want_shortest:
			best = min(best, lengths[i])
		else:
			best = max(best, lengths[i])
	return best

func on_line_returned(player: int):
	_record_finishers()
	check_game_over()

func restart_game():
	for i in range(NUM_PLAYERS):
		casts_remaining[i] = MAX_CASTS
		scores[i] = 0
		has_cast[i] = false
		forfeited[i] = false
		beasts_caught[i] = {}
		chests_collected[i] = 0
		electric_hits[i] = 0
		smallest_fish[i] = 0.0
		biggest_fish[i] = 0.0
		ui.update_score(i + 1, scores[i])
		ui.update_casts(i + 1, casts_remaining[i])
	finish_order.clear()
	game_over = false
	time_remaining = GAME_TIME
	ui.update_timer(time_remaining)
	ui.hide_game_over()
	fish_spawner.reset_whale()
