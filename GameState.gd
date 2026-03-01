extends Node

signal ore_changed(new_ore: float)
signal cash_changed(new_cash: float)
signal minerals_changed()
signal stats_changed()
signal drones_changed(new_count: int)
signal mined(amount: float)
signal layer_changed(new_layer: int)
signal ascension_changed()

enum AsteroidLayer { CRUST, MANTLE, CORE }

var ore: float = 0.0
var cash: float = 0.0
var minerals: Dictionary = {}
var drones_owned: int = 0
var efficiency_level: int = 0
var mining_table_id: String = "default"
var owned_tools: Dictionary = {}
var equipped_tool_id: String = "none"
var ore_mined_total: float = 0.0
var asteroid_layer: int = AsteroidLayer.CRUST
var click_level: int = 0
var overclock_charge: float = 0.0
var overclock_active: bool = false
var overclock_time_left: float = 0.0
var has_auto_overclock: bool = false
var auto_overclock_enabled: bool = false
var has_auto_buy_drones: bool = false
var auto_buy_drones_enabled: bool = false
var has_auto_buy_efficiency: bool = false
var auto_buy_efficiency_enabled: bool = false
var has_auto_buy_click: bool = false
var auto_buy_click_enabled: bool = false
var has_auto_priority_controller: bool = false
enum AutomationPriority { DRONES, EFFICIENCY, CLICK }
var automation_priority: int = AutomationPriority.DRONES
var max_drones_limit: int = 0
var max_efficiency_limit: int = 0
var max_click_limit: int = 0
var _automation_elapsed: float = 0.0
var mining_roll_accumulator: float = 0.0
var _mining_rng := RandomNumberGenerator.new()
var last_save_unix: int = 0
var ascension_points: float = 0.0
var ascension_upgrades: Dictionary = {}

const SAVE_PATH := "user://save.json"
const MAX_OFFLINE_SECONDS := 8 * 60 * 60
const OVERCLOCK_MAX_CHARGE := 100.0
const OVERCLOCK_DURATION := 10.0
const OVERCLOCK_MULTIPLIER := 2.0
const CHARGE_PER_CLICK := 1.0
const MANTLE_THRESHOLD := 250.0
const CORE_THRESHOLD := 1000.0
const PRESTIGE_UNLOCK_THRESHOLD := CORE_THRESHOLD + 500.0
const AP_ORE_DIVISOR := 1000.0
const ASC_UPGRADE_RARITY_BONUS := "rarity_bonus"
const ASC_UPGRADE_MINING_SPEED := "mining_speed"
const ASC_UPGRADE_PRICE_DISCOUNT := "price_discount"
const ASC_UPGRADE_AUTO_MINER := "auto_miner"
const ASC_UPGRADE_EARLY_TOOLS := "early_tools"

const ASCENSION_UPGRADES_DEF := {
	ASC_UPGRADE_RARITY_BONUS: {
		"name": "+1 Permanent Rarity Bonus",
		"desc": "Increases rarity bonus for all mineral rolls.",
		"base_cost": 1.0,
		"cost_growth": 1.8,
		"max_level": 20,
	},
	ASC_UPGRADE_MINING_SPEED: {
		"name": "+5% Permanent Mining Speed",
		"desc": "Boosts ore/sec and mineral roll speed permanently.",
		"base_cost": 1.0,
		"cost_growth": 1.7,
		"max_level": 40,
	},
	ASC_UPGRADE_PRICE_DISCOUNT: {
		"name": "+2% Global Upgrade Discount",
		"desc": "Reduces ore and cash upgrade costs permanently.",
		"base_cost": 2.0,
		"cost_growth": 2.2,
		"max_level": 20,
	},
	ASC_UPGRADE_AUTO_MINER: {
		"name": "Unlock Auto-Buy Drones at Run Start",
		"desc": "Starts each run with Auto-Buy Drones unlocked.",
		"base_cost": 5.0,
		"cost_growth": 1.0,
		"max_level": 1,
	},
	ASC_UPGRADE_EARLY_TOOLS: {
		"name": "Start With Core Drill",
		"desc": "Each run starts with the Core Drill unlocked.",
		"base_cost": 4.0,
		"cost_growth": 1.0,
		"max_level": 1,
	},
}

func _get_economy() -> Node:
	return get_node("/root/Economy")

func _ready() -> void:
	_mining_rng.randomize()
	Market.ensure_initialized()
	load_game()

func get_ore_per_sec() -> float:
	return get_base_ore_per_sec() * get_overclock_multiplier()

func get_mining_rolls_per_sec() -> float:
	var economy = _get_economy()
	var base_rolls_per_sec: float = economy.get_base_mining_rolls_per_sec(drones_owned, efficiency_level)
	return base_rolls_per_sec * get_mining_speed_multiplier() * get_overclock_multiplier()

func get_base_ore_per_sec() -> float:
	var economy = _get_economy()
	return economy.get_ore_per_sec(drones_owned, efficiency_level) * get_mining_speed_multiplier()

func get_click_gain() -> float:
	var economy = _get_economy()
	return economy.get_click_gain(click_level)

func get_rarity_bonus() -> float:
	return float(floor(efficiency_level / 10.0)) + get_ascension_rarity_bonus()

func get_mining_speed_multiplier() -> float:
	return 1.0 + (0.05 * float(get_ascension_upgrade_level(ASC_UPGRADE_MINING_SPEED)))

func get_global_price_discount_multiplier() -> float:
	var discount_level: int = get_ascension_upgrade_level(ASC_UPGRADE_PRICE_DISCOUNT)
	var discount_ratio: float = clamp(float(discount_level) * 0.02, 0.0, 0.5)
	return 1.0 - discount_ratio

func get_ascension_rarity_bonus() -> float:
	return float(get_ascension_upgrade_level(ASC_UPGRADE_RARITY_BONUS))

func get_ascension_upgrade_level(id: String) -> int:
	return int(max(0, int(ascension_upgrades.get(id, 0))))

func has_ascension_upgrade(id: String) -> bool:
	return get_ascension_upgrade_level(id) > 0

func get_ascension_upgrade_ids() -> Array[String]:
	var ids: Array[String] = []
	for id in ASCENSION_UPGRADES_DEF.keys():
		ids.append(str(id))
	ids.sort()
	return ids

func get_ascension_upgrade_def(id: String) -> Dictionary:
	if not ASCENSION_UPGRADES_DEF.has(id):
		return {}
	return ASCENSION_UPGRADES_DEF[id]

func get_ascension_upgrade_cost(id: String) -> float:
	var def: Dictionary = get_ascension_upgrade_def(id)
	if def.is_empty():
		return INF
	var level: int = get_ascension_upgrade_level(id)
	var max_level: int = int(def.get("max_level", 1))
	if level >= max_level:
		return INF
	var base_cost: float = float(def.get("base_cost", 1.0))
	var growth: float = float(def.get("cost_growth", 1.0))
	return base_cost * pow(growth, level)

func can_buy_ascension_upgrade(id: String) -> bool:
	var cost: float = get_ascension_upgrade_cost(id)
	if not is_finite(cost):
		return false
	return ascension_points >= cost

func buy_ascension_upgrade(id: String) -> bool:
	if not can_buy_ascension_upgrade(id):
		return false
	var cost: float = get_ascension_upgrade_cost(id)
	ascension_points -= cost
	ascension_upgrades[id] = get_ascension_upgrade_level(id) + 1
	emit_signal("ascension_changed")
	emit_signal("stats_changed")
	return true

func calculate_prestige_ap_reward() -> float:
	return floor(max(ore_mined_total, 0.0) / AP_ORE_DIVISOR)

func can_prestige() -> bool:
	return ore_mined_total >= PRESTIGE_UNLOCK_THRESHOLD

func prestige() -> float:
	if not can_prestige():
		return 0.0
	var reward: float = calculate_prestige_ap_reward()
	if reward > 0.0:
		ascension_points += reward

	ore = 0.0
	cash = 0.0
	minerals.clear()
	drones_owned = 0
	efficiency_level = 0
	click_level = 0
	ore_mined_total = 0.0
	mining_table_id = "default"
	owned_tools.clear()
	equipped_tool_id = "none"
	overclock_charge = 0.0
	overclock_active = false
	overclock_time_left = 0.0
	has_auto_overclock = false
	auto_overclock_enabled = false
	has_auto_buy_drones = has_ascension_upgrade(ASC_UPGRADE_AUTO_MINER)
	auto_buy_drones_enabled = has_auto_buy_drones
	has_auto_buy_efficiency = false
	auto_buy_efficiency_enabled = false
	has_auto_buy_click = false
	auto_buy_click_enabled = false
	has_auto_priority_controller = false
	automation_priority = AutomationPriority.DRONES
	max_drones_limit = 0
	max_efficiency_limit = 0
	max_click_limit = 0
	_automation_elapsed = 0.0
	mining_roll_accumulator = 0.0
	if has_ascension_upgrade(ASC_UPGRADE_EARLY_TOOLS):
		owned_tools["core_drill"] = true
	asteroid_layer = _calculate_layer_from_ore_mined(ore_mined_total)

	emit_signal("ore_changed", ore)
	emit_signal("cash_changed", cash)
	emit_signal("minerals_changed")
	emit_signal("drones_changed", drones_owned)
	emit_signal("layer_changed", asteroid_layer)
	emit_signal("ascension_changed")
	emit_signal("stats_changed")
	return reward

func get_asteroid_layer_name() -> String:
	match asteroid_layer:
		AsteroidLayer.MANTLE:
			return "MANTLE"
		AsteroidLayer.CORE:
			return "CORE"
		_:
			return "CRUST"

func get_current_drop_table_id() -> String:
	match asteroid_layer:
		AsteroidLayer.MANTLE:
			return "mantle"
		AsteroidLayer.CORE:
			return "core"
		_:
			return "crust"

func get_effective_drop_table_id() -> String:
	var base_table_id: String = get_current_drop_table_id()
	return Economy.get_tool_adjusted_table_id(base_table_id, equipped_tool_id)

func get_effective_rarity_bonus() -> float:
	return get_rarity_bonus() + Economy.get_tool_rarity_bonus_add(equipped_tool_id)

func _calculate_layer_from_ore_mined(ore_mined: float) -> int:
	if ore_mined >= CORE_THRESHOLD:
		return AsteroidLayer.CORE
	if ore_mined >= MANTLE_THRESHOLD:
		return AsteroidLayer.MANTLE
	return AsteroidLayer.CRUST

func _update_asteroid_layer_internal(emit_signals: bool) -> void:
	var next_layer: int = _calculate_layer_from_ore_mined(ore_mined_total)
	if next_layer == asteroid_layer:
		return
	asteroid_layer = next_layer
	if emit_signals:
		emit_signal("layer_changed", asteroid_layer)
		emit_signal("stats_changed")

func update_asteroid_layer() -> void:
	_update_asteroid_layer_internal(true)

func add_ore(amount: float) -> void:
	if amount <= 0.0:
		return
	ore += amount
	emit_signal("ore_changed", ore)

func _add_mined_ore_internal(amount: float, emit_signals: bool) -> void:
	if amount <= 0.0:
		return
	ore += amount
	ore_mined_total += amount
	if emit_signals:
		emit_signal("ore_changed", ore)
	_update_asteroid_layer_internal(emit_signals)

func add_mined_ore(amount: float) -> void:
	_add_mined_ore_internal(amount, true)

func add_cash(amount: float) -> void:
	if amount == 0.0:
		return
	cash = max(cash + amount, 0.0)
	emit_signal("cash_changed", cash)

func can_afford_cash(cost: float) -> bool:
	return cash >= cost

func spend_cash(cost: float) -> bool:
	if not can_afford_cash(cost):
		return false
	add_cash(-cost)
	return true

func add_mineral(id: String, amount: float) -> void:
	if is_zero_approx(amount):
		return
	var economy = _get_economy()
	if economy.get_mineral_def(id).is_empty():
		return
	var current: float = float(minerals.get(id, 0.0))
	var next_amount: float = max(current + amount, 0.0)
	if is_equal_approx(next_amount, current):
		return
	minerals[id] = next_amount
	emit_signal("minerals_changed")

func get_mineral_amount(id: String) -> float:
	return float(minerals.get(id, 0.0))

func get_all_minerals() -> Dictionary:
	return minerals.duplicate()

func can_sell_mineral(id: String, amount: float) -> bool:
	return get_mineral_amount(id) >= amount and amount > 0.0

func sell_mineral(id: String, amount: float) -> float:
	var economy = _get_economy()
	if economy.get_mineral_def(id).is_empty():
		return 0.0
	var available: float = get_mineral_amount(id)
	var sell_amount: float = min(amount, available)
	if sell_amount <= 0.0:
		return 0.0
	var price: float = economy.get_sell_price_per_unit(id)
	var earned: float = sell_amount * price
	add_mineral(id, -sell_amount)
	add_cash(earned)
	return earned

func sell_all_of_mineral(id: String) -> float:
	return sell_mineral(id, get_mineral_amount(id))

func sell_all_minerals() -> float:
	var economy = _get_economy()
	var total_earned: float = 0.0
	for id in economy.get_mineral_ids():
		total_earned += sell_all_of_mineral(String(id))
	return total_earned

func clear_minerals() -> void:
	minerals.clear()
	emit_signal("minerals_changed")

func manual_mine() -> void:
	var gain: float = get_click_gain()
	add_mined_ore(gain)
	var table_id: String = get_effective_drop_table_id()
	var mineral_id: String = Economy.roll_mineral_from_table(_mining_rng, table_id, get_effective_rarity_bonus())
	add_mineral(mineral_id, 1.0)
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

func update_mineral_mining(delta: float) -> void:
	mining_roll_accumulator += get_mining_rolls_per_sec() * delta
	var table_id: String = get_effective_drop_table_id()
	var rarity_bonus: float = get_effective_rarity_bonus()
	while mining_roll_accumulator >= 1.0:
		mining_roll_accumulator -= 1.0
		var mineral_id: String = Economy.roll_mineral_from_table(_mining_rng, table_id, rarity_bonus)
		add_mineral(mineral_id, 1.0)

func has_tool(tool_id: String) -> bool:
	if tool_id == "none":
		return true
	if Economy.get_mining_tool_def(tool_id).is_empty():
		return false
	return bool(owned_tools.get(tool_id, false))

func can_buy_tool(tool_id: String) -> bool:
	if tool_id == "none":
		return false
	var tool_def: Dictionary = Economy.get_mining_tool_def(tool_id)
	if tool_def.is_empty() or has_tool(tool_id):
		return false
	return can_afford_cash(get_mining_tool_cost(tool_id))

func buy_tool(tool_id: String) -> bool:
	if not can_buy_tool(tool_id):
		return false
	if not spend_cash(get_mining_tool_cost(tool_id)):
		return false
	owned_tools[tool_id] = true
	emit_signal("stats_changed")
	return true

func equip_tool(tool_id: String) -> void:
	var next_tool_id: String = tool_id
	if next_tool_id != "none" and not has_tool(next_tool_id):
		return
	if Economy.get_mining_tool_def(next_tool_id).is_empty() and next_tool_id != "none":
		next_tool_id = "none"
	if equipped_tool_id == next_tool_id:
		return
	equipped_tool_id = next_tool_id
	emit_signal("stats_changed")

func can_afford(cost: float) -> bool:
	return ore >= cost

func get_drone_cost() -> float:
	var economy = _get_economy()
	return economy.get_drone_cost(drones_owned) * get_global_price_discount_multiplier()

func get_efficiency_cost() -> float:
	var economy = _get_economy()
	return economy.get_efficiency_cost(efficiency_level) * get_global_price_discount_multiplier()

func get_click_cost() -> float:
	var economy = _get_economy()
	return economy.get_click_cost(click_level) * get_global_price_discount_multiplier()

func get_mining_tool_cost(tool_id: String) -> float:
	return Economy.get_mining_tool_cost(tool_id) * get_global_price_discount_multiplier()

func spend(cost: float) -> bool:
	if not can_afford(cost):
		return false
	ore -= cost
	emit_signal("ore_changed", ore)
	return true

func buy_drone() -> bool:
	var cost: float = get_drone_cost()
	if not spend(cost):
		return false
	drones_owned += 1
	emit_signal("drones_changed", drones_owned)
	emit_signal("stats_changed")
	return true

func buy_efficiency_upgrade() -> bool:
	var cost: float = get_efficiency_cost()
	if not spend(cost):
		return false
	efficiency_level += 1
	emit_signal("stats_changed")
	return true

func buy_click_upgrade() -> bool:
	var cost: float = get_click_cost()
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

func buy_auto_buy_efficiency() -> bool:
	if has_auto_buy_efficiency:
		return false
	var economy = _get_economy()
	var cost: float = economy.get_auto_buy_eff_cost(false)
	if not spend(cost):
		return false
	has_auto_buy_efficiency = true
	auto_buy_efficiency_enabled = true
	emit_signal("stats_changed")
	return true

func buy_auto_buy_click() -> bool:
	if has_auto_buy_click:
		return false
	var economy = _get_economy()
	var cost: float = economy.get_auto_buy_click_cost(false)
	if not spend(cost):
		return false
	has_auto_buy_click = true
	auto_buy_click_enabled = true
	emit_signal("stats_changed")
	return true

func buy_auto_priority_controller() -> bool:
	if has_auto_priority_controller:
		return false
	var economy = _get_economy()
	var cost: float = economy.get_auto_priority_controller_cost(false)
	if not spend(cost):
		return false
	has_auto_priority_controller = true
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

func set_auto_buy_efficiency_enabled(value: bool) -> void:
	if not has_auto_buy_efficiency:
		return
	auto_buy_efficiency_enabled = value
	emit_signal("stats_changed")

func set_auto_buy_click_enabled(value: bool) -> void:
	if not has_auto_buy_click:
		return
	auto_buy_click_enabled = value
	emit_signal("stats_changed")

func set_automation_priority(value: int) -> void:
	if not has_auto_priority_controller:
		return
	if value < AutomationPriority.DRONES or value > AutomationPriority.CLICK:
		return
	automation_priority = value
	emit_signal("stats_changed")

func set_max_drones_limit(value: int) -> void:
	if not has_auto_priority_controller:
		return
	max_drones_limit = int(max(0, value))
	emit_signal("stats_changed")

func set_max_efficiency_limit(value: int) -> void:
	if not has_auto_priority_controller:
		return
	max_efficiency_limit = int(max(0, value))
	emit_signal("stats_changed")

func set_max_click_limit(value: int) -> void:
	if not has_auto_priority_controller:
		return
	max_click_limit = int(max(0, value))
	emit_signal("stats_changed")

func _is_category_enabled(category: int) -> bool:
	match category:
		AutomationPriority.DRONES:
			return has_auto_buy_drones and auto_buy_drones_enabled
		AutomationPriority.EFFICIENCY:
			return has_auto_buy_efficiency and auto_buy_efficiency_enabled
		AutomationPriority.CLICK:
			return has_auto_buy_click and auto_buy_click_enabled
		_:
			return false

func _is_category_limited(category: int) -> bool:
	if not has_auto_priority_controller:
		return false

	match category:
		AutomationPriority.DRONES:
			return max_drones_limit > 0 and drones_owned >= max_drones_limit
		AutomationPriority.EFFICIENCY:
			return max_efficiency_limit > 0 and efficiency_level >= max_efficiency_limit
		AutomationPriority.CLICK:
			return max_click_limit > 0 and click_level >= max_click_limit
		_:
			return true

func _attempt_buy_category(category: int) -> bool:
	match category:
		AutomationPriority.DRONES:
			return buy_drone()
		AutomationPriority.EFFICIENCY:
			return buy_efficiency_upgrade()
		AutomationPriority.CLICK:
			return buy_click_upgrade()
		_:
			return false

func _get_fallback_order() -> Array[int]:
	return [AutomationPriority.DRONES, AutomationPriority.EFFICIENCY, AutomationPriority.CLICK]

func _get_priority_order() -> Array[int]:
	match automation_priority:
		AutomationPriority.EFFICIENCY:
			return [AutomationPriority.EFFICIENCY, AutomationPriority.DRONES, AutomationPriority.CLICK]
		AutomationPriority.CLICK:
			return [AutomationPriority.CLICK, AutomationPriority.DRONES, AutomationPriority.EFFICIENCY]
		_:
			return [AutomationPriority.DRONES, AutomationPriority.EFFICIENCY, AutomationPriority.CLICK]

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

		var purchases_made: int = 0
		var order: Array[int] = _get_priority_order() if has_auto_priority_controller else _get_fallback_order()
		while purchases_made < 5:
			var purchased_this_pass: bool = false
			for category in order:
				if not _is_category_enabled(category):
					continue
				if _is_category_limited(category):
					continue
				if _attempt_buy_category(category):
					purchases_made += 1
					purchased_this_pass = true
					if purchases_made >= 5:
						break
			if not purchased_this_pass:
				break

	if _automation_elapsed >= 0.25:
		_automation_elapsed = fmod(_automation_elapsed, 0.25)

func save_game() -> void:
	Market.ensure_initialized()
	last_save_unix = Time.get_unix_time_from_system()
	var save_data := {
		"ore": ore,
		"cash": cash,
		"minerals": minerals,
		"drones_owned": drones_owned,
		"efficiency_level": efficiency_level,
		"mining_table_id": mining_table_id,
		"owned_tools": owned_tools,
		"equipped_tool_id": equipped_tool_id,
		"ore_mined_total": ore_mined_total,
		"asteroid_layer": asteroid_layer,
		"click_level": click_level,
		"overclock_charge": overclock_charge,
		"overclock_active": overclock_active,
		"overclock_time_left": overclock_time_left,
		"has_auto_overclock": has_auto_overclock,
		"auto_overclock_enabled": auto_overclock_enabled,
		"has_auto_buy_drones": has_auto_buy_drones,
		"auto_buy_drones_enabled": auto_buy_drones_enabled,
		"has_auto_buy_efficiency": has_auto_buy_efficiency,
		"auto_buy_efficiency_enabled": auto_buy_efficiency_enabled,
		"has_auto_buy_click": has_auto_buy_click,
		"auto_buy_click_enabled": auto_buy_click_enabled,
		"has_auto_priority_controller": has_auto_priority_controller,
		"automation_priority": automation_priority,
		"max_drones_limit": max_drones_limit,
		"max_efficiency_limit": max_efficiency_limit,
		"max_click_limit": max_click_limit,
		"last_save_unix": last_save_unix,
		"ascension_points": ascension_points,
		"ascension_upgrades": ascension_upgrades,
		"market_base_seed": Market.base_seed,
		"market_refresh_index": Market.refresh_index,
		"market_next_refresh_unix": Market.next_refresh_unix,
		"market_multipliers": Market.multipliers,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Failed to save game at %s" % SAVE_PATH)
		return
	file.store_string(JSON.stringify(save_data))

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		Market.ensure_initialized()
		Market.update_market(Time.get_unix_time_from_system())
		last_save_unix = Time.get_unix_time_from_system()
		emit_signal("ore_changed", ore)
		emit_signal("cash_changed", cash)
		emit_signal("minerals_changed")
		emit_signal("stats_changed")
		emit_signal("ascension_changed")
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
	cash = float(data.get("cash", 0.0))
	minerals = {}
	var saved_minerals: Variant = data.get("minerals", {})
	if saved_minerals is Dictionary:
		for key in saved_minerals.keys():
			minerals[str(key)] = float(saved_minerals[key])
	drones_owned = int(data.get("drones_owned", 0))
	efficiency_level = int(data.get("efficiency_level", 0))
	mining_table_id = str(data.get("mining_table_id", "default"))
	if mining_table_id.is_empty():
		mining_table_id = "default"
	owned_tools = {}
	var saved_tools: Variant = data.get("owned_tools", {})
	if saved_tools is Dictionary:
		for key in saved_tools.keys():
			var tool_id: String = str(key)
			if tool_id == "none":
				continue
			if Economy.get_mining_tool_def(tool_id).is_empty():
				continue
			if bool(saved_tools[key]):
				owned_tools[tool_id] = true
	equipped_tool_id = str(data.get("equipped_tool_id", "none"))
	if equipped_tool_id != "none" and not has_tool(equipped_tool_id):
		equipped_tool_id = "none"
	ore_mined_total = max(0.0, float(data.get("ore_mined_total", 0.0)))
	asteroid_layer = _calculate_layer_from_ore_mined(ore_mined_total)
	click_level = int(data.get("click_level", 0))
	overclock_charge = float(data.get("overclock_charge", 0.0))
	overclock_active = bool(data.get("overclock_active", false))
	overclock_time_left = float(data.get("overclock_time_left", 0.0))
	has_auto_overclock = bool(data.get("has_auto_overclock", false))
	auto_overclock_enabled = bool(data.get("auto_overclock_enabled", false))
	has_auto_buy_drones = bool(data.get("has_auto_buy_drones", false))
	auto_buy_drones_enabled = bool(data.get("auto_buy_drones_enabled", false))
	has_auto_buy_efficiency = bool(data.get("has_auto_buy_efficiency", false))
	auto_buy_efficiency_enabled = bool(data.get("auto_buy_efficiency_enabled", false))
	has_auto_buy_click = bool(data.get("has_auto_buy_click", false))
	auto_buy_click_enabled = bool(data.get("auto_buy_click_enabled", false))
	has_auto_priority_controller = bool(data.get("has_auto_priority_controller", false))
	automation_priority = int(data.get("automation_priority", AutomationPriority.DRONES))
	automation_priority = int(clamp(automation_priority, AutomationPriority.DRONES, AutomationPriority.CLICK))
	max_drones_limit = int(max(0, int(data.get("max_drones_limit", 0))))
	max_efficiency_limit = int(max(0, int(data.get("max_efficiency_limit", 0))))
	max_click_limit = int(max(0, int(data.get("max_click_limit", 0))))
	if overclock_time_left <= 0.0:
		overclock_time_left = 0.0
		overclock_active = false
	last_save_unix = int(data.get("last_save_unix", Time.get_unix_time_from_system()))
	ascension_points = max(0.0, float(data.get("ascension_points", 0.0)))
	ascension_upgrades = {}
	var saved_ascension_upgrades: Variant = data.get("ascension_upgrades", {})
	if saved_ascension_upgrades is Dictionary:
		for key in saved_ascension_upgrades.keys():
			var id: String = str(key)
			if not ASCENSION_UPGRADES_DEF.has(id):
				continue
			ascension_upgrades[id] = int(max(0, int(saved_ascension_upgrades[key])))

	Market.ensure_initialized()
	Market.base_seed = int(data.get("market_base_seed", Market.base_seed))
	Market.refresh_index = int(data.get("market_refresh_index", Market.refresh_index))
	Market.next_refresh_unix = int(data.get("market_next_refresh_unix", Market.next_refresh_unix))
	Market.multipliers = {}
	var saved_multipliers: Variant = data.get("market_multipliers", {})
	if saved_multipliers is Dictionary:
		for key in saved_multipliers.keys():
			Market.multipliers[str(key)] = float(saved_multipliers[key])
	Market.update_market(Time.get_unix_time_from_system())

	apply_offline_progress(false)
	emit_signal("ore_changed", ore)
	emit_signal("cash_changed", cash)
	emit_signal("minerals_changed")
	emit_signal("stats_changed")
	emit_signal("ascension_changed")

func apply_offline_progress(emit_signals: bool = true) -> void:
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
	_add_mined_ore_internal(base_rate * boosted_time * OVERCLOCK_MULTIPLIER, emit_signals)
	_add_mined_ore_internal(base_rate * normal_time, emit_signals)
	last_save_unix = now

func debug_grant_starting_resources() -> void:
	ore = 100.0
	emit_signal("ore_changed", ore)

func debug_grant_test_minerals() -> void:
	add_mineral("iron", 100.0)
	add_mineral("copper", 25.0)
	add_mineral("tin", 5.0)
	add_cash(50.0)

func debug_set_ore_mined_total(value: float) -> void:
	ore_mined_total = max(0.0, value)
	update_asteroid_layer()

func debug_grant_tool(tool_id: String) -> void:
	if tool_id == "none":
		return
	if Economy.get_mining_tool_def(tool_id).is_empty():
		return
	owned_tools[tool_id] = true
	emit_signal("stats_changed")

func debug_grant_all_tools() -> void:
	for tool_id in Economy.get_mining_tool_ids():
		if tool_id == "none":
			continue
		owned_tools[tool_id] = true
	emit_signal("stats_changed")

func debug_set_equipped_tool(tool_id: String) -> void:
	equip_tool(tool_id)

func debug_grant_ap(points: float) -> void:
	if points <= 0.0:
		return
	ascension_points += points
	emit_signal("ascension_changed")
	emit_signal("stats_changed")

func debug_set_ap(points: float) -> void:
	ascension_points = max(0.0, points)
	emit_signal("ascension_changed")
	emit_signal("stats_changed")
