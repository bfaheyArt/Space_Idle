extends Node

const BASE_DRONE_RATE: float = 0.25
const BASE_MINING_ROLLS_PER_SEC: float = 0.5
const DRONE_BASE_COST: float = 10.0
const DRONE_COST_GROWTH: float = 1.15
const EFFICIENCY_BASE_COST: float = 50.0
const EFFICIENCY_COST_GROWTH: float = 1.25
const CLICK_BASE_COST: float = 25.0
const CLICK_COST_GROWTH: float = 1.22
const EFFICIENCY_MULTIPLIER_BASE: float = 1.10
const CLICK_GAIN_BASE: float = 1.0
const CLICK_GAIN_GROWTH: float = 1.15
const AUTO_OVERCLOCK_BASE_COST: float = 200.0
const AUTO_OVERCLOCK_GROWTH: float = 1.0
const AUTO_BUY_DRONES_BASE_COST: float = 300.0
const AUTO_BUY_DRONES_GROWTH: float = 1.0
const AUTO_BUY_EFF_BASE_COST: float = 500.0
const AUTO_BUY_CLICK_BASE_COST: float = 500.0
const AUTO_PRIORITY_CONTROLLER_BASE_COST: float = 800.0

enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY, SUPER_RARE }

const MINERALS := {
	"iron": {"name": "Iron", "rarity": Rarity.COMMON, "base_price": 1.0},
	"copper": {"name": "Copper", "rarity": Rarity.UNCOMMON, "base_price": 3.0},
	"tin": {"name": "Tin", "rarity": Rarity.RARE, "base_price": 8.0},
	"silver": {"name": "Silver", "rarity": Rarity.EPIC, "base_price": 25.0},
	"gold": {"name": "Gold", "rarity": Rarity.LEGENDARY, "base_price": 80.0},
	"platinum": {"name": "Platinum", "rarity": Rarity.SUPER_RARE, "base_price": 250.0},
}

func get_mineral_ids() -> Array[String]:
	var ids: Array[String] = []
	for id in MINERALS.keys():
		ids.append(str(id))
	return ids

func get_mineral_def(id: String) -> Dictionary:
	if not MINERALS.has(id):
		return {}
	return MINERALS[id]

func get_mineral_name(id: String) -> String:
	var mineral_def: Dictionary = get_mineral_def(id)
	return str(mineral_def.get("name", ""))

func get_mineral_base_price(id: String) -> float:
	var mineral_def: Dictionary = get_mineral_def(id)
	return float(mineral_def.get("base_price", 0.0))

func get_sell_price_per_unit(id: String) -> float:
	var market: Node = get_node_or_null("/root/Market")
	if market != null:
		return market.get_sell_price_per_unit(id)
	return get_mineral_base_price(id)

func get_mineral_rarity(id: String) -> int:
	var mineral_def: Dictionary = get_mineral_def(id)
	return int(mineral_def.get("rarity", -1))

func get_drone_cost(drones_owned: int) -> float:
	return DRONE_BASE_COST * pow(DRONE_COST_GROWTH, drones_owned)

func get_efficiency_cost(level: int) -> float:
	return EFFICIENCY_BASE_COST * pow(EFFICIENCY_COST_GROWTH, level)

func get_click_cost(level: int) -> float:
	return CLICK_BASE_COST * pow(CLICK_COST_GROWTH, level)

func get_ore_per_sec(drones_owned: int, efficiency_level: int) -> float:
	var efficiency_multiplier: float = pow(EFFICIENCY_MULTIPLIER_BASE, efficiency_level)
	return BASE_DRONE_RATE * drones_owned * efficiency_multiplier

func get_base_mining_rolls_per_sec(drones_owned: int, efficiency_level: int) -> float:
	var efficiency_multiplier: float = pow(EFFICIENCY_MULTIPLIER_BASE, efficiency_level)
	return BASE_MINING_ROLLS_PER_SEC * drones_owned * efficiency_multiplier

func roll_basic_mineral(rng: RandomNumberGenerator) -> String:
	var roll: float = rng.randf()
	if roll < 0.80:
		return "iron"
	if roll < 0.95:
		return "copper"
	return "tin"

func get_click_gain(click_level: int) -> float:
	return CLICK_GAIN_BASE * pow(CLICK_GAIN_GROWTH, click_level)

func get_auto_overclock_cost(purchased: bool) -> float:
	if purchased:
		return INF
	return AUTO_OVERCLOCK_BASE_COST

func get_auto_buy_drones_cost(purchased: bool) -> float:
	if purchased:
		return INF
	return AUTO_BUY_DRONES_BASE_COST

func get_auto_buy_eff_cost(purchased: bool) -> float:
	if purchased:
		return INF
	return AUTO_BUY_EFF_BASE_COST

func get_auto_buy_click_cost(purchased: bool) -> float:
	if purchased:
		return INF
	return AUTO_BUY_CLICK_BASE_COST

func get_auto_priority_controller_cost(purchased: bool) -> float:
	if purchased:
		return INF
	return AUTO_PRIORITY_CONTROLLER_BASE_COST
