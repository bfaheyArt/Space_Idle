extends Node

const BASE_DRONE_RATE: float = 0.25
const DRONE_BASE_COST: float = 10.0
const DRONE_COST_GROWTH: float = 1.15
const EFFICIENCY_BASE_COST: float = 50.0
const EFFICIENCY_COST_GROWTH: float = 1.25
const CLICK_BASE_COST: float = 25.0
const CLICK_COST_GROWTH: float = 1.22
const EFFICIENCY_MULTIPLIER_BASE: float = 1.10
const CLICK_GAIN_BASE: float = 1.0
const CLICK_GAIN_GROWTH: float = 1.15

func get_drone_cost(drones_owned: int) -> float:
	return DRONE_BASE_COST * pow(DRONE_COST_GROWTH, drones_owned)

func get_efficiency_cost(level: int) -> float:
	return EFFICIENCY_BASE_COST * pow(EFFICIENCY_COST_GROWTH, level)

func get_click_cost(level: int) -> float:
	return CLICK_BASE_COST * pow(CLICK_COST_GROWTH, level)

func get_ore_per_sec(drones_owned: int, efficiency_level: int) -> float:
	var efficiency_multiplier: float = pow(EFFICIENCY_MULTIPLIER_BASE, efficiency_level)
	return BASE_DRONE_RATE * drones_owned * efficiency_multiplier

func get_click_gain(click_level: int) -> float:
	return CLICK_GAIN_BASE * pow(CLICK_GAIN_GROWTH, click_level)
