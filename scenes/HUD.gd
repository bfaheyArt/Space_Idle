extends Control

@onready var ore_label: Label = $VBox/OreLabel
@onready var cash_label: Label = $VBox/CashLabel
@onready var mineral_label: Label = $VBox/MineralLabel
@onready var rate_label: Label = $VBox/RateLabel
@onready var mine_button: Button = $VBox/MineButton
@onready var overclock_bar: ProgressBar = $VBox/OverclockPanel/OverclockBar
@onready var overclock_button: Button = $VBox/OverclockPanel/OverclockButton
@onready var overclock_label: Label = $VBox/OverclockPanel/OverclockLabel
@onready var feedback_label: Label = $VBox/FeedbackLabel
@onready var open_shop_button: Button = $VBox/OpenShopButton
@onready var shop_popup: PanelContainer = $ShopPopup
@onready var close_shop_button: Button = $ShopPopup/ShopRoot/ShopHeader/CloseShopButton
@onready var automation_note_label: Label = $ShopPopup/ShopRoot/ShopScroll/ShopVBox/AutomationNoteLabel
@onready var buy_drone_button: Button = $ShopPopup/ShopRoot/ShopScroll/ShopVBox/BuyDroneButton
@onready var efficiency_button: Button = $ShopPopup/ShopRoot/ShopScroll/ShopVBox/EfficiencyButton
@onready var click_power_button: Button = $ShopPopup/ShopRoot/ShopScroll/ShopVBox/ClickPowerButton
@onready var buy_auto_overclock_button: Button = $ShopPopup/ShopRoot/ShopScroll/ShopVBox/BuyAutoOverclockButton
@onready var auto_overclock_toggle: CheckBox = $ShopPopup/ShopRoot/ShopScroll/ShopVBox/AutoOverclockToggle
@onready var buy_auto_buy_drones_button: Button = $ShopPopup/ShopRoot/ShopScroll/ShopVBox/BuyAutoBuyDronesButton
@onready var auto_buy_drones_toggle: CheckBox = $ShopPopup/ShopRoot/ShopScroll/ShopVBox/AutoBuyDronesToggle
@onready var buy_auto_buy_efficiency_button: Button = $ShopPopup/ShopRoot/ShopScroll/ShopVBox/AutoBuyEfficiencyPurchaseButton
@onready var auto_buy_efficiency_toggle: CheckBox = $ShopPopup/ShopRoot/ShopScroll/ShopVBox/AutoBuyEfficiencyToggle
@onready var buy_auto_buy_click_button: Button = $ShopPopup/ShopRoot/ShopScroll/ShopVBox/AutoBuyClickPurchaseButton
@onready var auto_buy_click_toggle: CheckBox = $ShopPopup/ShopRoot/ShopScroll/ShopVBox/AutoBuyClickToggle
@onready var auto_priority_purchase_button: Button = $ShopPopup/ShopRoot/ShopScroll/ShopVBox/AutoPriorityPurchaseButton
@onready var priority_label: Label = $ShopPopup/ShopRoot/ShopScroll/ShopVBox/PriorityLabel
@onready var priority_option: OptionButton = $ShopPopup/ShopRoot/ShopScroll/ShopVBox/PriorityOption
@onready var limits_label: Label = $ShopPopup/ShopRoot/ShopScroll/ShopVBox/LimitsLabel
@onready var max_drones_line: HBoxContainer = $ShopPopup/ShopRoot/ShopScroll/ShopVBox/MaxDronesLine
@onready var max_drones_spin: SpinBox = $ShopPopup/ShopRoot/ShopScroll/ShopVBox/MaxDronesLine/MaxDronesSpin
@onready var max_efficiency_line: HBoxContainer = $ShopPopup/ShopRoot/ShopScroll/ShopVBox/MaxEfficiencyLine
@onready var max_efficiency_spin: SpinBox = $ShopPopup/ShopRoot/ShopScroll/ShopVBox/MaxEfficiencyLine/MaxEfficiencySpin
@onready var max_click_line: HBoxContainer = $ShopPopup/ShopRoot/ShopScroll/ShopVBox/MaxClickLine
@onready var max_click_spin: SpinBox = $ShopPopup/ShopRoot/ShopScroll/ShopVBox/MaxClickLine/MaxClickSpin
@onready var materials_list: VBoxContainer = $ShopPopup/ShopRoot/ShopScroll/ShopVBox/MaterialsList
@onready var sell_all_materials_button: Button = $ShopPopup/ShopRoot/ShopScroll/ShopVBox/SellAllMaterialsButton

var autosave_elapsed: float = 0.0
var overclock_ui_elapsed: float = 0.0
var feedback_serial: int = 0

func _ready() -> void:
	GameState.ore_changed.connect(_on_game_state_changed)
	GameState.cash_changed.connect(_on_game_state_changed)
	GameState.minerals_changed.connect(_on_game_state_changed)
	GameState.stats_changed.connect(_on_game_state_changed)
	mine_button.pressed.connect(_on_mine_pressed)
	overclock_button.pressed.connect(_on_overclock_pressed)
	buy_drone_button.pressed.connect(_on_buy_drone_pressed)
	efficiency_button.pressed.connect(_on_efficiency_pressed)
	click_power_button.pressed.connect(_on_click_power_pressed)
	buy_auto_overclock_button.pressed.connect(_on_buy_auto_overclock_pressed)
	auto_overclock_toggle.toggled.connect(_on_auto_overclock_toggled)
	buy_auto_buy_drones_button.pressed.connect(_on_buy_auto_buy_drones_pressed)
	auto_buy_drones_toggle.toggled.connect(_on_auto_buy_drones_toggled)
	buy_auto_buy_efficiency_button.pressed.connect(_on_buy_auto_buy_efficiency_pressed)
	auto_buy_efficiency_toggle.toggled.connect(_on_auto_buy_efficiency_toggled)
	buy_auto_buy_click_button.pressed.connect(_on_buy_auto_buy_click_pressed)
	auto_buy_click_toggle.toggled.connect(_on_auto_buy_click_toggled)
	auto_priority_purchase_button.pressed.connect(_on_buy_auto_priority_controller_pressed)
	priority_option.item_selected.connect(_on_priority_selected)
	max_drones_spin.value_changed.connect(_on_max_drones_changed)
	max_efficiency_spin.value_changed.connect(_on_max_efficiency_changed)
	max_click_spin.value_changed.connect(_on_max_click_changed)
	feedback_label.text = ""
	open_shop_button.pressed.connect(_on_open_shop_pressed)
	close_shop_button.pressed.connect(_on_close_shop_pressed)
	sell_all_materials_button.pressed.connect(_on_sell_all_materials_pressed)
	refresh_ui()

func _process(delta: float) -> void:
	GameState.update_overclock(delta)
	GameState.update_automation(delta)
	GameState.update_mineral_mining(delta)
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
	var auto_overclock_cost: float = Economy.get_auto_overclock_cost(GameState.has_auto_overclock)
	var auto_buy_drones_cost: float = Economy.get_auto_buy_drones_cost(GameState.has_auto_buy_drones)
	var auto_buy_eff_cost: float = Economy.get_auto_buy_eff_cost(GameState.has_auto_buy_efficiency)
	var auto_buy_click_cost: float = Economy.get_auto_buy_click_cost(GameState.has_auto_buy_click)
	var auto_priority_cost: float = Economy.get_auto_priority_controller_cost(GameState.has_auto_priority_controller)

	ore_label.text = "Ore: %.1f" % GameState.ore
	cash_label.text = "Cash: %.1f" % GameState.cash
	mineral_label.text = "Iron: %.1f | Copper: %.1f | Tin: %.1f" % [
		GameState.get_mineral_amount("iron"),
		GameState.get_mineral_amount("copper"),
		GameState.get_mineral_amount("tin")
	]
	rate_label.text = "Rate: %.1f/s" % ore_per_sec
	mine_button.text = "MINE (+%.1f)" % click_gain
	buy_drone_button.text = "Buy Drone (%.1f)" % drone_cost
	efficiency_button.text = "Upgrade Efficiency Lv.%d (%.1f)" % [GameState.efficiency_level, efficiency_cost]
	click_power_button.text = "Upgrade Click Power Lv.%d (%.1f)" % [GameState.click_level, click_cost]

	buy_drone_button.disabled = not GameState.can_afford(drone_cost)
	efficiency_button.disabled = not GameState.can_afford(efficiency_cost)
	click_power_button.disabled = not GameState.can_afford(click_cost)

	if GameState.has_auto_overclock:
		buy_auto_overclock_button.text = "Auto Overclock Purchased"
		buy_auto_overclock_button.disabled = true
		auto_overclock_toggle.visible = true
		auto_overclock_toggle.disabled = false
		auto_overclock_toggle.set_pressed_no_signal(GameState.auto_overclock_enabled)
	else:
		buy_auto_overclock_button.text = "Buy Auto Overclock (%.1f)" % auto_overclock_cost
		buy_auto_overclock_button.disabled = not GameState.can_afford(auto_overclock_cost)
		auto_overclock_toggle.visible = false
		auto_overclock_toggle.disabled = true
		auto_overclock_toggle.set_pressed_no_signal(false)

	if GameState.has_auto_buy_drones:
		buy_auto_buy_drones_button.text = "Auto-Buy Drones Purchased"
		buy_auto_buy_drones_button.disabled = true
		auto_buy_drones_toggle.visible = true
		auto_buy_drones_toggle.disabled = false
		auto_buy_drones_toggle.set_pressed_no_signal(GameState.auto_buy_drones_enabled)
	else:
		buy_auto_buy_drones_button.text = "Buy Auto-Buy Drones (%.1f)" % auto_buy_drones_cost
		buy_auto_buy_drones_button.disabled = not GameState.can_afford(auto_buy_drones_cost)
		auto_buy_drones_toggle.visible = false
		auto_buy_drones_toggle.disabled = true
		auto_buy_drones_toggle.set_pressed_no_signal(false)

	if GameState.has_auto_buy_efficiency:
		buy_auto_buy_efficiency_button.text = "Auto-Buy Efficiency Purchased"
		buy_auto_buy_efficiency_button.disabled = true
		auto_buy_efficiency_toggle.visible = true
		auto_buy_efficiency_toggle.disabled = false
		auto_buy_efficiency_toggle.set_pressed_no_signal(GameState.auto_buy_efficiency_enabled)
	else:
		buy_auto_buy_efficiency_button.text = "Buy Auto-Buy Efficiency (%.1f)" % auto_buy_eff_cost
		buy_auto_buy_efficiency_button.disabled = not GameState.can_afford(auto_buy_eff_cost)
		auto_buy_efficiency_toggle.visible = false
		auto_buy_efficiency_toggle.disabled = true
		auto_buy_efficiency_toggle.set_pressed_no_signal(false)

	if GameState.has_auto_buy_click:
		buy_auto_buy_click_button.text = "Auto-Buy Click Power Purchased"
		buy_auto_buy_click_button.disabled = true
		auto_buy_click_toggle.visible = true
		auto_buy_click_toggle.disabled = false
		auto_buy_click_toggle.set_pressed_no_signal(GameState.auto_buy_click_enabled)
	else:
		buy_auto_buy_click_button.text = "Buy Auto-Buy Click Power (%.1f)" % auto_buy_click_cost
		buy_auto_buy_click_button.disabled = not GameState.can_afford(auto_buy_click_cost)
		auto_buy_click_toggle.visible = false
		auto_buy_click_toggle.disabled = true
		auto_buy_click_toggle.set_pressed_no_signal(false)

	automation_note_label.visible = (GameState.has_auto_buy_efficiency or GameState.has_auto_buy_click) and not GameState.has_auto_priority_controller

	if GameState.has_auto_priority_controller:
		auto_priority_purchase_button.text = "Auto-Priority Controller Purchased"
		auto_priority_purchase_button.disabled = true
		priority_label.visible = true
		priority_option.visible = true
		priority_option.disabled = false
		priority_option.select(GameState.automation_priority)
		limits_label.visible = true
		max_drones_line.visible = true
		max_efficiency_line.visible = true
		max_click_line.visible = true
		max_drones_spin.editable = true
		max_efficiency_spin.editable = true
		max_click_spin.editable = true
		max_drones_spin.set_value_no_signal(float(GameState.max_drones_limit))
		max_efficiency_spin.set_value_no_signal(float(GameState.max_efficiency_limit))
		max_click_spin.set_value_no_signal(float(GameState.max_click_limit))
	else:
		auto_priority_purchase_button.text = "Buy Auto-Priority Controller (%.1f)" % auto_priority_cost
		auto_priority_purchase_button.disabled = not GameState.can_afford(auto_priority_cost)
		priority_label.visible = false
		priority_option.visible = false
		priority_option.disabled = true
		limits_label.visible = false
		max_drones_line.visible = false
		max_efficiency_line.visible = false
		max_click_line.visible = false
		max_drones_spin.editable = false
		max_efficiency_spin.editable = false
		max_click_spin.editable = false
		max_drones_spin.set_value_no_signal(0.0)
		max_efficiency_spin.set_value_no_signal(0.0)
		max_click_spin.set_value_no_signal(0.0)

	rebuild_materials_list()
	var has_materials: bool = false
	for id in Economy.get_mineral_ids():
		if GameState.get_mineral_amount(id) > 0.0:
			has_materials = true
			break
	sell_all_materials_button.disabled = not has_materials

	refresh_overclock_ui()

func rebuild_materials_list() -> void:
	for child in materials_list.get_children():
		child.queue_free()

	var mineral_ids: Array[String] = Economy.get_mineral_ids()
	mineral_ids.sort_custom(func(a: String, b: String) -> bool:
		var rarity_a: int = Economy.get_mineral_rarity(a)
		var rarity_b: int = Economy.get_mineral_rarity(b)
		if rarity_a == rarity_b:
			return Economy.get_mineral_name(a) < Economy.get_mineral_name(b)
		return rarity_a < rarity_b
	)

	for id in mineral_ids:
		var amount: float = GameState.get_mineral_amount(id)
		if amount <= 0.0:
			continue

		var row: HBoxContainer = HBoxContainer.new()

		var name_label: Label = Label.new()
		name_label.text = Economy.get_mineral_name(id)
		row.add_child(name_label)

		var amount_label: Label = Label.new()
		amount_label.text = "Amount: %.1f" % amount
		row.add_child(amount_label)

		var price_label: Label = Label.new()
		price_label.text = "Price: %.1f/u" % Economy.get_sell_price_per_unit(id)
		row.add_child(price_label)

		var sell10_btn: Button = Button.new()
		sell10_btn.text = "Sell 10"
		sell10_btn.set_meta("mineral_id", id)
		sell10_btn.pressed.connect(_on_sell10_pressed)
		row.add_child(sell10_btn)

		var sell_all_btn: Button = Button.new()
		sell_all_btn.text = "Sell All"
		sell_all_btn.set_meta("mineral_id", id)
		sell_all_btn.pressed.connect(_on_sellall_pressed)
		row.add_child(sell_all_btn)

		materials_list.add_child(row)

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

func _on_buy_auto_overclock_pressed() -> void:
	GameState.buy_auto_overclock()

func _on_auto_overclock_toggled(value: bool) -> void:
	GameState.set_auto_overclock_enabled(value)

func _on_buy_auto_buy_drones_pressed() -> void:
	GameState.buy_auto_buy_drones()

func _on_auto_buy_drones_toggled(value: bool) -> void:
	GameState.set_auto_buy_drones_enabled(value)

func _on_buy_auto_buy_efficiency_pressed() -> void:
	GameState.buy_auto_buy_efficiency()

func _on_auto_buy_efficiency_toggled(value: bool) -> void:
	GameState.set_auto_buy_efficiency_enabled(value)

func _on_buy_auto_buy_click_pressed() -> void:
	GameState.buy_auto_buy_click()

func _on_auto_buy_click_toggled(value: bool) -> void:
	GameState.set_auto_buy_click_enabled(value)

func _on_buy_auto_priority_controller_pressed() -> void:
	GameState.buy_auto_priority_controller()

func _on_priority_selected(index: int) -> void:
	GameState.set_automation_priority(index)

func _on_max_drones_changed(value: float) -> void:
	GameState.set_max_drones_limit(int(value))

func _on_max_efficiency_changed(value: float) -> void:
	GameState.set_max_efficiency_limit(int(value))

func _on_max_click_changed(value: float) -> void:
	GameState.set_max_click_limit(int(value))

func _on_sell10_pressed() -> void:
	var sender_id: int = get_signal_sender_id()
	var sender: Object = instance_from_id(sender_id)
	if sender == null or not sender.has_meta("mineral_id"):
		return
	var id: String = str(sender.get_meta("mineral_id"))
	GameState.sell_mineral(id, 10.0)

func _on_sellall_pressed() -> void:
	var sender_id: int = get_signal_sender_id()
	var sender: Object = instance_from_id(sender_id)
	if sender == null or not sender.has_meta("mineral_id"):
		return
	var id: String = str(sender.get_meta("mineral_id"))
	GameState.sell_all_of_mineral(id)

func _on_sell_all_materials_pressed() -> void:
	GameState.sell_all_minerals()

func show_feedback(gain: float) -> void:
	feedback_serial += 1
	var this_serial: int = feedback_serial
	feedback_label.text = "+%.1f ore" % gain
	await get_tree().create_timer(0.5).timeout
	if this_serial == feedback_serial:
		feedback_label.text = ""


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and shop_popup.visible:
		shop_popup.visible = false
		get_viewport().set_input_as_handled()

func _on_open_shop_pressed() -> void:
	shop_popup.visible = true
	refresh_ui()

func _on_close_shop_pressed() -> void:
	shop_popup.visible = false
