extends Node

signal relation_changed(faction_a: String, faction_b: String, new_value: int)
signal entity_registered(entity: Node, faction: String)
signal reputation_changed(player_id: int, faction: String, new_value: int)

var factions = {}
var faction_entities = {}
var player_reputations := {}

var faction_names := {
        "player": "Игрок",
        "town": "Города",
        "wild": "Дикие животные",
        "bandits": "Бандиты",
        "monsters": "Монстры",
        "neutral": "Нейтральные",
        "traders": "Торговцы",
        "hunters": "Охотники",
        "miners": "Шахтёры",
        "guards": "Стража"
}

var reputation_ranks := {
        -100: {"name": "Враг народа", "color": Color(0.8, 0, 0)},
        -75: {"name": "Ненавидят", "color": Color(0.9, 0.2, 0.1)},
        -50: {"name": "Недолюбливают", "color": Color(0.9, 0.4, 0.2)},
        -25: {"name": "Не доверяют", "color": Color(0.8, 0.6, 0.3)},
        0: {"name": "Нейтрально", "color": Color(0.7, 0.7, 0.7)},
        25: {"name": "Приветливы", "color": Color(0.5, 0.8, 0.4)},
        50: {"name": "Уважают", "color": Color(0.3, 0.8, 0.3)},
        75: {"name": "Почитают", "color": Color(0.2, 0.9, 0.5)},
        100: {"name": "Герой", "color": Color(1.0, 0.85, 0.2)}
}

func _ready():
        _setup_default_factions()

func _setup_default_factions():
        create_faction("player")
        create_faction("town")
        create_faction("wild")
        create_faction("bandits")
        create_faction("monsters")
        create_faction("neutral")
        create_faction("traders")
        create_faction("hunters")
        create_faction("miners")
        create_faction("guards")
        
        set_relation("player", "town", 50)
        set_relation("town", "player", 50)
        set_relation("player", "wild", -30)
        set_relation("wild", "player", -30)
        set_relation("player", "bandits", -100)
        set_relation("bandits", "player", -100)
        set_relation("player", "monsters", -100)
        set_relation("monsters", "player", -100)
        set_relation("town", "bandits", -100)
        set_relation("bandits", "town", -100)
        set_relation("town", "monsters", -100)
        set_relation("monsters", "town", -100)
        set_relation("wild", "monsters", 0)

func create_faction(faction_name: String):
        if factions.has(faction_name):
                return
        factions[faction_name] = {"relations": {}, "reputation": 0}
        faction_entities[faction_name] = []

func register_entity(entity: Node, faction: String):
        if not factions.has(faction):
                create_faction(faction)
        
        if not faction_entities.has(faction):
                faction_entities[faction] = []
        
        if entity not in faction_entities[faction]:
                faction_entities[faction].append(entity)
                emit_signal("entity_registered", entity, faction)

func unregister_entity(entity: Node, faction: String):
        if faction_entities.has(faction):
                faction_entities[faction].erase(entity)

func get_faction_entities(faction: String) -> Array:
        if faction_entities.has(faction):
                return faction_entities[faction].filter(func(e): return is_instance_valid(e))
        return []

func set_relation(faction_a: String, faction_b: String, value: int):
        if not factions.has(faction_a):
                create_faction(faction_a)
        if not factions.has(faction_b):
                create_faction(faction_b)
        
        value = clamp(value, -100, 100)
        factions[faction_a].relations[faction_b] = value
        emit_signal("relation_changed", faction_a, faction_b, value)

func get_relation(faction_a: String, faction_b: String) -> int:
        if not factions.has(faction_a) or not factions.has(faction_b):
                return 0
        return factions[faction_a].relations.get(faction_b, 0)

func modify_relation(faction_a: String, faction_b: String, delta: int):
        var current = get_relation(faction_a, faction_b)
        set_relation(faction_a, faction_b, current + delta)

func is_hostile(faction_a: String, faction_b: String) -> bool:
        return get_relation(faction_a, faction_b) < -25

func is_friendly(faction_a: String, faction_b: String) -> bool:
        return get_relation(faction_a, faction_b) > 25

func is_neutral(faction_a: String, faction_b: String) -> bool:
        var rel = get_relation(faction_a, faction_b)
        return rel >= -25 and rel <= 25

func get_faction_reputation(faction: String) -> int:
        if factions.has(faction):
                return factions[faction].get("reputation", 0)
        return 0

func modify_faction_reputation(faction: String, delta: int):
        if not factions.has(faction):
                create_faction(faction)
        factions[faction]["reputation"] = clamp(factions[faction].get("reputation", 0) + delta, -100, 100)

func ensure_player_reputation(player_id: int):
        if not player_reputations.has(player_id):
                player_reputations[player_id] = {}
                for f in factions.keys():
                        if f != "player":
                                player_reputations[player_id][f] = 0

func get_player_reputation(player_id: int, faction: String) -> int:
        ensure_player_reputation(player_id)
        return player_reputations[player_id].get(faction, 0)

func modify_player_reputation(player_id: int, faction: String, delta: int):
        ensure_player_reputation(player_id)
        
        var perk_sys = get_node_or_null("/root/PerkSystem")
        if perk_sys:
                delta = int(delta * perk_sys.get_perk_effect(player_id, "reputation_gain"))
        
        var current = player_reputations[player_id].get(faction, 0)
        var new_value = clamp(current + delta, -100, 100)
        player_reputations[player_id][faction] = new_value
        emit_signal("reputation_changed", player_id, faction, new_value)

func get_reputation_rank(value: int) -> Dictionary:
        var result = reputation_ranks[0]
        for threshold in reputation_ranks.keys():
                if value >= threshold:
                        result = reputation_ranks[threshold]
        return result

func get_faction_name(faction: String) -> String:
        return faction_names.get(faction, faction)

func get_all_factions() -> Array:
        return factions.keys()

func get_player_all_reputations(player_id: int) -> Dictionary:
        ensure_player_reputation(player_id)
        return player_reputations[player_id].duplicate()

func can_trade_with(player_id: int, faction: String) -> bool:
        var rep = get_player_reputation(player_id, faction)
        return rep >= -25

func can_enter_settlement(player_id: int, faction: String) -> bool:
        var rep = get_player_reputation(player_id, faction)
        return rep >= -50

func get_trade_price_modifier(player_id: int, faction: String) -> float:
        var rep = get_player_reputation(player_id, faction)
        return 1.0 - (rep * 0.002)
