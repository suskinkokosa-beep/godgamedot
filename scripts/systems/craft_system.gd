extends Node

signal recipe_unlocked(recipe_id)
signal item_crafted(recipe_id, amount)

var recipes := {}
var unlocked_recipes := {}

func _ready():
        _register_default_recipes()

func _register_default_recipes():
        register_recipe("stone_axe", {"stone": 3, "stick": 2}, "stone_axe", 1, 0)
        register_recipe("stone_pickaxe", {"stone": 3, "stick": 2}, "stone_pickaxe", 1, 0)
        register_recipe("stone_knife", {"stone": 2, "stick": 1}, "stone_knife", 1, 0)
        register_recipe("wooden_spear", {"stick": 3, "flint": 1}, "wooden_spear", 1, 0)
        register_recipe("campfire", {"stone": 5, "wood": 10}, "campfire", 1, 0)
        register_recipe("torch", {"stick": 1, "plant_fiber": 2}, "torch", 1, 0)
        register_recipe("bandage", {"plant_fiber": 5}, "bandage", 2, 0)
        
        register_recipe("wooden_foundation", {"wood": 50}, "wooden_foundation", 1, 1)
        register_recipe("wooden_wall", {"wood": 30}, "wooden_wall", 1, 1)
        register_recipe("wooden_floor", {"wood": 25}, "wooden_floor", 1, 1)
        register_recipe("wooden_door", {"wood": 40}, "wooden_door", 1, 1)
        register_recipe("workbench_1", {"wood": 50, "stone": 20}, "workbench_1", 1, 0)
        register_recipe("storage_box", {"wood": 30}, "storage_box", 1, 1)
        
        register_recipe("iron_ingot", {"iron_ore": 2, "wood": 1}, "iron_ingot", 1, 2)
        register_recipe("copper_ingot", {"copper_ore": 2, "wood": 1}, "copper_ingot", 1, 2)
        register_recipe("iron_axe", {"iron_ingot": 3, "stick": 2}, "iron_axe", 1, 2)
        register_recipe("iron_pickaxe", {"iron_ingot": 3, "stick": 2}, "iron_pickaxe", 1, 2)
        register_recipe("iron_sword", {"iron_ingot": 4, "stick": 1}, "iron_sword", 1, 2)
        register_recipe("workbench_2", {"wood": 100, "iron_ingot": 10}, "workbench_2", 1, 1)
        
        register_recipe("stone_foundation", {"stone": 100}, "stone_foundation", 1, 2)
        register_recipe("stone_wall", {"stone": 60}, "stone_wall", 1, 2)
        register_recipe("metal_door", {"iron_ingot": 10}, "metal_door", 1, 2)
        register_recipe("furnace", {"stone": 50, "iron_ingot": 5}, "furnace", 1, 2)
        
        register_recipe("steel_ingot", {"iron_ingot": 2, "wood": 2}, "steel_ingot", 1, 3)
        register_recipe("steel_sword", {"steel_ingot": 5, "stick": 1}, "steel_sword", 1, 3)
        register_recipe("steel_armor_chest", {"steel_ingot": 8, "hide": 4}, "steel_armor_chest", 1, 3)
        register_recipe("bow", {"wood": 10, "plant_fiber": 5}, "bow", 1, 2)
        register_recipe("arrow", {"stick": 1, "flint": 1}, "arrow", 5, 1)
        
        register_recipe("medicine", {"herbs": 3, "berries": 2}, "medicine", 1, 1)
        register_recipe("antidote", {"herbs": 5, "bone": 1}, "antidote", 1, 2)
        register_recipe("cooked_meat", {"meat": 1}, "cooked_meat", 1, 0)

func register_recipe(id: String, inputs: Dictionary, output: String, amount: int = 1, tier: int = 0):
        recipes[id] = {
                "id": id,
                "inputs": inputs,
                "output": output,
                "amount": amount,
                "tier": tier
        }

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
