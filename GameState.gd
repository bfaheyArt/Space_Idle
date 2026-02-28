extends Node

signal ore_changed(new_ore: float)
signal stats_changed()
signal drones_changed(new_count: int)
signal mined(amount: float)

var ore: float = 0.0
var drones_owned: int = 0
var efficiency_level: int = 0
var click_level: int = 0
var overclock_charge: float = 0.0
var last_save_unix: int = 0

const SAVE_PATH := "user://save.json"
const MAX_OFFLINE_SECONDS := 8 * 60 * 60

func _get_economy() -> Node:
	return get_node("/root/Economy")

func _ready() -> void:
	load_game()

func get_ore_per_sec() -> float:
	var economy = _get_economy()
	return economy.get_ore_per_sec(drones_owned, efficiency_level)

func get_click_gain() -> float:
	var economy = _get_economy()
	return economy.get_click_gain(click_level)

func add_ore(amount: float) -> void:
	if amount <= 0.0:
		return
	ore += amount
	emit_signal("ore_changed", ore)

func manual_mine() -> void:
	var gain: float = get_click_gain()
	add_ore(gain)
	emit_signal("mined", gain)

func can_afford(cost: float) -> bool:
	return ore >= cost

func spend(cost: float) -> bool:
	if not can_afford(cost):
		return false
	ore -= cost
	emit_signal("ore_changed", ore)
	return true

func buy_drone() -> bool:
	var economy = _get_economy()
	var cost: float = economy.get_drone_cost(drones_owned)
	if not spend(cost):
		return false
	drones_owned += 1
	emit_signal("drones_changed", drones_owned)
	emit_signal("stats_changed")
	return true

func buy_efficiency_upgrade() -> bool:
	var economy = _get_economy()
	var cost: float = economy.get_efficiency_cost(efficiency_level)
	if not spend(cost):
		return false
	efficiency_level += 1
	emit_signal("stats_changed")
	return true

func buy_click_upgrade() -> bool:
	var economy = _get_economy()
	var cost: float = economy.get_click_cost(click_level)
	if not spend(cost):
		return false
	click_level += 1
	emit_signal("stats_changed")
	return true

func save_game() -> void:
	last_save_unix = Time.get_unix_time_from_system()
	var save_data := {
		"ore": ore,
		"drones_owned": drones_owned,
		"efficiency_level": efficiency_level,
		"click_level": click_level,
		"overclock_charge": overclock_charge,
		"last_save_unix": last_save_unix,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Failed to save game at %s" % SAVE_PATH)
		return
	file.store_string(JSON.stringify(save_data))

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		last_save_unix = Time.get_unix_time_from_system()
		emit_signal("ore_changed", ore)
		emit_signal("stats_changed")
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("Failed to load game at %s" % SAVE_PATH)
		return

	var content: String = file.get_as_text()
	var json := JSON.new()
	var parse_error: int = json.parse(content)
	if parse_error != OK:
		push_error("Invalid save data: %s" % json.get_error_message())
		return

	var data: Dictionary = json.data if json.data is Dictionary else {}
	ore = float(data.get("ore", 0.0))
	drones_owned = int(data.get("drones_owned", 0))
	efficiency_level = int(data.get("efficiency_level", 0))
	click_level = int(data.get("click_level", 0))
	overclock_charge = float(data.get("overclock_charge", 0.0))
	last_save_unix = int(data.get("last_save_unix", Time.get_unix_time_from_system()))

	apply_offline_progress()
	emit_signal("ore_changed", ore)
	emit_signal("stats_changed")

func apply_offline_progress() -> void:
	var now: int = Time.get_unix_time_from_system()
	var elapsed: int = clamp(now - last_save_unix, 0, MAX_OFFLINE_SECONDS)
	if elapsed > 0:
		ore += get_ore_per_sec() * float(elapsed)
		last_save_unix = now

func debug_grant_starting_resources() -> void:
	ore = 100.0
	emit_signal("ore_changed", ore)
