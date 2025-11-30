extends Control

signal blueprint_selected(blueprint_id: String)
signal craft_requested(blueprint_id: String)

@onready var category_list: VBoxContainer = $MainPanel/HSplitContainer/LeftPanel/CategoryList
@onready var blueprint_grid: GridContainer = $MainPanel/HSplitContainer/RightPanel/ScrollContainer/BlueprintGrid
@onready var detail_panel: PanelContainer = $DetailPanel
@onready var detail_name: Label = $DetailPanel/VBox/NameLabel
@onready var detail_desc: Label = $DetailPanel/VBox/DescLabel
@onready var detail_tier: Label = $DetailPanel/VBox/TierLabel
@onready var detail_requirements: Label = $DetailPanel/VBox/RequirementsLabel
@onready var detail_materials: VBoxContainer = $DetailPanel/VBox/MaterialsList
@onready var craft_button: Button = $DetailPanel/VBox/CraftButton
@onready var progress_label: Label = $MainPanel/TopBar/ProgressLabel
@onready var search_input: LineEdit = $MainPanel/TopBar/SearchInput

var current_category := "survival"
var selected_blueprint_id := ""
var player_id := 1
var language := "ru"

func _ready():
	_setup_ui()
	_connect_signals()
	_populate_categories()
	_select_category("survival")
	_update_progress()

func _setup_ui():
	if detail_panel:
		detail_panel.visible = false
	
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		language = gm.get_language()

func _connect_signals():
	if search_input:
		search_input.text_changed.connect(_on_search_changed)
	if craft_button:
		craft_button.pressed.connect(_on_craft_pressed)

func _populate_categories():
	if not category_list:
		return
	
	for child in category_list.get_children():
		child.queue_free()
	
	var bp_book = get_node_or_null("/root/BlueprintBook")
	if not bp_book:
		return
	
	var categories = bp_book.get_all_categories()
	for cat in categories:
		var btn = Button.new()
		btn.text = bp_book.get_category_display_name(cat, language)
		btn.custom_minimum_size = Vector2(150, 40)
		btn.pressed.connect(_on_category_selected.bind(cat))
		_apply_category_button_style(btn, cat == current_category)
		category_list.add_child(btn)

func _apply_category_button_style(btn: Button, selected: bool):
	var style = StyleBoxFlat.new()
	if selected:
		style.bg_color = Color(0.4, 0.3, 0.2, 0.9)
		style.border_color = Color(0.8, 0.6, 0.3)
	else:
		style.bg_color = Color(0.2, 0.15, 0.1, 0.8)
		style.border_color = Color(0.4, 0.3, 0.2)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_color_override("font_color", Color(0.9, 0.85, 0.75))

func _on_category_selected(category: String):
	current_category = category
	_populate_categories()
	_populate_blueprints(category)

func _select_category(category: String):
	current_category = category
	_populate_blueprints(category)

func _populate_blueprints(category: String, search_filter: String = ""):
	if not blueprint_grid:
		return
	
	for child in blueprint_grid.get_children():
		child.queue_free()
	
	var bp_book = get_node_or_null("/root/BlueprintBook")
	if not bp_book:
		return
	
	var blueprints = bp_book.get_blueprints_by_category(player_id, category, true)
	
	for bp in blueprints:
		var bp_name = bp_book.get_blueprint_display_name(bp.id, language)
		
		if search_filter != "" and not bp_name.to_lower().contains(search_filter.to_lower()):
			continue
		
		var is_unlocked = bp_book.is_blueprint_unlocked(player_id, bp.id)
		_create_blueprint_card(bp, is_unlocked)

func _create_blueprint_card(bp: Dictionary, is_unlocked: bool):
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(120, 140)
	
	var style = StyleBoxFlat.new()
	if is_unlocked:
		style.bg_color = Color(0.15, 0.12, 0.1, 0.9)
		style.border_color = Color(0.5, 0.4, 0.3)
	else:
		style.bg_color = Color(0.1, 0.1, 0.1, 0.7)
		style.border_color = Color(0.3, 0.25, 0.2)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	card.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(vbox)
	
	var icon_rect = TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(64, 64)
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	
	if is_unlocked:
		icon_rect.modulate = Color.WHITE
	else:
		icon_rect.modulate = Color(0.3, 0.3, 0.3)
	
	vbox.add_child(icon_rect)
	
	var bp_book = get_node_or_null("/root/BlueprintBook")
	var name_label = Label.new()
	name_label.text = bp_book.get_blueprint_display_name(bp.id, language) if bp_book else bp.id
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 12)
	
	if is_unlocked:
		name_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.75))
	else:
		name_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	
	vbox.add_child(name_label)
	
	var tier_label = Label.new()
	var tier_text = bp_book.get_tier_display_name(bp.tier, language) if bp_book else str(bp.tier)
	tier_label.text = tier_text
	tier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tier_label.add_theme_font_size_override("font_size", 10)
	
	var tier_colors := [
		Color(0.5, 0.5, 0.5),
		Color(0.4, 0.7, 0.4),
		Color(0.4, 0.6, 0.9),
		Color(0.8, 0.5, 0.9)
	]
	tier_label.add_theme_color_override("font_color", tier_colors[clampi(bp.tier, 0, 3)])
	vbox.add_child(tier_label)
	
	if not is_unlocked:
		var lock_icon = Label.new()
		lock_icon.text = "🔒"
		lock_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(lock_icon)
	
	var btn = Button.new()
	btn.flat = true
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.pressed.connect(_on_blueprint_clicked.bind(bp.id))
	card.add_child(btn)
	
	blueprint_grid.add_child(card)

func _on_blueprint_clicked(blueprint_id: String):
	selected_blueprint_id = blueprint_id
	_show_blueprint_details(blueprint_id)
	emit_signal("blueprint_selected", blueprint_id)

func _show_blueprint_details(blueprint_id: String):
	if not detail_panel:
		return
	
	var bp_book = get_node_or_null("/root/BlueprintBook")
	if not bp_book or not bp_book.blueprints.has(blueprint_id):
		detail_panel.visible = false
		return
	
	var bp = bp_book.blueprints[blueprint_id]
	var is_unlocked = bp_book.is_blueprint_unlocked(player_id, blueprint_id)
	
	detail_panel.visible = true
	
	if detail_name:
		detail_name.text = bp_book.get_blueprint_display_name(blueprint_id, language)
	
	if detail_desc:
		detail_desc.text = bp_book.get_blueprint_description(blueprint_id, language)
	
	if detail_tier:
		detail_tier.text = "Уровень: " + bp_book.get_tier_display_name(bp.tier, language) if language == "ru" else "Tier: " + bp_book.get_tier_display_name(bp.tier, language)
	
	if detail_requirements:
		if is_unlocked:
			detail_requirements.text = "✓ " + ("Разблокировано" if language == "ru" else "Unlocked")
			detail_requirements.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
		else:
			detail_requirements.text = bp_book.get_unlock_requirement_text(blueprint_id, language)
			detail_requirements.add_theme_color_override("font_color", Color(0.9, 0.5, 0.3))
	
	_populate_materials(bp.get("recipe_id", blueprint_id))
	
	if craft_button:
		craft_button.visible = is_unlocked
		craft_button.text = "Создать" if language == "ru" else "Craft"
		
		var craft_sys = get_node_or_null("/root/CraftSystem")
		var inv = get_node_or_null("/root/Inventory")
		if craft_sys and inv and is_unlocked:
			var can_craft = craft_sys.can_craft(inv, bp.get("recipe_id", blueprint_id))
			craft_button.disabled = not can_craft

func _populate_materials(recipe_id: String):
	if not detail_materials:
		return
	
	for child in detail_materials.get_children():
		child.queue_free()
	
	var craft_sys = get_node_or_null("/root/CraftSystem")
	var inv = get_node_or_null("/root/Inventory")
	
	if not craft_sys or not craft_sys.recipes.has(recipe_id):
		return
	
	var recipe = craft_sys.recipes[recipe_id]
	var inputs = recipe.get("inputs", {})
	
	var header = Label.new()
	header.text = "Материалы:" if language == "ru" else "Materials:"
	header.add_theme_font_size_override("font_size", 14)
	header.add_theme_color_override("font_color", Color(0.8, 0.75, 0.65))
	detail_materials.add_child(header)
	
	for item_id in inputs.keys():
		var required = inputs[item_id]
		var have = 0
		if inv:
			have = inv.get_item_count(item_id)
		
		var row = HBoxContainer.new()
		
		var item_name = item_id
		if inv and inv.item_database.has(item_id):
			item_name = inv.item_database[item_id].get("name", item_id)
		
		var name_lbl = Label.new()
		name_lbl.text = item_name
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.add_theme_font_size_override("font_size", 12)
		row.add_child(name_lbl)
		
		var count_lbl = Label.new()
		count_lbl.text = "%d / %d" % [have, required]
		count_lbl.add_theme_font_size_override("font_size", 12)
		
		if have >= required:
			count_lbl.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
		else:
			count_lbl.add_theme_color_override("font_color", Color(0.9, 0.4, 0.3))
		
		row.add_child(count_lbl)
		detail_materials.add_child(row)

func _on_craft_pressed():
	if selected_blueprint_id == "":
		return
	
	emit_signal("craft_requested", selected_blueprint_id)
	
	var bp_book = get_node_or_null("/root/BlueprintBook")
	if not bp_book or not bp_book.blueprints.has(selected_blueprint_id):
		return
	
	var bp = bp_book.blueprints[selected_blueprint_id]
	var recipe_id = bp.get("recipe_id", selected_blueprint_id)
	
	var craft_sys = get_node_or_null("/root/CraftSystem")
	var inv = get_node_or_null("/root/Inventory")
	
	if craft_sys and inv:
		if craft_sys.craft_item(inv, recipe_id):
			_show_blueprint_details(selected_blueprint_id)
			var notif = get_node_or_null("/root/NotificationSystem")
			if notif:
				var item_name = bp_book.get_blueprint_display_name(selected_blueprint_id, language)
				notif.show_notification("Создано: " + item_name if language == "ru" else "Crafted: " + item_name, "success")

func _on_search_changed(text: String):
	_populate_blueprints(current_category, text)

func _update_progress():
	if not progress_label:
		return
	
	var bp_book = get_node_or_null("/root/BlueprintBook")
	if not bp_book:
		return
	
	var unlocked = bp_book.get_unlocked_count(player_id)
	var total = bp_book.get_total_count()
	var percent = bp_book.get_progress_percent(player_id)
	
	if language == "ru":
		progress_label.text = "Чертежи: %d / %d (%.0f%%)" % [unlocked, total, percent]
	else:
		progress_label.text = "Blueprints: %d / %d (%.0f%%)" % [unlocked, total, percent]

func _input(event):
	if event.is_action_pressed("escape"):
		hide()
		get_viewport().set_input_as_handled()

func show_book():
	visible = true
	_update_progress()
	_select_category(current_category)

func hide_book():
	visible = false
