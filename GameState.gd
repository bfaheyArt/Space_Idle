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
var overclock_active: bool = false
var overclock_time_left: float = 0.0
var has_auto_overclock: bool = false
var auto_overclock_enabled: bool = false
var has_auto_buy_drones: bool = false
var auto_buy_drones_enabled: bool = false
var _automation_elapsed: float = 0.0
var last_save_unix: int = 0

const SAVE_PATH := "user://save.json"
const MAX_OFFLINE_SECONDS := 8 * 60 * 60
const OVERCLOCK_MAX_CHARGE := 100.0
const OVERCLOCK_DURATION := 10.0
const OVERCLOCK_MULTIPLIER := 2.0
const CHARGE_PER_CLICK := 1.0

func _get_economy() -> Node:
	return get_node("/root/Economy")

func _ready() -> void:
	load_game()

func get_ore_per_sec() -> float:
	return get_base_ore_per_sec() * get_overclock_multiplier()

func get_base_ore_per_sec() -> float:
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
	if not overclock_active:
		overclock_charge = clamp(overclock_charge + CHARGE_PER_CLICK, 0.0, OVERCLOCK_MAX_CHARGE)
		emit_signal("stats_changed")
	emit_signal("mined", gain)

func can_activate_overclock() -> bool:
	return overclock_charge >= OVERCLOCK_MAX_CHARGE and not overclock_active

func activate_overclock() -> bool:
	if not can_activate_overclock():
		return false
	overclock_active = true
	overclock_time_left = OVERCLOCK_DURATION
	overclock_charge = 0.0
	emit_signal("stats_changed")
	return true

func get_overclock_multiplier() -> float:
	if overclock_active:
		return OVERCLOCK_MULTIPLIER
	return 1.0

func update_overclock(delta: float) -> void:
	if not overclock_active:
		return
	overclock_time_left -= delta
	if overclock_time_left <= 0.0:
		overclock_active = false
		overclock_time_left = 0.0
		emit_signal("stats_changed")

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

func buy_auto_overclock() -> bool:
	if has_auto_overclock:
		return false
	var economy = _get_economy()
	var cost: float = economy.get_auto_overclock_cost(false)
	if not spend(cost):
		return false
	has_auto_overclock = true
	auto_overclock_enabled = true
	emit_signal("stats_changed")
	return true

func buy_auto_buy_drones() -> bool:
	if has_auto_buy_drones:
		return false
	var economy = _get_economy()
	var cost: float = economy.get_auto_buy_drones_cost(false)
	if not spend(cost):
		return false
	has_auto_buy_drones = true
	auto_buy_drones_enabled = true
	emit_signal("stats_changed")
	return true

func set_auto_overclock_enabled(value: bool) -> void:
	if not has_auto_overclock:
		return
	auto_overclock_enabled = value
	emit_signal("stats_changed")

func set_auto_buy_drones_enabled(value: bool) -> void:
	if not has_auto_buy_drones:
		return
	auto_buy_drones_enabled = value
	emit_signal("stats_changed")

func update_automation(delta: float) -> void:
	_automation_elapsed += delta
	if _automation_elapsed < 0.25:
		return

	var iterations: int = 0
	while _automation_elapsed >= 0.25 and iterations < 20:
		_automation_elapsed -= 0.25
		iterations += 1

		if has_auto_overclock and auto_overclock_enabled and can_activate_overclock():
			activate_overclock()

		if has_auto_buy_drones and auto_buy_drones_enabled:
			for _i in range(3):
				if not buy_drone():
					break

	if _automation_elapsed >= 0.25:
		_automation_elapsed = fmod(_automation_elapsed, 0.25)

func save_game() -> void:
	last_save_unix = Time.get_unix_time_from_system()
	var save_data := {
		"ore": ore,
		"drones_owned": drones_owned,
		"efficiency_level": efficiency_level,
		"click_level": click_level,
		"overclock_charge": overclock_charge,
		"overclock_active": overclock_active,
		"overclock_time_left": overclock_time_left,
		"has_auto_overclock": has_auto_overclock,
		"auto_overclock_enabled": auto_overclock_enabled,
		"has_auto_buy_drones": has_auto_buy_drones,
		"auto_buy_drones_enabled": auto_buy_drones_enabled,
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
	overclock_active = bool(data.get("overclock_active", false))
	overclock_time_left = float(data.get("overclock_time_left", 0.0))
	has_auto_overclock = bool(data.get("has_auto_overclock", false))
	auto_overclock_enabled = bool(data.get("auto_overclock_enabled", false))
	has_auto_buy_drones = bool(data.get("has_auto_buy_drones", false))
	auto_buy_drones_enabled = bool(data.get("auto_buy_drones_enabled", false))
	if overclock_time_left <= 0.0:
		overclock_time_left = 0.0
		overclock_active = false
	last_save_unix = int(data.get("last_save_unix", Time.get_unix_time_from_system()))

	apply_offline_progress()
	emit_signal("ore_changed", ore)
	emit_signal("stats_changed")

func apply_offline_progress() -> void:
	var now: int = Time.get_unix_time_from_system()
	var elapsed: int = clamp(now - last_save_unix, 0, MAX_OFFLINE_SECONDS)
	if elapsed <= 0:
		return

	var elapsed_f: float = float(elapsed)
	var base_rate: float = get_base_ore_per_sec()
	var boosted_time: float = 0.0

	if overclock_active and overclock_time_left > 0.0:
		boosted_time = min(elapsed_f, overclock_time_left)
		overclock_time_left -= boosted_time
		if overclock_time_left <= 0.0:
			overclock_time_left = 0.0
			overclock_active = false

	var normal_time: float = elapsed_f - boosted_time
	ore += base_rate * boosted_time * OVERCLOCK_MULTIPLIER
	ore += base_rate * normal_time
	last_save_unix = now

func debug_grant_starting_resources() -> void:
	ore = 100.0
	emit_signal("ore_changed", ore)
