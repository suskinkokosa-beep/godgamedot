extends Node

signal animal_spawned(animal_type, position)
signal animal_killed(animal_type, killer, position)
signal trophy_collected(trophy_type, quality)
signal hunting_skill_increased(new_level)

enum AnimalType {
	RABBIT,
	DEER,
	BOAR,
	WOLF,
	BEAR,
	FOX,
	ELK,
	BISON
}

enum TrophyQuality {
	POOR,
	COMMON,
	GOOD,
	EXCELLENT,
	LEGENDARY
}

var animals := {
	AnimalType.RABBIT: {
		"name": "Заяц",
		"health": 15,
		"speed": 8.0,
		"damage": 0,
		"flee_distance": 15.0,
		"xp_reward": 5,
		"drops": [
			{"item": "rabbit_meat", "min": 1, "max": 2, "chance": 1.0},
			{"item": "rabbit_fur", "min": 1, "max": 1, "chance": 0.8},
			{"item": "rabbit_foot", "min": 1, "max": 1, "chance": 0.1}
		],
		"trophy": {"item": "rabbit_trophy", "chance": 0.05}
	},
	AnimalType.DEER: {
		"name": "Олень",
		"health": 50,
		"speed": 7.0,
		"damage": 5,
		"flee_distance": 20.0,
		"xp_reward": 15,
		"drops": [
			{"item": "venison", "min": 2, "max": 4, "chance": 1.0},
			{"item": "deer_hide", "min": 1, "max": 2, "chance": 0.9},
			{"item": "antlers", "min": 1, "max": 2, "chance": 0.4}
		],
		"trophy": {"item": "deer_trophy", "chance": 0.08}
	},
	AnimalType.BOAR: {
		"name": "Кабан",
		"health": 80,
		"speed": 5.5,
		"damage": 15,
		"flee_distance": 8.0,
		"aggressive": true,
		"xp_reward": 25,
		"drops": [
			{"item": "pork", "min": 3, "max": 5, "chance": 1.0},
			{"item": "boar_hide", "min": 1, "max": 2, "chance": 0.85},
			{"item": "boar_tusk", "min": 0, "max": 2, "chance": 0.5}
		],
		"trophy": {"item": "boar_trophy", "chance": 0.1}
	},
	AnimalType.WOLF: {
		"name": "Волк",
		"health": 60,
		"speed": 7.5,
		"damage": 20,
		"flee_distance": 0.0,
		"aggressive": true,
		"pack_animal": true,
		"xp_reward": 35,
		"drops": [
			{"item": "wolf_meat", "min": 1, "max": 3, "chance": 0.8},
			{"item": "wolf_pelt", "min": 1, "max": 1, "chance": 0.9},
			{"item": "wolf_fang", "min": 1, "max": 2, "chance": 0.6}
		],
		"trophy": {"item": "wolf_trophy", "chance": 0.12}
	},
	AnimalType.BEAR: {
		"name": "Медведь",
		"health": 200,
		"speed": 5.0,
		"damage": 40,
		"flee_distance": 0.0,
		"aggressive": true,
		"xp_reward": 80,
		"drops": [
			{"item": "bear_meat", "min": 4, "max": 8, "chance": 1.0},
			{"item": "bear_pelt", "min": 1, "max": 2, "chance": 0.95},
			{"item": "bear_claw", "min": 2, "max": 4, "chance": 0.7},
			{"item": "bear_fat", "min": 1, "max": 3, "chance": 0.6}
		],
		"trophy": {"item": "bear_trophy", "chance": 0.15}
	},
	AnimalType.FOX: {
		"name": "Лиса",
		"health": 30,
		"speed": 8.5,
		"damage": 5,
		"flee_distance": 18.0,
		"xp_reward": 12,
		"drops": [
			{"item": "fox_meat", "min": 1, "max": 2, "chance": 0.7},
			{"item": "fox_pelt", "min": 1, "max": 1, "chance": 0.95}
		],
		"trophy": {"item": "fox_trophy", "chance": 0.08}
	},
	AnimalType.ELK: {
		"name": "Лось",
		"health": 120,
		"speed": 6.0,
		"damage": 25,
		"flee_distance": 15.0,
		"xp_reward": 45,
		"drops": [
			{"item": "elk_meat", "min": 4, "max": 7, "chance": 1.0},
			{"item": "elk_hide", "min": 1, "max": 2, "chance": 0.9},
			{"item": "elk_antlers", "min": 1, "max": 2, "chance": 0.6}
		],
		"trophy": {"item": "elk_trophy", "chance": 0.12}
	},
	AnimalType.BISON: {
		"name": "Бизон",
		"health": 250,
		"speed": 4.5,
		"damage": 35,
		"flee_distance": 10.0,
		"herd_animal": true,
		"xp_reward": 60,
		"drops": [
			{"item": "bison_meat", "min": 6, "max": 10, "chance": 1.0},
			{"item": "bison_hide", "min": 2, "max": 3, "chance": 0.95},
			{"item": "bison_horn", "min": 1, "max": 2, "chance": 0.5}
		],
		"trophy": {"item": "bison_trophy", "chance": 0.1}
	}
}

var hunting_grounds := {}
var active_animals := []
var player_hunting_skill := 0
var player_hunting_xp := 0
var xp_per_level := 100

var spawn_timer := 0.0
var spawn_interval := 30.0

func _ready():
	_init_hunting_grounds()

func _process(delta):
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		_try_spawn_animals()

func _init_hunting_grounds():
	hunting_grounds = {
		"forest": {
			"position": Vector3(100, 0, 100),
			"radius": 80.0,
			"animal_types": [AnimalType.RABBIT, AnimalType.DEER, AnimalType.BOAR, AnimalType.WOLF, AnimalType.FOX],
			"max_animals": 12,
			"spawn_weights": {AnimalType.RABBIT: 30, AnimalType.DEER: 25, AnimalType.FOX: 20, AnimalType.BOAR: 15, AnimalType.WOLF: 10}
		},
		"plains": {
			"position": Vector3(-100, 0, 50),
			"radius": 100.0,
			"animal_types": [AnimalType.RABBIT, AnimalType.DEER, AnimalType.BISON],
			"max_animals": 15,
			"spawn_weights": {AnimalType.RABBIT: 25, AnimalType.DEER: 35, AnimalType.BISON: 40}
		},
		"mountains": {
			"position": Vector3(50, 20, -100),
			"radius": 60.0,
			"animal_types": [AnimalType.BEAR, AnimalType.ELK, AnimalType.WOLF],
			"max_animals": 8,
			"spawn_weights": {AnimalType.ELK: 40, AnimalType.WOLF: 35, AnimalType.BEAR: 25}
		}
	}

func _try_spawn_animals():
	for ground_id in hunting_grounds:
		var ground = hunting_grounds[ground_id]
		var current_count = _count_animals_in_area(ground.position, ground.radius)
		
		if current_count < ground.max_animals:
			var animal_type = _weighted_random_animal(ground.spawn_weights)
			var spawn_pos = _random_position_in_circle(ground.position, ground.radius)
			spawn_animal(animal_type, spawn_pos)

func _count_animals_in_area(center: Vector3, radius: float) -> int:
	var count = 0
	for animal_data in active_animals:
		if animal_data.node and is_instance_valid(animal_data.node):
			var dist = animal_data.node.global_position.distance_to(center)
			if dist <= radius:
				count += 1
	return count

func _weighted_random_animal(weights: Dictionary) -> int:
	var total = 0
	for w in weights.values():
		total += w
	
	var roll = randi() % total
	var cumulative = 0
	
	for animal_type in weights:
		cumulative += weights[animal_type]
		if roll < cumulative:
			return animal_type
	
	return weights.keys()[0]

func _random_position_in_circle(center: Vector3, radius: float) -> Vector3:
	var angle = randf() * TAU
	var dist = randf() * radius
	return Vector3(
		center.x + cos(angle) * dist,
		center.y,
		center.z + sin(angle) * dist
	)

func spawn_animal(animal_type: int, position: Vector3) -> Node3D:
	var animal_data = animals.get(animal_type)
	if not animal_data:
		return null
	
	var animal_node = CharacterBody3D.new()
	animal_node.name = animal_data.name + "_" + str(randi())
	animal_node.global_position = position
	
	var collision = CollisionShape3D.new()
	var shape = CapsuleShape3D.new()
	shape.radius = 0.5
	shape.height = 1.0
	collision.shape = shape
	animal_node.add_child(collision)
	
	var mesh_instance = MeshInstance3D.new()
	var mesh = CapsuleMesh.new()
	mesh.radius = 0.4
	mesh.height = 0.8
	mesh_instance.mesh = mesh
	
	var mat = StandardMaterial3D.new()
	match animal_type:
		AnimalType.RABBIT: mat.albedo_color = Color(0.7, 0.6, 0.5)
		AnimalType.DEER: mat.albedo_color = Color(0.6, 0.45, 0.3)
		AnimalType.BOAR: mat.albedo_color = Color(0.35, 0.25, 0.2)
		AnimalType.WOLF: mat.albedo_color = Color(0.5, 0.5, 0.55)
		AnimalType.BEAR: mat.albedo_color = Color(0.3, 0.2, 0.15)
		AnimalType.FOX: mat.albedo_color = Color(0.8, 0.4, 0.2)
		AnimalType.ELK: mat.albedo_color = Color(0.5, 0.4, 0.3)
		AnimalType.BISON: mat.albedo_color = Color(0.25, 0.2, 0.15)
	mesh_instance.material_override = mat
	animal_node.add_child(mesh_instance)
	
	var script = load("res://scripts/entities/animal_ai.gd")
	if script:
		animal_node.set_script(script)
		animal_node.animal_type = animal_type
		animal_node.max_health = animal_data.health
		animal_node.current_health = animal_data.health
		animal_node.move_speed = animal_data.speed
		animal_node.damage = animal_data.damage
		animal_node.flee_distance = animal_data.flee_distance
		animal_node.is_aggressive = animal_data.get("aggressive", false)
	
	animal_node.add_to_group("animals")
	animal_node.add_to_group("huntable")
	
	get_tree().current_scene.add_child(animal_node)
	
	active_animals.append({
		"node": animal_node,
		"type": animal_type,
		"spawn_time": Time.get_unix_time_from_system()
	})
	
	emit_signal("animal_spawned", animal_type, position)
	return animal_node

func on_animal_killed(animal_node: Node, killer: Node):
	var animal_type = -1
	
	for i in range(active_animals.size()):
		if active_animals[i].node == animal_node:
			animal_type = active_animals[i].type
			active_animals.remove_at(i)
			break
	
	if animal_type < 0:
		return
	
	var animal_data = animals.get(animal_type)
	if not animal_data:
		return
	
	var position = animal_node.global_position
	emit_signal("animal_killed", animal_type, killer, position)
	
	_add_hunting_xp(animal_data.xp_reward)
	_generate_loot(animal_data, position, killer)

func _add_hunting_xp(amount: int):
	player_hunting_xp += amount
	
	var new_level = player_hunting_xp / xp_per_level
	if new_level > player_hunting_skill:
		player_hunting_skill = new_level
		emit_signal("hunting_skill_increased", player_hunting_skill)
		
		var notif = get_node_or_null("/root/NotificationSystem")
		if notif:
			notif.show_notification("Навык охоты повышен до %d!" % player_hunting_skill, "success")

func _generate_loot(animal_data: Dictionary, position: Vector3, killer: Node):
	var loot_items = []
	var skill_bonus = 1.0 + (player_hunting_skill * 0.1)
	
	for drop in animal_data.drops:
		var roll = randf()
		if roll <= drop.chance * skill_bonus:
			var quantity = randi_range(drop.min, drop.max)
			if quantity > 0:
				loot_items.append({
					"item_id": drop.item,
					"quantity": quantity
				})
	
	var trophy = animal_data.get("trophy", {})
	if not trophy.is_empty():
		var trophy_chance = trophy.chance * (1.0 + player_hunting_skill * 0.05)
		if randf() <= trophy_chance:
			var quality = _determine_trophy_quality()
			loot_items.append({
				"item_id": trophy.item,
				"quantity": 1,
				"quality": quality
			})
			emit_signal("trophy_collected", trophy.item, quality)
	
	_spawn_loot_drops(loot_items, position)
	
	if killer and killer.has_method("receive_loot"):
		killer.receive_loot(loot_items)
	else:
		var inv = get_node_or_null("/root/Inventory")
		if inv:
			for loot in loot_items:
				inv.add_item(loot.item_id, loot.quantity, 1.0)

func _determine_trophy_quality() -> int:
	var roll = randf()
	var skill_mod = player_hunting_skill * 0.02
	
	if roll < 0.01 + skill_mod:
		return TrophyQuality.LEGENDARY
	elif roll < 0.05 + skill_mod:
		return TrophyQuality.EXCELLENT
	elif roll < 0.2 + skill_mod:
		return TrophyQuality.GOOD
	elif roll < 0.5:
		return TrophyQuality.COMMON
	else:
		return TrophyQuality.POOR

func _spawn_loot_drops(items: Array, position: Vector3):
	for item in items:
		var loot_drop = Node3D.new()
		loot_drop.name = "LootDrop_" + item.item_id
		loot_drop.global_position = position + Vector3(randf_range(-0.5, 0.5), 0.2, randf_range(-0.5, 0.5))
		
		var mesh = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(0.3, 0.3, 0.3)
		mesh.mesh = box
		
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.8, 0.7, 0.4)
		mat.emission_enabled = true
		mat.emission = Color(0.4, 0.35, 0.2)
		mesh.material_override = mat
		loot_drop.add_child(mesh)
		
		var area = Area3D.new()
		var coll = CollisionShape3D.new()
		var shape = SphereShape3D.new()
		shape.radius = 0.5
		coll.shape = shape
		area.add_child(coll)
		loot_drop.add_child(area)
		
		loot_drop.set_meta("loot_item", item)
		loot_drop.add_to_group("loot_drops")
		
		get_tree().current_scene.add_child(loot_drop)

func get_animal_info(animal_type: int) -> Dictionary:
	return animals.get(animal_type, {})

func get_hunting_skill() -> int:
	return player_hunting_skill

func get_hunting_xp() -> int:
	return player_hunting_xp

func get_nearby_animals(position: Vector3, radius: float) -> Array:
	var result = []
	for animal_data in active_animals:
		if animal_data.node and is_instance_valid(animal_data.node):
			var dist = animal_data.node.global_position.distance_to(position)
			if dist <= radius:
				result.append({
					"node": animal_data.node,
					"type": animal_data.type,
					"distance": dist
				})
	return result

func track_animal(position: Vector3, radius: float = 50.0) -> Dictionary:
	var skill_multiplier = 1.0 + (player_hunting_skill * 0.1)
	var effective_radius = radius * skill_multiplier
	
	var tracks = []
	for animal_data in active_animals:
		if animal_data.node and is_instance_valid(animal_data.node):
			var dist = animal_data.node.global_position.distance_to(position)
			if dist <= effective_radius:
				var track_chance = 0.5 + (player_hunting_skill * 0.05)
				if randf() <= track_chance:
					var direction = (animal_data.node.global_position - position).normalized()
					tracks.append({
						"type": animal_data.type,
						"direction": direction,
						"freshness": 1.0 - (dist / effective_radius),
						"approximate_distance": dist
					})
	
	return {
		"tracks_found": tracks.size(),
		"tracks": tracks
	}
