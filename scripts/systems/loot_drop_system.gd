extends Node

signal loot_spawned(item_id: String, position: Vector3)
signal loot_collected(item_id: String, collector_id: int)

var active_drops := []
var drop_lifetime := 300.0
var max_active_drops := 50
var collection_range := 2.5

var rarity_colors := {
	"common": Color(0.8, 0.8, 0.8),
	"uncommon": Color(0.3, 0.9, 0.3),
	"rare": Color(0.3, 0.5, 1.0),
	"epic": Color(0.7, 0.3, 0.9),
	"legendary": Color(1.0, 0.6, 0.1)
}

var rarity_glow_intensity := {
	"common": 0.0,
	"uncommon": 0.5,
	"rare": 1.0,
	"epic": 1.5,
	"legendary": 2.0
}

func _process(delta):
	_update_drops(delta)

func _update_drops(delta):
	var expired := []
	for drop in active_drops:
		if not is_instance_valid(drop):
			expired.append(drop)
			continue
		
		drop["lifetime"] -= delta
		if drop["lifetime"] <= 0:
			expired.append(drop)
			continue
		
		if drop.has("node") and is_instance_valid(drop["node"]):
			_animate_drop(drop, delta)
	
	for drop in expired:
		_remove_drop(drop)

func _animate_drop(drop: Dictionary, delta: float):
	var node = drop["node"]
	if not is_instance_valid(node):
		return
	
	drop["bob_time"] = drop.get("bob_time", 0.0) + delta * 2.0
	var bob_offset = sin(drop["bob_time"]) * 0.1
	
	if node is Node3D:
		node.position.y = drop["base_y"] + bob_offset
		node.rotation.y += delta * 0.5
	
	drop["spin_time"] = drop.get("spin_time", 0.0) + delta

func spawn_loot(item_id: String, position: Vector3, count: int = 1, rarity: String = "common") -> Dictionary:
	if active_drops.size() >= max_active_drops:
		_remove_oldest_drop()
	
	var drop_data := {
		"item_id": item_id,
		"count": count,
		"rarity": rarity,
		"position": position,
		"base_y": position.y + 0.5,
		"lifetime": drop_lifetime,
		"bob_time": randf() * TAU,
		"spin_time": 0.0,
		"node": null
	}
	
	var drop_node = _create_drop_visual(item_id, position, rarity)
	if drop_node:
		drop_data["node"] = drop_node
	
	active_drops.append(drop_data)
	
	var audio = get_node_or_null("/root/AudioManager")
	if audio:
		audio.play_event_sound("loot_drop")
	
	var vfx = get_node_or_null("/root/VFXManager")
	if vfx and vfx.has_method("spawn_item_pickup_effect"):
		vfx.spawn_item_pickup_effect(position)
	
	emit_signal("loot_spawned", item_id, position)
	
	return drop_data

func _create_drop_visual(item_id: String, position: Vector3, rarity: String) -> Node3D:
	var root = get_tree().current_scene
	if not root:
		return null
	
	var drop_node = Node3D.new()
	drop_node.name = "LootDrop_" + item_id
	drop_node.position = position
	drop_node.position.y += 0.5
	
	var mesh_instance = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.3, 0.3, 0.3)
	mesh_instance.mesh = box
	
	var material = StandardMaterial3D.new()
	material.albedo_color = rarity_colors.get(rarity, Color.WHITE)
	material.emission_enabled = rarity_glow_intensity.get(rarity, 0.0) > 0
	if material.emission_enabled:
		material.emission = rarity_colors.get(rarity, Color.WHITE)
		material.emission_energy_multiplier = rarity_glow_intensity.get(rarity, 1.0)
	mesh_instance.material_override = material
	
	drop_node.add_child(mesh_instance)
	
	var area = Area3D.new()
	area.name = "PickupArea"
	var collision = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = collection_range
	collision.shape = sphere
	area.add_child(collision)
	area.body_entered.connect(_on_body_entered_drop.bind(drop_node))
	drop_node.add_child(area)
	
	root.add_child(drop_node)
	return drop_node

func _on_body_entered_drop(body: Node3D, drop_node: Node3D):
	if not body.is_in_group("players"):
		return
	
	for drop in active_drops:
		if drop.get("node") == drop_node:
			try_collect(drop, body)
			break

func try_collect(drop: Dictionary, collector: Node) -> bool:
	if not drop or not is_instance_valid(collector):
		return false
	
	var inv = get_node_or_null("/root/Inventory")
	if not inv:
		return false
	
	var item_id = drop.get("item_id", "")
	var count = drop.get("count", 1)
	
	if inv.has_method("add_item"):
		var added = inv.add_item(item_id, count)
		if added > 0:
			var audio = get_node_or_null("/root/AudioManager")
			if audio:
				audio.play_pickup_sound("resource")
			
			var notif = get_node_or_null("/root/NotificationSystem")
			if notif:
				notif.show_notification("+" + str(added) + " " + item_id, "pickup")
			
			var quest = get_node_or_null("/root/QuestSystem")
			if quest and quest.has_method("on_item_collected"):
				quest.on_item_collected(item_id, added)
			
			var collector_id = collector.get("net_id") if collector.get("net_id") else 0
			emit_signal("loot_collected", item_id, collector_id)
			
			_remove_drop(drop)
			return true
	
	return false

func _remove_drop(drop: Dictionary):
	if drop.has("node") and is_instance_valid(drop["node"]):
		drop["node"].queue_free()
	
	active_drops.erase(drop)

func _remove_oldest_drop():
	if active_drops.size() > 0:
		_remove_drop(active_drops[0])

func spawn_loot_table(loot_table: Array, position: Vector3, spread: float = 1.0):
	for loot in loot_table:
		var item_id = loot.get("id", "")
		var count = loot.get("count", 1)
		var chance = loot.get("chance", 1.0)
		var rarity = loot.get("rarity", "common")
		
		if randf() <= chance:
			var offset = Vector3(
				randf_range(-spread, spread),
				0,
				randf_range(-spread, spread)
			)
			spawn_loot(item_id, position + offset, count, rarity)

func spawn_enemy_loot(enemy_type: String, position: Vector3):
	var balance = get_node_or_null("/root/GameBalance")
	if balance and balance.has_method("get_mob_loot"):
		var loot_table = balance.get_mob_loot(enemy_type)
		spawn_loot_table(loot_table, position)
	else:
		var default_loot = [
			{"id": "bone", "count": randi_range(1, 2), "chance": 0.8, "rarity": "common"},
			{"id": "hide", "count": 1, "chance": 0.5, "rarity": "common"},
			{"id": "meat", "count": randi_range(1, 3), "chance": 0.7, "rarity": "common"}
		]
		spawn_loot_table(default_loot, position)

func clear_all_drops():
	for drop in active_drops.duplicate():
		_remove_drop(drop)
	active_drops.clear()

func get_drops_in_range(position: Vector3, range_dist: float) -> Array:
	var nearby := []
	for drop in active_drops:
		var drop_pos = drop.get("position", Vector3.ZERO)
		if drop_pos.distance_to(position) <= range_dist:
			nearby.append(drop)
	return nearby
