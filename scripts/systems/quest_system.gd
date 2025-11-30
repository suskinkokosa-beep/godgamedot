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

var dynamic_quests := {}
var generated_quest_counter := 0

var biome_quest_templates := {
        "forest": [
                {"name_ru": "Лесозаготовка", "name_en": "Logging", "type": "gather", "target": "wood", "base_amount": 30},
                {"name_ru": "Охота в лесу", "name_en": "Forest Hunt", "type": "kill", "target": "wolf", "base_amount": 3},
                {"name_ru": "Сбор грибов", "name_en": "Mushroom Gathering", "type": "gather", "target": "mushroom", "base_amount": 10}
        ],
        "desert": [
                {"name_ru": "Поиск оазиса", "name_en": "Oasis Search", "type": "explore", "target": "water_source", "base_amount": 1},
                {"name_ru": "Охота на скорпионов", "name_en": "Scorpion Hunt", "type": "kill", "target": "scorpion", "base_amount": 5},
                {"name_ru": "Добыча песчаника", "name_en": "Sandstone Mining", "type": "gather", "target": "stone", "base_amount": 20}
        ],
        "tundra": [
                {"name_ru": "Выживание в холоде", "name_en": "Cold Survival", "type": "survive", "target": "cold", "base_amount": 300},
                {"name_ru": "Охота на медведей", "name_en": "Bear Hunt", "type": "kill", "target": "bear", "base_amount": 2},
                {"name_ru": "Заготовка топлива", "name_en": "Fuel Gathering", "type": "gather", "target": "coal", "base_amount": 15}
        ],
        "mountains": [
                {"name_ru": "Добыча руды", "name_en": "Ore Mining", "type": "gather", "target": "iron_ore", "base_amount": 20},
                {"name_ru": "Восхождение", "name_en": "Mountain Climb", "type": "reach_height", "target": "height", "base_amount": 50},
                {"name_ru": "Истребление горных львов", "name_en": "Mountain Lion Hunt", "type": "kill", "target": "lion", "base_amount": 3}
        ],
        "swamp": [
                {"name_ru": "Болотная охота", "name_en": "Swamp Hunt", "type": "kill", "target": "boar", "base_amount": 4},
                {"name_ru": "Сбор лекарственных трав", "name_en": "Herb Gathering", "type": "gather", "target": "herbs", "base_amount": 15},
                {"name_ru": "Очистка болота", "name_en": "Swamp Cleansing", "type": "clear_area", "target": "swamp", "base_amount": 1}
        ]
}

var faction_quest_templates := {
        "traders": [
                {"name_ru": "Торговая поставка", "name_en": "Trade Delivery", "type": "deliver", "base_amount": 1},
                {"name_ru": "Охрана каравана", "name_en": "Caravan Guard", "type": "escort", "base_amount": 1},
                {"name_ru": "Рыночные закупки", "name_en": "Market Purchase", "type": "trade", "base_amount": 5}
        ],
        "bandits": [
                {"name_ru": "Рейд на склад", "name_en": "Warehouse Raid", "type": "raid", "base_amount": 1},
                {"name_ru": "Ограбление", "name_en": "Robbery", "type": "steal", "base_amount": 100},
                {"name_ru": "Засада", "name_en": "Ambush", "type": "kill", "base_amount": 5}
        ],
        "settlers": [
                {"name_ru": "Строительство укреплений", "name_en": "Fortification", "type": "build", "base_amount": 5},
                {"name_ru": "Обеспечение продовольствием", "name_en": "Food Supply", "type": "deliver", "base_amount": 1},
                {"name_ru": "Набор поселенцев", "name_en": "Settler Recruitment", "type": "recruit", "base_amount": 3}
        ],
        "military": [
                {"name_ru": "Патрулирование", "name_en": "Patrol", "type": "patrol", "base_amount": 1},
                {"name_ru": "Истребление угрозы", "name_en": "Threat Elimination", "type": "kill", "base_amount": 10},
                {"name_ru": "Оборона позиции", "name_en": "Position Defense", "type": "defend", "base_amount": 1}
        ]
}

var event_quest_templates := [
        {"id": "blood_moon", "name_ru": "Кровавая луна", "name_en": "Blood Moon", "type": "survive_event", "difficulty": 3},
        {"id": "invasion", "name_ru": "Вторжение", "name_en": "Invasion", "type": "defend_settlement", "difficulty": 4},
        {"id": "treasure_hunt", "name_ru": "Охота за сокровищами", "name_en": "Treasure Hunt", "type": "find_treasure", "difficulty": 2},
        {"id": "rare_spawn", "name_ru": "Редкий зверь", "name_en": "Rare Beast", "type": "hunt_rare", "difficulty": 3},
        {"id": "meteor_shower", "name_ru": "Метеоритный дождь", "name_en": "Meteor Shower", "type": "collect_meteors", "difficulty": 2}
]

func generate_biome_quest(player_id: int, biome: String, difficulty: int = 1) -> String:
        if not biome_quest_templates.has(biome):
                biome = "forest"
        
        if _has_active_biome_quest(player_id, biome):
                return ""
        
        var templates = biome_quest_templates[biome]
        var template = templates[randi() % templates.size()]
        
        generated_quest_counter += 1
        var timestamp = int(Time.get_unix_time_from_system())
        var quest_id = "dynamic_biome_%d_%d_%d" % [player_id, generated_quest_counter, timestamp]
        
        var amount = int(template["base_amount"] * (1.0 + difficulty * 0.5))
        var xp_reward = 50 * difficulty + randi() % 50
        
        var quest_data = {
                "id": quest_id,
                "name": template["name_ru"],
                "name_en": template["name_en"],
                "description": "Динамический квест в биоме: " + biome,
                "description_en": "Dynamic quest in biome: " + biome,
                "category": "exploration",
                "is_dynamic": true,
                "difficulty": difficulty,
                "biome": biome,
                "objectives": [
                        {"id": "main_obj", "type": template["type"], "target": template["target"], "amount": amount, "current": 0}
                ],
                "rewards": {"xp": xp_reward},
                "expires_in": 3600,
                "created_at": timestamp
        }
        
        dynamic_quests[quest_id] = quest_data.duplicate(true)
        _register_dynamic_quest(quest_id, quest_data.duplicate(true))
        start_quest(player_id, quest_id)
        
        return quest_id

func _has_active_biome_quest(player_id: int, biome: String) -> bool:
        if not active_quests.has(player_id):
                return false
        for quest_id in active_quests[player_id].keys():
                var quest = active_quests[player_id][quest_id]
                if quest.get("is_dynamic", false) and quest.get("biome", "") == biome:
                        return true
        return false

func _register_dynamic_quest(quest_id: String, data: Dictionary):
        if quests.has(quest_id):
                return
        quests[quest_id] = data.duplicate(true)

func generate_faction_quest(player_id: int, faction: String, reputation: int = 0) -> String:
        if not faction_quest_templates.has(faction):
                return ""
        
        if _has_active_faction_quest(player_id, faction):
                return ""
        
        var templates = faction_quest_templates[faction]
        var template = templates[randi() % templates.size()]
        
        generated_quest_counter += 1
        var timestamp = int(Time.get_unix_time_from_system())
        var quest_id = "dynamic_faction_%d_%d_%d" % [player_id, generated_quest_counter, timestamp]
        
        var difficulty = 1 + int(abs(reputation) / 25)
        var amount = int(template["base_amount"] * (1.0 + difficulty * 0.3))
        var xp_reward = 75 * difficulty
        var rep_reward = 10 + difficulty * 5
        
        var quest_data = {
                "id": quest_id,
                "name": template["name_ru"],
                "name_en": template["name_en"],
                "description": "Задание от фракции: " + faction,
                "description_en": "Quest from faction: " + faction,
                "category": "side",
                "is_dynamic": true,
                "faction": faction,
                "difficulty": difficulty,
                "objectives": [
                        {"id": "faction_obj", "type": template["type"], "target": "any", "amount": amount, "current": 0}
                ],
                "rewards": {"xp": xp_reward, "reputation": {faction: rep_reward}},
                "expires_in": 7200,
                "created_at": timestamp
        }
        
        dynamic_quests[quest_id] = quest_data.duplicate(true)
        _register_dynamic_quest(quest_id, quest_data.duplicate(true))
        
        return quest_id

func _has_active_faction_quest(player_id: int, faction: String) -> bool:
        if not active_quests.has(player_id):
                return false
        for quest_id in active_quests[player_id].keys():
                var quest = active_quests[player_id][quest_id]
                if quest.get("is_dynamic", false) and quest.get("faction", "") == faction:
                        return true
        return false

func generate_event_quest(event_type: String) -> String:
        if _has_active_event_quest(event_type):
                return ""
        
        var template = null
        for t in event_quest_templates:
                if t["id"] == event_type:
                        template = t
                        break
        
        if template == null:
                template = event_quest_templates[randi() % event_quest_templates.size()]
        
        generated_quest_counter += 1
        var timestamp = int(Time.get_unix_time_from_system())
        var quest_id = "event_%s_%d_%d" % [event_type, generated_quest_counter, timestamp]
        
        var difficulty = template["difficulty"]
        var xp_reward = 100 * difficulty
        
        var quest_data = {
                "id": quest_id,
                "name": template["name_ru"],
                "name_en": template["name_en"],
                "description": "Особое мировое событие!",
                "description_en": "Special world event!",
                "category": "challenge",
                "is_dynamic": true,
                "is_event": true,
                "event_type": event_type,
                "difficulty": difficulty,
                "objectives": [
                        {"id": "event_obj", "type": template["type"], "target": event_type, "amount": 1, "current": 0}
                ],
                "rewards": {"xp": xp_reward, "items": {"gold_ingot": difficulty}},
                "expires_in": 1800,
                "created_at": timestamp
        }
        
        dynamic_quests[quest_id] = quest_data.duplicate(true)
        _register_dynamic_quest(quest_id, quest_data.duplicate(true))
        
        for player_id in active_quests.keys():
                start_quest(player_id, quest_id)
        
        return quest_id

func _has_active_event_quest(event_type: String) -> bool:
        for quest_id in dynamic_quests.keys():
                var quest = dynamic_quests[quest_id]
                if quest.get("is_event", false) and quest.get("event_type", "") == event_type:
                        return true
        return false

func get_dynamic_quests_for_player(player_id: int) -> Array:
        var result := []
        for quest_id in dynamic_quests.keys():
                if active_quests.has(player_id) and active_quests[player_id].has(quest_id):
                        result.append(dynamic_quests[quest_id])
        return result

func cleanup_expired_quests():
        var current_time = Time.get_unix_time_from_system()
        var to_remove := []
        
        for quest_id in dynamic_quests.keys():
                var quest = dynamic_quests[quest_id]
                if quest.has("created_at") and quest.has("expires_in"):
                        if current_time - quest["created_at"] > quest["expires_in"]:
                                to_remove.append(quest_id)
        
        for quest_id in to_remove:
                for player_id in active_quests.keys():
                        if active_quests[player_id].has(quest_id):
                                fail_quest(player_id, quest_id)
                dynamic_quests.erase(quest_id)
                quests.erase(quest_id)
