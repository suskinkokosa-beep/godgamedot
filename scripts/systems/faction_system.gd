extends Node

signal relation_changed(faction_a: String, faction_b: String, new_value: int)
signal entity_registered(entity: Node, faction: String)

var factions = {}
var faction_entities = {}

func _ready():
        _setup_default_factions()

func _setup_default_factions():
        create_faction("player")
        create_faction("town")
        create_faction("wild")
        create_faction("bandits")
        create_faction("monsters")
        create_faction("neutral")
        
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
