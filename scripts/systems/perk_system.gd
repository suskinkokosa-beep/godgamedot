extends Node

signal perk_unlocked(player_id: int, perk_id: String)
signal perk_applied(player_id: int, perk_id: String)

var player_perks := {}

var perk_database := {
        "fast_builder": {
                "name": "Быстрый строитель",
                "description": "Скорость строительства +30%",
                "icon": "🏗️",
                "category": "building",
                "cost": 1,
                "required_level": 3,
                "effects": {"build_speed": 1.3}
        },
        "efficient_miner": {
                "name": "Эффективный шахтёр",
                "description": "Добыча руды +25%",
                "icon": "⛏️",
                "category": "gathering",
                "cost": 1,
                "required_level": 2,
                "effects": {"ore_gather": 1.25}
        },
        "double_harvest": {
                "name": "Двойной урожай",
                "description": "Шанс двойного сбора ресурсов 20%",
                "icon": "🌾",
                "category": "gathering",
                "cost": 2,
                "required_level": 5,
                "effects": {"double_harvest_chance": 0.2}
        },
        "light_load": {
                "name": "Лёгкая ноша",
                "description": "Вес ресурсов снижен на 20%",
                "icon": "🎒",
                "category": "utility",
                "cost": 1,
                "required_level": 3,
                "effects": {"resource_weight": 0.8}
        },
        "marksman": {
                "name": "Меткий стрелок",
                "description": "Точность +15%",
                "icon": "🎯",
                "category": "combat",
                "cost": 1,
                "required_level": 4,
                "effects": {"accuracy": 1.15}
        },
        "shadow_walker": {
                "name": "Тень",
                "description": "Скрытность +25%",
                "icon": "👤",
                "category": "utility",
                "cost": 2,
                "required_level": 6,
                "effects": {"stealth": 1.25}
        },
        "iron_skin": {
                "name": "Железная кожа",
                "description": "Получаемый урон -10%",
                "icon": "🛡️",
                "category": "combat",
                "cost": 2,
                "required_level": 5,
                "effects": {"damage_reduction": 0.9}
        },
        "berserker": {
                "name": "Берсерк",
                "description": "Урон +20%, но защита -10%",
                "icon": "⚔️",
                "category": "combat",
                "cost": 2,
                "required_level": 7,
                "effects": {"damage_mult": 1.2, "damage_reduction": 1.1}
        },
        "sprinter": {
                "name": "Спринтер",
                "description": "Скорость бега +15%",
                "icon": "🏃",
                "category": "utility",
                "cost": 1,
                "required_level": 2,
                "effects": {"sprint_speed": 1.15}
        },
        "endurance_master": {
                "name": "Мастер выносливости",
                "description": "Восстановление стамины +30%",
                "icon": "💪",
                "category": "utility",
                "cost": 1,
                "required_level": 4,
                "effects": {"stamina_regen": 1.3}
        },
        "healer": {
                "name": "Целитель",
                "description": "Эффективность лечения +25%",
                "icon": "❤️",
                "category": "survival",
                "cost": 1,
                "required_level": 3,
                "effects": {"heal_mult": 1.25}
        },
        "survivalist": {
                "name": "Выживальщик",
                "description": "Голод и жажда снижаются медленнее на 20%",
                "icon": "🏕️",
                "category": "survival",
                "cost": 2,
                "required_level": 5,
                "effects": {"hunger_drain": 0.8, "thirst_drain": 0.8}
        },
        "cold_resistant": {
                "name": "Морозостойкость",
                "description": "Сопротивление холоду +30%",
                "icon": "❄️",
                "category": "survival",
                "cost": 1,
                "required_level": 4,
                "effects": {"cold_resist": 1.3}
        },
        "heat_resistant": {
                "name": "Жаростойкость",
                "description": "Сопротивление жаре +30%",
                "icon": "🔥",
                "category": "survival",
                "cost": 1,
                "required_level": 4,
                "effects": {"heat_resist": 1.3}
        },
        "master_blacksmith": {
                "name": "Мастер-кузнец",
                "description": "Качество крафта оружия +20%",
                "icon": "🔨",
                "category": "crafting",
                "cost": 2,
                "required_level": 8,
                "effects": {"craft_quality": 1.2}
        },
        "trader": {
                "name": "Торговец",
                "description": "Цены покупки -15%, продажи +15%",
                "icon": "💰",
                "category": "social",
                "cost": 1,
                "required_level": 4,
                "effects": {"buy_price": 0.85, "sell_price": 1.15}
        },
        "diplomat": {
                "name": "Дипломат",
                "description": "Репутация с фракциями растёт быстрее на 25%",
                "icon": "🤝",
                "category": "social",
                "cost": 2,
                "required_level": 6,
                "effects": {"reputation_gain": 1.25}
        },
        "lucky": {
                "name": "Везунчик",
                "description": "Шанс критического удара +5%",
                "icon": "🍀",
                "category": "combat",
                "cost": 2,
                "required_level": 5,
                "effects": {"crit_chance": 0.05}
        }
}

var perk_categories := {
        "building": "Строительство",
        "gathering": "Добыча",
        "utility": "Общие",
        "combat": "Бой",
        "survival": "Выживание",
        "crafting": "Крафт",
        "social": "Социальные"
}

func _ready():
        pass

func ensure_player(player_id: int):
        if not player_perks.has(player_id):
                player_perks[player_id] = []

func unlock_perk(player_id: int, perk_id: String) -> Dictionary:
        ensure_player(player_id)
        
        if not perk_database.has(perk_id):
                return {"success": false, "error": "Перк не найден"}
        
        if has_perk(player_id, perk_id):
                return {"success": false, "error": "Перк уже изучен"}
        
        var perk = perk_database[perk_id]
        var prog = get_node_or_null("/root/PlayerProgression")
        
        if prog:
                var p = prog.get_player(player_id)
                if p.is_empty():
                        return {"success": false, "error": "Игрок не найден"}
                
                if p.level < perk.required_level:
                        return {"success": false, "error": "Требуется уровень %d" % perk.required_level}
                
                if not prog.spend_perk_points(player_id, perk.cost):
                        return {"success": false, "error": "Недостаточно очков талантов (%d/%d)" % [prog.get_perk_points(player_id), perk.cost]}
        
        player_perks[player_id].append(perk_id)
        emit_signal("perk_unlocked", player_id, perk_id)
        emit_signal("perk_applied", player_id, perk_id)
        
        return {"success": true, "perk": perk}

func has_perk(player_id: int, perk_id: String) -> bool:
        ensure_player(player_id)
        return perk_id in player_perks[player_id]

func get_player_perks(player_id: int) -> Array:
        ensure_player(player_id)
        return player_perks[player_id].duplicate()

func get_perk_effect(player_id: int, effect_name: String) -> float:
        ensure_player(player_id)
        
        var total := 1.0
        for perk_id in player_perks[player_id]:
                if perk_database.has(perk_id):
                        var effects = perk_database[perk_id].effects
                        if effects.has(effect_name):
                                if effect_name.ends_with("_chance"):
                                        total += effects[effect_name]
                                else:
                                        total *= effects[effect_name]
        
        return total

func get_perk_additive_effect(player_id: int, effect_name: String) -> float:
        ensure_player(player_id)
        
        var total := 0.0
        for perk_id in player_perks[player_id]:
                if perk_database.has(perk_id):
                        var effects = perk_database[perk_id].effects
                        if effects.has(effect_name):
                                total += effects[effect_name]
        
        return total

func get_available_perks(player_id: int) -> Array:
        ensure_player(player_id)
        
        var result := []
        var prog = get_node_or_null("/root/PlayerProgression")
        var level := 1
        
        if prog:
                var p = prog.get_player(player_id)
                if not p.is_empty():
                        level = p.level
        
        for perk_id in perk_database.keys():
                var perk = perk_database[perk_id]
                if perk.required_level <= level and not has_perk(player_id, perk_id):
                        result.append(perk_id)
        
        return result

func get_perks_by_category(category: String) -> Array:
        var result := []
        for perk_id in perk_database.keys():
                if perk_database[perk_id].category == category:
                        result.append(perk_id)
        return result

func get_perk_info(perk_id: String) -> Dictionary:
        return perk_database.get(perk_id, {})

func get_all_categories() -> Array:
        return perk_categories.keys()

func get_category_name(category: String) -> String:
        return perk_categories.get(category, category)
