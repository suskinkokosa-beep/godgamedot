extends Node

signal equipment_built(equipment_type, position)
signal equipment_destroyed(equipment_id)
signal wall_breached(settlement_id, wall_section)
signal gate_destroyed(settlement_id)

enum EquipmentType {
        BATTERING_RAM,
        SIEGE_TOWER,
        CATAPULT,
        TREBUCHET,
        BALLISTA,
        SIEGE_LADDER,
        MANTLET,
        MINING_TUNNEL
}

var equipment_data := {
        EquipmentType.BATTERING_RAM: {
                "name": "Таран",
                "build_time": 120.0,
                "cost": {"wood": 100, "iron": 20},
                "crew_required": 8,
                "gate_damage": 15,
                "wall_damage": 2,
                "health": 200,
                "speed": 1.5
        },
        EquipmentType.SIEGE_TOWER: {
                "name": "Осадная башня",
                "build_time": 300.0,
                "cost": {"wood": 200, "iron": 50, "cloth": 30},
                "crew_required": 20,
                "troops_capacity": 30,
                "health": 400,
                "speed": 0.5
        },
        EquipmentType.CATAPULT: {
                "name": "Катапульта",
                "build_time": 180.0,
                "cost": {"wood": 80, "iron": 30, "rope": 20},
                "crew_required": 4,
                "wall_damage": 10,
                "building_damage": 15,
                "range": 100.0,
                "reload_time": 8.0,
                "health": 150
        },
        EquipmentType.TREBUCHET: {
                "name": "Требушет",
                "build_time": 360.0,
                "cost": {"wood": 150, "iron": 60, "rope": 40},
                "crew_required": 6,
                "wall_damage": 25,
                "building_damage": 30,
                "range": 200.0,
                "reload_time": 15.0,
                "health": 200
        },
        EquipmentType.BALLISTA: {
                "name": "Баллиста",
                "build_time": 150.0,
                "cost": {"wood": 60, "iron": 40, "rope": 15},
                "crew_required": 3,
                "troop_damage": 50,
                "wall_damage": 5,
                "range": 150.0,
                "reload_time": 5.0,
                "health": 100
        },
        EquipmentType.SIEGE_LADDER: {
                "name": "Осадная лестница",
                "build_time": 30.0,
                "cost": {"wood": 20},
                "crew_required": 2,
                "troops_capacity": 5,
                "health": 30
        },
        EquipmentType.MANTLET: {
                "name": "Щит-мантелет",
                "build_time": 60.0,
                "cost": {"wood": 40, "leather": 10},
                "crew_required": 2,
                "protection": 0.7,
                "health": 80
        },
        EquipmentType.MINING_TUNNEL: {
                "name": "Подкоп",
                "build_time": 600.0,
                "cost": {"wood": 50, "tools": 10},
                "crew_required": 10,
                "wall_collapse_chance": 0.3,
                "stealth": true
        }
}

var active_equipment := {}
var equipment_id_counter := 0

func _ready():
        pass

func _process(delta):
        _update_equipment(delta)

func build_equipment(equipment_type: int, position: Vector3, faction: String) -> int:
        var data = equipment_data.get(equipment_type, null)
        if not data:
                return -1
        
        if not _check_resources(faction, data.cost):
                return -1
        
        _consume_resources(faction, data.cost)
        
        equipment_id_counter += 1
        var equipment_id = equipment_id_counter
        
        active_equipment[equipment_id] = {
                "id": equipment_id,
                "type": equipment_type,
                "faction": faction,
                "position": position,
                "target_position": position,
                "health": data.health,
                "max_health": data.health,
                "state": "building",
                "build_progress": 0.0,
                "build_time": data.build_time,
                "reload_timer": 0.0,
                "crew": 0,
                "loaded_troops": []
        }
        
        return equipment_id

func _update_equipment(delta):
        var to_remove = []
        
        for equipment_id in active_equipment:
                var eq = active_equipment[equipment_id]
                
                match eq.state:
                        "building":
                                eq.build_progress += delta
                                if eq.build_progress >= eq.build_time:
                                        eq.state = "ready"
                                        emit_signal("equipment_built", eq.type, eq.position)
                        
                        "moving":
                                _move_equipment(eq, delta)
                        
                        "attacking":
                                _process_attack(eq, delta)
                
                if eq.health <= 0:
                        to_remove.append(equipment_id)
        
        for equipment_id in to_remove:
                _destroy_equipment(equipment_id)

func _move_equipment(eq: Dictionary, delta):
        var data = equipment_data.get(eq.type, {})
        var speed = data.get("speed", 1.0)
        
        var direction = (eq.target_position - eq.position).normalized()
        eq.position += direction * speed * delta
        
        if eq.position.distance_to(eq.target_position) < 1.0:
                eq.state = "ready"

func move_to(equipment_id: int, target: Vector3):
        if active_equipment.has(equipment_id):
                var eq = active_equipment[equipment_id]
                eq.target_position = target
                eq.state = "moving"

func attack_target(equipment_id: int, target_settlement_id: int) -> bool:
        if not active_equipment.has(equipment_id):
                return false
        
        var eq = active_equipment[equipment_id]
        var data = equipment_data.get(eq.type, {})
        
        if not data.has("wall_damage") and not data.has("gate_damage") and not data.has("building_damage"):
                return false
        
        eq.state = "attacking"
        eq.target_settlement = target_settlement_id
        return true

func _process_attack(eq: Dictionary, delta):
        var data = equipment_data.get(eq.type, {})
        
        eq.reload_timer += delta
        var reload_time = data.get("reload_time", 5.0)
        
        if eq.reload_timer >= reload_time:
                eq.reload_timer = 0.0
                _fire_at_target(eq, data)

func _fire_at_target(eq: Dictionary, data: Dictionary):
        var ss = get_node_or_null("/root/SettlementSystem")
        if not ss:
                return
        
        var settlement = ss.get_settlement(eq.get("target_settlement", -1))
        if not settlement:
                return
        
        var wall_damage = data.get("wall_damage", 0)
        var gate_damage = data.get("gate_damage", 0)
        var building_damage = data.get("building_damage", 0)
        
        if wall_damage > 0:
                if not settlement.has("wall_health"):
                        settlement.wall_health = 500
                settlement.wall_health -= wall_damage
                
                if settlement.wall_health <= 0:
                        emit_signal("wall_breached", settlement.id, 0)
        
        if gate_damage > 0:
                if not settlement.has("gate_health"):
                        settlement.gate_health = 300
                settlement.gate_health -= gate_damage
                
                if settlement.gate_health <= 0:
                        emit_signal("gate_destroyed", settlement.id)
        
        if building_damage > 0:
                var buildings = settlement.get("buildings", [])
                if buildings.size() > 0:
                        var target_building = buildings[randi() % buildings.size()]
                        if target_building.has("health"):
                                target_building.health -= building_damage

func damage_equipment(equipment_id: int, damage: float, source = null):
        if active_equipment.has(equipment_id):
                active_equipment[equipment_id].health -= damage

func _destroy_equipment(equipment_id: int):
        if active_equipment.has(equipment_id):
                emit_signal("equipment_destroyed", equipment_id)
                active_equipment.erase(equipment_id)

func load_troops(equipment_id: int, troops: Array) -> bool:
        if not active_equipment.has(equipment_id):
                return false
        
        var eq = active_equipment[equipment_id]
        var data = equipment_data.get(eq.type, {})
        
        if not data.has("troops_capacity"):
                return false
        
        var capacity = data.troops_capacity
        var current = eq.loaded_troops.size()
        
        for troop in troops:
                if current >= capacity:
                        break
                eq.loaded_troops.append(troop)
                current += 1
        
        return true

func unload_troops(equipment_id: int) -> Array:
        if not active_equipment.has(equipment_id):
                return []
        
        var eq = active_equipment[equipment_id]
        var troops = eq.loaded_troops.duplicate()
        eq.loaded_troops.clear()
        return troops

func assign_crew(equipment_id: int, count: int) -> bool:
        if not active_equipment.has(equipment_id):
                return false
        
        var eq = active_equipment[equipment_id]
        var data = equipment_data.get(eq.type, {})
        
        eq.crew = min(count, data.get("crew_required", 1))
        return eq.crew >= data.get("crew_required", 1)

func _check_resources(faction: String, cost: Dictionary) -> bool:
        var ss = get_node_or_null("/root/SettlementSystem")
        if not ss:
                return false
        
        var settlements = ss.get_settlements_by_faction(faction)
        var total_resources = {}
        
        for s in settlements:
                for res_type in s.resources:
                        if not total_resources.has(res_type):
                                total_resources[res_type] = 0
                        total_resources[res_type] += s.resources[res_type]
        
        for res_type in cost:
                if total_resources.get(res_type, 0) < cost[res_type]:
                        return false
        
        return true

func _consume_resources(faction: String, cost: Dictionary):
        var ss = get_node_or_null("/root/SettlementSystem")
        if not ss:
                return
        
        var settlements = ss.get_settlements_by_faction(faction)
        var remaining_cost = cost.duplicate()
        
        for s in settlements:
                for res_type in remaining_cost.keys():
                        if remaining_cost[res_type] <= 0:
                                continue
                        
                        var available = s.resources.get(res_type, 0)
                        var to_take = min(available, remaining_cost[res_type])
                        s.resources[res_type] -= to_take
                        remaining_cost[res_type] -= to_take

func get_equipment_info(equipment_id: int) -> Dictionary:
        return active_equipment.get(equipment_id, {})

func get_equipment_type_info(equipment_type: int) -> Dictionary:
        return equipment_data.get(equipment_type, {})

func get_faction_equipment(faction: String) -> Array:
        var result = []
        for eq in active_equipment.values():
                if eq.faction == faction:
                        result.append(eq)
        return result

func get_equipment_near(position: Vector3, radius: float) -> Array:
        var result = []
        for eq in active_equipment.values():
                if eq.position.distance_to(position) <= radius:
                        result.append(eq)
        return result
