extends Node

signal blueprint_unlocked(blueprint_id: String)
signal blueprint_book_opened
signal blueprint_book_closed

var blueprints := {}
var unlocked_blueprints := {}
var player_blueprints := {}

var tier_names := {
        0: {"ru": "Базовые", "en": "Basic"},
        1: {"ru": "Улучшенные", "en": "Improved"},
        2: {"ru": "Продвинутые", "en": "Advanced"},
        3: {"ru": "Мастерские", "en": "Master"}
}

var category_names := {
        "survival": {"ru": "Выживание", "en": "Survival"},
        "tools": {"ru": "Инструменты", "en": "Tools"},
        "weapons": {"ru": "Оружие", "en": "Weapons"},
        "building": {"ru": "Строительство", "en": "Building"},
        "armor": {"ru": "Броня", "en": "Armor"},
        "food": {"ru": "Еда", "en": "Food"},
        "medical": {"ru": "Медицина", "en": "Medical"},
        "materials": {"ru": "Материалы", "en": "Materials"}
}

func _ready():
        _register_all_blueprints()

func initialize_player(player_id: int):
        _unlock_starter_blueprints(player_id)

func _register_all_blueprints():
        _register_survival_blueprints()
        _register_tool_blueprints()
        _register_weapon_blueprints()
        _register_building_blueprints()
        _register_armor_blueprints()
        _register_medical_blueprints()
        _register_material_blueprints()

func _register_survival_blueprints():
        register_blueprint("stone_axe", {
                "name_ru": "Каменный топор",
                "name_en": "Stone Axe",
                "desc_ru": "Базовый инструмент для рубки деревьев",
                "desc_en": "Basic tool for chopping trees",
                "category": "survival",
                "tier": 0,
                "recipe_id": "stone_axe",
                "unlock_source": "starter",
                "icon": "res://assets/icons/stone_axe.png"
        })
        
        register_blueprint("stone_pickaxe", {
                "name_ru": "Каменная кирка",
                "name_en": "Stone Pickaxe",
                "desc_ru": "Базовый инструмент для добычи руды",
                "desc_en": "Basic tool for mining ore",
                "category": "survival",
                "tier": 0,
                "recipe_id": "stone_pickaxe",
                "unlock_source": "starter",
                "icon": "res://assets/icons/stone_pickaxe.png"
        })
        
        register_blueprint("wooden_spear", {
                "name_ru": "Деревянное копьё",
                "name_en": "Wooden Spear",
                "desc_ru": "Примитивное оружие для охоты и защиты",
                "desc_en": "Primitive weapon for hunting and defense",
                "category": "survival",
                "tier": 0,
                "recipe_id": "wooden_spear",
                "unlock_source": "starter",
                "icon": "res://assets/icons/wooden_spear.png"
        })
        
        register_blueprint("bandage", {
                "name_ru": "Бинт",
                "name_en": "Bandage",
                "desc_ru": "Простое перевязочное средство",
                "desc_en": "Simple first aid bandage",
                "category": "survival",
                "tier": 0,
                "recipe_id": "bandage",
                "unlock_source": "starter",
                "icon": "res://assets/icons/bandage.png"
        })
        
        register_blueprint("torch", {
                "name_ru": "Факел",
                "name_en": "Torch",
                "desc_ru": "Источник света в темноте",
                "desc_en": "Light source in darkness",
                "category": "survival",
                "tier": 0,
                "recipe_id": "torch",
                "unlock_source": "starter",
                "icon": "res://assets/icons/torch.png"
        })
        
        register_blueprint("campfire", {
                "name_ru": "Костёр",
                "name_en": "Campfire",
                "desc_ru": "Для приготовления пищи и обогрева",
                "desc_en": "For cooking and heating",
                "category": "survival",
                "tier": 0,
                "recipe_id": "campfire",
                "unlock_source": "starter",
                "icon": "res://assets/icons/campfire.png"
        })
        
        register_blueprint("sleeping_bag", {
                "name_ru": "Спальный мешок",
                "name_en": "Sleeping Bag",
                "desc_ru": "Точка возрождения",
                "desc_en": "Respawn point",
                "category": "survival",
                "tier": 0,
                "recipe_id": "sleeping_bag",
                "unlock_source": "starter",
                "icon": "res://assets/icons/sleeping_bag.png"
        })
        
        register_blueprint("rope", {
                "name_ru": "Верёвка",
                "name_en": "Rope",
                "desc_ru": "Полезный материал для крафта",
                "desc_en": "Useful crafting material",
                "category": "survival",
                "tier": 0,
                "recipe_id": "rope",
                "unlock_source": "starter",
                "icon": "res://assets/icons/rope.png"
        })

func _register_tool_blueprints():
        register_blueprint("hammer", {
                "name_ru": "Молоток",
                "name_en": "Hammer",
                "desc_ru": "Для строительства и ремонта",
                "desc_en": "For building and repairs",
                "category": "tools",
                "tier": 0,
                "recipe_id": "hammer",
                "unlock_source": "starter",
                "icon": "res://assets/icons/hammer.png"
        })
        
        register_blueprint("iron_axe", {
                "name_ru": "Железный топор",
                "name_en": "Iron Axe",
                "desc_ru": "Улучшенный топор из железа",
                "desc_en": "Improved iron axe",
                "category": "tools",
                "tier": 2,
                "recipe_id": "iron_axe",
                "unlock_source": "workbench_2",
                "icon": "res://assets/icons/iron_axe.png"
        })
        
        register_blueprint("iron_pickaxe", {
                "name_ru": "Железная кирка",
                "name_en": "Iron Pickaxe",
                "desc_ru": "Улучшенная кирка из железа",
                "desc_en": "Improved iron pickaxe",
                "category": "tools",
                "tier": 2,
                "recipe_id": "iron_pickaxe",
                "unlock_source": "workbench_2",
                "icon": "res://assets/icons/iron_pickaxe.png"
        })
        
        register_blueprint("steel_axe", {
                "name_ru": "Стальной топор",
                "name_en": "Steel Axe",
                "desc_ru": "Мощный стальной топор",
                "desc_en": "Powerful steel axe",
                "category": "tools",
                "tier": 3,
                "recipe_id": "steel_axe",
                "unlock_source": "workbench_3",
                "icon": "res://assets/icons/steel_axe.png"
        })
        
        register_blueprint("steel_pickaxe", {
                "name_ru": "Стальная кирка",
                "name_en": "Steel Pickaxe",
                "desc_ru": "Мощная стальная кирка",
                "desc_en": "Powerful steel pickaxe",
                "category": "tools",
                "tier": 3,
                "recipe_id": "steel_pickaxe",
                "unlock_source": "workbench_3",
                "icon": "res://assets/icons/steel_pickaxe.png"
        })
        
        register_blueprint("repair_hammer", {
                "name_ru": "Ремонтный молоток",
                "name_en": "Repair Hammer",
                "desc_ru": "Для ремонта строений",
                "desc_en": "For repairing structures",
                "category": "tools",
                "tier": 2,
                "recipe_id": "repair_hammer",
                "unlock_source": "workbench_2",
                "icon": "res://assets/icons/repair_hammer.png"
        })
        
        register_blueprint("fishing_rod", {
                "name_ru": "Удочка",
                "name_en": "Fishing Rod",
                "desc_ru": "Для ловли рыбы",
                "desc_en": "For fishing",
                "category": "tools",
                "tier": 1,
                "recipe_id": "fishing_rod",
                "unlock_source": "workbench_1",
                "icon": "res://assets/icons/fishing_rod.png"
        })

func _register_weapon_blueprints():
        register_blueprint("stone_knife", {
                "name_ru": "Каменный нож",
                "name_en": "Stone Knife",
                "desc_ru": "Примитивный режущий инструмент",
                "desc_en": "Primitive cutting tool",
                "category": "weapons",
                "tier": 0,
                "recipe_id": "stone_knife",
                "unlock_source": "starter",
                "icon": "res://assets/icons/stone_knife.png"
        })
        
        register_blueprint("bow", {
                "name_ru": "Лук",
                "name_en": "Bow",
                "desc_ru": "Дальнобойное оружие",
                "desc_en": "Ranged weapon",
                "category": "weapons",
                "tier": 1,
                "recipe_id": "bow",
                "unlock_source": "workbench_1",
                "icon": "res://assets/icons/bow.png"
        })
        
        register_blueprint("arrow", {
                "name_ru": "Стрела",
                "name_en": "Arrow",
                "desc_ru": "Боеприпас для лука",
                "desc_en": "Ammo for bow",
                "category": "weapons",
                "tier": 1,
                "recipe_id": "arrow",
                "unlock_source": "workbench_1",
                "icon": "res://assets/icons/arrow.png"
        })
        
        register_blueprint("iron_sword", {
                "name_ru": "Железный меч",
                "name_en": "Iron Sword",
                "desc_ru": "Надёжное оружие ближнего боя",
                "desc_en": "Reliable melee weapon",
                "category": "weapons",
                "tier": 2,
                "recipe_id": "iron_sword",
                "unlock_source": "workbench_2",
                "icon": "res://assets/icons/iron_sword.png"
        })
        
        register_blueprint("crossbow", {
                "name_ru": "Арбалет",
                "name_en": "Crossbow",
                "desc_ru": "Мощное дальнобойное оружие",
                "desc_en": "Powerful ranged weapon",
                "category": "weapons",
                "tier": 2,
                "recipe_id": "crossbow",
                "unlock_source": "workbench_2",
                "icon": "res://assets/icons/crossbow.png"
        })
        
        register_blueprint("steel_sword", {
                "name_ru": "Стальной меч",
                "name_en": "Steel Sword",
                "desc_ru": "Лучшее оружие ближнего боя",
                "desc_en": "Best melee weapon",
                "category": "weapons",
                "tier": 3,
                "recipe_id": "steel_sword",
                "unlock_source": "workbench_3",
                "icon": "res://assets/icons/steel_sword.png"
        })

func _register_building_blueprints():
        register_blueprint("workbench_1", {
                "name_ru": "Базовый верстак",
                "name_en": "Basic Workbench",
                "desc_ru": "Открывает улучшенные рецепты",
                "desc_en": "Unlocks improved recipes",
                "category": "building",
                "tier": 0,
                "recipe_id": "workbench_1",
                "unlock_source": "starter",
                "icon": "res://assets/icons/workbench_1.png"
        })
        
        register_blueprint("storage_box", {
                "name_ru": "Ящик для хранения",
                "name_en": "Storage Box",
                "desc_ru": "Малое хранилище",
                "desc_en": "Small storage",
                "category": "building",
                "tier": 1,
                "recipe_id": "storage_box",
                "unlock_source": "workbench_1",
                "icon": "res://assets/icons/storage_box.png"
        })
        
        register_blueprint("workbench_2", {
                "name_ru": "Продвинутый верстак",
                "name_en": "Advanced Workbench",
                "desc_ru": "Открывает продвинутые рецепты",
                "desc_en": "Unlocks advanced recipes",
                "category": "building",
                "tier": 1,
                "recipe_id": "workbench_2",
                "unlock_source": "workbench_1",
                "icon": "res://assets/icons/workbench_2.png"
        })
        
        register_blueprint("furnace", {
                "name_ru": "Печь",
                "name_en": "Furnace",
                "desc_ru": "Для плавки металлов",
                "desc_en": "For smelting metals",
                "category": "building",
                "tier": 2,
                "recipe_id": "furnace",
                "unlock_source": "workbench_2",
                "icon": "res://assets/icons/furnace.png"
        })
        
        register_blueprint("large_storage", {
                "name_ru": "Большой ящик",
                "name_en": "Large Storage",
                "desc_ru": "Большое хранилище",
                "desc_en": "Large storage",
                "category": "building",
                "tier": 2,
                "recipe_id": "large_storage",
                "unlock_source": "workbench_2",
                "icon": "res://assets/icons/large_storage.png"
        })
        
        register_blueprint("workbench_3", {
                "name_ru": "Мастерский верстак",
                "name_en": "Master Workbench",
                "desc_ru": "Открывает мастерские рецепты",
                "desc_en": "Unlocks master recipes",
                "category": "building",
                "tier": 2,
                "recipe_id": "workbench_3",
                "unlock_source": "workbench_2",
                "icon": "res://assets/icons/workbench_3.png"
        })
        
        register_blueprint("wooden_foundation", {
                "name_ru": "Деревянный фундамент",
                "name_en": "Wooden Foundation",
                "desc_ru": "Основа для постройки",
                "desc_en": "Building foundation",
                "category": "building",
                "tier": 1,
                "recipe_id": "wooden_foundation",
                "unlock_source": "workbench_1",
                "icon": "res://assets/icons/wooden_foundation.png"
        })
        
        register_blueprint("wooden_wall", {
                "name_ru": "Деревянная стена",
                "name_en": "Wooden Wall",
                "desc_ru": "Защитная стена",
                "desc_en": "Defensive wall",
                "category": "building",
                "tier": 1,
                "recipe_id": "wooden_wall",
                "unlock_source": "workbench_1",
                "icon": "res://assets/icons/wooden_wall.png"
        })
        
        register_blueprint("wooden_door", {
                "name_ru": "Деревянная дверь",
                "name_en": "Wooden Door",
                "desc_ru": "Вход в строение",
                "desc_en": "Building entrance",
                "category": "building",
                "tier": 1,
                "recipe_id": "wooden_door",
                "unlock_source": "workbench_1",
                "icon": "res://assets/icons/wooden_door.png"
        })
        
        register_blueprint("stone_wall", {
                "name_ru": "Каменная стена",
                "name_en": "Stone Wall",
                "desc_ru": "Прочная каменная стена",
                "desc_en": "Strong stone wall",
                "category": "building",
                "tier": 2,
                "recipe_id": "stone_wall",
                "unlock_source": "workbench_2",
                "icon": "res://assets/icons/stone_wall.png"
        })
        
        register_blueprint("metal_door", {
                "name_ru": "Металлическая дверь",
                "name_en": "Metal Door",
                "desc_ru": "Прочная металлическая дверь",
                "desc_en": "Strong metal door",
                "category": "building",
                "tier": 2,
                "recipe_id": "metal_door",
                "unlock_source": "workbench_2",
                "icon": "res://assets/icons/metal_door.png"
        })
        
        register_blueprint("armored_door", {
                "name_ru": "Бронированная дверь",
                "name_en": "Armored Door",
                "desc_ru": "Максимальная защита",
                "desc_en": "Maximum protection",
                "category": "building",
                "tier": 3,
                "recipe_id": "armored_door",
                "unlock_source": "workbench_3",
                "icon": "res://assets/icons/armored_door.png"
        })

func _register_armor_blueprints():
        register_blueprint("leather_vest", {
                "name_ru": "Кожаный жилет",
                "name_en": "Leather Vest",
                "desc_ru": "Базовая защита торса",
                "desc_en": "Basic torso protection",
                "category": "armor",
                "tier": 1,
                "recipe_id": "leather_vest",
                "unlock_source": "workbench_1",
                "icon": "res://assets/icons/leather_vest.png"
        })
        
        register_blueprint("leather_pants", {
                "name_ru": "Кожаные штаны",
                "name_en": "Leather Pants",
                "desc_ru": "Базовая защита ног",
                "desc_en": "Basic leg protection",
                "category": "armor",
                "tier": 1,
                "recipe_id": "leather_pants",
                "unlock_source": "workbench_1",
                "icon": "res://assets/icons/leather_pants.png"
        })
        
        register_blueprint("iron_armor_chest", {
                "name_ru": "Железный нагрудник",
                "name_en": "Iron Chestplate",
                "desc_ru": "Надёжная защита торса",
                "desc_en": "Reliable torso protection",
                "category": "armor",
                "tier": 2,
                "recipe_id": "iron_armor_chest",
                "unlock_source": "workbench_2",
                "icon": "res://assets/icons/iron_armor_chest.png"
        })
        
        register_blueprint("steel_armor_chest", {
                "name_ru": "Стальной нагрудник",
                "name_en": "Steel Chestplate",
                "desc_ru": "Лучшая защита торса",
                "desc_en": "Best torso protection",
                "category": "armor",
                "tier": 3,
                "recipe_id": "steel_armor_chest",
                "unlock_source": "workbench_3",
                "icon": "res://assets/icons/steel_armor_chest.png"
        })

func _register_medical_blueprints():
        register_blueprint("medicine", {
                "name_ru": "Лекарство",
                "name_en": "Medicine",
                "desc_ru": "Улучшенное лечение",
                "desc_en": "Improved healing",
                "category": "medical",
                "tier": 1,
                "recipe_id": "medicine",
                "unlock_source": "workbench_1",
                "icon": "res://assets/icons/medicine.png"
        })
        
        register_blueprint("antidote", {
                "name_ru": "Антидот",
                "name_en": "Antidote",
                "desc_ru": "Лечит отравление",
                "desc_en": "Cures poison",
                "category": "medical",
                "tier": 2,
                "recipe_id": "antidote",
                "unlock_source": "workbench_2",
                "icon": "res://assets/icons/antidote.png"
        })
        
        register_blueprint("splint", {
                "name_ru": "Шина",
                "name_en": "Splint",
                "desc_ru": "Лечит переломы",
                "desc_en": "Heals broken bones",
                "category": "medical",
                "tier": 1,
                "recipe_id": "splint",
                "unlock_source": "workbench_1",
                "icon": "res://assets/icons/splint.png"
        })

func _register_material_blueprints():
        register_blueprint("iron_ingot", {
                "name_ru": "Железный слиток",
                "name_en": "Iron Ingot",
                "desc_ru": "Выплавка железа",
                "desc_en": "Iron smelting",
                "category": "materials",
                "tier": 2,
                "recipe_id": "iron_ingot",
                "unlock_source": "furnace",
                "icon": "res://assets/icons/iron_ingot.png"
        })
        
        register_blueprint("steel_ingot", {
                "name_ru": "Стальной слиток",
                "name_en": "Steel Ingot",
                "desc_ru": "Выплавка стали",
                "desc_en": "Steel smelting",
                "category": "materials",
                "tier": 3,
                "recipe_id": "steel_ingot",
                "unlock_source": "furnace",
                "icon": "res://assets/icons/steel_ingot.png"
        })

func register_blueprint(id: String, data: Dictionary):
        blueprints[id] = data
        blueprints[id]["id"] = id

func _unlock_starter_blueprints(player_id: int):
        if not player_blueprints.has(player_id):
                player_blueprints[player_id] = []
        
        for bp_id in blueprints.keys():
                var bp = blueprints[bp_id]
                if bp.get("unlock_source", "") == "starter":
                        if bp_id not in player_blueprints[player_id]:
                                player_blueprints[player_id].append(bp_id)

func unlock_blueprint(player_id: int, blueprint_id: String) -> bool:
        if not blueprints.has(blueprint_id):
                return false
        
        if not player_blueprints.has(player_id):
                player_blueprints[player_id] = []
        
        if blueprint_id in player_blueprints[player_id]:
                return false
        
        player_blueprints[player_id].append(blueprint_id)
        emit_signal("blueprint_unlocked", blueprint_id)
        
        var craft_sys = get_node_or_null("/root/CraftSystem")
        if craft_sys:
                var recipe_id = blueprints[blueprint_id].get("recipe_id", blueprint_id)
                craft_sys.unlock_recipe(player_id, recipe_id)
        
        return true

func unlock_blueprints_from_source(player_id: int, source: String):
        for bp_id in blueprints.keys():
                var bp = blueprints[bp_id]
                if bp.get("unlock_source", "") == source:
                        unlock_blueprint(player_id, bp_id)

func is_blueprint_unlocked(player_id: int, blueprint_id: String) -> bool:
        if not blueprints.has(blueprint_id):
                return false
        
        if not player_blueprints.has(player_id):
                _unlock_starter_blueprints(player_id)
        
        var bp = blueprints[blueprint_id]
        if bp.get("unlock_source", "") == "starter":
                return true
        
        return blueprint_id in player_blueprints[player_id]

func get_blueprints_by_category(player_id: int, category: String, include_locked: bool = false) -> Array:
        if not player_blueprints.has(player_id):
                _unlock_starter_blueprints(player_id)
        
        var result := []
        for bp_id in blueprints.keys():
                var bp = blueprints[bp_id]
                if bp.get("category", "") == category:
                        if include_locked or is_blueprint_unlocked(player_id, bp_id):
                                result.append(bp)
        result.sort_custom(func(a, b): return a.tier < b.tier)
        return result

func get_blueprints_by_tier(player_id: int, tier: int, include_locked: bool = false) -> Array:
        var result := []
        for bp_id in blueprints.keys():
                var bp = blueprints[bp_id]
                if bp.get("tier", 0) == tier:
                        if include_locked or is_blueprint_unlocked(player_id, bp_id):
                                result.append(bp)
        return result

func get_all_categories() -> Array:
        return category_names.keys()

func get_category_display_name(category: String, lang: String = "ru") -> String:
        if category_names.has(category):
                return category_names[category].get(lang, category)
        return category

func get_tier_display_name(tier: int, lang: String = "ru") -> String:
        if tier_names.has(tier):
                return tier_names[tier].get(lang, str(tier))
        return str(tier)

func get_blueprint_display_name(blueprint_id: String, lang: String = "ru") -> String:
        if not blueprints.has(blueprint_id):
                return blueprint_id
        var bp = blueprints[blueprint_id]
        return bp.get("name_" + lang, bp.get("name_ru", blueprint_id))

func get_blueprint_description(blueprint_id: String, lang: String = "ru") -> String:
        if not blueprints.has(blueprint_id):
                return ""
        var bp = blueprints[blueprint_id]
        return bp.get("desc_" + lang, bp.get("desc_ru", ""))

func get_unlock_requirement_text(blueprint_id: String, lang: String = "ru") -> String:
        if not blueprints.has(blueprint_id):
                return ""
        
        var bp = blueprints[blueprint_id]
        var source = bp.get("unlock_source", "")
        
        var requirements := {
                "starter": {"ru": "Доступно с начала", "en": "Available from start"},
                "workbench_1": {"ru": "Требуется: Базовый верстак", "en": "Requires: Basic Workbench"},
                "workbench_2": {"ru": "Требуется: Продвинутый верстак", "en": "Requires: Advanced Workbench"},
                "workbench_3": {"ru": "Требуется: Мастерский верстак", "en": "Requires: Master Workbench"},
                "furnace": {"ru": "Требуется: Печь", "en": "Requires: Furnace"}
        }
        
        if requirements.has(source):
                return requirements[source].get(lang, source)
        return source

func get_unlocked_count(player_id: int) -> int:
        var count := 0
        for bp_id in blueprints.keys():
                if is_blueprint_unlocked(player_id, bp_id):
                        count += 1
        return count

func get_total_count() -> int:
        return blueprints.size()

func get_progress_percent(player_id: int) -> float:
        var total = get_total_count()
        if total == 0:
                return 100.0
        return (float(get_unlocked_count(player_id)) / float(total)) * 100.0

func save_blueprints(player_id: int) -> Dictionary:
        return {
                "unlocked": player_blueprints.get(player_id, [])
        }

func load_blueprints(player_id: int, data: Dictionary):
        if data.has("unlocked"):
                player_blueprints[player_id] = data["unlocked"]
