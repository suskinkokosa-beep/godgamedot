extends Node

signal settlement_created(id, name, position)
signal settlement_upgraded(id, new_level)
signal settlement_destroyed(id)
signal population_changed(id, new_pop)
signal war_declared(attacker_id, defender_id)

enum SettlementLevel { CAMP, VILLAGE, TOWN, CITY, CAPITAL }

var settlements := {}
var next_id := 1

var level_requirements := {
        SettlementLevel.VILLAGE: {"population": 10, "buildings": 5},
        SettlementLevel.TOWN: {"population": 50, "buildings": 20},
        SettlementLevel.CITY: {"population": 200, "buildings": 50},
        SettlementLevel.CAPITAL: {"population": 500, "buildings": 100}
}

var population_classes := {
        "worker": {"production_mult": 1.2, "combat_mult": 0.5},
        "guard": {"production_mult": 0.3, "combat_mult": 1.5},
        "craftsman": {"production_mult": 0.8, "combat_mult": 0.3, "craft_mult": 2.0},
        "trader": {"production_mult": 0.5, "combat_mult": 0.2, "trade_mult": 2.0}
}

func _ready():
        _spawn_initial_settlements()

func _spawn_initial_settlements():
        create_settlement("Starter Village", Vector3(0, 0, 0), 10, "town")
        create_settlement("Forest Camp", Vector3(100, 0, 50), 5, "wild")
        create_settlement("Desert Outpost", Vector3(-80, 0, 120), 8, "bandits")

func create_settlement(settlement_name: String, pos: Vector3, initial_pop: int = 4, faction: String = "player") -> int:
        var id = next_id
        next_id += 1
        
        settlements[id] = {
                "id": id,
                "name": settlement_name,
                "position": pos,
                "level": SettlementLevel.CAMP,
                "population": initial_pop,
                "max_population": 20,
                "happiness": 75.0,
                "faction": faction,
                "resources": {
                        "food": 100,
                        "wood": 50,
                        "stone": 20,
                        "iron": 0,
                        "gold": 0
                },
                "population_breakdown": {
                        "worker": max(1, initial_pop - 1),
                        "guard": 1,
                        "craftsman": 0,
                        "trader": 0
                },
                "buildings": [],
                "laws": [],
                "relations": {},
                "army_strength": 10,
                "territory_radius": 50.0,
                "production_rate": 1.0,
                "tax_rate": 0.1,
                "last_update": 0.0
        }
        
        emit_signal("settlement_created", id, settlement_name, pos)
        return id

func update_settlement(id: int, delta: float):
        if not settlements.has(id):
                return
        
        var s = settlements[id]
        s.last_update += delta
        
        if s.last_update < 1.0:
                return
        s.last_update = 0.0
        
        _process_resources(s)
        _process_population(s)
        _process_happiness(s)
        _check_level_upgrade(id)

func _process_resources(s: Dictionary):
        var workers = s.population_breakdown.get("worker", 0)
        var prod_mult = s.production_rate * (1.0 + workers * 0.1)
        
        s.resources.food += int(workers * prod_mult * 0.5)
        s.resources.wood += int(workers * prod_mult * 0.2)
        s.resources.stone += int(workers * prod_mult * 0.1)
        
        var food_consumption = s.population * 1
        s.resources.food -= food_consumption
        
        if s.resources.food < 0:
                s.resources.food = 0
                s.happiness -= 5.0

func _process_population(s: Dictionary):
        if s.resources.food > s.population * 2 and s.happiness > 50:
                if s.population < s.max_population:
                        s.population += 1
                        s.population_breakdown.worker += 1
                        emit_signal("population_changed", s.id, s.population)
        
        if s.resources.food <= 0 and s.population > 1:
                s.population -= 1
                if s.population_breakdown.worker > 0:
                        s.population_breakdown.worker -= 1
                emit_signal("population_changed", s.id, s.population)

func _process_happiness(s: Dictionary):
        var food_per_capita = float(s.resources.food) / max(1, s.population)
        if food_per_capita > 5:
                s.happiness = min(100, s.happiness + 1)
        elif food_per_capita < 1:
                s.happiness = max(0, s.happiness - 2)
        
        var guard_ratio = float(s.population_breakdown.get("guard", 0)) / max(1, s.population)
        if guard_ratio > 0.1:
                s.happiness = min(100, s.happiness + 0.5)
        
        s.happiness = clamp(s.happiness, 0, 100)

func _check_level_upgrade(id: int):
        var s = settlements[id]
        var current_level = s.level
        var next_level = current_level + 1
        
        if next_level > SettlementLevel.CAPITAL:
                return
        
        var req = level_requirements.get(next_level, {})
        if s.population >= req.get("population", 999) and s.buildings.size() >= req.get("buildings", 999):
                s.level = next_level
                s.max_population = _get_max_population_for_level(next_level)
                s.territory_radius *= 1.5
                emit_signal("settlement_upgraded", id, next_level)

func _get_max_population_for_level(level: int) -> int:
        match level:
                SettlementLevel.CAMP: return 20
                SettlementLevel.VILLAGE: return 50
                SettlementLevel.TOWN: return 200
                SettlementLevel.CITY: return 500
                SettlementLevel.CAPITAL: return 1000
        return 20

func add_building(settlement_id: int, building_type: String):
        if settlements.has(settlement_id):
                settlements[settlement_id].buildings.append(building_type)
                _apply_building_bonus(settlement_id, building_type)

func _apply_building_bonus(settlement_id: int, building_type: String):
        var s = settlements[settlement_id]
        match building_type:
                "farm": s.production_rate += 0.1
                "barracks": s.army_strength += 20
                "market": s.max_population += 10
                "wall": s.army_strength += 10

func add_resource(settlement_id: int, resource_id: String, amount: int):
        if not settlements.has(settlement_id):
                return
        var s = settlements[settlement_id]
        s.resources[resource_id] = s.resources.get(resource_id, 0) + amount

func consume_resource(settlement_id: int, resource_id: String, amount: int) -> bool:
        if not settlements.has(settlement_id):
                return false
        var s = settlements[settlement_id]
        var have = s.resources.get(resource_id, 0)
        if have < amount:
                return false
        s.resources[resource_id] = have - amount
        return true

func assign_population(settlement_id: int, from_class: String, to_class: String, count: int) -> bool:
        if not settlements.has(settlement_id):
                return false
        var s = settlements[settlement_id]
        if s.population_breakdown.get(from_class, 0) < count:
                return false
        s.population_breakdown[from_class] -= count
        s.population_breakdown[to_class] = s.population_breakdown.get(to_class, 0) + count
        return true

func declare_war(attacker_id: int, defender_id: int):
        if not settlements.has(attacker_id) or not settlements.has(defender_id):
                return
        settlements[attacker_id].relations[defender_id] = -100
        settlements[defender_id].relations[attacker_id] = -100
        emit_signal("war_declared", attacker_id, defender_id)

func make_alliance(settlement_a: int, settlement_b: int):
        if not settlements.has(settlement_a) or not settlements.has(settlement_b):
                return
        settlements[settlement_a].relations[settlement_b] = 100
        settlements[settlement_b].relations[settlement_a] = 100

func get_relation(settlement_a: int, settlement_b: int) -> int:
        if not settlements.has(settlement_a):
                return 0
        return settlements[settlement_a].relations.get(settlement_b, 0)

func get_settlement_info(id: int) -> Dictionary:
        return settlements.get(id, {})

func get_settlement(id: int) -> Dictionary:
        return settlements.get(id, {})

func change_faction(settlement_id: int, new_faction: String):
        if settlements.has(settlement_id):
                settlements[settlement_id].faction = new_faction

func get_all_settlements() -> Array:
        return settlements.values()

func get_settlements_by_faction(faction: String) -> Array:
        var result := []
        for s in settlements.values():
                if s.faction == faction:
                        result.append(s)
        return result

func get_nearest_settlement(pos: Vector3) -> Dictionary:
        var nearest = {}
        var min_dist = INF
        for s in settlements.values():
                var dist = pos.distance_to(s.position)
                if dist < min_dist:
                        min_dist = dist
                        nearest = s
        return nearest

func _process(delta):
        for id in settlements.keys():
                update_settlement(id, delta)

func get_level_name(level: int) -> String:
        match level:
                SettlementLevel.CAMP: return "Лагерь"
                SettlementLevel.VILLAGE: return "Деревня"
                SettlementLevel.TOWN: return "Город"
                SettlementLevel.CITY: return "Большой город"
                SettlementLevel.CAPITAL: return "Столица"
        return "Неизвестно"

func get_level_name_en(level: int) -> String:
        match level:
                SettlementLevel.CAMP: return "Camp"
                SettlementLevel.VILLAGE: return "Village"
                SettlementLevel.TOWN: return "Town"
                SettlementLevel.CITY: return "City"
                SettlementLevel.CAPITAL: return "Capital"
        return "Unknown"

func get_class_name_ru(pop_class: String) -> String:
        var names := {
                "worker": "Рабочий",
                "guard": "Охранник",
                "craftsman": "Ремесленник",
                "trader": "Торговец"
        }
        return names.get(pop_class, pop_class)
