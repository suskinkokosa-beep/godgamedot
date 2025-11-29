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

var resource_data := {
	"wood": {"xp_skill": "gathering", "xp_amount": 1.0, "weight": 1.0},
	"log": {"xp_skill": "gathering", "xp_amount": 2.0, "weight": 3.0},
	"stick": {"xp_skill": "gathering", "xp_amount": 0.3, "weight": 0.2},
	"stone": {"xp_skill": "gathering", "xp_amount": 1.5, "weight": 2.0},
	"iron_ore": {"xp_skill": "gathering", "xp_amount": 2.0, "weight": 3.0},
	"copper_ore": {"xp_skill": "gathering", "xp_amount": 2.0, "weight": 2.5},
	"silver_ore": {"xp_skill": "gathering", "xp_amount": 3.0, "weight": 2.0},
	"gold_ore": {"xp_skill": "gathering", "xp_amount": 4.0, "weight": 3.5},
	"titanium_ore": {"xp_skill": "gathering", "xp_amount": 5.0, "weight": 4.0},
	"flint": {"xp_skill": "gathering", "xp_amount": 0.5, "weight": 0.5},
	"clay": {"xp_skill": "gathering", "xp_amount": 0.5, "weight": 1.5},
	"sand": {"xp_skill": "gathering", "xp_amount": 0.3, "weight": 1.5},
	"plant_fiber": {"xp_skill": "gathering", "xp_amount": 0.3, "weight": 0.2},
	"berries": {"xp_skill": "gathering", "xp_amount": 0.2, "weight": 0.1},
	"herbs": {"xp_skill": "gathering", "xp_amount": 0.5, "weight": 0.1},
	"meat": {"xp_skill": "hunting", "xp_amount": 2.0, "weight": 1.0},
	"hide": {"xp_skill": "hunting", "xp_amount": 1.5, "weight": 0.8},
	"bone": {"xp_skill": "hunting", "xp_amount": 1.0, "weight": 0.5}
}

func _ready():
	current_amount = resource_amount
	add_to_group("resources")

func gather(gatherer) -> Dictionary:
	if is_depleted:
		return {"success": false, "reason": "depleted"}
	
	if required_tool != "":
		var has_tool = false
		var inv = gatherer.get("inventory") if gatherer else null
		if inv and inv.has_method("has_item"):
			has_tool = inv.has_item(required_tool, 1)
		if not has_tool:
			return {"success": false, "reason": "no_tool", "required": required_tool}
	
	var amount = min(gather_amount * quality, current_amount)
	current_amount -= amount
	
	var data = resource_data.get(resource_type, {"xp_skill": "gathering", "xp_amount": 1.0, "weight": 1.0})
	
	var inv = get_node_or_null("/root/Inventory")
	if inv and inv.has_method("add_item"):
		inv.add_item(resource_type, int(amount), data.weight)
	
	var prog = get_node_or_null("/root/PlayerProgression")
	if prog and gatherer:
		var pid = gatherer.get("net_id") if gatherer.has_method("get") and gatherer.get("net_id") else 1
		prog.add_skill_xp(pid, data.xp_skill, data.xp_amount * amount)
		prog.add_xp(pid, data.xp_amount * 0.5 * amount)
	
	emit_signal("gathered", resource_type, amount, gatherer)
	
	if current_amount <= 0:
		_on_depleted()
	
	return {"success": true, "type": resource_type, "amount": int(amount), "remaining": current_amount}

func on_interact(player):
	return gather(player)

func apply_damage(amount: float, source):
	return gather(source)

func _on_depleted():
	is_depleted = true
	hide()
	emit_signal("depleted")
	var t = get_tree().create_timer(respawn_time)
	t.connect("timeout", Callable(self, "_respawn"))

func _respawn():
	is_depleted = false
	current_amount = resource_amount
	show()

func get_info() -> Dictionary:
	return {
		"type": resource_type,
		"amount": current_amount,
		"max_amount": resource_amount,
		"quality": quality,
		"depleted": is_depleted,
		"required_tool": required_tool
	}
