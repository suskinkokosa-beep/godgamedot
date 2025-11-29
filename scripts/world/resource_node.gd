extends StaticBody3D
class_name ResourceNode

signal depleted()
signal gathered(resource_type, amount, gatherer)

@export var resource_type := "wood"
@export var resource_amount := 100.0
@export var gather_amount := 10.0
@export var required_tool := ""
@export var respawn_time := 300.0
@export var quality := 1

var current_amount := 0.0
var is_depleted := false
var original_scale := Vector3.ONE

var resource_data := {
	"wood": {"xp_skill": "gathering", "xp_amount": 1.0, "weight": 1.0, "name_ru": "Дерево", "name_en": "Wood"},
	"log": {"xp_skill": "gathering", "xp_amount": 2.0, "weight": 3.0, "name_ru": "Бревно", "name_en": "Log"},
	"stick": {"xp_skill": "gathering", "xp_amount": 0.3, "weight": 0.2, "name_ru": "Палка", "name_en": "Stick"},
	"stone": {"xp_skill": "gathering", "xp_amount": 1.5, "weight": 2.0, "name_ru": "Камень", "name_en": "Stone"},
	"iron_ore": {"xp_skill": "mining", "xp_amount": 2.0, "weight": 3.0, "name_ru": "Железная руда", "name_en": "Iron Ore"},
	"copper_ore": {"xp_skill": "mining", "xp_amount": 2.0, "weight": 2.5, "name_ru": "Медная руда", "name_en": "Copper Ore"},
	"silver_ore": {"xp_skill": "mining", "xp_amount": 3.0, "weight": 2.0, "name_ru": "Серебряная руда", "name_en": "Silver Ore"},
	"gold_ore": {"xp_skill": "mining", "xp_amount": 4.0, "weight": 3.5, "name_ru": "Золотая руда", "name_en": "Gold Ore"},
	"titanium_ore": {"xp_skill": "mining", "xp_amount": 5.0, "weight": 4.0, "name_ru": "Титановая руда", "name_en": "Titanium Ore"},
	"flint": {"xp_skill": "gathering", "xp_amount": 0.5, "weight": 0.5, "name_ru": "Кремень", "name_en": "Flint"},
	"clay": {"xp_skill": "gathering", "xp_amount": 0.5, "weight": 1.5, "name_ru": "Глина", "name_en": "Clay"},
	"sand": {"xp_skill": "gathering", "xp_amount": 0.3, "weight": 1.5, "name_ru": "Песок", "name_en": "Sand"},
	"plant_fiber": {"xp_skill": "gathering", "xp_amount": 0.3, "weight": 0.2, "name_ru": "Растительное волокно", "name_en": "Plant Fiber"},
	"berries": {"xp_skill": "gathering", "xp_amount": 0.2, "weight": 0.1, "name_ru": "Ягоды", "name_en": "Berries"},
	"herbs": {"xp_skill": "gathering", "xp_amount": 0.5, "weight": 0.1, "name_ru": "Травы", "name_en": "Herbs"},
	"meat": {"xp_skill": "hunting", "xp_amount": 2.0, "weight": 1.0, "name_ru": "Мясо", "name_en": "Meat"},
	"hide": {"xp_skill": "hunting", "xp_amount": 1.5, "weight": 0.8, "name_ru": "Шкура", "name_en": "Hide"},
	"bone": {"xp_skill": "hunting", "xp_amount": 1.0, "weight": 0.5, "name_ru": "Кость", "name_en": "Bone"}
}

var tool_types := {
	"axe": ["stone_axe", "iron_axe", "steel_axe", "titanium_axe"],
	"pickaxe": ["stone_pickaxe", "iron_pickaxe", "steel_pickaxe", "titanium_pickaxe"],
	"shovel": ["stone_shovel", "iron_shovel", "steel_shovel"],
	"knife": ["stone_knife", "iron_knife", "steel_knife"],
	"hand": []
}

func _ready():
	current_amount = resource_amount
	original_scale = scale
	add_to_group("resources")
	add_to_group("interactable")

func gather(gatherer) -> Dictionary:
	if is_depleted:
		return {"success": false, "reason": "depleted"}
	
	var tool_check = _check_tool(gatherer)
	if not tool_check.has_tool:
		_show_notification(gatherer, "requires_tool", required_tool)
		return {"success": false, "reason": "no_tool", "required": required_tool}
	
	var tool_bonus = tool_check.bonus
	var amount = min(gather_amount * quality * tool_bonus, current_amount)
	current_amount -= amount
	
	var data = resource_data.get(resource_type, {"xp_skill": "gathering", "xp_amount": 1.0, "weight": 1.0})
	
	var inv = get_node_or_null("/root/Inventory")
	if inv and inv.has_method("add_item"):
		var added = inv.add_item(resource_type, int(amount), data.weight)
		if added:
			_show_notification(gatherer, "gathered", int(amount))
	
	var prog = get_node_or_null("/root/PlayerProgression")
	if prog and gatherer:
		var pid = 1
		if gatherer.has_method("get") and gatherer.get("net_id") != null:
			pid = gatherer.get("net_id")
		prog.add_skill_xp(pid, data.xp_skill, data.xp_amount * amount)
		prog.add_xp(pid, data.xp_amount * 0.5 * amount)
	
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		match resource_type:
			"wood", "log", "stick":
				audio.play_hit_sound("wood")
			"stone", "iron_ore", "copper_ore", "silver_ore", "gold_ore", "titanium_ore":
				audio.play_hit_sound("stone")
			_:
				audio.play_item_pickup()
	
	var vfx = get_node_or_null("/root/VFXManager")
	if vfx:
		vfx.spawn_item_pickup_effect(global_position + Vector3(0, 1, 0))
	
	_animate_hit()
	
	emit_signal("gathered", resource_type, amount, gatherer)
	
	if current_amount <= 0:
		_on_depleted()
	
	return {"success": true, "type": resource_type, "amount": int(amount), "remaining": current_amount}

func _check_tool(gatherer) -> Dictionary:
	if required_tool == "" or required_tool == "hand":
		return {"has_tool": true, "bonus": 1.0}
	
	var held_item = ""
	
	if gatherer and gatherer.has_method("get_node_or_null"):
		var arms = gatherer.get_node_or_null("Camera3D/FirstPersonArms")
		if arms and arms.has_method("get_held_item_id"):
			held_item = arms.get_held_item_id()
	
	if held_item == "":
		var inv = get_node_or_null("/root/Inventory")
		if inv and inv.has_method("get_selected_hotbar_item"):
			var item = inv.get_selected_hotbar_item()
			if item and item is Dictionary:
				held_item = item.get("id", "")
		elif inv and inv.has_method("get_selected_hotbar_slot") and inv.has_method("get_hotbar_slot"):
			var slot = inv.get_selected_hotbar_slot()
			var item = inv.get_hotbar_slot(slot)
			if item and item is Dictionary:
				held_item = item.get("id", "")
	
	if held_item == "":
		return {"has_tool": false, "bonus": 0.0}
	
	var valid_tools = tool_types.get(required_tool, [])
	
	if held_item in valid_tools or held_item.contains(required_tool):
		var bonus = 1.0
		if held_item.contains("stone"):
			bonus = 1.0
		elif held_item.contains("iron"):
			bonus = 1.5
		elif held_item.contains("steel"):
			bonus = 2.0
		elif held_item.contains("titanium"):
			bonus = 2.5
		return {"has_tool": true, "bonus": bonus}
	
	return {"has_tool": false, "bonus": 0.0}

func _show_notification(gatherer, type: String, value = null):
	var notif = get_node_or_null("/root/NotificationSystem")
	if not notif:
		return
	
	var lang = "ru"
	var settings = get_node_or_null("/root/SettingsManager")
	if settings:
		lang = settings.get_current_language()
	
	match type:
		"gathered":
			var data = resource_data.get(resource_type, {})
			var item_name = data.get("name_" + lang, resource_type)
			if lang == "ru":
				notif.show_notification("+%d %s" % [value, item_name], "item")
			else:
				notif.show_notification("+%d %s" % [value, item_name], "item")
		"requires_tool":
			if lang == "ru":
				var tool_names = {"axe": "топор", "pickaxe": "кирка", "shovel": "лопата", "knife": "нож"}
				notif.show_notification("Требуется: %s" % tool_names.get(value, value), "warning")
			else:
				notif.show_notification("Required: %s" % value, "warning")

func _animate_hit():
	var tween = create_tween()
	tween.tween_property(self, "scale", original_scale * 0.9, 0.1)
	tween.tween_property(self, "scale", original_scale, 0.1)

func on_interact(player):
	return gather(player)

func apply_damage(amount: float, source):
	return gather(source)

func _on_depleted():
	is_depleted = true
	
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3.ZERO, 0.3)
	tween.tween_callback(Callable(self, "_hide_after_deplete"))
	
	emit_signal("depleted")

func _hide_after_deplete():
	hide()
	
	var timer = get_tree().create_timer(respawn_time)
	timer.connect("timeout", Callable(self, "_respawn"))

func _respawn():
	is_depleted = false
	current_amount = resource_amount
	scale = original_scale
	show()

func get_info() -> Dictionary:
	var data = resource_data.get(resource_type, {})
	return {
		"type": resource_type,
		"name_ru": data.get("name_ru", resource_type),
		"name_en": data.get("name_en", resource_type),
		"amount": current_amount,
		"max_amount": resource_amount,
		"quality": quality,
		"depleted": is_depleted,
		"required_tool": required_tool
	}

func get_display_name() -> String:
	var lang = "ru"
	var settings = get_node_or_null("/root/SettingsManager")
	if settings:
		lang = settings.get_current_language()
	
	var data = resource_data.get(resource_type, {})
	return data.get("name_" + lang, resource_type)

func get_remaining_percent() -> float:
	if resource_amount <= 0:
		return 0.0
	return (current_amount / resource_amount) * 100.0
