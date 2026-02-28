extends Node

signal market_updated()

const REFRESH_MIN_SECONDS: int = 300
const REFRESH_MAX_SECONDS: int = 600
const MAX_CATCH_UP_LOOPS: int = 50
const MIN_SELL_PRICE: float = 0.01

var base_seed: int = 0
var refresh_index: int = 0
var next_refresh_unix: int = 0
var multipliers: Dictionary = {}

func ensure_initialized() -> void:
	if base_seed == 0:
		base_seed = int(Time.get_unix_time_from_system())
	if next_refresh_unix <= 0:
		next_refresh_unix = int(Time.get_unix_time_from_system())

func set_debug_seed(seed: int) -> void:
	if not OS.is_debug_build():
		return
	base_seed = seed
	refresh_index = 0
	multipliers = {}
	next_refresh_unix = int(Time.get_unix_time_from_system())
	emit_signal("market_updated")

func get_sell_price_per_unit(id: String) -> float:
	var economy: Node = get_node_or_null("/root/Economy")
	if economy == null:
		return MIN_SELL_PRICE
	var base_price: float = economy.get_mineral_base_price(id)
	return max(base_price * get_multiplier(id), MIN_SELL_PRICE)

func get_multiplier(id: String) -> float:
	if multipliers.has(id):
		return float(multipliers[id])
	return 1.0

func get_seconds_until_refresh() -> int:
	ensure_initialized()
	return max(next_refresh_unix - int(Time.get_unix_time_from_system()), 0)

func update_market(now_unix: int) -> void:
	ensure_initialized()
	if now_unix >= next_refresh_unix:
		refresh_until(now_unix)

func refresh_once() -> void:
	ensure_initialized()
	var scheduled_refresh_unix: int = next_refresh_unix
	if scheduled_refresh_unix <= 0:
		scheduled_refresh_unix = int(Time.get_unix_time_from_system())

	var rng := RandomNumberGenerator.new()
	rng.seed = int(base_seed) + refresh_index

	var economy: Node = get_node_or_null("/root/Economy")
	if economy != null:
		var next_multipliers: Dictionary = {}
		for id_variant in economy.get_mineral_ids():
			var id: String = str(id_variant)
			var rarity: int = economy.get_mineral_rarity(id)
			var range: Vector2 = _get_multiplier_range_for_rarity(rarity)
			next_multipliers[id] = rng.randf_range(range.x, range.y)
		multipliers = next_multipliers

	var interval: int = rng.randi_range(REFRESH_MIN_SECONDS, REFRESH_MAX_SECONDS)
	next_refresh_unix = scheduled_refresh_unix + interval
	refresh_index += 1
	emit_signal("market_updated")

func refresh_until(now_unix: int) -> void:
	var loops: int = 0
	while now_unix >= next_refresh_unix and loops < MAX_CATCH_UP_LOOPS:
		refresh_once()
		loops += 1
	if now_unix >= next_refresh_unix:
		next_refresh_unix = now_unix + REFRESH_MAX_SECONDS

func debug_force_refresh() -> void:
	next_refresh_unix = int(Time.get_unix_time_from_system())
	update_market(next_refresh_unix)

func _get_multiplier_range_for_rarity(rarity: int) -> Vector2:
	match rarity:
		Economy.Rarity.COMMON:
			return Vector2(0.85, 1.15)
		Economy.Rarity.UNCOMMON:
			return Vector2(0.80, 1.20)
		Economy.Rarity.RARE:
			return Vector2(0.75, 1.25)
		Economy.Rarity.EPIC:
			return Vector2(0.70, 1.30)
		Economy.Rarity.LEGENDARY:
			return Vector2(0.65, 1.35)
		Economy.Rarity.SUPER_RARE:
			return Vector2(0.60, 1.40)
		_:
			return Vector2(0.85, 1.15)
