extends Node

# Persistent top-ten high score list.
# Only one entry per game is recorded: the winning (highest) score of that game,
# and only when it beats the current tenth place.

const SAVE_PATH = "user://leaderboard.json"
const MAX_ENTRIES = 10
const MAX_NAME_LENGTH = 8
const DEFAULT_NAME = "AAA"

# Array of { "name": String, "score": int }, sorted highest score first.
var entries: Array = []

func _ready():
	load_scores()

func load_scores():
	entries = []
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("Leaderboard: cannot read %s (error %d)" % [SAVE_PATH, FileAccess.get_open_error()])
		return
	var text = file.get_as_text()
	file.close()

	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_ARRAY:
		push_warning("Leaderboard: %s is not a valid score list, starting fresh" % SAVE_PATH)
		return
	for item in data:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		if not item.has("name") or not item.has("score"):
			continue
		var entry_name = sanitize_name(str(item["name"]))
		if entry_name.is_empty():
			entry_name = DEFAULT_NAME
		entries.append({"name": entry_name, "score": int(item["score"])})

	entries.sort_custom(func(a, b): return a["score"] > b["score"])
	if entries.size() > MAX_ENTRIES:
		entries.resize(MAX_ENTRIES)

func save_scores():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Leaderboard: cannot write %s (error %d)" % [SAVE_PATH, FileAccess.get_open_error()])
		return
	file.store_string(JSON.stringify(entries))
	file.close()

# Keeps letters and digits only, uppercased, capped at MAX_NAME_LENGTH.
func sanitize_name(raw: String) -> String:
	var clean = ""
	for c in raw.to_upper():
		if (c >= "A" and c <= "Z") or (c >= "0" and c <= "9"):
			clean += c
			if clean.length() >= MAX_NAME_LENGTH:
				break
	return clean

func qualifies(score: int) -> bool:
	if score <= 0:
		return false
	if entries.size() < MAX_ENTRIES:
		return true
	return score > int(entries[MAX_ENTRIES - 1]["score"])

# Inserts a score and returns its rank index, or -1 if it did not make the list.
# Ties are placed below the scores already on the board.
func add_score(player_name: String, score: int) -> int:
	if not qualifies(score):
		return -1
	var clean = sanitize_name(player_name)
	if clean.is_empty():
		clean = DEFAULT_NAME

	var index = entries.size()
	for i in range(entries.size()):
		if score > int(entries[i]["score"]):
			index = i
			break
	entries.insert(index, {"name": clean, "score": score})
	if entries.size() > MAX_ENTRIES:
		entries.resize(MAX_ENTRIES)
	save_scores()
	return index
