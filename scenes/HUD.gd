extends Control

@onready var ore_label: Label = $VBox/StatsPanel/StatsVBox/OreLabel
@onready var cash_label: Label = $VBox/StatsPanel/StatsVBox/CashLabel
@onready var mineral_label: Label = $VBox/StatsPanel/StatsVBox/MineralLabel
@onready var rate_label: Label = $VBox/StatsPanel/StatsVBox/RateLabel
@onready var layer_label: Label = $VBox/StatsPanel/StatsVBox/LayerLabel
@onready var mine_button: Button = $VBox/MineRow/MineButton
@onready var overclock_bar: ProgressBar = $VBox/OverclockPanel/OverclockVBox/OverclockBar
@onready var overclock_button: Button = $VBox/OverclockPanel/OverclockVBox/OverclockButton
@onready var overclock_label: Label = $VBox/OverclockPanel/OverclockVBox/OverclockLabel
@onready var feedback_label: Label = $VBox/FeedbackLabel
@onready var open_upgrades_button: Button = $VBox/MenuButtonsRow/OpenUpgradesButton
@onready var open_automation_button: Button = $VBox/MenuButtonsRow/OpenAutomationButton
@onready var open_market_button: Button = $VBox/MenuButtonsRow/OpenMarketButton
@onready var upgrades_popup: PanelContainer = $UpgradesPopup
@onready var close_upgrades_button: Button = $UpgradesPopup/PopupRoot/Header/CloseButton
@onready var automation_popup: PanelContainer = $AutomationPopup
@onready var close_automation_button: Button = $AutomationPopup/PopupRoot/Header/CloseButton
@onready var market_popup: PanelContainer = $MarketPopup
@onready var close_market_button: Button = $MarketPopup/PopupRoot/Header/CloseButton
@onready var buy_drone_button: Button = $UpgradesPopup/PopupRoot/ContentMargin/Scroll/VBox/BuyDroneButton
@onready var efficiency_button: Button = $UpgradesPopup/PopupRoot/ContentMargin/Scroll/VBox/EfficiencyButton
@onready var click_power_button: Button = $UpgradesPopup/PopupRoot/ContentMargin/Scroll/VBox/ClickPowerButton
@onready var tools_list: VBoxContainer = $UpgradesPopup/PopupRoot/ContentMargin/Scroll/VBox/ToolsList
@onready var automation_note_label: Label = $AutomationPopup/PopupRoot/ContentMargin/Scroll/VBox/AutomationNoteLabel
@onready var buy_auto_overclock_button: Button = $AutomationPopup/PopupRoot/ContentMargin/Scroll/VBox/BuyAutoOverclockButton
@onready var auto_overclock_toggle: CheckBox = $AutomationPopup/PopupRoot/ContentMargin/Scroll/VBox/AutoOverclockToggleIndent/AutoOverclockToggleRow/AutoOverclockToggle
@onready var buy_auto_buy_drones_button: Button = $AutomationPopup/PopupRoot/ContentMargin/Scroll/VBox/BuyAutoBuyDronesButton
@onready var auto_buy_drones_toggle: CheckBox = $AutomationPopup/PopupRoot/ContentMargin/Scroll/VBox/AutoBuyDronesToggleIndent/AutoBuyDronesToggleRow/AutoBuyDronesToggle
@onready var buy_auto_buy_efficiency_button: Button = $AutomationPopup/PopupRoot/ContentMargin/Scroll/VBox/BuyAutoEfficiencyPurchaseButton
@onready var auto_buy_efficiency_toggle: CheckBox = $AutomationPopup/PopupRoot/ContentMargin/Scroll/VBox/AutoBuyEfficiencyToggleIndent/AutoBuyEfficiencyToggleRow/AutoBuyEfficiencyToggle
@onready var buy_auto_buy_click_button: Button = $AutomationPopup/PopupRoot/ContentMargin/Scroll/VBox/BuyAutoClickPurchaseButton
@onready var auto_buy_click_toggle: CheckBox = $AutomationPopup/PopupRoot/ContentMargin/Scroll/VBox/AutoBuyClickToggleIndent/AutoBuyClickToggleRow/AutoBuyClickToggle
@onready var auto_priority_purchase_button: Button = $AutomationPopup/PopupRoot/ContentMargin/Scroll/VBox/AutoPriorityPurchaseButton
@onready var priority_line: HBoxContainer = $AutomationPopup/PopupRoot/ContentMargin/Scroll/VBox/PriorityLine
@onready var priority_label: Label = $AutomationPopup/PopupRoot/ContentMargin/Scroll/VBox/PriorityLine/PriorityLabel
@onready var priority_option: OptionButton = $AutomationPopup/PopupRoot/ContentMargin/Scroll/VBox/PriorityLine/PriorityOption
@onready var limits_label: Label = $AutomationPopup/PopupRoot/ContentMargin/Scroll/VBox/LimitsLabel
@onready var limits_hint_label: Label = $AutomationPopup/PopupRoot/ContentMargin/Scroll/VBox/LimitsHintLabel
@onready var max_drones_line: HBoxContainer = $AutomationPopup/PopupRoot/ContentMargin/Scroll/VBox/MaxDronesLine
@onready var max_drones_spin: SpinBox = $AutomationPopup/PopupRoot/ContentMargin/Scroll/VBox/MaxDronesLine/MaxDronesSpin
@onready var max_efficiency_line: HBoxContainer = $AutomationPopup/PopupRoot/ContentMargin/Scroll/VBox/MaxEfficiencyLine
@onready var max_efficiency_spin: SpinBox = $AutomationPopup/PopupRoot/ContentMargin/Scroll/VBox/MaxEfficiencyLine/MaxEfficiencySpin
@onready var max_click_line: HBoxContainer = $AutomationPopup/PopupRoot/ContentMargin/Scroll/VBox/MaxClickLine
@onready var max_click_spin: SpinBox = $AutomationPopup/PopupRoot/ContentMargin/Scroll/VBox/MaxClickLine/MaxClickSpin
@onready var sell_all_materials_button: Button = $MarketPopup/PopupRoot/ContentMargin/Scroll/VBox/SellAllMaterialsButton
@onready var market_refresh_label: Label = $MarketPopup/PopupRoot/ContentMargin/Scroll/VBox/MarketRefreshLabel
@onready var materials_list: VBoxContainer = $MarketPopup/PopupRoot/ContentMargin/Scroll/VBox/MaterialsList

var autosave_elapsed: float = 0.0
var overclock_ui_elapsed: float = 0.0
var feedback_serial: int = 0
var _materials_rebuild_pending: bool = false
var _materials_rebuild_cooldown: float = 0.0
var _tools_rebuild_pending: bool = false
var _tools_rebuild_cooldown: float = 0.0
var _market_countdown_update_elapsed: float = 0.0

func _ready() -> void:
	GameState.ore_changed.connect(_on_ore_changed)
	GameState.cash_changed.connect(_on_cash_changed)
	GameState.minerals_changed.connect(_on_minerals_changed)
	GameState.stats_changed.connect(_on_stats_changed)
	Market.market_updated.connect(_on_market_updated)
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
	open_upgrades_button.pressed.connect(_on_open_upgrades_pressed)
	close_upgrades_button.pressed.connect(_on_close_upgrades_pressed)
	open_automation_button.pressed.connect(_on_open_automation_pressed)
	close_automation_button.pressed.connect(_on_close_automation_pressed)
	open_market_button.pressed.connect(_on_open_market_pressed)
	close_market_button.pressed.connect(_on_close_market_pressed)
	sell_all_materials_button.pressed.connect(_on_sell_all_materials_pressed)
	refresh_ui()

func _process(delta: float) -> void:
	var now_unix: int = int(Time.get_unix_time_from_system())
	Market.update_market(now_unix)

	GameState.update_overclock(delta)
	GameState.update_automation(delta)
	GameState.update_mineral_mining(delta)
	GameState.add_mined_ore(GameState.get_ore_per_sec() * delta)

	if market_popup.visible:
		_market_countdown_update_elapsed += delta
		if _market_countdown_update_elapsed >= 0.5:
			_market_countdown_update_elapsed = 0.0
			_update_market_refresh_label()
	else:
		_market_countdown_update_elapsed = 0.0

	if GameState.overclock_active:
		overclock_ui_elapsed += delta
		if overclock_ui_elapsed >= 0.1:
			overclock_ui_elapsed = 0.0
			refresh_overclock_ui()
	else:
		overclock_ui_elapsed = 0.0

	if market_popup.visible:
		_materials_rebuild_cooldown = max(_materials_rebuild_cooldown - delta, 0.0)
		if _materials_rebuild_pending and _materials_rebuild_cooldown <= 0.0:
			_materials_rebuild_pending = false
			_materials_rebuild_cooldown = 0.2
			rebuild_materials_list()
	else:
		_materials_rebuild_pending = false
		_materials_rebuild_cooldown = 0.0

	if upgrades_popup.visible:
		_tools_rebuild_cooldown = max(_tools_rebuild_cooldown - delta, 0.0)
		if _tools_rebuild_pending and _tools_rebuild_cooldown <= 0.0:
			_tools_rebuild_pending = false
			_tools_rebuild_cooldown = 0.25
			_rebuild_mining_tools_list()
	else:
		_tools_rebuild_pending = false
		_tools_rebuild_cooldown = 0.0

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
	_refresh_stats_labels()
	_refresh_upgrade_buttons()
	_refresh_automation_popup_ui()
	_refresh_sell_all_button()
	if market_popup.visible:
		_update_market_refresh_label()
	refresh_overclock_ui()

func _refresh_mineral_summary() -> void:
	var parts: Array[String] = []
	var ids: Array[String] = Economy.get_mineral_ids()
	ids.sort_custom(func(a: String, b: String) -> bool:
		var rarity_a: int = Economy.get_mineral_rarity(a)
		var rarity_b: int = Economy.get_mineral_rarity(b)
		if rarity_a == rarity_b:
			return Economy.get_mineral_name(a) < Economy.get_mineral_name(b)
		return rarity_a < rarity_b
	)
	for id: String in ids:
		parts.append("%s: %.1f" % [Economy.get_mineral_name(id), GameState.get_mineral_amount(id)])
	mineral_label.text = " | ".join(parts)

func _refresh_stats_labels() -> void:
	ore_label.text = "Ore: %.1f" % GameState.ore
	cash_label.text = "Cash: %.1f" % GameState.cash
	_refresh_mineral_summary()
	rate_label.text = "Rate: %.1f/s" % GameState.get_ore_per_sec()
	layer_label.text = "Layer: %s" % GameState.get_asteroid_layer_name()
	mine_button.text = "MINE (+%.1f)" % GameState.get_click_gain()

func _refresh_upgrade_buttons() -> void:
	var drone_cost: float = Economy.get_drone_cost(GameState.drones_owned)
	var efficiency_cost: float = Economy.get_efficiency_cost(GameState.efficiency_level)
	var click_cost: float = Economy.get_click_cost(GameState.click_level)
	buy_drone_button.text = "Buy Drone (%.1f)" % drone_cost
	efficiency_button.text = "Upgrade Efficiency Lv.%d (%.1f)" % [GameState.efficiency_level, efficiency_cost]
	click_power_button.text = "Upgrade Click Power Lv.%d (%.1f)" % [GameState.click_level, click_cost]
	buy_drone_button.disabled = not GameState.can_afford(drone_cost)
	efficiency_button.disabled = not GameState.can_afford(efficiency_cost)
	click_power_button.disabled = not GameState.can_afford(click_cost)

func _refresh_automation_popup_ui() -> void:
	var auto_overclock_cost: float = Economy.get_auto_overclock_cost(GameState.has_auto_overclock)
	var auto_buy_drones_cost: float = Economy.get_auto_buy_drones_cost(GameState.has_auto_buy_drones)
	var auto_buy_eff_cost: float = Economy.get_auto_buy_eff_cost(GameState.has_auto_buy_efficiency)
	var auto_buy_click_cost: float = Economy.get_auto_buy_click_cost(GameState.has_auto_buy_click)
	var auto_priority_cost: float = Economy.get_auto_priority_controller_cost(GameState.has_auto_priority_controller)

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
		priority_line.visible = true
		priority_label.visible = true
		priority_option.visible = true
		priority_option.disabled = false
		priority_option.select(GameState.automation_priority)
		limits_label.visible = true
		limits_hint_label.visible = true
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
		priority_line.visible = false
		priority_label.visible = false
		priority_option.visible = false
		priority_option.disabled = true
		limits_label.visible = false
		limits_hint_label.visible = false
		max_drones_line.visible = false
		max_efficiency_line.visible = false
		max_click_line.visible = false
		max_drones_spin.editable = false
		max_efficiency_spin.editable = false
		max_click_spin.editable = false
		max_drones_spin.set_value_no_signal(0.0)
		max_efficiency_spin.set_value_no_signal(0.0)
		max_click_spin.set_value_no_signal(0.0)

func _refresh_sell_all_button() -> void:
	var has_materials: bool = false
	for id in Economy.get_mineral_ids():
		if GameState.get_mineral_amount(id) > 0.0:
			has_materials = true
			break
	sell_all_materials_button.disabled = not has_materials

func _rebuild_mining_tools_list() -> void:
	for child in tools_list.get_children():
		child.queue_free()

	var none_row: HBoxContainer = HBoxContainer.new()
	none_row.add_theme_constant_override("separation", 8)
	var none_label: Label = Label.new()
	none_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	none_label.text = "None - No tool equipped."
	none_row.add_child(none_label)
	var equip_none_button: Button = Button.new()
	equip_none_button.text = "Equipped" if GameState.equipped_tool_id == "none" else "Equip None"
	equip_none_button.disabled = GameState.equipped_tool_id == "none"
	equip_none_button.pressed.connect(_on_equip_tool_pressed.bind("none"))
	none_row.add_child(equip_none_button)
	tools_list.add_child(none_row)

	var ids: Array[String] = Economy.get_mining_tool_ids()
	ids.sort()
	for tool_id in ids:
		if tool_id == "none":
			continue

		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		var text_label: Label = Label.new()
		text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var name: String = Economy.get_mining_tool_name(tool_id)
		var desc: String = Economy.get_mining_tool_desc(tool_id)
		var cost: float = Economy.get_mining_tool_cost(tool_id)
		var status: String = "Owned" if GameState.has_tool(tool_id) else "Locked"
		if GameState.equipped_tool_id == tool_id:
			status = "Equipped"
		text_label.text = "%s (%.1f cash) - %s [%s]" % [name, cost, desc, status]
		row.add_child(text_label)

		var buy_button: Button = Button.new()
		if GameState.has_tool(tool_id):
			buy_button.text = "Owned"
			buy_button.disabled = true
		else:
			buy_button.text = "Buy"
			buy_button.disabled = not GameState.can_buy_tool(tool_id)
			buy_button.pressed.connect(_on_buy_tool_pressed.bind(tool_id))
		row.add_child(buy_button)

		var equip_button: Button = Button.new()
		equip_button.text = "Equipped" if GameState.equipped_tool_id == tool_id else "Equip"
		equip_button.disabled = not GameState.has_tool(tool_id) or GameState.equipped_tool_id == tool_id
		if not equip_button.disabled:
			equip_button.pressed.connect(_on_equip_tool_pressed.bind(tool_id))
		row.add_child(equip_button)

		tools_list.add_child(row)

func rebuild_materials_list() -> void:
	for child in materials_list.get_children():
		child.queue_free()

	var header_row: HBoxContainer = HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 8)

	var material_header: Label = Label.new()
	material_header.text = "Material"
	material_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(material_header)

	var amount_header: Label = Label.new()
	amount_header.text = "Amount"
	amount_header.custom_minimum_size.x = 90
	amount_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header_row.add_child(amount_header)

	var price_header: Label = Label.new()
	price_header.text = "Price"
	price_header.custom_minimum_size.x = 90
	price_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header_row.add_child(price_header)

	var action_spacer: Control = Control.new()
	action_spacer.custom_minimum_size.x = 168
	header_row.add_child(action_spacer)

	materials_list.add_child(header_row)

	var divider: HSeparator = HSeparator.new()
	materials_list.add_child(divider)

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
		row.add_theme_constant_override("separation", 8)

		var name_label: Label = Label.new()
		name_label.text = Economy.get_mineral_name(id)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)

		var amount_label: Label = Label.new()
		amount_label.text = "%.1f" % amount
		amount_label.custom_minimum_size.x = 90
		amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(amount_label)

		var price_label: Label = Label.new()
		price_label.text = "%.1f/u" % Economy.get_sell_price_per_unit(id)
		price_label.custom_minimum_size.x = 90
		price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(price_label)

		var sell10_btn: Button = Button.new()
		sell10_btn.text = "Sell 10"
		sell10_btn.custom_minimum_size.x = 80
		sell10_btn.pressed.connect(_on_sell10_pressed.bind(id))
		row.add_child(sell10_btn)

		var sell_all_btn: Button = Button.new()
		sell_all_btn.text = "Sell All"
		sell_all_btn.custom_minimum_size.x = 80
		sell_all_btn.pressed.connect(_on_sellall_pressed.bind(id))
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

func _on_ore_changed(_value: Variant = null) -> void:
	ore_label.text = "Ore: %.1f" % GameState.ore
	rate_label.text = "Rate: %.1f/s" % GameState.get_ore_per_sec()
	layer_label.text = "Layer: %s" % GameState.get_asteroid_layer_name()
	mine_button.text = "MINE (+%.1f)" % GameState.get_click_gain()
	_refresh_upgrade_buttons()

func _on_cash_changed(_value: Variant = null) -> void:
	cash_label.text = "Cash: %.1f" % GameState.cash
	if upgrades_popup.visible:
		_tools_rebuild_pending = true
	_refresh_sell_all_button()

func _on_minerals_changed(_value: Variant = null) -> void:
	_refresh_mineral_summary()
	_refresh_sell_all_button()
	if market_popup.visible:
		_materials_rebuild_pending = true

func _on_stats_changed(_value: Variant = null) -> void:
	_refresh_stats_labels()
	_refresh_upgrade_buttons()
	_refresh_automation_popup_ui()
	refresh_overclock_ui()
	if upgrades_popup.visible:
		_tools_rebuild_pending = true
	if market_popup.visible:
		_materials_rebuild_pending = true

func _on_market_updated() -> void:
	if market_popup.visible:
		_update_market_refresh_label()
		_materials_rebuild_pending = true

func _update_market_refresh_label() -> void:
	var seconds_left: int = max(Market.get_seconds_until_refresh(), 0)
	var minutes: int = int(seconds_left / 60)
	var seconds: int = int(seconds_left % 60)
	market_refresh_label.text = "Next refresh: %02d:%02d" % [minutes, seconds]

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


func _on_buy_tool_pressed(tool_id: String) -> void:
	if GameState.buy_tool(tool_id):
		_tools_rebuild_pending = true

func _on_equip_tool_pressed(tool_id: String) -> void:
	GameState.equip_tool(tool_id)
	_tools_rebuild_pending = true

func _on_sell10_pressed(id: String) -> void:
	GameState.sell_mineral(id, 10.0)

func _on_sellall_pressed(id: String) -> void:
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
	if event.is_action_pressed("ui_cancel") and (upgrades_popup.visible or automation_popup.visible or market_popup.visible):
		close_all_popups()
		get_viewport().set_input_as_handled()

func close_all_popups() -> void:
	upgrades_popup.visible = false
	automation_popup.visible = false
	market_popup.visible = false

func _on_open_upgrades_pressed() -> void:
	close_all_popups()
	upgrades_popup.visible = true
	_refresh_stats_labels()
	_refresh_upgrade_buttons()
	_tools_rebuild_pending = true
	_tools_rebuild_cooldown = 0.0
	_rebuild_mining_tools_list()

func _on_close_upgrades_pressed() -> void:
	upgrades_popup.visible = false

func _on_open_automation_pressed() -> void:
	close_all_popups()
	automation_popup.visible = true
	_refresh_stats_labels()
	_refresh_upgrade_buttons()
	_refresh_automation_popup_ui()
	refresh_overclock_ui()

func _on_close_automation_pressed() -> void:
	automation_popup.visible = false

func _on_open_market_pressed() -> void:
	close_all_popups()
	market_popup.visible = true
	Market.update_market(int(Time.get_unix_time_from_system()))
	_update_market_refresh_label()
	rebuild_materials_list()
	_materials_rebuild_pending = false
	_materials_rebuild_cooldown = 0.2
	_refresh_stats_labels()
	_refresh_sell_all_button()

func _on_close_market_pressed() -> void:
	market_popup.visible = false
