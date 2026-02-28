# GameManager.gd
extends Node

# Resources
var minerals : float = 0.0

# Generation Rates & Units
var minerals_per_second : float = 1.0
var drone_count : int = 0
var drone_mps_bonus : float = 0.5 # Each drone adds this much MPS

# Upgrade Costs - Use exponential growth for balancing
var drone_base_cost : float = 10.0
var drone_cost_multiplier : float = 1.15 # Cost increases by 15% each time
var current_drone_cost : float = drone_base_cost

func _process(delta: float) -> void:
	minerals += minerals_per_second * delta

func _ready() -> void:
	# Calculate initial state if needed (or load from save later)
	recalculate_mps()
	recalculate_drone_cost()

func recalculate_mps() -> void:
	# Base MPS + bonus from drones
	minerals_per_second = 1.0 + (drone_count * drone_mps_bonus)

func recalculate_drone_cost() -> void:
	# Cost = base_cost * (multiplier ^ count)
	current_drone_cost = drone_base_cost * pow(drone_cost_multiplier, drone_count)

func can_afford_drone() -> bool:
	return minerals >= current_drone_cost

func buy_drone() -> bool:
	if can_afford_drone():
		minerals -= current_drone_cost
		drone_count += 1
		recalculate_mps()
		recalculate_drone_cost()
		print("Bought Drone! Total:", drone_count, " New MPS:", minerals_per_second, " Next Cost:", current_drone_cost)
		return true # Purchase successful
	else:
		print("Not enough minerals for a drone!")
		return false # Purchase failed
