extends CanvasLayer

@onready var score_labels = [$P1ScoreLabel, $P2ScoreLabel, $P3ScoreLabel]
@onready var casts_labels = [$P1CastsLabel, $P2CastsLabel, $P3CastsLabel]
@onready var flash_labels = [$P1FlashLabel, $P2FlashLabel, $P3FlashLabel]
@onready var game_over_panel = $GameOverPanel
@onready var game_over_label = $GameOverPanel/GameOverLabel
@onready var instructions_label = $InstructionsLabel
@onready var winner_label = $WinnerLabel
@onready var timer_label = $TimerLabel
@onready var leaderboard_panel = $LeaderboardPanel
@onready var leaderboard_names_label = $LeaderboardPanel/NamesLabel
@onready var leaderboard_scores_label = $LeaderboardPanel/ScoresLabel
@onready var name_entry_label = $NameEntryLabel
@onready var name_entry_edit = $NameEntryEdit
@onready var restart_label = $RestartLabel
@onready var bonus_float_template = $BonusFloatTemplate

const BONUS_REVEAL_INTERVAL = 0.7
# Each bonus message stays fully readable for 3 seconds, then fades out
const BONUS_FLOAT_HOLD = 3.0
const BONUS_FLOAT_FADE = 0.5
const BONUS_END_DELAY = BONUS_FLOAT_HOLD + BONUS_FLOAT_FADE + 0.2
const BONUS_FLOAT_START_Y = 470.0
const BONUS_FLOAT_STACK = 72.0
const BONUS_FLOAT_RISE = 36.0
const BONUS_COLUMN_X = [60.0, 490.0, 920.0]
# A player can earn more bonuses than fit in a column, so slots are reused once
# the message that was in them has faded away
const BONUS_FLOAT_SLOTS = 5

var showing_bonuses: bool = false
var bonus_queue: Array = []
var bonus_index: int = 0
var bonus_timer: float = 0.0
var bonus_stack = [0, 0, 0]
var bonus_floats: Array = []
var running_scores: Array = []
var pending_final_scores: Array = []

var flash_timers = [0.0, 0.0, 0.0]
var flash_duration: float = 1.2
var flashing = [false, false, false]
var winner_time: float = 0.0
var showing_winner: bool = false
var entering_name: bool = false
var pending_score: int = 0
var new_entry_index: int = -1

func _ready():
	game_over_panel.visible = false
	winner_label.visible = false
	leaderboard_panel.visible = false
	name_entry_label.visible = false
	name_entry_edit.visible = false
	restart_label.visible = false
	name_entry_edit.text_changed.connect(_on_name_text_changed)
	name_entry_edit.text_submitted.connect(_on_name_submitted)
	for label in flash_labels:
		label.visible = false

func _process(delta):
	for i in range(3):
		if flashing[i]:
			flash_timers[i] += delta
			_animate_flash(flash_labels[i], flash_timers[i])
			if flash_timers[i] >= flash_duration:
				flashing[i] = false
				flash_labels[i].visible = false

	if showing_winner:
		winner_time += delta
		_animate_winner()

	if showing_bonuses:
		bonus_timer += delta
		if bonus_index < bonus_queue.size():
			if bonus_timer >= BONUS_REVEAL_INTERVAL:
				bonus_timer = 0.0
				_reveal_next_bonus()
		elif bonus_timer >= BONUS_END_DELAY:
			_finish_bonus_round()

func _animate_flash(label: Label, t: float):
	var progress = t / flash_duration
	var scale_val = 1.0 + sin(progress * PI) * 0.3
	label.scale = Vector2(scale_val, scale_val)
	var blink = int(t * 8) % 2
	var alpha = 1.0 if blink == 0 else 0.6
	alpha *= (1.0 - progress * 0.5)
	label.modulate.a = alpha
	label.position.y = label.get_meta("start_y") - progress * 40.0

func _animate_winner():
	var pulse = (sin(winner_time * 4.0) + 1.0) * 0.15 + 1.0
	winner_label.scale = Vector2(pulse, pulse)
	var hue = fmod(winner_time * 0.5, 1.0)
	winner_label.modulate = Color.from_hsv(hue, 0.8, 1.0)

const SMALL_FISH_MESSAGES = [
	"What a guppy!",
	"Can't live on shrimp!",
	"This is bait!",
]

const LARGE_FISH_MESSAGES = [
	"Whoa momma!",
	"We need a bigger boat!",
	"Wowzeers!",
	"BIG GUY!",
]

const WHALE_MESSAGES = [
	"There she blows!",
	"The big momma!",
]

const TREASURE_MESSAGES = [
	"Arrr matey!",
	"I'm rich!",
	"Time to party!",
]

const SHARK_MESSAGES = [
	"Jaws!",
	"We need a bigger boat!",
	"Chomp chomp!",
	"Shark attack!",
]

const SQUID_MESSAGES = [
	"Release the kraken!",
	"Ten arms of trouble!",
	"Ink-credible!",
	"That's a big pink one!",
]

const ELECTRIC_MESSAGES = [
	"Oohh that stings!",
	"She shocked me!",
	"Its electric!",
]

func flash_score(player: int, points: int, catch_type: String = "medium"):
	var i = player - 1
	var message = ""
	match catch_type:
		"small":
			message = SMALL_FISH_MESSAGES[randi() % SMALL_FISH_MESSAGES.size()]
		"large":
			message = LARGE_FISH_MESSAGES[randi() % LARGE_FISH_MESSAGES.size()]
		"whale":
			message = WHALE_MESSAGES[randi() % WHALE_MESSAGES.size()]
		"treasure":
			message = TREASURE_MESSAGES[randi() % TREASURE_MESSAGES.size()]
		"shark":
			message = SHARK_MESSAGES[randi() % SHARK_MESSAGES.size()]
		"squid":
			message = SQUID_MESSAGES[randi() % SQUID_MESSAGES.size()]
		"electric":
			message = ELECTRIC_MESSAGES[randi() % ELECTRIC_MESSAGES.size()]

	if catch_type == "electric":
		flash_labels[i].text = "%d\n%s" % [points, message]
		flash_labels[i].modulate = Color(0.2, 0.9, 1.0, 1)
	elif message != "":
		flash_labels[i].text = "+%d\n%s" % [points, message]
		flash_labels[i].modulate = Color(1, 1, 0, 1)
	else:
		flash_labels[i].text = "+%d" % points
		flash_labels[i].modulate = Color(1, 1, 0, 1)
	flash_labels[i].visible = true
	flash_labels[i].scale = Vector2.ONE
	flash_labels[i].position.y = 280.0
	flash_labels[i].set_meta("start_y", 280.0)
	flash_timers[i] = 0.0
	flashing[i] = true

func flash_lost(player: int, points: int):
	var i = player - 1
	flash_labels[i].text = "-%d" % points
	flash_labels[i].visible = true
	flash_labels[i].modulate = Color(1, 0.2, 0.2, 1)
	flash_labels[i].scale = Vector2.ONE
	flash_labels[i].position.y = 280.0
	flash_labels[i].set_meta("start_y", 280.0)
	flash_timers[i] = 0.0
	flashing[i] = true

func flash_forfeit(player: int):
	var i = player - 1
	flash_labels[i].text = "FORFEIT!"
	flash_labels[i].visible = true
	flash_labels[i].modulate = Color(1, 0.2, 0.2, 1)
	flash_labels[i].scale = Vector2.ONE
	flash_labels[i].position.y = 280.0
	flash_labels[i].set_meta("start_y", 280.0)
	flash_timers[i] = 0.0
	flashing[i] = true
	casts_labels[i].text = "P%d FORFEITED" % player

func update_score(player: int, score: int):
	score_labels[player - 1].text = "P%d Score: %d" % [player, score]

func update_casts(player: int, casts: int):
	casts_labels[player - 1].text = "P%d Casts: %d" % [player, casts]

# Bonus screen: shows the three scores, then reveals each earned bonus one at a
# time as arcade text floating up over that player's side of the board.
func show_bonus_round(base_scores: Array, bonuses: Array, final_scores: Array):
	running_scores = base_scores.duplicate()
	pending_final_scores = final_scores.duplicate()
	bonus_queue.clear()
	bonus_stack = [0, 0, 0]
	bonus_index = 0
	bonus_timer = 0.0
	for i in range(bonuses.size()):
		for bonus in bonuses[i]:
			bonus_queue.append({
				"player": i + 1,
				"label": bonus["label"],
				"points": int(bonus["points"]),
			})

	for i in range(running_scores.size()):
		update_score(i + 1, running_scores[i])

	game_over_panel.visible = true
	game_over_label.text = _score_line(running_scores)
	winner_label.text = "BONUS POINTS!"
	winner_label.visible = true
	showing_winner = true
	winner_time = 0.0

	if bonus_queue.is_empty():
		_finish_bonus_round()
	else:
		showing_bonuses = true

func _score_line(values: Array) -> String:
	return "P1: %d  |  P2: %d  |  P3: %d" % [values[0], values[1], values[2]]

func _reveal_next_bonus():
	var item = bonus_queue[bonus_index]
	bonus_index += 1
	var player = item["player"]
	running_scores[player - 1] += item["points"]
	update_score(player, running_scores[player - 1])
	game_over_label.text = _score_line(running_scores)
	_spawn_bonus_float(player, item["label"], item["points"])
	SoundManager.play_catch()

func _spawn_bonus_float(player: int, bonus_label: String, points: int):
	var i = player - 1
	var float_label = bonus_float_template.duplicate()
	add_child(float_label)
	float_label.text = "%s\n+%d" % [bonus_label, points]
	var slot = bonus_stack[i] % BONUS_FLOAT_SLOTS
	float_label.position = Vector2(
		BONUS_COLUMN_X[i],
		BONUS_FLOAT_START_Y - slot * BONUS_FLOAT_STACK
	)
	float_label.modulate = Color(1, 1, 1, 1)
	float_label.scale = Vector2.ONE
	float_label.visible = true
	bonus_stack[i] += 1
	bonus_floats.append(float_label)

	var rise = float_label.create_tween()
	rise.set_parallel(true)
	rise.tween_property(float_label, "position:y",
		float_label.position.y - BONUS_FLOAT_RISE,
		BONUS_FLOAT_HOLD + BONUS_FLOAT_FADE).set_ease(Tween.EASE_OUT)
	rise.tween_property(float_label, "modulate:a", 0.0,
		BONUS_FLOAT_FADE).set_delay(BONUS_FLOAT_HOLD)
	rise.finished.connect(_on_bonus_float_done.bind(float_label))

	var pop = float_label.create_tween()
	pop.tween_property(float_label, "scale", Vector2(1.15, 1.15), 0.12).from(Vector2(0.5, 0.5))
	pop.tween_property(float_label, "scale", Vector2.ONE, 0.12)

func _on_bonus_float_done(float_label):
	bonus_floats.erase(float_label)
	if is_instance_valid(float_label):
		float_label.queue_free()

func _finish_bonus_round():
	showing_bonuses = false
	for i in range(pending_final_scores.size()):
		update_score(i + 1, pending_final_scores[i])
	game_over_label.text = _score_line(pending_final_scores)
	_show_results(pending_final_scores)

func _show_results(scores: Array):
	game_over_panel.visible = true

	var max_score = scores.max()
	var winners = []
	for i in range(scores.size()):
		if scores[i] == max_score:
			winners.append(i + 1)

	var winner_text = ""
	if winners.size() > 1:
		winner_text = "IT'S A TIE!"
	else:
		winner_text = "PLAYER %d WINS!" % winners[0]

	game_over_label.text = _score_line(scores)
	winner_label.text = winner_text
	winner_label.visible = true
	showing_winner = true
	winner_time = 0.0

	# The top ten is always shown at the end of a game. Only the winning score of
	# this game can be added, and only if it beats the current tenth place.
	new_entry_index = -1
	pending_score = max_score
	leaderboard_panel.visible = true
	_refresh_leaderboard()
	if Leaderboard.qualifies(max_score):
		_start_name_entry(winners, max_score)
	else:
		restart_label.visible = true

func _start_name_entry(winners: Array, score: int):
	entering_name = true
	var who = "PLAYER %d" % winners[0]
	if winners.size() > 1:
		who = "THE TIED PLAYERS"
	name_entry_label.text = "%s MADE THE TOP TEN WITH %d! TYPE A NAME (8 MAX) AND PRESS ENTER" % [who, score]
	name_entry_label.visible = true
	name_entry_edit.text = ""
	name_entry_edit.visible = true
	name_entry_edit.grab_focus()
	restart_label.visible = false
	SoundManager.play_catch()

func _on_name_text_changed(new_text: String):
	var clean = Leaderboard.sanitize_name(new_text)
	if clean != new_text:
		name_entry_edit.text = clean
		name_entry_edit.caret_column = clean.length()

func _on_name_submitted(submitted_name: String):
	if not entering_name:
		return
	entering_name = false
	new_entry_index = Leaderboard.add_score(submitted_name, pending_score)
	name_entry_edit.release_focus()
	name_entry_edit.visible = false
	name_entry_label.visible = false
	_refresh_leaderboard()
	restart_label.visible = true

func _refresh_leaderboard():
	var names = PackedStringArray()
	var points = PackedStringArray()
	var entries = Leaderboard.entries
	for i in range(Leaderboard.MAX_ENTRIES):
		if i < entries.size():
			var marker = "  <NEW" if i == new_entry_index else ""
			names.append("%2d. %s%s" % [i + 1, entries[i]["name"], marker])
			points.append(str(entries[i]["score"]))
		else:
			names.append("%2d. ---" % (i + 1))
			points.append("---")
	leaderboard_names_label.text = "\n".join(names)
	leaderboard_scores_label.text = "\n".join(points)

# Restarting is locked out while bonuses are still being revealed, and while a
# name is being typed so cast keys can be used in the name.
func blocks_restart() -> bool:
	return entering_name or showing_bonuses

func hide_game_over():
	game_over_panel.visible = false
	winner_label.visible = false
	showing_winner = false
	leaderboard_panel.visible = false
	name_entry_label.visible = false
	name_entry_edit.release_focus()
	name_entry_edit.visible = false
	restart_label.visible = false
	entering_name = false
	new_entry_index = -1

	showing_bonuses = false
	bonus_queue.clear()
	bonus_index = 0
	bonus_timer = 0.0
	bonus_stack = [0, 0, 0]
	for float_label in bonus_floats:
		if is_instance_valid(float_label):
			float_label.queue_free()
	bonus_floats.clear()

func update_timer(time_left: float):
	var minutes = int(time_left) / 60
	var seconds = int(time_left) % 60
	timer_label.text = "%d:%02d" % [minutes, seconds]
	if time_left <= 10.0:
		timer_label.modulate = Color(1, 0.2, 0.2)
	elif time_left <= 30.0:
		timer_label.modulate = Color(1, 0.8, 0.0)
	else:
		timer_label.modulate = Color(1, 1, 1)
