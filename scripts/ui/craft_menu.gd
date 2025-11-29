extends Control

signal recipe_crafted(recipe_id: String)

@onready var search_box = %SearchBox
@onready var close_button = %CloseButton
@onready var category_list = %CategoryList
@onready var recipe_grid = %RecipeGrid
@onready var recipe_details = %RecipeDetails
@onready var recipe_name = %RecipeName
@onready var ingredients_label = %Ingredients
@onready var craft_button = %CraftButton

var inventory = null
var craft_system = null
var selected_recipe: String = ""
var current_category: String = ""
var category_buttons := {}

const CATEGORY_NAMES := {
	"tools": "Инструменты",
	"weapons": "Оружие",
	"armor": "Броня",
	"building": "Строительство",
	"crafting": "Станки",
	"food": "Еда",
	"medical": "Медицина",
	"ammo": "Боеприпасы",
	"misc": "Разное"
}

const CATEGORY_ICONS := {
	"tools": "🔧",
	"weapons": "⚔️",
	"armor": "🛡️",
	"building": "🏠",
	"crafting": "⚙️",
	"food": "🍖",
	"medical": "💊",
	"ammo": "🎯",
	"misc": "📦"
}

func _ready():
	hide()
	
	inventory = get_node_or_null("/root/Inventory")
	craft_system = get_node_or_null("/root/CraftSystem")
	
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	if search_box:
		search_box.text_changed.connect(_on_search_changed)
	if craft_button:
		craft_button.pressed.connect(_on_craft_pressed)
	
	visibility_changed.connect(_on_visibility_changed)
	
	_create_categories()

func _create_categories():
	for child in category_list.get_children():
		child.queue_free()
	category_buttons.clear()
	
	for cat_id in CATEGORY_NAMES.keys():
		var btn = Button.new()
		btn.text = CATEGORY_ICONS.get(cat_id, "•") + " " + CATEGORY_NAMES[cat_id]
		btn.toggle_mode = true
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(140, 35)
		btn.pressed.connect(_on_category_selected.bind(cat_id))
		category_list.add_child(btn)
		category_buttons[cat_id] = btn
	
	if CATEGORY_NAMES.size() > 0:
		var first_cat = CATEGORY_NAMES.keys()[0]
		_on_category_selected(first_cat)

func _on_category_selected(category: String):
	current_category = category
	
	for cat_id in category_buttons:
		category_buttons[cat_id].button_pressed = (cat_id == category)
	
	_refresh_recipes()

func _on_search_changed(text: String):
	_refresh_recipes(text)

func _refresh_recipes(search_filter: String = ""):
	for child in recipe_grid.get_children():
		child.queue_free()
	
	if not craft_system:
		return
	
	var recipes = craft_system.get_recipes_by_category(current_category)
	
	for recipe_id in recipes:
		var recipe = craft_system.get_recipe(recipe_id)
		if recipe == null:
			continue
		
		var result_name = recipe.get("result_name", recipe_id)
		
		if search_filter.length() > 0:
			if not result_name.to_lower().contains(search_filter.to_lower()):
				continue
		
		var btn = _create_recipe_button(recipe_id, recipe)
		recipe_grid.add_child(btn)

func _create_recipe_button(recipe_id: String, recipe: Dictionary) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(100, 80)
	btn.toggle_mode = true
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn.add_child(vbox)
	
	var icon = Label.new()
	icon.text = recipe.get("icon", "📦")
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 28)
	vbox.add_child(icon)
	
	var name_label = Label.new()
	var display_name = recipe.get("result_name", recipe_id)
	if display_name.length() > 10:
		display_name = display_name.substr(0, 9) + "."
	name_label.text = display_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(name_label)
	
	var can_craft = _can_craft_recipe(recipe)
	if not can_craft:
		btn.modulate = Color(0.6, 0.6, 0.6, 0.8)
	
	btn.pressed.connect(_on_recipe_selected.bind(recipe_id))
	
	return btn

func _on_recipe_selected(recipe_id: String):
	selected_recipe = recipe_id
	_update_recipe_details()

func _update_recipe_details():
	if selected_recipe.is_empty() or not craft_system:
		recipe_name.text = "Выберите рецепт"
		ingredients_label.text = ""
		craft_button.disabled = true
		return
	
	var recipe = craft_system.get_recipe(selected_recipe)
	if recipe == null:
		return
	
	recipe_name.text = recipe.get("icon", "📦") + " " + recipe.get("result_name", selected_recipe)
	
	var ingredients_text = "Требуется:\n"
	var ingredients = recipe.get("ingredients", {})
	for item_id in ingredients:
		var count = ingredients[item_id]
		var item_name = item_id
		if inventory:
			var info = inventory.get_item_info(item_id)
			if info:
				item_name = info.get("name", item_id)
		
		var have = 0
		if inventory:
			have = inventory.count_item(item_id)
		
		var color = "green" if have >= count else "red"
		ingredients_text += "  • %s: %d/%d\n" % [item_name, have, count]
	
	if recipe.has("workbench"):
		ingredients_text += "\nТребуется: " + recipe["workbench"]
	
	ingredients_label.text = ingredients_text
	
	craft_button.disabled = not _can_craft_recipe(recipe)

func _can_craft_recipe(recipe: Dictionary) -> bool:
	if not inventory:
		return false
	
	var ingredients = recipe.get("ingredients", {})
	for item_id in ingredients:
		var need = ingredients[item_id]
		var have = inventory.count_item(item_id)
		if have < need:
			return false
	
	return true

func _on_craft_pressed():
	if selected_recipe.is_empty() or not craft_system:
		return
	
	var success = craft_system.craft(selected_recipe, inventory)
	if success:
		emit_signal("recipe_crafted", selected_recipe)
		_update_recipe_details()
		_refresh_recipes()
		
		var notif = get_node_or_null("/root/NotificationSystem")
		if notif:
			var recipe = craft_system.get_recipe(selected_recipe)
			var name = recipe.get("result_name", selected_recipe) if recipe else selected_recipe
			notif.notify_success("Создано: " + name)
		
		var vfx = get_node_or_null("/root/VFXManager")
		var audio = get_node_or_null("/root/AudioManager")
		if audio:
			audio.play_ui_sound("craft")

func _on_close_pressed():
	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_visibility_changed():
	if visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		_refresh_recipes()
		_update_recipe_details()

func _input(event):
	if not visible:
		return
	
	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
