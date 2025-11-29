extends Node

signal quest_started(quest_id)
signal quest_completed(quest_id)
signal quest_failed(quest_id)
signal objective_updated(quest_id, objective_id, current, target)

var quests := {}
var active_quests := {}
var completed_quests := {}

func _ready():
        _register_default_quests()

func _register_default_quests():
        register_quest("tutorial_gather", {
                "name": "Первые шаги",
                "description": "Соберите базовые ресурсы для выживания",
                "objectives": [
                        {"id": "gather_wood", "type": "gather", "target": "wood", "amount": 10, "current": 0},
                        {"id": "gather_stone", "type": "gather", "target": "stone", "amount": 5, "current": 0}
                ],
                "rewards": {"xp": 50, "items": {"bandage": 2}},
                "auto_start": true
        })
        
        register_quest("tutorial_craft", {
                "name": "Ремесленник",
                "description": "Создайте свой первый инструмент",
                "prerequisites": ["tutorial_gather"],
                "objectives": [
                        {"id": "craft_axe", "type": "craft", "target": "stone_axe", "amount": 1, "current": 0}
                ],
                "rewards": {"xp": 75, "items": {"torch": 3}}
        })
        
        register_quest("tutorial_build", {
                "name": "Первое убежище",
                "description": "Постройте небольшое укрытие",
                "prerequisites": ["tutorial_craft"],
                "objectives": [
                        {"id": "build_foundation", "type": "build", "target": "wooden_foundation", "amount": 1, "current": 0},
                        {"id": "build_walls", "type": "build", "target": "wooden_wall", "amount": 4, "current": 0}
                ],
                "rewards": {"xp": 150, "items": {"cooked_meat": 5}}
        })
        
        register_quest("explore_biomes", {
                "name": "Исследователь",
                "description": "Посетите разные биомы мира",
                "objectives": [
                        {"id": "visit_forest", "type": "visit_biome", "target": "forest", "amount": 1, "current": 0},
                        {"id": "visit_desert", "type": "visit_biome", "target": "desert", "amount": 1, "current": 0},
                        {"id": "visit_tundra", "type": "visit_biome", "target": "tundra", "amount": 1, "current": 0}
                ],
                "rewards": {"xp": 200, "skill_xp": {"exploration": 50}}
        })
        
        register_quest("hunter", {
                "name": "Охотник",
                "description": "Уничтожьте враждебных существ",
                "objectives": [
                        {"id": "kill_mobs", "type": "kill", "target": "mob_basic", "amount": 5, "current": 0}
                ],
                "rewards": {"xp": 100, "items": {"iron_ore": 5}}
        })
        
        register_quest("settlement_founder", {
                "name": "Основатель",
                "description": "Создайте своё первое поселение",
                "prerequisites": ["tutorial_build"],
                "objectives": [
                        {"id": "build_structures", "type": "build", "target": "any", "amount": 10, "current": 0},
                        {"id": "reach_population", "type": "settlement_population", "target": 5, "amount": 5, "current": 0}
                ],
                "rewards": {"xp": 500, "items": {"iron_ingot": 10}, "unlock_recipes": ["workbench_2"]}
        })

func register_quest(quest_id: String, data: Dictionary):
        quests[quest_id] = data
        quests[quest_id]["id"] = quest_id
        
        if data.get("auto_start", false):
                start_quest(1, quest_id)

func start_quest(player_id: int, quest_id: String) -> bool:
        if not quests.has(quest_id):
                return false
        
        var quest = quests[quest_id]
        
        var prereqs = quest.get("prerequisites", [])
        for prereq in prereqs:
                if not is_quest_completed(player_id, prereq):
                        return false
        
        if not active_quests.has(player_id):
                active_quests[player_id] = {}
        
        if active_quests[player_id].has(quest_id):
                return false
        
        var quest_copy = quest.duplicate(true)
        active_quests[player_id][quest_id] = quest_copy
        
        emit_signal("quest_started", quest_id)
        return true

func is_quest_completed(player_id: int, quest_id: String) -> bool:
        if not completed_quests.has(player_id):
                return false
        return quest_id in completed_quests[player_id]

func update_objective(player_id: int, objective_type: String, target: String, amount: int = 1):
        if not active_quests.has(player_id):
                return
        
        for quest_id in active_quests[player_id].keys():
                var quest = active_quests[player_id][quest_id]
                
                for i in range(quest.objectives.size()):
                        var obj = quest.objectives[i]
                        
                        if obj.type == objective_type and (obj.target == target or obj.target == "any"):
                                obj.current = min(obj.current + amount, obj.amount)
                                quest.objectives[i] = obj
                                emit_signal("objective_updated", quest_id, obj.id, obj.current, obj.amount)
                                
                                _check_quest_completion(player_id, quest_id)

func _check_quest_completion(player_id: int, quest_id: String):
        if not active_quests.has(player_id) or not active_quests[player_id].has(quest_id):
                return
        
        var quest = active_quests[player_id][quest_id]
        var all_complete = true
        
        for obj in quest.objectives:
                if obj.current < obj.amount:
                        all_complete = false
                        break
        
        if all_complete:
                complete_quest(player_id, quest_id)

func complete_quest(player_id: int, quest_id: String):
        if not active_quests.has(player_id) or not active_quests[player_id].has(quest_id):
                return
        
        var quest = active_quests[player_id][quest_id]
        var rewards = quest.get("rewards", {})
        
        var prog = get_node_or_null("/root/PlayerProgression")
        if prog and rewards.has("xp"):
                prog.add_xp(player_id, rewards.xp)
        
        if prog and rewards.has("skill_xp"):
                for skill in rewards.skill_xp.keys():
                        prog.add_skill_xp(player_id, skill, rewards.skill_xp[skill])
        
        var inv = get_node_or_null("/root/Inventory")
        if inv and rewards.has("items"):
                for item_id in rewards.items.keys():
                        inv.add_item(item_id, rewards.items[item_id], 1.0)
        
        var craft = get_node_or_null("/root/CraftSystem")
        if craft and rewards.has("unlock_recipes"):
                for recipe_id in rewards.unlock_recipes:
                        craft.unlock_recipe(player_id, recipe_id)
        
        active_quests[player_id].erase(quest_id)
        
        if not completed_quests.has(player_id):
                completed_quests[player_id] = []
        completed_quests[player_id].append(quest_id)
        
        emit_signal("quest_completed", quest_id)
        
        _check_unlocked_quests(player_id)

func _check_unlocked_quests(player_id: int):
        for quest_id in quests.keys():
                if is_quest_completed(player_id, quest_id):
                        continue
                if active_quests.has(player_id) and active_quests[player_id].has(quest_id):
                        continue
                
                var quest = quests[quest_id]
                var prereqs = quest.get("prerequisites", [])
                var can_start = true
                
                for prereq in prereqs:
                        if not is_quest_completed(player_id, prereq):
                                can_start = false
                                break
                
                if can_start and not quest.get("auto_start", false):
                        pass

func fail_quest(player_id: int, quest_id: String):
        if not active_quests.has(player_id) or not active_quests[player_id].has(quest_id):
                return
        
        active_quests[player_id].erase(quest_id)
        emit_signal("quest_failed", quest_id)

func get_active_quests(player_id: int) -> Array:
        if not active_quests.has(player_id):
                return []
        return active_quests[player_id].values()

func get_available_quests(player_id: int) -> Array:
        var available := []
        
        for quest_id in quests.keys():
                if is_quest_completed(player_id, quest_id):
                        continue
                if active_quests.has(player_id) and active_quests[player_id].has(quest_id):
                        continue
                
                var quest = quests[quest_id]
                var prereqs = quest.get("prerequisites", [])
                var can_start = true
                
                for prereq in prereqs:
                        if not is_quest_completed(player_id, prereq):
                                can_start = false
                                break
                
                if can_start:
                        available.append(quest)
        
        return available

func get_quest_progress(player_id: int, quest_id: String) -> Dictionary:
        if not active_quests.has(player_id) or not active_quests[player_id].has(quest_id):
                return {}
        return active_quests[player_id][quest_id]
