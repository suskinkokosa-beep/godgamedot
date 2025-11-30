extends StaticBody3D
class_name WorkbenchProp

signal crafting_started(recipe)
signal crafting_completed(item)
signal workbench_upgraded(new_level)

@export var prop_name: String = "Верстак"
@export var workbench_level: int = 1
@export var workbench_type: String = "general"
@export var is_destructible: bool = true
@export var health: float = 100.0

var current_health: float
var is_in_use: bool = false
var current_user = null
var crafting_queue: Array = []

var workbench_types := {
	"general": {
		"name": "Общий верстак",
		"categories": ["tools", "basic", "building"]
	},
	"smithing": {
		"name": "Кузница",
		"categories": ["weapons", "armor", "metal"]
	},
	"alchemy": {
		"name": "Алхимический стол",
		"categories": ["potions", "medicine", "magic"]
	},
	"cooking": {
		"name": "Кухонный стол",
		"categories": ["food", "drinks"]
	},
	"tailoring": {
		"name": "Швейный стол",
		"categories": ["clothing", "bags", "cloth"]
	}
}

func _ready():
	current_health = health
	add_to_group("interactables")
	add_to_group("props")
	add_to_group("workbenches")

func interact(player) -> bool:
	if is_in_use and current_user != player:
		var notif = get_node_or_null("/root/NotificationSystem")
		if notif:
			notif.show_notification("Верстак занят", "warning")
		return false
	
	is_in_use = true
	current_user = player
	
	var craft_sys = get_node_or_null("/root/CraftSystem")
	if craft_sys and craft_sys.has_method("open_workbench"):
		craft_sys.open_workbench(self)
		return true
	
	return false

func close_workbench():
	is_in_use = false
	current_user = null

func can_craft_recipe(recipe_id: String) -> bool:
	var craft_sys = get_node_or_null("/root/CraftSystem")
	if not craft_sys:
		return false
	
	var recipe = craft_sys.get_recipe(recipe_id)
	if not recipe:
		return false
	
	if recipe.get("required_level", 1) > workbench_level:
		return false
	
	var wb_data = workbench_types.get(workbench_type, {})
	var categories = wb_data.get("categories", [])
	var recipe_category = recipe.get("category", "basic")
	
	if workbench_type != "general" and recipe_category not in categories:
		return false
	
	return true

func get_available_recipes() -> Array:
	var craft_sys = get_node_or_null("/root/CraftSystem")
	if not craft_sys:
		return []
	
	var all_recipes = craft_sys.get_all_recipes()
	var available = []
	
	for recipe_id in all_recipes:
		if can_craft_recipe(recipe_id):
			available.append(recipe_id)
	
	return available

func start_crafting(recipe_id: String, player) -> bool:
	if not can_craft_recipe(recipe_id):
		return false
	
	var craft_sys = get_node_or_null("/root/CraftSystem")
	if craft_sys and craft_sys.has_method("start_craft"):
		var result = craft_sys.start_craft(recipe_id, player)
		if result:
			emit_signal("crafting_started", recipe_id)
		return result
	
	return false

func upgrade(new_level: int):
	if new_level > workbench_level:
		workbench_level = new_level
		emit_signal("workbench_upgraded", new_level)
		
		var notif = get_node_or_null("/root/NotificationSystem")
		if notif:
			notif.show_notification("Верстак улучшен до уровня " + str(new_level), "success")

func take_damage(amount: float, source = null):
	if not is_destructible:
		return
	
	current_health -= amount
	
	if current_health <= 0:
		_die()

func _die():
	var vfx = get_node_or_null("/root/VFXManager")
	if vfx and vfx.has_method("spawn_destruction_effect"):
		vfx.spawn_destruction_effect(global_position)
	
	queue_free()

func get_display_name() -> String:
	var level_suffix = " (Ур. " + str(workbench_level) + ")"
	return prop_name + level_suffix

func get_interaction_hint() -> String:
	return "Нажмите E для крафта"

func save_data() -> Dictionary:
	return {
		"prop_name": prop_name,
		"workbench_level": workbench_level,
		"workbench_type": workbench_type,
		"current_health": current_health,
		"position": global_position
	}

func load_data(data: Dictionary):
	if data.has("workbench_level"):
		workbench_level = data.workbench_level
	if data.has("current_health"):
		current_health = data.current_health
