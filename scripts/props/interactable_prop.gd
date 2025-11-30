extends StaticBody3D
class_name InteractableProp

signal interacted(player)
signal destroyed()
signal inventory_changed()

@export var prop_name: String = "Предмет"
@export var prop_type: String = "generic"
@export var max_items: int = 12
@export var is_destructible: bool = true
@export var health: float = 50.0
@export var loot_table: String = ""

var current_health: float
var inventory: Array = []
var is_open: bool = false

func _ready():
	current_health = health
	add_to_group("interactables")
	add_to_group("props")
	
	if prop_type == "container":
		add_to_group("containers")
		_generate_loot()

func _generate_loot():
	if loot_table.is_empty():
		return
	
	var loot_sys = get_node_or_null("/root/LootSystem")
	if loot_sys and loot_sys.has_method("generate_loot"):
		inventory = loot_sys.generate_loot(loot_table)

func interact(player) -> bool:
	emit_signal("interacted", player)
	
	match prop_type:
		"container":
			return _open_container(player)
		"resource":
			return _gather_resource(player)
		_:
			return _generic_interact(player)

func _open_container(player) -> bool:
	is_open = !is_open
	
	if is_open:
		var inv_ui = get_node_or_null("/root/Inventory")
		if inv_ui and inv_ui.has_method("open_container"):
			inv_ui.open_container(self)
		return true
	else:
		var inv_ui = get_node_or_null("/root/Inventory")
		if inv_ui and inv_ui.has_method("close_container"):
			inv_ui.close_container()
		return true
	
	return false

func _gather_resource(player) -> bool:
	if inventory.size() > 0:
		var item = inventory.pop_back()
		var inv = get_node_or_null("/root/Inventory")
		if inv and inv.has_method("add_item"):
			inv.add_item(item)
			emit_signal("inventory_changed")
			return true
	return false

func _generic_interact(player) -> bool:
	return true

func add_item(item: Dictionary) -> bool:
	if inventory.size() >= max_items:
		return false
	inventory.append(item)
	emit_signal("inventory_changed")
	return true

func remove_item(index: int) -> Dictionary:
	if index < 0 or index >= inventory.size():
		return {}
	var item = inventory[index]
	inventory.remove_at(index)
	emit_signal("inventory_changed")
	return item

func take_damage(amount: float, source = null):
	if not is_destructible:
		return
	
	current_health -= amount
	
	var vfx = get_node_or_null("/root/VFXManager")
	if vfx and vfx.has_method("spawn_hit_effect"):
		vfx.spawn_hit_effect(global_position + Vector3(0, 0.5, 0))
	
	if current_health <= 0:
		_die()

func _die():
	emit_signal("destroyed")
	
	for item in inventory:
		var loot_drop = get_node_or_null("/root/LootDropSystem")
		if loot_drop and loot_drop.has_method("spawn_drop"):
			var offset = Vector3(randf_range(-0.5, 0.5), 0.5, randf_range(-0.5, 0.5))
			loot_drop.spawn_drop(item, global_position + offset)
	
	var vfx = get_node_or_null("/root/VFXManager")
	if vfx and vfx.has_method("spawn_destruction_effect"):
		vfx.spawn_destruction_effect(global_position)
	
	queue_free()

func get_display_name() -> String:
	return prop_name

func get_interaction_hint() -> String:
	match prop_type:
		"container":
			return "Нажмите E чтобы открыть " + prop_name
		"resource":
			return "Нажмите E чтобы собрать"
		_:
			return "Нажмите E для взаимодействия"

func save_data() -> Dictionary:
	return {
		"prop_name": prop_name,
		"prop_type": prop_type,
		"current_health": current_health,
		"inventory": inventory,
		"position": global_position
	}

func load_data(data: Dictionary):
	if data.has("current_health"):
		current_health = data.current_health
	if data.has("inventory"):
		inventory = data.inventory
