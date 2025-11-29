extends Node

signal recipe_unlocked(recipe_id)
signal item_crafted(recipe_id, amount)

var recipes := {}
var unlocked_recipes := {}

func _ready():
        _register_default_recipes()

func _register_default_recipes():
        _register_basic_recipes()
        _register_tool_recipes()
        _register_building_recipes()
        _register_armor_recipes()
        _register_food_recipes()
        _register_medical_recipes()
        _register_advanced_recipes()

func _register_basic_recipes():
        register_recipe("stone_axe", {"stone": 3, "stick": 2}, "stone_axe", 1, 0, "tools")
        register_recipe("stone_pickaxe", {"stone": 3, "stick": 2}, "stone_pickaxe", 1, 0, "tools")
        register_recipe("stone_knife", {"stone": 2, "stick": 1}, "stone_knife", 1, 0, "tools")
        register_recipe("wooden_spear", {"stick": 3, "flint": 1}, "wooden_spear", 1, 0, "weapons")
        register_recipe("campfire", {"stone": 5, "wood": 10}, "campfire", 1, 0, "building")
        register_recipe("torch", {"stick": 1, "plant_fiber": 2}, "torch", 1, 0, "misc")
        register_recipe("bandage", {"plant_fiber": 5}, "bandage", 2, 0, "medical")
        register_recipe("rope", {"plant_fiber": 10}, "rope", 1, 0, "misc")
        register_recipe("sleeping_bag", {"plant_fiber": 30, "hide": 5}, "sleeping_bag", 1, 0, "building")

func _register_tool_recipes():
        register_recipe("iron_axe", {"iron_ingot": 3, "stick": 2}, "iron_axe", 1, 2, "tools")
        register_recipe("iron_pickaxe", {"iron_ingot": 3, "stick": 2}, "iron_pickaxe", 1, 2, "tools")
        register_recipe("steel_axe", {"steel_ingot": 3, "stick": 2}, "steel_axe", 1, 3, "tools")
        register_recipe("steel_pickaxe", {"steel_ingot": 3, "stick": 2}, "steel_pickaxe", 1, 3, "tools")
        register_recipe("hammer", {"wood": 10, "stone": 5}, "hammer", 1, 0, "tools")
        register_recipe("repair_hammer", {"iron_ingot": 5, "stick": 2}, "repair_hammer", 1, 2, "tools")
        register_recipe("fishing_rod", {"stick": 5, "plant_fiber": 3}, "fishing_rod", 1, 1, "tools")

func _register_building_recipes():
        register_recipe("workbench_1", {"wood": 50, "stone": 20}, "workbench_1", 1, 0, "building")
        register_recipe("workbench_2", {"wood": 100, "iron_ingot": 10}, "workbench_2", 1, 1, "building")
        register_recipe("workbench_3", {"wood": 150, "steel_ingot": 20}, "workbench_3", 1, 2, "building")
        register_recipe("wooden_foundation", {"wood": 50}, "wooden_foundation", 1, 1, "building")
        register_recipe("wooden_wall", {"wood": 30}, "wooden_wall", 1, 1, "building")
        register_recipe("wooden_floor", {"wood": 25}, "wooden_floor", 1, 1, "building")
        register_recipe("wooden_door", {"wood": 40}, "wooden_door", 1, 1, "building")
        register_recipe("wooden_doorframe", {"wood": 35}, "wooden_doorframe", 1, 1, "building")
        register_recipe("wooden_window", {"wood": 25}, "wooden_window", 1, 1, "building")
        register_recipe("wooden_roof", {"wood": 35}, "wooden_roof", 1, 1, "building")
        register_recipe("wooden_stairs", {"wood": 40}, "wooden_stairs", 1, 1, "building")
        register_recipe("stone_foundation", {"stone": 100}, "stone_foundation", 1, 2, "building")
        register_recipe("stone_wall", {"stone": 60}, "stone_wall", 1, 2, "building")
        register_recipe("stone_floor", {"stone": 50}, "stone_floor", 1, 2, "building")
        register_recipe("metal_door", {"iron_ingot": 10}, "metal_door", 1, 2, "building")
        register_recipe("armored_door", {"steel_ingot": 15}, "armored_door", 1, 3, "building")
        register_recipe("furnace", {"stone": 50, "iron_ingot": 5}, "furnace", 1, 2, "building")
        register_recipe("storage_box", {"wood": 30}, "storage_box", 1, 1, "building")
        register_recipe("large_storage", {"wood": 100, "iron_ingot": 5}, "large_storage", 1, 2, "building")
        register_recipe("tool_cupboard", {"wood": 100, "iron_ingot": 2}, "tool_cupboard", 1, 1, "building")

func _register_armor_recipes():
        register_recipe("leather_vest", {"hide": 15}, "leather_vest", 1, 1, "armor")
        register_recipe("leather_pants", {"hide": 12}, "leather_pants", 1, 1, "armor")
        register_recipe("leather_boots", {"hide": 8}, "leather_boots", 1, 1, "armor")
        register_recipe("leather_gloves", {"hide": 6}, "leather_gloves", 1, 1, "armor")
        register_recipe("leather_helmet", {"hide": 10}, "leather_helmet", 1, 1, "armor")
        register_recipe("iron_armor_chest", {"iron_ingot": 15, "hide": 5}, "iron_armor_chest", 1, 2, "armor")
        register_recipe("iron_armor_legs", {"iron_ingot": 12, "hide": 4}, "iron_armor_legs", 1, 2, "armor")
        register_recipe("iron_helmet", {"iron_ingot": 8}, "iron_helmet", 1, 2, "armor")
        register_recipe("steel_armor_chest", {"steel_ingot": 8, "hide": 4}, "steel_armor_chest", 1, 3, "armor")
        register_recipe("steel_armor_legs", {"steel_ingot": 6, "hide": 3}, "steel_armor_legs", 1, 3, "armor")
        register_recipe("steel_helmet", {"steel_ingot": 5}, "steel_helmet", 1, 3, "armor")

func _register_food_recipes():
        register_recipe("cooked_meat", {"meat": 1}, "cooked_meat", 1, 0, "food")
        register_recipe("cooked_fish", {"fish": 1}, "cooked_fish", 1, 0, "food")
        register_recipe("berry_mix", {"berries": 5}, "berry_mix", 1, 0, "food")
        register_recipe("stew", {"meat": 2, "berries": 3, "water_bottle": 1}, "stew", 1, 1, "food")
        register_recipe("bread", {"wheat": 5}, "bread", 2, 1, "food")
        register_recipe("water_bottle", {"plant_fiber": 3}, "water_bottle", 1, 0, "food")
        register_recipe("grilled_vegetables", {"mushroom": 2, "berries": 2}, "grilled_vegetables", 1, 0, "food")

func _register_medical_recipes():
        register_recipe("medicine", {"herbs": 3, "berries": 2}, "medicine", 1, 1, "medical")
        register_recipe("antidote", {"herbs": 5, "bone": 1}, "antidote", 1, 2, "medical")
        register_recipe("blood_pack", {"hide": 5, "herbs": 3}, "blood_pack", 1, 2, "medical")
        register_recipe("splint", {"stick": 3, "plant_fiber": 5}, "splint", 1, 1, "medical")
        register_recipe("painkiller", {"herbs": 8, "berries": 5}, "painkiller", 1, 2, "medical")
        register_recipe("anti_rad", {"herbs": 10, "mushroom": 5}, "anti_rad", 1, 3, "medical")
        register_recipe("warm_potion", {"herbs": 5, "coal": 2}, "warm_potion", 1, 2, "medical")
        register_recipe("cooling_potion", {"herbs": 5, "water_bottle": 1}, "cooling_potion", 1, 2, "medical")

func _register_advanced_recipes():
        register_recipe("iron_ingot", {"iron_ore": 2, "wood": 1}, "iron_ingot", 1, 2, "materials")
        register_recipe("copper_ingot", {"copper_ore": 2, "wood": 1}, "copper_ingot", 1, 2, "materials")
        register_recipe("steel_ingot", {"iron_ingot": 2, "coal": 2}, "steel_ingot", 1, 3, "materials")
        register_recipe("silver_ingot", {"silver_ore": 2, "wood": 1}, "silver_ingot", 1, 3, "materials")
        register_recipe("gold_ingot", {"gold_ore": 2, "wood": 1}, "gold_ingot", 1, 3, "materials")
        register_recipe("iron_sword", {"iron_ingot": 4, "stick": 1}, "iron_sword", 1, 2, "weapons")
        register_recipe("steel_sword", {"steel_ingot": 5, "stick": 1}, "steel_sword", 1, 3, "weapons")
        register_recipe("bow", {"wood": 10, "plant_fiber": 5}, "bow", 1, 1, "weapons")
        register_recipe("crossbow", {"wood": 15, "iron_ingot": 5, "rope": 2}, "crossbow", 1, 2, "weapons")
        register_recipe("arrow", {"stick": 1, "flint": 1}, "arrow", 5, 1, "ammo")
        register_recipe("iron_arrow", {"stick": 1, "iron_ingot": 1}, "iron_arrow", 5, 2, "ammo")
        register_recipe("bolt", {"stick": 1, "iron_ingot": 2}, "bolt", 5, 2, "ammo")

func register_recipe(id: String, inputs: Dictionary, output: String, amount: int = 1, tier: int = 0, category: String = "misc"):
        recipes[id] = {
                "id": id,
                "inputs": inputs,
                "output": output,
                "amount": amount,
                "tier": tier,
                "category": category
        }

func get_recipes_by_category(category: String, workbench_tier: int = 99) -> Array:
        var result := []
        for id in recipes.keys():
                var r = recipes[id]
                if r.category == category and r.tier <= workbench_tier:
                        result.append(r)
        return result

func get_all_categories() -> Array:
        var cats := []
        for id in recipes.keys():
                var cat = recipes[id].category
                if cat not in cats:
                        cats.append(cat)
        return cats

func get_category_name_ru(category: String) -> String:
        var names := {
                "tools": "Инструменты",
                "weapons": "Оружие",
                "building": "Строительство",
                "armor": "Броня",
                "food": "Еда",
                "medical": "Медицина",
                "materials": "Материалы",
                "ammo": "Боеприпасы",
                "misc": "Разное"
        }
        return names.get(category, category)

func unlock_recipe(player_id: int, recipe_id: String):
        if not unlocked_recipes.has(player_id):
                unlocked_recipes[player_id] = []
        if recipe_id not in unlocked_recipes[player_id]:
                unlocked_recipes[player_id].append(recipe_id)
                emit_signal("recipe_unlocked", recipe_id)

func is_unlocked(player_id: int, recipe_id: String) -> bool:
        if not recipes.has(recipe_id):
                return false
        if recipes[recipe_id].tier == 0:
                return true
        if not unlocked_recipes.has(player_id):
                return false
        return recipe_id in unlocked_recipes[player_id]

func can_craft(inv, recipe_id: String, workbench_tier: int = 0) -> bool:
        if not recipes.has(recipe_id):
                return false
        var r = recipes[recipe_id]
        if workbench_tier < r.tier:
                return false
        for k in r.inputs.keys():
                if not inv.has_item(k, r.inputs[k]):
                        return false
        return true

func craft(inv, recipe_id: String, workbench_tier: int = 0, player = null) -> bool:
        if not can_craft(inv, recipe_id, workbench_tier):
                return false
        
        var r = recipes[recipe_id]
        
        for k in r.inputs.keys():
                inv.remove_item(k, r.inputs[k])
        
        inv.add_item(r.output, r.amount, 1.0)
        
        var prog = get_node_or_null("/root/PlayerProgression")
        if prog and player:
                var pid = player.get("net_id") if player.has_method("get") and player.get("net_id") else 1
                prog.add_skill_xp(pid, "blacksmith", float(r.tier + 1) * 2.0)
                prog.add_xp(pid, float(r.tier + 1))
        
        emit_signal("item_crafted", recipe_id, r.amount)
        return true

func get_recipes_for_tier(tier: int) -> Array:
        var result := []
        for id in recipes.keys():
                if recipes[id].tier <= tier:
                        result.append(recipes[id])
        return result

func get_available_recipes(inv, workbench_tier: int) -> Array:
        var result := []
        for id in recipes.keys():
                if can_craft(inv, id, workbench_tier):
                        result.append(recipes[id])
        return result

func get_recipe(recipe_id: String) -> Dictionary:
        return recipes.get(recipe_id, {})

func get_all_recipes_for_tier(workbench_tier: int) -> Dictionary:
        var result := {}
        for id in recipes.keys():
                if recipes[id].tier <= workbench_tier:
                        result[id] = recipes[id]
        return result

func craft_item(recipe_id: String, inv, workbench_tier: int = 0, player = null) -> Dictionary:
        if not recipes.has(recipe_id):
                return {"success": false, "error": "Рецепт не найден"}
        
        var r = recipes[recipe_id]
        
        if workbench_tier < r.tier:
                var tier_names = ["руки", "базовый верстак", "продвинутый верстак", "мастерский верстак"]
                return {"success": false, "error": "Требуется: %s" % tier_names[r.tier]}
        
        for mat_id in r.inputs.keys():
                if not inv.has_item(mat_id, r.inputs[mat_id]):
                        return {"success": false, "error": "Недостаточно материалов"}
        
        for mat_id in r.inputs.keys():
                inv.remove_item(mat_id, r.inputs[mat_id])
        
        inv.add_item(r.output, r.amount, 1.0)
        
        var prog = get_node_or_null("/root/PlayerProgression")
        if prog and player:
                var pid = player.get("net_id") if player.get("net_id") else 1
                prog.add_skill_xp(pid, "blacksmith", float(r.tier + 1) * 2.0)
                prog.add_xp(pid, float(r.tier + 1))
        
        emit_signal("item_crafted", recipe_id, r.amount)
        return {"success": true, "item": r.output, "amount": r.amount}
