extends Node2D

const MAX_VISIBLE_DRONES := 100
const DRONE_ORBIT_RADIUS := 170.0
const DRONE_BASE_SPEED := 0.6
const SPARK_LIFETIME := 0.35

@onready var asteroid: Node2D = $Asteroid
@onready var drones_root: Node2D = $Drones
@onready var sparks_root: Node2D = $Sparks

var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	if GameState.stats_changed.is_connected(_on_stats_changed) == false:
		GameState.stats_changed.connect(_on_stats_changed)
	if GameState.mined.is_connected(_on_mined) == false:
		GameState.mined.connect(_on_mined)
	rebuild_drones()

func _process(delta: float) -> void:
	_update_drones(delta)
	_update_sparks(delta)

func _on_stats_changed() -> void:
	rebuild_drones()

func rebuild_drones() -> void:
	for child in drones_root.get_children():
		child.queue_free()

	var count := mini(GameState.drones_owned, MAX_VISIBLE_DRONES)
	if count <= 0:
		return

	for i in count:
		var drone := Node2D.new()
		drone.name = "Drone%d" % i
		drone.set_meta("orbit_angle", TAU * (float(i) / float(count)))
		drone.set_meta("orbit_radius", DRONE_ORBIT_RADIUS + _rng.randf_range(-18.0, 18.0))
		drone.set_meta("orbit_speed", DRONE_BASE_SPEED + _rng.randf_range(-0.15, 0.18))

		var body := ColorRect.new()
		body.name = "Body"
		body.color = Color(0.58, 0.84, 0.98)
		body.size = Vector2(10.0, 6.0)
		body.position = Vector2(-5.0, -3.0)
		drone.add_child(body)

		var nose := Polygon2D.new()
		nose.name = "Nose"
		nose.color = Color(0.78, 0.94, 1.0)
		nose.polygon = PackedVector2Array([
			Vector2(5.0, -3.0),
			Vector2(10.0, 0.0),
			Vector2(5.0, 3.0),
		])
		drone.add_child(nose)

		drones_root.add_child(drone)

func _update_drones(delta: float) -> void:
	for drone in drones_root.get_children():
		if drone is not Node2D:
			continue
		var angle: float = float(drone.get_meta("orbit_angle", 0.0))
		var speed: float = float(drone.get_meta("orbit_speed", DRONE_BASE_SPEED))
		var radius: float = float(drone.get_meta("orbit_radius", DRONE_ORBIT_RADIUS))
		angle += speed * delta
		drone.set_meta("orbit_angle", angle)
		drone.position = asteroid.position + Vector2.RIGHT.rotated(angle) * radius
		drone.rotation = angle + PI * 0.5

func _on_mined(amount: float) -> void:
	var spark_count := _rng.randi_range(6, 10)
	for _i in spark_count:
		_spawn_spark(amount)

func _spawn_spark(_amount: float) -> void:
	var spark := ColorRect.new()
	spark.color = Color(1.0, 0.85, 0.35, 1.0)
	spark.size = Vector2(3.0, 3.0)
	spark.position = asteroid.position + Vector2(_rng.randf_range(-18.0, 18.0), _rng.randf_range(-18.0, 18.0))

	var direction := _rng.randf_range(0.0, TAU)
	var speed := _rng.randf_range(70.0, 150.0)
	spark.set_meta("velocity", Vector2.RIGHT.rotated(direction) * speed)
	spark.set_meta("life", SPARK_LIFETIME)
	spark.set_meta("ttl", SPARK_LIFETIME)
	sparks_root.add_child(spark)

func _update_sparks(delta: float) -> void:
	for spark in sparks_root.get_children():
		if spark is not ColorRect:
			continue
		var velocity: Vector2 = spark.get_meta("velocity", Vector2.ZERO)
		var life: float = float(spark.get_meta("life", SPARK_LIFETIME)) - delta
		var ttl: float = float(spark.get_meta("ttl", SPARK_LIFETIME))
		spark.position += velocity * delta
		spark.set_meta("life", life)
		var alpha := clampf(life / maxf(ttl, 0.001), 0.0, 1.0)
		spark.modulate.a = alpha
		if life <= 0.0:
			spark.queue_free()

# To integrate this view, instance res://scenes/AsteroidView.tscn under your main Node2D.
# Keep HUD inside a CanvasLayer so UI is always rendered above the asteroid scene.
