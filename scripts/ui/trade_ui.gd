extends Control

signal trade_completed(items_bought: Array, items_sold: Array)
signal trade_cancelled()

var trader_inventory := []
var player_inventory := []
var trader_name: String = "Торговец"
var trader_gold: int = 1000

var main_panel: PanelContainer
var trader_list: ItemList
var player_list: ItemList
var cart_list: ItemList
var gold_label: Label
var total_label: Label

var cart := []
var cart_total: int = 0

func _ready():
	visible = false
	_create_ui()

func _create_ui():
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0, 0, 0, 0.85)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 80)
	margin.add_theme_constant_override("margin_right", 80)
	margin.add_theme_constant_override("margin_top", 60)
	margin.add_theme_constant_override("margin_bottom", 60)
	add_child(margin)
	
	main_panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.12, 0.1, 0.98)
	style.border_color = Color(0.6, 0.5, 0.3)
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(20)
	main_panel.add_theme_stylebox_override("panel", style)
	margin.add_child(main_panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	main_panel.add_child(vbox)
	
	var title_hbox = HBoxContainer.new()
	vbox.add_child(title_hbox)
	
	var title = Label.new()
	title.name = "TraderName"
	title.text = "ТОРГОВЛЯ: " + trader_name
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_hbox.add_child(title)
	
	gold_label = Label.new()
	gold_label.name = "GoldLabel"
	gold_label.text = "Ваше золото: 0"
	gold_label.add_theme_font_size_override("font_size", 20)
	gold_label.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
	title_hbox.add_child(gold_label)
	
	var lists_hbox = HBoxContainer.new()
	lists_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lists_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(lists_hbox)
	
	var trader_panel = _create_list_panel("Товары торговца", true)
	trader_list = trader_panel.get_node("VBox/ItemList")
	lists_hbox.add_child(trader_panel)
	
	var cart_panel = _create_cart_panel()
	cart_list = cart_panel.get_node("VBox/ItemList")
	lists_hbox.add_child(cart_panel)
	
	var player_panel = _create_list_panel("Ваш инвентарь", false)
	player_list = player_panel.get_node("VBox/ItemList")
	lists_hbox.add_child(player_panel)
	
	var bottom_hbox = HBoxContainer.new()
	bottom_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(bottom_hbox)
	
	total_label = Label.new()
	total_label.name = "TotalLabel"
	total_label.text = "Итого: 0 золота"
	total_label.add_theme_font_size_override("font_size", 22)
	total_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.6))
	total_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_hbox.add_child(total_label)
	
	var clear_btn = Button.new()
	clear_btn.text = "Очистить"
	clear_btn.custom_minimum_size = Vector2(120, 45)
	clear_btn.pressed.connect(_clear_cart)
	bottom_hbox.add_child(clear_btn)
	
	var confirm_btn = Button.new()
	confirm_btn.text = "Подтвердить"
	confirm_btn.custom_minimum_size = Vector2(150, 45)
	confirm_btn.pressed.connect(_confirm_trade)
	bottom_hbox.add_child(confirm_btn)
	
	var cancel_btn = Button.new()
	cancel_btn.text = "Отмена [ESC]"
	cancel_btn.custom_minimum_size = Vector2(120, 45)
	cancel_btn.pressed.connect(_close_ui)
	bottom_hbox.add_child(cancel_btn)

func _create_list_panel(title_text: String, is_trader: bool) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.08, 0.06)
	style.border_color = Color(0.4, 0.35, 0.25)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)
	
	var title = Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.6))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var item_list = ItemList.new()
	item_list.name = "ItemList"
	item_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	item_list.select_mode = ItemList.SELECT_SINGLE
	item_list.allow_rmb_select = true
	
	if is_trader:
		item_list.item_clicked.connect(_on_trader_item_clicked)
	else:
		item_list.item_clicked.connect(_on_player_item_clicked)
	
	vbox.add_child(item_list)
	
	return panel

func _create_cart_panel() -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_stretch_ratio = 0.8
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.1, 0.08)
	style.border_color = Color(0.5, 0.45, 0.3)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "Корзина"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.6, 0.9, 0.6))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var item_list = ItemList.new()
	item_list.name = "ItemList"
	item_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	item_list.select_mode = ItemList.SELECT_SINGLE
	item_list.item_clicked.connect(_on_cart_item_clicked)
	vbox.add_child(item_list)
	
	return panel

func open_trade(trader, trader_items: Array, player_items: Array, p_gold: int):
	trader_inventory = trader_items.duplicate()
	player_inventory = player_items.duplicate()
	
	if trader:
		trader_name = trader.npc_name if trader.has("npc_name") else "Торговец"
		trader_gold = trader.gold if trader.has("gold") else 1000
	
	cart.clear()
	cart_total = 0
	
	var title_node = main_panel.get_node_or_null("VBoxContainer/HBoxContainer/TraderName")
	if title_node:
		title_node.text = "ТОРГОВЛЯ: " + trader_name
	
	_update_gold_display(p_gold)
	_refresh_lists()
	
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _refresh_lists():
	trader_list.clear()
	player_list.clear()
	cart_list.clear()
	
	for item in trader_inventory:
		var text = "%s x%d - %d зол." % [item.name, item.quantity, item.price]
		trader_list.add_item(text)
	
	for item in player_inventory:
		var sell_price = int(item.price * 0.5)
		var text = "%s x%d - %d зол." % [item.name, item.quantity, sell_price]
		player_list.add_item(text)
	
	for cart_item in cart:
		var prefix = "+" if cart_item.is_buy else "-"
		var text = "%s %s x%d (%d)" % [prefix, cart_item.name, cart_item.quantity, cart_item.total_price]
		cart_list.add_item(text)
	
	_update_total()

func _on_trader_item_clicked(index: int, at_position: Vector2, mouse_button_index: int):
	if index < 0 or index >= trader_inventory.size():
		return
	
	var item = trader_inventory[index]
	_add_to_cart(item, true, 1)

func _on_player_item_clicked(index: int, at_position: Vector2, mouse_button_index: int):
	if index < 0 or index >= player_inventory.size():
		return
	
	var item = player_inventory[index]
	_add_to_cart(item, false, 1)

func _on_cart_item_clicked(index: int, at_position: Vector2, mouse_button_index: int):
	if index < 0 or index >= cart.size():
		return
	
	cart.remove_at(index)
	_refresh_lists()

func _add_to_cart(item: Dictionary, is_buy: bool, quantity: int):
	var price_per_unit = item.price if is_buy else int(item.price * 0.5)
	
	for cart_item in cart:
		if cart_item.id == item.id and cart_item.is_buy == is_buy:
			cart_item.quantity += quantity
			cart_item.total_price = cart_item.quantity * price_per_unit
			_refresh_lists()
			return
	
	cart.append({
		"id": item.id,
		"name": item.name,
		"quantity": quantity,
		"is_buy": is_buy,
		"price_per_unit": price_per_unit,
		"total_price": quantity * price_per_unit
	})
	
	_refresh_lists()

func _update_total():
	cart_total = 0
	for cart_item in cart:
		if cart_item.is_buy:
			cart_total += cart_item.total_price
		else:
			cart_total -= cart_item.total_price
	
	if cart_total > 0:
		total_label.text = "Итого: -%d золота" % cart_total
		total_label.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
	elif cart_total < 0:
		total_label.text = "Итого: +%d золота" % abs(cart_total)
		total_label.add_theme_color_override("font_color", Color(0.5, 1, 0.5))
	else:
		total_label.text = "Итого: 0 золота"
		total_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.6))

func _update_gold_display(amount: int):
	gold_label.text = "Ваше золото: %d" % amount

func _clear_cart():
	cart.clear()
	_refresh_lists()

func _confirm_trade():
	var inv = get_node_or_null("/root/Inventory")
	if not inv:
		_close_ui()
		return
	
	var player_gold = inv.get_gold() if inv.has_method("get_gold") else 0
	
	if cart_total > 0 and player_gold < cart_total:
		var notif = get_node_or_null("/root/NotificationSystem")
		if notif:
			notif.show_notification("Недостаточно золота!", "error")
		return
	
	var items_bought = []
	var items_sold = []
	
	for cart_item in cart:
		if cart_item.is_buy:
			items_bought.append(cart_item)
			if inv.has_method("add_item"):
				inv.add_item(cart_item.id, cart_item.quantity, 1.0)
		else:
			items_sold.append(cart_item)
			if inv.has_method("remove_item_amount"):
				inv.remove_item_amount(cart_item.id, cart_item.quantity)
	
	if inv.has_method("add_gold") and inv.has_method("remove_gold"):
		if cart_total > 0:
			inv.remove_gold(cart_total)
		else:
			inv.add_gold(abs(cart_total))
	
	emit_signal("trade_completed", items_bought, items_sold)
	
	var notif = get_node_or_null("/root/NotificationSystem")
	if notif:
		notif.show_notification("Сделка завершена!", "success")
	
	_close_ui()

func _close_ui():
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	emit_signal("trade_cancelled")

func _input(event):
	if visible and event.is_action_pressed("ui_cancel"):
		_close_ui()
		get_viewport().set_input_as_handled()
