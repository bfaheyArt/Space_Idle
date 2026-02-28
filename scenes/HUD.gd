extends Control

@onready var ore_label: Label = $VBox/OreLabel
@onready var rate_label: Label = $VBox/RateLabel
@onready var mine_button: Button = $VBox/MineButton
@onready var overclock_bar: ProgressBar = $VBox/OverclockPanel/OverclockBar
@onready var overclock_button: Button = $VBox/OverclockPanel/OverclockButton
@onready var overclock_label: Label = $VBox/OverclockPanel/OverclockLabel
@onready var feedback_label: Label = $VBox/FeedbackLabel
@onready var buy_drone_button: Button = $VBox/ShopPanel/ShopVBox/BuyDroneButton
@onready var efficiency_button: Button = $VBox/ShopPanel/ShopVBox/EfficiencyButton
@onready var click_power_button: Button = $VBox/ShopPanel/ShopVBox/ClickPowerButton

var autosave_elapsed: float = 0.0
var overclock_ui_elapsed: float = 0.0
var feedback_serial: int = 0

func _ready() -> void:
	GameState.ore_changed.connect(_on_game_state_changed)
	GameState.stats_changed.connect(_on_game_state_changed)
	mine_button.pressed.connect(_on_mine_pressed)
	overclock_button.pressed.connect(_on_overclock_pressed)
	buy_drone_button.pressed.connect(_on_buy_drone_pressed)
	efficiency_button.pressed.connect(_on_efficiency_pressed)
	click_power_button.pressed.connect(_on_click_power_pressed)
	feedback_label.text = ""
	refresh_ui()

func _process(delta: float) -> void:
	GameState.update_overclock(delta)
	GameState.add_ore(GameState.get_ore_per_sec() * delta)

	if GameState.overclock_active:
		overclock_ui_elapsed += delta
		if overclock_ui_elapsed >= 0.1:
			overclock_ui_elapsed = 0.0
			refresh_overclock_ui()
	else:
		overclock_ui_elapsed = 0.0

	autosave_elapsed += delta
	if autosave_elapsed >= 30.0:
		autosave_elapsed = 0.0
		GameState.save_game()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		GameState.save_game()
		get_tree().quit()
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		GameState.save_game()

func refresh_ui() -> void:
	var ore_per_sec: float = GameState.get_ore_per_sec()
	var click_gain: float = GameState.get_click_gain()
	var drone_cost: float = Economy.get_drone_cost(GameState.drones_owned)
	var efficiency_cost: float = Economy.get_efficiency_cost(GameState.efficiency_level)
	var click_cost: float = Economy.get_click_cost(GameState.click_level)

	ore_label.text = "Ore: %.1f" % GameState.ore
	rate_label.text = "Rate: %.1f/s" % ore_per_sec
	mine_button.text = "MINE (+%.1f)" % click_gain
	buy_drone_button.text = "Buy Drone (%.1f)" % drone_cost
	efficiency_button.text = "Upgrade Efficiency Lv.%d (%.1f)" % [GameState.efficiency_level, efficiency_cost]
	click_power_button.text = "Upgrade Click Power Lv.%d (%.1f)" % [GameState.click_level, click_cost]

	buy_drone_button.disabled = not GameState.can_afford(drone_cost)
	efficiency_button.disabled = not GameState.can_afford(efficiency_cost)
	click_power_button.disabled = not GameState.can_afford(click_cost)

	refresh_overclock_ui()

func refresh_overclock_ui() -> void:
	overclock_button.disabled = not GameState.can_activate_overclock()
	if GameState.overclock_active:
		overclock_bar.value = GameState.OVERCLOCK_MAX_CHARGE
		overclock_label.text = "OVERCLOCK ACTIVE (%.1fs)" % GameState.overclock_time_left
	else:
		overclock_bar.value = GameState.overclock_charge
		overclock_label.text = "Charge: %.0f / %.0f" % [GameState.overclock_charge, GameState.OVERCLOCK_MAX_CHARGE]

func _on_game_state_changed(_value: Variant = null) -> void:
	refresh_ui()

func _on_mine_pressed() -> void:
	var gain: float = GameState.get_click_gain()
	GameState.manual_mine()
	show_feedback(gain)

func _on_overclock_pressed() -> void:
	GameState.activate_overclock()

func _on_buy_drone_pressed() -> void:
	GameState.buy_drone()

func _on_efficiency_pressed() -> void:
	GameState.buy_efficiency_upgrade()

func _on_click_power_pressed() -> void:
	GameState.buy_click_upgrade()

func show_feedback(gain: float) -> void:
	feedback_serial += 1
	var this_serial: int = feedback_serial
	feedback_label.text = "+%.1f ore" % gain
	await get_tree().create_timer(0.5).timeout
	if this_serial == feedback_serial:
		feedback_label.text = ""
