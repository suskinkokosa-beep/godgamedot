extends Node

signal tech_researched(tech_id, player_id)
signal tech_started(tech_id, player_id)
signal tech_progress(tech_id, progress, total)

enum TechCategory {
        SURVIVAL,
        BUILDING,
        METALLURGY,
        WEAPONS,
        ARMOR,
        AGRICULTURE,
        MEDICINE,
        CRAFTING,
        MAGIC,
        SIEGE,
        TRADE,
        GOVERNMENT
}

var technologies := {
        "basic_tools": {
                "name": "Базовые инструменты",
                "description": "Создание простых каменных и деревянных инструментов",
                "category": TechCategory.CRAFTING,
                "research_time": 30.0,
                "cost": {"wood": 10, "stone": 5},
                "prerequisites": [],
                "unlocks": ["stone_axe", "stone_pickaxe", "wooden_club"],
                "effects": {}
        },
        "fire_making": {
                "name": "Добыча огня",
                "description": "Умение разжигать костры и факелы",
                "category": TechCategory.SURVIVAL,
                "research_time": 45.0,
                "cost": {"wood": 20, "flint": 5},
                "prerequisites": [],
                "unlocks": ["campfire", "torch"],
                "effects": {"cold_resistance": 0.2}
        },
        "basic_shelter": {
                "name": "Базовое укрытие",
                "description": "Строительство простых деревянных строений",
                "category": TechCategory.BUILDING,
                "research_time": 60.0,
                "cost": {"wood": 50},
                "prerequisites": ["basic_tools"],
                "unlocks": ["wooden_wall", "wooden_floor", "wooden_door"],
                "effects": {}
        },
        "copper_working": {
                "name": "Обработка меди",
                "description": "Плавка и обработка медной руды",
                "category": TechCategory.METALLURGY,
                "research_time": 120.0,
                "cost": {"stone": 30, "copper_ore": 20},
                "prerequisites": ["basic_tools", "fire_making"],
                "unlocks": ["copper_axe", "copper_pickaxe", "copper_sword"],
                "effects": {"mining_speed": 0.1}
        },
        "iron_working": {
                "name": "Обработка железа",
                "description": "Плавка и обработка железной руды",
                "category": TechCategory.METALLURGY,
                "research_time": 240.0,
                "cost": {"copper": 50, "iron_ore": 30},
                "prerequisites": ["copper_working"],
                "unlocks": ["iron_axe", "iron_pickaxe", "iron_sword", "iron_armor"],
                "effects": {"mining_speed": 0.2}
        },
        "steel_forging": {
                "name": "Ковка стали",
                "description": "Создание высококачественной стали",
                "category": TechCategory.METALLURGY,
                "research_time": 480.0,
                "cost": {"iron": 100, "coal": 50},
                "prerequisites": ["iron_working"],
                "unlocks": ["steel_sword", "steel_armor", "steel_tools"],
                "effects": {"weapon_damage": 0.2, "armor_protection": 0.2}
        },
        "archery": {
                "name": "Стрельба из лука",
                "description": "Создание луков и стрел",
                "category": TechCategory.WEAPONS,
                "research_time": 90.0,
                "cost": {"wood": 30, "fiber": 20},
                "prerequisites": ["basic_tools"],
                "unlocks": ["wooden_bow", "arrows"],
                "effects": {}
        },
        "crossbow": {
                "name": "Арбалет",
                "description": "Мощное дальнобойное оружие",
                "category": TechCategory.WEAPONS,
                "research_time": 180.0,
                "cost": {"wood": 50, "iron": 30, "fiber": 20},
                "prerequisites": ["archery", "iron_working"],
                "unlocks": ["crossbow", "bolts"],
                "effects": {}
        },
        "leather_working": {
                "name": "Обработка кожи",
                "description": "Создание кожаной брони и сумок",
                "category": TechCategory.ARMOR,
                "research_time": 75.0,
                "cost": {"leather": 20, "fiber": 10},
                "prerequisites": ["basic_tools"],
                "unlocks": ["leather_armor", "leather_bag"],
                "effects": {}
        },
        "chainmail": {
                "name": "Кольчуга",
                "description": "Плетение кольчужной брони",
                "category": TechCategory.ARMOR,
                "research_time": 200.0,
                "cost": {"iron": 80},
                "prerequisites": ["iron_working", "leather_working"],
                "unlocks": ["chainmail_armor"],
                "effects": {}
        },
        "plate_armor": {
                "name": "Латные доспехи",
                "description": "Лучшая защита для воинов",
                "category": TechCategory.ARMOR,
                "research_time": 360.0,
                "cost": {"steel": 100, "leather": 30},
                "prerequisites": ["steel_forging", "chainmail"],
                "unlocks": ["plate_armor", "plate_helmet"],
                "effects": {}
        },
        "farming": {
                "name": "Земледелие",
                "description": "Выращивание культур",
                "category": TechCategory.AGRICULTURE,
                "research_time": 90.0,
                "cost": {"wood": 20, "seeds": 10},
                "prerequisites": ["basic_tools"],
                "unlocks": ["farm_plot", "hoe", "wheat", "carrots"],
                "effects": {"food_production": 0.3}
        },
        "animal_husbandry": {
                "name": "Животноводство",
                "description": "Разведение домашних животных",
                "category": TechCategory.AGRICULTURE,
                "research_time": 150.0,
                "cost": {"wood": 50, "food": 30},
                "prerequisites": ["farming"],
                "unlocks": ["animal_pen", "chicken", "pig", "cow"],
                "effects": {"food_production": 0.2, "leather_production": 0.3}
        },
        "herbal_medicine": {
                "name": "Травяная медицина",
                "description": "Создание лечебных зелий из трав",
                "category": TechCategory.MEDICINE,
                "research_time": 60.0,
                "cost": {"herbs": 20},
                "prerequisites": [],
                "unlocks": ["healing_salve", "antidote"],
                "effects": {"healing_rate": 0.2}
        },
        "advanced_medicine": {
                "name": "Продвинутая медицина",
                "description": "Сложные медицинские препараты",
                "category": TechCategory.MEDICINE,
                "research_time": 180.0,
                "cost": {"herbs": 50, "alcohol": 20},
                "prerequisites": ["herbal_medicine"],
                "unlocks": ["medkit", "cure_disease", "stimulant"],
                "effects": {"healing_rate": 0.3, "disease_resistance": 0.2}
        },
        "stone_masonry": {
                "name": "Каменная кладка",
                "description": "Строительство каменных зданий",
                "category": TechCategory.BUILDING,
                "research_time": 120.0,
                "cost": {"stone": 100, "iron": 20},
                "prerequisites": ["basic_shelter", "copper_working"],
                "unlocks": ["stone_wall", "stone_floor", "stone_foundation"],
                "effects": {"building_durability": 0.3}
        },
        "fortification": {
                "name": "Фортификация",
                "description": "Оборонительные укрепления",
                "category": TechCategory.BUILDING,
                "research_time": 240.0,
                "cost": {"stone": 200, "iron": 50},
                "prerequisites": ["stone_masonry"],
                "unlocks": ["watchtower", "palisade", "gate", "moat"],
                "effects": {"settlement_defense": 0.4}
        },
        "siege_weapons": {
                "name": "Осадные орудия",
                "description": "Катапульты и тараны",
                "category": TechCategory.SIEGE,
                "research_time": 300.0,
                "cost": {"wood": 150, "iron": 80, "rope": 40},
                "prerequisites": ["iron_working", "fortification"],
                "unlocks": ["battering_ram", "catapult", "siege_ladder"],
                "effects": {}
        },
        "advanced_siege": {
                "name": "Продвинутая осада",
                "description": "Требушеты и осадные башни",
                "category": TechCategory.SIEGE,
                "research_time": 480.0,
                "cost": {"wood": 300, "steel": 100, "rope": 80},
                "prerequisites": ["siege_weapons", "steel_forging"],
                "unlocks": ["trebuchet", "siege_tower", "ballista"],
                "effects": {}
        },
        "basic_trade": {
                "name": "Основы торговли",
                "description": "Торговые навыки и караваны",
                "category": TechCategory.TRADE,
                "research_time": 90.0,
                "cost": {"gold": 50},
                "prerequisites": [],
                "unlocks": ["trade_post", "caravan"],
                "effects": {"trade_profit": 0.1}
        },
        "advanced_trade": {
                "name": "Продвинутая торговля",
                "description": "Торговые гильдии и маршруты",
                "category": TechCategory.TRADE,
                "research_time": 180.0,
                "cost": {"gold": 200},
                "prerequisites": ["basic_trade"],
                "unlocks": ["trade_guild", "trade_route"],
                "effects": {"trade_profit": 0.25}
        },
        "tribal_governance": {
                "name": "Племенное управление",
                "description": "Базовая организация поселения",
                "category": TechCategory.GOVERNMENT,
                "research_time": 60.0,
                "cost": {},
                "prerequisites": ["basic_shelter"],
                "unlocks": ["chieftain_hut"],
                "effects": {"max_population": 20}
        },
        "feudal_system": {
                "name": "Феодальная система",
                "description": "Иерархическое управление",
                "category": TechCategory.GOVERNMENT,
                "research_time": 240.0,
                "cost": {"gold": 100},
                "prerequisites": ["tribal_governance", "stone_masonry"],
                "unlocks": ["castle", "noble_titles"],
                "effects": {"max_population": 100, "army_size": 0.3}
        },
        "arcane_studies": {
                "name": "Изучение магии",
                "description": "Первые шаги в магических искусствах",
                "category": TechCategory.MAGIC,
                "research_time": 300.0,
                "cost": {"magic_essence": 20, "books": 10},
                "prerequisites": ["advanced_medicine"],
                "unlocks": ["spell_heal", "mana_potion"],
                "effects": {"magic_power": 0.1}
        },
        "elemental_magic": {
                "name": "Стихийная магия",
                "description": "Управление огнём, водой, землёй и воздухом",
                "category": TechCategory.MAGIC,
                "research_time": 480.0,
                "cost": {"magic_essence": 50, "elemental_shards": 20},
                "prerequisites": ["arcane_studies"],
                "unlocks": ["spell_fireball", "spell_ice_shield", "spell_earthshake"],
                "effects": {"magic_power": 0.3}
        }
}

var player_research := {}
var active_research := {}

func _ready():
        pass

func _process(delta):
        _update_research(delta)

func _update_research(delta):
        for player_id in active_research.keys():
                var research = active_research[player_id]
                research.progress += delta
                
                emit_signal("tech_progress", research.tech_id, research.progress, research.total_time)
                
                if research.progress >= research.total_time:
                        _complete_research(player_id, research.tech_id)

func start_research(player_id: int, tech_id: String) -> bool:
        if not technologies.has(tech_id):
                return false
        
        var tech = technologies[tech_id]
        
        if not _check_prerequisites(player_id, tech_id):
                return false
        
        if is_researched(player_id, tech_id):
                return false
        
        if active_research.has(player_id):
                return false
        
        if not _consume_research_cost(player_id, tech.cost):
                return false
        
        active_research[player_id] = {
                "tech_id": tech_id,
                "progress": 0.0,
                "total_time": tech.research_time
        }
        
        emit_signal("tech_started", tech_id, player_id)
        return true

func cancel_research(player_id: int):
        if active_research.has(player_id):
                active_research.erase(player_id)

func _complete_research(player_id: int, tech_id: String):
        if not player_research.has(player_id):
                player_research[player_id] = []
        
        player_research[player_id].append(tech_id)
        active_research.erase(player_id)
        
        _apply_tech_effects(player_id, tech_id)
        _unlock_recipes(player_id, tech_id)
        
        emit_signal("tech_researched", tech_id, player_id)

func _check_prerequisites(player_id: int, tech_id: String) -> bool:
        var tech = technologies.get(tech_id, {})
        var prerequisites = tech.get("prerequisites", [])
        
        for prereq in prerequisites:
                if not is_researched(player_id, prereq):
                        return false
        
        return true

func _consume_research_cost(player_id: int, cost: Dictionary) -> bool:
        var inv = get_node_or_null("/root/Inventory")
        if not inv:
                return cost.is_empty()
        
        for item_type in cost:
                var required = cost[item_type]
                if not inv.has_item_amount(item_type, required):
                        return false
        
        for item_type in cost:
                inv.remove_item_amount(item_type, cost[item_type])
        
        return true

func _apply_tech_effects(player_id: int, tech_id: String):
        var tech = technologies.get(tech_id, {})
        var effects = tech.get("effects", {})
        
        var progression = get_node_or_null("/root/PlayerProgression")
        if progression:
                for effect_name in effects:
                        var value = effects[effect_name]
                        progression.add_bonus(player_id, effect_name, value)

func _unlock_recipes(player_id: int, tech_id: String):
        var tech = technologies.get(tech_id, {})
        var unlocks = tech.get("unlocks", [])
        
        var craft_sys = get_node_or_null("/root/CraftSystem")
        if craft_sys:
                for recipe_id in unlocks:
                        craft_sys.unlock_recipe(player_id, recipe_id)

func is_researched(player_id: int, tech_id: String) -> bool:
        if not player_research.has(player_id):
                return false
        return tech_id in player_research[player_id]

func get_researched_techs(player_id: int) -> Array:
        return player_research.get(player_id, [])

func get_available_techs(player_id: int) -> Array:
        var available = []
        
        for tech_id in technologies:
                if is_researched(player_id, tech_id):
                        continue
                
                if _check_prerequisites(player_id, tech_id):
                        available.append(tech_id)
        
        return available

func get_tech_info(tech_id: String) -> Dictionary:
        return technologies.get(tech_id, {})

func get_research_progress(player_id: int) -> Dictionary:
        return active_research.get(player_id, {})

func get_techs_by_category(category: int) -> Array:
        var result = []
        for tech_id in technologies:
                if technologies[tech_id].category == category:
                        result.append(tech_id)
        return result
