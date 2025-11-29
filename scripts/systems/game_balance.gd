extends Node

const VERSION := "1.0.0"

const PLAYER_STATS := {
	"max_health": 100.0,
	"max_stamina": 100.0,
	"max_hunger": 100.0,
	"max_thirst": 100.0,
	"max_blood": 100.0,
	"max_sanity": 100.0,
	"base_speed": 5.0,
	"sprint_multiplier": 1.6,
	"crouch_multiplier": 0.5,
	"jump_force": 8.0,
	"max_jumps": 2,
	"base_carry_weight": 80.0,
	"health_regen_rate": 0.5,
	"stamina_regen_rate": 15.0,
	"stamina_sprint_drain": 10.0,
	"stamina_jump_cost": 8.0
}

const SURVIVAL_RATES := {
	"hunger_decay_rate": 0.8,
	"thirst_decay_rate": 1.2,
	"sanity_decay_night": 0.3,
	"sanity_regen_day": 0.2,
	"blood_regen_rate": 0.1,
	"body_temp_change_rate": 0.05,
	"hypothermia_threshold": 35.0,
	"hyperthermia_threshold": 38.5,
	"starvation_damage": 0.5,
	"dehydration_damage": 0.8,
	"bleeding_damage": 1.0,
	"freezing_damage": 0.3,
	"overheating_damage": 0.2
}

const WEAPON_BASE_STATS := {
	"fist": {"damage": 5, "speed": 1.5, "stamina_cost": 3, "range": 1.5, "crit": 0.02},
	"stone_knife": {"damage": 12, "speed": 1.4, "stamina_cost": 5, "range": 1.8, "crit": 0.08},
	"stone_axe": {"damage": 18, "speed": 0.9, "stamina_cost": 10, "range": 2.0, "crit": 0.05},
	"stone_pickaxe": {"damage": 15, "speed": 0.8, "stamina_cost": 12, "range": 2.2, "crit": 0.03},
	"wooden_spear": {"damage": 22, "speed": 1.0, "stamina_cost": 8, "range": 3.0, "crit": 0.1},
	"iron_sword": {"damage": 35, "speed": 1.2, "stamina_cost": 12, "range": 2.5, "crit": 0.12},
	"iron_axe": {"damage": 28, "speed": 0.85, "stamina_cost": 14, "range": 2.2, "crit": 0.06},
	"steel_sword": {"damage": 50, "speed": 1.15, "stamina_cost": 15, "range": 2.6, "crit": 0.15},
	"steel_axe": {"damage": 40, "speed": 0.8, "stamina_cost": 18, "range": 2.3, "crit": 0.08},
	"bow": {"damage": 30, "speed": 0.6, "stamina_cost": 8, "range": 50.0, "crit": 0.2},
	"crossbow": {"damage": 55, "speed": 0.3, "stamina_cost": 5, "range": 70.0, "crit": 0.25}
}

const ARMOR_VALUES := {
	"cloth_shirt": {"chest": 5, "back": 3},
	"cloth_pants": {"legs": 4},
	"leather_vest": {"chest": 15, "back": 10},
	"leather_pants": {"legs": 12},
	"leather_boots": {"feet": 8},
	"leather_gloves": {"hands": 6},
	"iron_chestplate": {"chest": 35, "back": 25},
	"iron_helmet": {"head": 30, "neck": 15},
	"iron_leggings": {"legs": 28},
	"steel_chestplate": {"chest": 50, "back": 40},
	"steel_helmet": {"head": 45, "neck": 25},
	"steel_leggings": {"legs": 42}
}

const FOOD_VALUES := {
	"berries": {"hunger": 5, "thirst": 2, "health": 0},
	"mushroom": {"hunger": 8, "thirst": 0, "health": -5},
	"meat": {"hunger": -10, "thirst": -5, "health": -15},
	"cooked_meat": {"hunger": 35, "thirst": -5, "health": 5},
	"fish": {"hunger": -8, "thirst": 0, "health": -10},
	"cooked_fish": {"hunger": 25, "thirst": 0, "health": 3},
	"stew": {"hunger": 50, "thirst": 20, "health": 10},
	"bread": {"hunger": 20, "thirst": -5, "health": 0},
	"carrot": {"hunger": 12, "thirst": 5, "health": 2}
}

const DRINK_VALUES := {
	"water_bottle": {"thirst": 40, "hunger": 0, "health": 0},
	"dirty_water": {"thirst": 25, "hunger": 0, "health": -10},
	"tea": {"thirst": 30, "hunger": 5, "health": 5, "stamina_boost": 20},
	"juice": {"thirst": 35, "hunger": 10, "health": 2}
}

const MEDICINE_VALUES := {
	"bandage": {"health": 0, "blood": 25, "stops_bleeding": true},
	"medkit": {"health": 50, "blood": 40, "stops_bleeding": true},
	"medicine": {"health": 20, "removes_debuff": "infection"},
	"painkillers": {"health": 10, "stamina_boost": 30},
	"antidote": {"health": 0, "removes_debuff": "poison"},
	"herbs": {"health": 5, "removes_debuff": null}
}

const MOB_STATS := {
	"wolf": {"health": 80, "damage": 15, "speed": 6.0, "xp": 25, "detection_range": 20.0, "attack_range": 2.0},
	"bear": {"health": 250, "damage": 40, "speed": 4.5, "xp": 80, "detection_range": 15.0, "attack_range": 3.0},
	"boar": {"health": 120, "damage": 20, "speed": 5.0, "xp": 40, "detection_range": 12.0, "attack_range": 2.5},
	"deer": {"health": 60, "damage": 0, "speed": 7.0, "xp": 15, "detection_range": 25.0, "attack_range": 0},
	"rabbit": {"health": 15, "damage": 0, "speed": 8.0, "xp": 5, "detection_range": 20.0, "attack_range": 0},
	"zombie": {"health": 100, "damage": 25, "speed": 3.0, "xp": 35, "detection_range": 18.0, "attack_range": 2.0},
	"skeleton": {"health": 70, "damage": 20, "speed": 4.0, "xp": 30, "detection_range": 22.0, "attack_range": 2.5},
	"bandit": {"health": 100, "damage": 30, "speed": 5.0, "xp": 50, "detection_range": 25.0, "attack_range": 15.0}
}

const LOOT_TABLES := {
	"wolf": [
		{"id": "hide", "chance": 0.9, "count_min": 2, "count_max": 4},
		{"id": "meat", "chance": 0.8, "count_min": 1, "count_max": 3},
		{"id": "bone", "chance": 0.7, "count_min": 1, "count_max": 2}
	],
	"bear": [
		{"id": "hide", "chance": 1.0, "count_min": 4, "count_max": 8},
		{"id": "meat", "chance": 0.95, "count_min": 3, "count_max": 6},
		{"id": "bone", "chance": 0.8, "count_min": 2, "count_max": 4},
		{"id": "fat", "chance": 0.6, "count_min": 1, "count_max": 2}
	],
	"boar": [
		{"id": "hide", "chance": 0.85, "count_min": 1, "count_max": 3},
		{"id": "meat", "chance": 0.9, "count_min": 2, "count_max": 4},
		{"id": "bone", "chance": 0.5, "count_min": 1, "count_max": 2}
	],
	"deer": [
		{"id": "hide", "chance": 0.95, "count_min": 2, "count_max": 4},
		{"id": "meat", "chance": 0.85, "count_min": 2, "count_max": 3}
	]
}

const RESOURCE_YIELDS := {
	"tree_small": {"wood": [3, 6], "stick": [1, 3]},
	"tree_medium": {"wood": [8, 15], "stick": [2, 5]},
	"tree_large": {"wood": [15, 25], "stick": [3, 8]},
	"stone_small": {"stone": [3, 6], "flint": [0, 1]},
	"stone_medium": {"stone": [8, 15], "flint": [1, 2]},
	"iron_ore_node": {"iron_ore": [3, 8]},
	"copper_ore_node": {"copper_ore": [3, 8]},
	"gold_ore_node": {"gold_ore": [1, 3]},
	"coal_node": {"coal": [5, 12]},
	"bush_berry": {"berries": [2, 5]},
	"herb_patch": {"herbs": [1, 3]},
	"mushroom_cluster": {"mushroom": [2, 4]}
}

const CRAFTING_TIMES := {
	"tier_0": 1.0,
	"tier_1": 2.0,
	"tier_2": 4.0,
	"tier_3": 8.0,
	"tier_4": 15.0
}

const BUILDING_DECAY := {
	"wood": {"rate": 0.1, "weather_mult": 1.5},
	"stone": {"rate": 0.02, "weather_mult": 1.0},
	"metal": {"rate": 0.05, "weather_mult": 1.2},
	"steel": {"rate": 0.01, "weather_mult": 0.8}
}

const XP_REQUIREMENTS := {
	1: 0,
	2: 100,
	3: 250,
	4: 450,
	5: 700,
	6: 1000,
	7: 1400,
	8: 1900,
	9: 2500,
	10: 3200,
	15: 8000,
	20: 15000,
	25: 25000,
	30: 40000,
	40: 80000,
	50: 150000
}

const SKILL_XP_REQUIREMENTS := {
	1: 0,
	2: 50,
	3: 120,
	4: 220,
	5: 350,
	6: 520,
	7: 730,
	8: 1000,
	9: 1350,
	10: 1800
}

const TRADER_PRICES := {
	"wood": {"buy": 2, "sell": 1},
	"stone": {"buy": 3, "sell": 1},
	"iron_ore": {"buy": 10, "sell": 5},
	"iron_ingot": {"buy": 25, "sell": 12},
	"steel_ingot": {"buy": 60, "sell": 30},
	"hide": {"buy": 8, "sell": 4},
	"leather": {"buy": 20, "sell": 10},
	"meat": {"buy": 5, "sell": 2},
	"cooked_meat": {"buy": 12, "sell": 6},
	"bandage": {"buy": 15, "sell": 7},
	"medkit": {"buy": 50, "sell": 25},
	"stone_axe": {"buy": 30, "sell": 10},
	"iron_sword": {"buy": 150, "sell": 50},
	"steel_sword": {"buy": 400, "sell": 150}
}

func get_player_stat(stat_name: String) -> float:
	return PLAYER_STATS.get(stat_name, 0.0)

func get_survival_rate(rate_name: String) -> float:
	return SURVIVAL_RATES.get(rate_name, 0.0)

func get_weapon_stats(weapon_id: String) -> Dictionary:
	return WEAPON_BASE_STATS.get(weapon_id, WEAPON_BASE_STATS["fist"])

func get_armor_value(armor_id: String, zone: String) -> int:
	var armor = ARMOR_VALUES.get(armor_id, {})
	return armor.get(zone, 0)

func get_food_value(food_id: String, stat: String) -> int:
	var food = FOOD_VALUES.get(food_id, {})
	return food.get(stat, 0)

func get_mob_stats(mob_id: String) -> Dictionary:
	return MOB_STATS.get(mob_id, {})

func get_loot_table(mob_id: String) -> Array:
	return LOOT_TABLES.get(mob_id, [])

func get_resource_yield(resource_id: String) -> Dictionary:
	return RESOURCE_YIELDS.get(resource_id, {})

func get_xp_for_level(level: int) -> int:
	if XP_REQUIREMENTS.has(level):
		return XP_REQUIREMENTS[level]
	
	var prev_level = 1
	for l in XP_REQUIREMENTS.keys():
		if l < level and l > prev_level:
			prev_level = l
	
	var base = XP_REQUIREMENTS.get(prev_level, 0)
	var mult = pow(1.15, level - prev_level)
	return int(base * mult)

func get_trader_price(item_id: String, is_buy: bool) -> int:
	var prices = TRADER_PRICES.get(item_id, {"buy": 10, "sell": 3})
	return prices["buy"] if is_buy else prices["sell"]

func calculate_damage_with_balance(base_damage: float, weapon_id: String, attacker_level: int) -> float:
	var weapon = get_weapon_stats(weapon_id)
	var level_bonus = 1.0 + (attacker_level - 1) * 0.03
	return base_damage * level_bonus

func get_spawn_rate_modifier(day: int) -> float:
	return min(1.0 + (day - 1) * 0.05, 2.5)

func get_difficulty_multiplier(difficulty: String) -> Dictionary:
	match difficulty:
		"easy":
			return {"damage_taken": 0.7, "hunger_rate": 0.7, "mob_damage": 0.7, "xp_mult": 0.8}
		"normal":
			return {"damage_taken": 1.0, "hunger_rate": 1.0, "mob_damage": 1.0, "xp_mult": 1.0}
		"hard":
			return {"damage_taken": 1.3, "hunger_rate": 1.3, "mob_damage": 1.3, "xp_mult": 1.2}
		"survival":
			return {"damage_taken": 1.5, "hunger_rate": 1.5, "mob_damage": 1.5, "xp_mult": 1.5}
	return {"damage_taken": 1.0, "hunger_rate": 1.0, "mob_damage": 1.0, "xp_mult": 1.0}
