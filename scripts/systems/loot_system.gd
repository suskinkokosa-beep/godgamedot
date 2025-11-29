extends Node

var loot_tables := {}
var world_items := []

func _ready():
	_register_loot_tables()

func _register_loot_tables():
	loot_tables["mob_basic"] = {
		"guaranteed": [],
		"common": [
			{"id": "meat", "min": 1, "max": 3, "chance": 0.6},
			{"id": "hide", "min": 1, "max": 2, "chance": 0.4},
			{"id": "bone", "min": 1, "max": 2, "chance": 0.25}
		],
		"rare": [
			{"id": "animal_tooth", "min": 1, "max": 1, "chance": 0.1},
			{"id": "animal_claw", "min": 1, "max": 1, "chance": 0.08}
		],
		"legendary": []
	}
	
	loot_tables["mob_wolf"] = {
		"guaranteed": [
			{"id": "meat", "min": 2, "max": 4}
		],
		"common": [
			{"id": "wolf_pelt", "min": 1, "max": 1, "chance": 0.7},
			{"id": "bone", "min": 2, "max": 4, "chance": 0.5}
		],
		"rare": [
			{"id": "wolf_fang", "min": 1, "max": 2, "chance": 0.2},
			{"id": "animal_claw", "min": 2, "max": 3, "chance": 0.15}
		],
		"legendary": [
			{"id": "alpha_pelt", "min": 1, "max": 1, "chance": 0.02}
		]
	}
	
	loot_tables["mob_bear"] = {
		"guaranteed": [
			{"id": "meat", "min": 4, "max": 8}
		],
		"common": [
			{"id": "bear_pelt", "min": 1, "max": 1, "chance": 0.8},
			{"id": "bone", "min": 3, "max": 6, "chance": 0.6},
			{"id": "animal_fat", "min": 2, "max": 4, "chance": 0.5}
		],
		"rare": [
			{"id": "bear_claw", "min": 2, "max": 4, "chance": 0.3},
			{"id": "bear_heart", "min": 1, "max": 1, "chance": 0.1}
		],
		"legendary": [
			{"id": "giant_bear_pelt", "min": 1, "max": 1, "chance": 0.01}
		]
	}
	
	loot_tables["bandit"] = {
		"guaranteed": [],
		"common": [
			{"id": "cloth", "min": 1, "max": 3, "chance": 0.5},
			{"id": "leather", "min": 1, "max": 2, "chance": 0.4},
			{"id": "iron_ore", "min": 1, "max": 3, "chance": 0.3}
		],
		"rare": [
			{"id": "iron_ingot", "min": 1, "max": 2, "chance": 0.15},
			{"id": "gold_coin", "min": 5, "max": 20, "chance": 0.2},
			{"id": "bandit_key", "min": 1, "max": 1, "chance": 0.05}
		],
		"legendary": [
			{"id": "bandit_treasure_map", "min": 1, "max": 1, "chance": 0.01}
		]
	}
	
	loot_tables["chest_common"] = {
		"guaranteed": [
			{"id": "gold_coin", "min": 10, "max": 30}
		],
		"common": [
			{"id": "wood", "min": 5, "max": 15, "chance": 0.6},
			{"id": "stone", "min": 5, "max": 15, "chance": 0.6},
			{"id": "iron_ore", "min": 2, "max": 8, "chance": 0.4},
			{"id": "cloth", "min": 2, "max": 6, "chance": 0.5}
		],
		"rare": [
			{"id": "iron_ingot", "min": 1, "max": 3, "chance": 0.2},
			{"id": "leather", "min": 2, "max": 5, "chance": 0.25}
		],
		"legendary": []
	}
	
	loot_tables["chest_rare"] = {
		"guaranteed": [
			{"id": "gold_coin", "min": 50, "max": 150}
		],
		"common": [
			{"id": "iron_ingot", "min": 3, "max": 8, "chance": 0.7},
			{"id": "leather", "min": 5, "max": 10, "chance": 0.6}
		],
		"rare": [
			{"id": "steel_ingot", "min": 1, "max": 3, "chance": 0.3},
			{"id": "gem_ruby", "min": 1, "max": 2, "chance": 0.15},
			{"id": "gem_sapphire", "min": 1, "max": 2, "chance": 0.15}
		],
		"legendary": [
			{"id": "ancient_artifact", "min": 1, "max": 1, "chance": 0.05}
		]
	}

func generate_loot(table_id: String, luck_bonus: float = 0.0) -> Array:
	if not loot_tables.has(table_id):
		return []
	
	var table = loot_tables[table_id]
	var drops := []
	
	for item in table.get("guaranteed", []):
		drops.append({
			"id": item.id,
			"amount": randi_range(item.min, item.max)
		})
	
	for item in table.get("common", []):
		if randf() < item.chance + luck_bonus * 0.1:
			drops.append({
				"id": item.id,
				"amount": randi_range(item.min, item.max)
			})
	
	for item in table.get("rare", []):
		if randf() < item.chance + luck_bonus * 0.05:
			drops.append({
				"id": item.id,
				"amount": randi_range(item.min, item.max)
			})
	
	for item in table.get("legendary", []):
		if randf() < item.chance + luck_bonus * 0.02:
			drops.append({
				"id": item.id,
				"amount": randi_range(item.min, item.max)
			})
	
	return drops

func drop_loot_at(table_id: String, position: Vector3, luck_bonus: float = 0.0):
	var items = generate_loot(table_id, luck_bonus)
	
	for item in items:
		spawn_world_item(item.id, item.amount, position + Vector3(randf_range(-0.5, 0.5), 0.5, randf_range(-0.5, 0.5)))

func spawn_world_item(item_id: String, amount: int, position: Vector3):
	var inv = get_node_or_null("/root/Inventory")
	if inv:
		inv.add_item(item_id, amount, 1.0)

func get_loot_table(table_id: String) -> Dictionary:
	return loot_tables.get(table_id, {})

func register_loot_table(table_id: String, table: Dictionary):
	loot_tables[table_id] = table
