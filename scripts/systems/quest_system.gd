extends Node

signal quest_started(quest_id: String)
signal quest_completed(quest_id: String)
signal quest_failed(quest_id: String)
signal objective_updated(quest_id: String, objective_id: String, current: int, target: int)
signal achievement_unlocked(achievement_id: String)
signal daily_quest_available(quest_id: String)

var quests := {}
var active_quests := {}
var completed_quests := {}
var achievements := {}
var unlocked_achievements := {}
var daily_quests := {}
var last_daily_reset := 0

var quest_categories := ["main", "side", "daily", "challenge", "exploration", "combat", "crafting"]

func _ready():
        _register_default_quests()
        _register_achievements()
        _register_daily_quests()

func _register_default_quests():
        register_quest("tutorial_gather", {
                "name": "Первые шаги",
                "name_en": "First Steps",
                "description": "Соберите базовые ресурсы для выживания",
                "description_en": "Gather basic resources for survival",
                "category": "main",
                "objectives": [
                        {"id": "gather_wood", "type": "gather", "target": "wood", "amount": 10, "current": 0},
                        {"id": "gather_stone", "type": "gather", "target": "stone", "amount": 5, "current": 0}
                ],
                "rewards": {"xp": 50, "items": {"bandage": 2}},
                "auto_start": true
        })
        
        register_quest("tutorial_craft", {
                "name": "Ремесленник",
                "name_en": "Craftsman",
                "description": "Создайте свой первый инструмент",
                "description_en": "Craft your first tool",
                "category": "main",
                "prerequisites": ["tutorial_gather"],
                "objectives": [
                        {"id": "craft_axe", "type": "craft", "target": "stone_axe", "amount": 1, "current": 0}
                ],
                "rewards": {"xp": 75, "items": {"torch": 3}}
        })
        
        register_quest("tutorial_build", {
                "name": "Первое убежище",
                "name_en": "First Shelter",
                "description": "Постройте небольшое укрытие",
                "description_en": "Build a small shelter",
                "category": "main",
                "prerequisites": ["tutorial_craft"],
                "objectives": [
                        {"id": "build_foundation", "type": "build", "target": "wooden_foundation", "amount": 1, "current": 0},
                        {"id": "build_walls", "type": "build", "target": "wooden_wall", "amount": 4, "current": 0}
                ],
                "rewards": {"xp": 150, "items": {"cooked_meat": 5}}
        })
        
        register_quest("explore_biomes", {
                "name": "Исследователь",
                "name_en": "Explorer",
                "description": "Посетите разные биомы мира",
                "description_en": "Visit different biomes of the world",
                "category": "exploration",
                "objectives": [
                        {"id": "visit_forest", "type": "visit_biome", "target": "forest", "amount": 1, "current": 0},
                        {"id": "visit_desert", "type": "visit_biome", "target": "desert", "amount": 1, "current": 0},
                        {"id": "visit_tundra", "type": "visit_biome", "target": "tundra", "amount": 1, "current": 0}
                ],
                "rewards": {"xp": 200, "skill_xp": {"exploration": 50}}
        })
        
        register_quest("hunter", {
                "name": "Охотник",
                "name_en": "Hunter",
                "description": "Уничтожьте враждебных существ",
                "description_en": "Eliminate hostile creatures",
                "category": "combat",
                "objectives": [
                        {"id": "kill_mobs", "type": "kill", "target": "mob_basic", "amount": 5, "current": 0}
                ],
                "rewards": {"xp": 100, "items": {"iron_ore": 5}}
        })
        
        register_quest("big_game_hunter", {
                "name": "Охотник на крупную дичь",
                "name_en": "Big Game Hunter",
                "description": "Уничтожьте опасных хищников",
                "description_en": "Eliminate dangerous predators",
                "category": "combat",
                "prerequisites": ["hunter"],
                "objectives": [
                        {"id": "kill_bear", "type": "kill", "target": "bear", "amount": 3, "current": 0},
                        {"id": "kill_lion", "type": "kill", "target": "lion", "amount": 2, "current": 0}
                ],
                "rewards": {"xp": 300, "items": {"hide": 10, "meat": 15}}
        })
        
        register_quest("boss_slayer", {
                "name": "Убийца боссов",
                "name_en": "Boss Slayer",
                "description": "Победите могущественного босса",
                "description_en": "Defeat a powerful boss",
                "category": "challenge",
                "prerequisites": ["big_game_hunter"],
                "objectives": [
                        {"id": "kill_boss", "type": "kill", "target": "boss", "amount": 1, "current": 0}
                ],
                "rewards": {"xp": 1000, "items": {"steel_ingot": 20, "gold_ingot": 5}}
        })
        
        register_quest("settlement_founder", {
                "name": "Основатель",
                "name_en": "Founder",
                "description": "Создайте своё первое поселение",
                "description_en": "Create your first settlement",
                "category": "main",
                "prerequisites": ["tutorial_build"],
                "objectives": [
                        {"id": "build_structures", "type": "build", "target": "any", "amount": 10, "current": 0},
                        {"id": "reach_population", "type": "settlement_population", "target": 5, "amount": 5, "current": 0}
                ],
                "rewards": {"xp": 500, "items": {"iron_ingot": 10}, "unlock_recipes": ["workbench_2"]}
        })
        
        register_quest("master_blacksmith", {
                "name": "Мастер-кузнец",
                "name_en": "Master Blacksmith",
                "description": "Создайте продвинутое снаряжение",
                "description_en": "Create advanced equipment",
                "category": "crafting",
                "objectives": [
                        {"id": "craft_steel_items", "type": "craft_tier", "target": 3, "amount": 5, "current": 0}
                ],
                "rewards": {"xp": 400, "skill_xp": {"blacksmith": 100}}
        })
        
        register_quest("survive_night", {
                "name": "Пережить ночь",
                "name_en": "Survive the Night",
                "description": "Переживите полную ночь без смерти",
                "description_en": "Survive a full night without dying",
                "category": "challenge",
                "objectives": [
                        {"id": "survive_night", "type": "survive_time", "target": "night", "amount": 1, "current": 0}
                ],
                "rewards": {"xp": 150, "items": {"torch": 5}}
        })
        
        register_quest("trader_relations", {
                "name": "Торговые связи",
                "name_en": "Trade Relations",
                "description": "Улучшите репутацию с торговцами",
                "description_en": "Improve reputation with traders",
                "category": "side",
                "objectives": [
                        {"id": "trade_count", "type": "trade", "target": "any", "amount": 10, "current": 0}
                ],
                "rewards": {"xp": 200, "reputation": {"traders": 25}}
        })
        
        register_quest("rare_hunter", {
                "name": "Охотник за редкостями",
                "name_en": "Rare Hunter",
                "description": "Найдите и уничтожьте редкого моба",
                "description_en": "Find and eliminate a rare mob",
                "category": "challenge",
                "objectives": [
                        {"id": "kill_rare", "type": "kill", "target": "rare", "amount": 1, "current": 0}
                ],
                "rewards": {"xp": 500, "items": {"gold_ingot": 3}}
        })

func _register_achievements():
        register_achievement("first_kill", {
                "name": "Первая кровь",
                "name_en": "First Blood",
                "description": "Убейте первого моба",
                "description_en": "Kill your first mob",
                "condition": {"type": "kill_count", "amount": 1},
                "reward": {"xp": 25}
        })
        
        register_achievement("killer_100", {
                "name": "Истребитель",
                "name_en": "Exterminator",
                "description": "Убейте 100 мобов",
                "description_en": "Kill 100 mobs",
                "condition": {"type": "kill_count", "amount": 100},
                "reward": {"xp": 250, "title": "Истребитель"}
        })
        
        register_achievement("gatherer_1000", {
                "name": "Собиратель",
                "name_en": "Gatherer",
                "description": "Соберите 1000 ресурсов",
                "description_en": "Gather 1000 resources",
                "condition": {"type": "gather_count", "amount": 1000},
                "reward": {"xp": 200}
        })
        
        register_achievement("level_10", {
                "name": "Опытный",
                "name_en": "Experienced",
                "description": "Достигните 10 уровня",
                "description_en": "Reach level 10",
                "condition": {"type": "level", "amount": 10},
                "reward": {"xp": 100, "items": {"medicine": 5}}
        })
        
        register_achievement("level_25", {
                "name": "Ветеран",
                "name_en": "Veteran",
                "description": "Достигните 25 уровня",
                "description_en": "Reach level 25",
                "condition": {"type": "level", "amount": 25},
                "reward": {"xp": 500, "title": "Ветеран"}
        })
        
        register_achievement("level_50", {
                "name": "Легенда",
                "name_en": "Legend",
                "description": "Достигните 50 уровня",
                "description_en": "Reach level 50",
                "condition": {"type": "level", "amount": 50},
                "reward": {"xp": 1000, "title": "Легенда"}
        })
        
        register_achievement("builder_100", {
                "name": "Архитектор",
                "name_en": "Architect",
                "description": "Постройте 100 строений",
                "description_en": "Build 100 structures",
                "condition": {"type": "build_count", "amount": 100},
                "reward": {"xp": 300, "title": "Архитектор"}
        })
        
        register_achievement("survivor_7days", {
                "name": "Выживший",
                "name_en": "Survivor",
                "description": "Проживите 7 игровых дней",
                "description_en": "Survive 7 in-game days",
                "condition": {"type": "days_survived", "amount": 7},
                "reward": {"xp": 200}
        })
        
        register_achievement("all_biomes", {
                "name": "Путешественник",
                "name_en": "Traveler",
                "description": "Посетите все биомы",
                "description_en": "Visit all biomes",
                "condition": {"type": "biomes_visited", "amount": 10},
                "reward": {"xp": 500, "title": "Путешественник"}
        })
        
        register_achievement("boss_killer", {
                "name": "Победитель боссов",
                "name_en": "Boss Killer",
                "description": "Победите 5 боссов",
                "description_en": "Defeat 5 bosses",
                "condition": {"type": "boss_kills", "amount": 5},
                "reward": {"xp": 1000, "title": "Победитель боссов"}
        })
        
        register_achievement("wealthy", {
                "name": "Богач",
                "name_en": "Wealthy",
                "description": "Накопите 1000 золота",
                "description_en": "Accumulate 1000 gold",
                "condition": {"type": "gold_accumulated", "amount": 1000},
                "reward": {"xp": 300, "title": "Богач"}
        })
        
        register_achievement("crafter_master", {
                "name": "Мастер ремесла",
                "name_en": "Master Crafter",
                "description": "Создайте 500 предметов",
                "description_en": "Craft 500 items",
                "condition": {"type": "craft_count", "amount": 500},
                "reward": {"xp": 400, "title": "Мастер ремесла"}
        })

func _register_daily_quests():
        var daily_templates := [
                {
                        "id": "daily_gather_wood",
                        "name": "Дровосек дня",
                        "name_en": "Woodcutter of the Day",
                        "objectives": [{"id": "gather", "type": "gather", "target": "wood", "amount": 50, "current": 0}],
                        "rewards": {"xp": 100, "items": {"torch": 5}}
                },
                {
                        "id": "daily_gather_stone",
                        "name": "Каменщик дня",
                        "name_en": "Stonecutter of the Day",
                        "objectives": [{"id": "gather", "type": "gather", "target": "stone", "amount": 30, "current": 0}],
                        "rewards": {"xp": 100, "items": {"iron_ore": 3}}
                },
                {
                        "id": "daily_hunt",
                        "name": "Охота дня",
                        "name_en": "Hunt of the Day",
                        "objectives": [{"id": "kill", "type": "kill", "target": "any", "amount": 10, "current": 0}],
                        "rewards": {"xp": 150, "items": {"meat": 10}}
                },
                {
                        "id": "daily_craft",
                        "name": "Крафт дня",
                        "name_en": "Craft of the Day",
                        "objectives": [{"id": "craft", "type": "craft", "target": "any", "amount": 5, "current": 0}],
                        "rewards": {"xp": 100, "items": {"bandage": 5}}
                },
                {
                        "id": "daily_explore",
                        "name": "Разведка дня",
                        "name_en": "Exploration of the Day",
                        "objectives": [{"id": "explore", "type": "distance_traveled", "target": "any", "amount": 1000, "current": 0}],
                        "rewards": {"xp": 120, "items": {"water_bottle": 3}}
                }
        ]
        
        for template in daily_templates:
                daily_quests[template["id"]] = template

func register_quest(quest_id: String, data: Dictionary):
        quests[quest_id] = data
        quests[quest_id]["id"] = quest_id
        
        if data.get("auto_start", false):
                start_quest(1, quest_id)

func register_achievement(achievement_id: String, data: Dictionary):
        achievements[achievement_id] = data
        achievements[achievement_id]["id"] = achievement_id

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
        
        var notif = get_node_or_null("/root/NotificationSystem")
        if notif and notif.has_method("notify"):
                var loc = get_node_or_null("/root/LocalizationService")
                var lang = "ru"
                if loc and loc.has_method("get_language"):
                        lang = loc.get_language()
                var name_key = "name_en" if lang == "en" else "name"
                notif.notify("Квест: " + quest.get(name_key, quest["name"]))
        
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
        
        _check_achievements(player_id, objective_type, target, amount)

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
                prog.add_xp(player_id, rewards["xp"])
        
        if prog and rewards.has("skill_xp"):
                for skill in rewards["skill_xp"].keys():
                        prog.add_skill_xp(player_id, skill, rewards["skill_xp"][skill])
        
        var inv = get_node_or_null("/root/Inventory")
        if inv and rewards.has("items"):
                for item_id in rewards["items"].keys():
                        inv.add_item(item_id, rewards["items"][item_id], 1.0)
        
        var craft = get_node_or_null("/root/CraftSystem")
        if craft and rewards.has("unlock_recipes"):
                for recipe_id in rewards["unlock_recipes"]:
                        craft.unlock_recipe(player_id, recipe_id)
        
        var faction_sys = get_node_or_null("/root/FactionSystem")
        if faction_sys and rewards.has("reputation"):
                for faction in rewards["reputation"].keys():
                        faction_sys.modify_player_reputation(player_id, faction, rewards["reputation"][faction])
        
        active_quests[player_id].erase(quest_id)
        
        if not completed_quests.has(player_id):
                completed_quests[player_id] = []
        completed_quests[player_id].append(quest_id)
        
        emit_signal("quest_completed", quest_id)
        
        var notif = get_node_or_null("/root/NotificationSystem")
        if notif and notif.has_method("notify_success"):
                var loc = get_node_or_null("/root/LocalizationService")
                var lang = "ru"
                if loc and loc.has_method("get_language"):
                        lang = loc.get_language()
                var name_key = "name_en" if lang == "en" else "name"
                notif.notify_success(quest.get(name_key, quest["name"]) + " - завершен!")
        
        _check_unlocked_quests(player_id)

func _check_achievements(player_id: int, objective_type: String, target: String, amount: int):
        pass

func unlock_achievement(player_id: int, achievement_id: String):
        if not achievements.has(achievement_id):
                return
        
        if not unlocked_achievements.has(player_id):
                unlocked_achievements[player_id] = []
        
        if achievement_id in unlocked_achievements[player_id]:
                return
        
        unlocked_achievements[player_id].append(achievement_id)
        
        var achievement = achievements[achievement_id]
        var reward = achievement.get("reward", {})
        
        var prog = get_node_or_null("/root/PlayerProgression")
        if prog and reward.has("xp"):
                prog.add_xp(player_id, reward["xp"])
        
        var inv = get_node_or_null("/root/Inventory")
        if inv and reward.has("items"):
                for item_id in reward["items"].keys():
                        inv.add_item(item_id, reward["items"][item_id], 1.0)
        
        emit_signal("achievement_unlocked", achievement_id)
        
        var notif = get_node_or_null("/root/NotificationSystem")
        if notif and notif.has_method("notify_achievement"):
                var loc = get_node_or_null("/root/LocalizationService")
                var lang = "ru"
                if loc and loc.has_method("get_language"):
                        lang = loc.get_language()
                var name_key = "name_en" if lang == "en" else "name"
                notif.notify_achievement(achievement.get(name_key, achievement["name"]))

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

func get_achievements(player_id: int) -> Dictionary:
        var result := {}
        for ach_id in achievements.keys():
                result[ach_id] = {
                        "data": achievements[ach_id],
                        "unlocked": unlocked_achievements.has(player_id) and ach_id in unlocked_achievements[player_id]
                }
        return result

func get_quests_by_category(category: String) -> Array:
        var result := []
        for quest_id in quests.keys():
                if quests[quest_id].get("category", "") == category:
                        result.append(quests[quest_id])
        return result
