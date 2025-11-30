extends Node

signal war_declared(attacker_faction, defender_faction, reason)
signal war_ended(faction_a, faction_b, winner, terms)
signal battle_started(attacker_settlement, defender_settlement)
signal battle_ended(settlement_id, winner, casualties)
signal siege_started(attacker_faction, settlement_id)
signal siege_ended(settlement_id, conquered)
signal army_created(faction, army_data)
signal army_destroyed(faction, army_id)

var active_wars := {}
var active_sieges := {}
var armies := {}
var battle_history := []

var war_reasons := {
        "territory": {"aggression_cost": 20, "war_score_mult": 1.0},
        "resources": {"aggression_cost": 15, "war_score_mult": 0.8},
        "revenge": {"aggression_cost": 5, "war_score_mult": 1.2},
        "liberation": {"aggression_cost": 0, "war_score_mult": 1.5},
        "holy_war": {"aggression_cost": 25, "war_score_mult": 1.3},
        "conquest": {"aggression_cost": 30, "war_score_mult": 1.5}
}

var unit_types := {
        "militia": {"attack": 5, "defense": 3, "morale": 30, "cost": 10},
        "soldier": {"attack": 10, "defense": 8, "morale": 50, "cost": 25},
        "archer": {"attack": 12, "defense": 4, "morale": 40, "cost": 30},
        "cavalry": {"attack": 15, "defense": 10, "morale": 60, "cost": 50},
        "elite": {"attack": 20, "defense": 15, "morale": 80, "cost": 100},
        "siege_unit": {"attack": 5, "defense": 2, "morale": 20, "cost": 75, "siege_power": 20}
}

func _ready():
        pass

func _process(delta):
        _process_wars(delta)
        _process_sieges(delta)
        _process_armies(delta)

func declare_war(attacker_faction: String, defender_faction: String, reason: String = "territory") -> bool:
        var war_key = _get_war_key(attacker_faction, defender_faction)
        
        if active_wars.has(war_key):
                return false
        
        var faction_sys = get_node_or_null("/root/FactionSystem")
        if faction_sys:
                faction_sys.modify_relation(attacker_faction, defender_faction, -50)
        
        var reason_data = war_reasons.get(reason, war_reasons.territory)
        
        active_wars[war_key] = {
                "attacker": attacker_faction,
                "defender": defender_faction,
                "reason": reason,
                "start_time": Time.get_unix_time_from_system(),
                "attacker_war_score": 0,
                "defender_war_score": 0,
                "battles_fought": 0,
                "total_casualties": {"attacker": 0, "defender": 0},
                "conquered_settlements": [],
                "aggression_cost": reason_data.aggression_cost,
                "war_score_mult": reason_data.war_score_mult
        }
        
        emit_signal("war_declared", attacker_faction, defender_faction, reason)
        
        _mobilize_faction(attacker_faction)
        _mobilize_faction(defender_faction)
        
        return true

func end_war(faction_a: String, faction_b: String, forced_winner: String = "") -> Dictionary:
        var war_key = _get_war_key(faction_a, faction_b)
        
        if not active_wars.has(war_key):
                return {}
        
        var war = active_wars[war_key]
        var winner = forced_winner
        
        if winner.is_empty():
                if war.attacker_war_score > war.defender_war_score + 25:
                        winner = war.attacker
                elif war.defender_war_score > war.attacker_war_score + 25:
                        winner = war.defender
                else:
                        winner = "draw"
        
        var terms = _generate_peace_terms(war, winner)
        _apply_peace_terms(terms, war)
        
        for siege_key in active_sieges.keys():
                var siege = active_sieges[siege_key]
                if siege.attacker_faction == faction_a or siege.attacker_faction == faction_b:
                        _end_siege(siege_key, false)
        
        active_wars.erase(war_key)
        
        battle_history.append({
                "war": war,
                "winner": winner,
                "terms": terms,
                "end_time": Time.get_unix_time_from_system()
        })
        
        emit_signal("war_ended", faction_a, faction_b, winner, terms)
        
        return terms

func _generate_peace_terms(war: Dictionary, winner: String) -> Dictionary:
        var terms = {
                "winner": winner,
                "loser": war.defender if winner == war.attacker else war.attacker,
                "reparations": 0,
                "territory_transfer": [],
                "prisoners_released": true
        }
        
        if winner != "draw":
                var war_score_diff = abs(war.attacker_war_score - war.defender_war_score)
                terms.reparations = war_score_diff * 10
                
                if war_score_diff > 50:
                        terms.territory_transfer = war.conquered_settlements
        
        return terms

func _apply_peace_terms(terms: Dictionary, war: Dictionary):
        var ss = get_node_or_null("/root/SettlementSystem")
        var faction_sys = get_node_or_null("/root/FactionSystem")
        
        if ss and terms.territory_transfer.size() > 0:
                for settlement_id in terms.territory_transfer:
                        ss.change_faction(settlement_id, terms.winner)
        
        if faction_sys:
                faction_sys.modify_relation(war.attacker, war.defender, 30)

func start_siege(attacker_faction: String, settlement_id: int) -> bool:
        var ss = get_node_or_null("/root/SettlementSystem")
        if not ss:
                return false
        
        var settlement = ss.get_settlement(settlement_id)
        if not settlement:
                return false
        
        if settlement.faction == attacker_faction:
                return false
        
        var war_key = _get_war_key(attacker_faction, settlement.faction)
        if not active_wars.has(war_key):
                return false
        
        var siege_key = str(attacker_faction) + "_" + str(settlement_id)
        
        if active_sieges.has(siege_key):
                return false
        
        var army_strength = _get_faction_army_strength(attacker_faction, settlement.position)
        var defense_strength = _get_settlement_defense(settlement)
        
        active_sieges[siege_key] = {
                "attacker_faction": attacker_faction,
                "settlement_id": settlement_id,
                "defender_faction": settlement.faction,
                "progress": 0.0,
                "max_progress": 100.0 + defense_strength,
                "attacker_strength": army_strength,
                "defender_strength": defense_strength,
                "start_time": Time.get_unix_time_from_system(),
                "assault_count": 0,
                "starvation_timer": 0.0
        }
        
        emit_signal("siege_started", attacker_faction, settlement_id)
        return true

func _process_sieges(delta):
        var completed_sieges = []
        
        for siege_key in active_sieges:
                var siege = active_sieges[siege_key]
                
                siege.starvation_timer += delta
                if siege.starvation_timer > 300:
                        siege.defender_strength = max(1, siege.defender_strength - 1)
                        siege.starvation_timer = 0
                
                var siege_power = _get_siege_power(siege.attacker_faction, siege.settlement_id)
                siege.progress += siege_power * delta * 0.1
                
                if siege.progress >= siege.max_progress:
                        completed_sieges.append(siege_key)

        for siege_key in completed_sieges:
                _end_siege(siege_key, true)

func assault_siege(siege_key: String) -> Dictionary:
        if not active_sieges.has(siege_key):
                return {"success": false, "error": "Siege not found"}
        
        var siege = active_sieges[siege_key]
        siege.assault_count += 1
        
        var attacker_roll = randf() * siege.attacker_strength
        var defender_roll = randf() * siege.defender_strength * 1.5
        
        var result = {
                "success": attacker_roll > defender_roll,
                "attacker_casualties": int(defender_roll * 0.3),
                "defender_casualties": int(attacker_roll * 0.2)
        }
        
        siege.attacker_strength -= result.attacker_casualties
        siege.defender_strength -= result.defender_casualties
        
        if result.success:
                siege.progress += 30
        
        if siege.defender_strength <= 0:
                _end_siege(siege_key, true)
        elif siege.attacker_strength <= 0:
                _end_siege(siege_key, false)
        
        return result

func _end_siege(siege_key: String, conquered: bool):
        if not active_sieges.has(siege_key):
                return
        
        var siege = active_sieges[siege_key]
        
        if conquered:
                var ss = get_node_or_null("/root/SettlementSystem")
                if ss:
                        ss.change_faction(siege.settlement_id, siege.attacker_faction)
                
                var war_key = _get_war_key(siege.attacker_faction, siege.defender_faction)
                if active_wars.has(war_key):
                        var war = active_wars[war_key]
                        if war.attacker == siege.attacker_faction:
                                war.attacker_war_score += 25
                        else:
                                war.defender_war_score += 25
                        war.conquered_settlements.append(siege.settlement_id)
        
        active_sieges.erase(siege_key)
        emit_signal("siege_ended", siege.settlement_id, conquered)

func create_army(faction: String, settlement_id: int, units: Dictionary) -> int:
        var ss = get_node_or_null("/root/SettlementSystem")
        if not ss:
                return -1
        
        var settlement = ss.get_settlement(settlement_id)
        if not settlement or settlement.faction != faction:
                return -1
        
        var army_id = _generate_army_id()
        var total_cost = 0
        var total_strength = 0
        
        for unit_type in units:
                var count = units[unit_type]
                var unit_data = unit_types.get(unit_type, unit_types.militia)
                total_cost += unit_data.cost * count
                total_strength += (unit_data.attack + unit_data.defense) * count
        
        if settlement.resources.get("gold", 0) < total_cost:
                return -1
        
        settlement.resources.gold -= total_cost
        
        armies[army_id] = {
                "id": army_id,
                "faction": faction,
                "units": units.duplicate(),
                "strength": total_strength,
                "morale": 100.0,
                "position": settlement.position,
                "target_position": settlement.position,
                "state": "idle"
        }
        
        emit_signal("army_created", faction, armies[army_id])
        return army_id

func move_army(army_id: int, target_position: Vector3):
        if armies.has(army_id):
                armies[army_id].target_position = target_position
                armies[army_id].state = "moving"

func _process_armies(delta):
        for army_id in armies:
                var army = armies[army_id]
                
                if army.state == "moving":
                        var direction = (army.target_position - army.position).normalized()
                        army.position += direction * 5.0 * delta
                        
                        if army.position.distance_to(army.target_position) < 2.0:
                                army.state = "idle"
                                army.position = army.target_position

func _process_wars(delta):
        for war_key in active_wars:
                var war = active_wars[war_key]
                
                var war_duration = Time.get_unix_time_from_system() - war.start_time
                if war_duration > 3600:
                        var exhaustion = war_duration / 7200
                        if randf() < exhaustion * 0.01:
                                end_war(war.attacker, war.defender)

func _get_faction_army_strength(faction: String, near_position: Vector3) -> float:
        var total = 0.0
        for army in armies.values():
                if army.faction == faction and army.position.distance_to(near_position) < 50:
                        total += army.strength
        return max(total, 10)

func _get_settlement_defense(settlement: Dictionary) -> float:
        var base_defense = 50.0
        var guards = settlement.population_breakdown.get("guard", 0)
        var level_bonus = settlement.level * 20
        return base_defense + guards * 10 + level_bonus

func _get_siege_power(faction: String, settlement_id: int) -> float:
        var ss = get_node_or_null("/root/SettlementSystem")
        if not ss:
                return 1.0
        
        var settlement = ss.get_settlement(settlement_id)
        if not settlement:
                return 1.0
        
        var power = 0.0
        for army in armies.values():
                if army.faction == faction and army.position.distance_to(settlement.position) < 30:
                        for unit_type in army.units:
                                var count = army.units[unit_type]
                                var unit_data = unit_types.get(unit_type, {})
                                power += unit_data.get("siege_power", 1) * count
        
        return max(power, 1.0)

func _mobilize_faction(faction: String):
        var ss = get_node_or_null("/root/SettlementSystem")
        if not ss:
                return
        
        for settlement in ss.get_settlements_by_faction(faction):
                var guards = settlement.population_breakdown.get("guard", 0)
                if guards >= 3:
                        var units = {"soldier": int(guards * 0.5), "militia": guards - int(guards * 0.5)}
                        create_army(faction, settlement.id, units)

func _get_war_key(faction_a: String, faction_b: String) -> String:
        var factions = [faction_a, faction_b]
        factions.sort()
        return factions[0] + "_vs_" + factions[1]

func _generate_army_id() -> int:
        var max_id = 0
        for id in armies.keys():
                max_id = max(max_id, id)
        return max_id + 1

func is_at_war(faction_a: String, faction_b: String) -> bool:
        return active_wars.has(_get_war_key(faction_a, faction_b))

func get_war_info(faction_a: String, faction_b: String) -> Dictionary:
        return active_wars.get(_get_war_key(faction_a, faction_b), {})

func get_faction_wars(faction: String) -> Array:
        var wars = []
        for war in active_wars.values():
                if war.attacker == faction or war.defender == faction:
                        wars.append(war)
        return wars

func get_faction_armies(faction: String) -> Array:
        var result = []
        for army in armies.values():
                if army.faction == faction:
                        result.append(army)
        return result
