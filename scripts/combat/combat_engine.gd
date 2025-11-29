extends Node

signal hit_registered(attacker_id: int, target_id: int, damage: float, zone: String)
signal actor_killed(target_id: int, killer_id: int)
signal combo_performed(attacker_id: int, combo_count: int, bonus_damage: float)
signal attack_blocked(defender_id: int, attacker_id: int, damage_reduced: float)
signal attack_parried(defender_id: int, attacker_id: int)
signal critical_hit(attacker_id: int, target_id: int, damage: float)
signal stamina_depleted(player_id: int)

var combo_windows := {}
var combo_counts := {}
var block_states := {}
var block_timers := {}
var parry_windows := {}
var attack_cooldowns := {}
var dodge_cooldowns := {}

var block_timeout := 5.0

var combo_time_window := 1.5
var parry_window_duration := 0.3
var dodge_cooldown := 1.0
var dodge_stamina_cost := 15.0
var block_stamina_cost_mult := 0.5
var parry_stamina_cost := 10.0

var zone_multipliers := {
        "head": 2.0,
        "neck": 1.8,
        "chest": 1.0,
        "back": 1.2,
        "arms": 0.7,
        "hands": 0.5,
        "legs": 0.7,
        "feet": 0.5
}

var damage_type_effectiveness := {
        "slash": {"leather": 1.0, "iron": 0.7, "steel": 0.5, "cloth": 1.3},
        "pierce": {"leather": 1.2, "iron": 0.8, "steel": 0.6, "cloth": 1.0},
        "blunt": {"leather": 0.8, "iron": 1.2, "steel": 1.0, "cloth": 0.9},
        "fire": {"leather": 1.5, "iron": 0.5, "steel": 0.3, "cloth": 2.0},
        "ice": {"leather": 1.0, "iron": 1.0, "steel": 1.0, "cloth": 1.2}
}

func _process(delta):
        _update_combo_windows(delta)
        _update_parry_windows(delta)
        _update_cooldowns(delta)
        _update_block_timers(delta)

func _update_block_timers(delta):
        var expired = []
        for id in block_timers.keys():
                block_timers[id] -= delta
                if block_timers[id] <= 0:
                        expired.append(id)
        for id in expired:
                block_timers.erase(id)
                block_states[id] = false

func _update_combo_windows(delta):
        var expired = []
        for id in combo_windows.keys():
                combo_windows[id] -= delta
                if combo_windows[id] <= 0:
                        expired.append(id)
        for id in expired:
                combo_windows.erase(id)
                combo_counts.erase(id)

func _update_parry_windows(delta):
        var expired = []
        for id in parry_windows.keys():
                parry_windows[id] -= delta
                if parry_windows[id] <= 0:
                        expired.append(id)
        for id in expired:
                parry_windows.erase(id)

func _update_cooldowns(delta):
        for id in attack_cooldowns.keys():
                attack_cooldowns[id] = max(0, attack_cooldowns[id] - delta)
        for id in dodge_cooldowns.keys():
                dodge_cooldowns[id] = max(0, dodge_cooldowns[id] - delta)

func calculate_damage(attacker, target, weapon: Dictionary, zone: String) -> Dictionary:
        var damage_min = weapon.get("damage_min", 0)
        var damage_max = weapon.get("damage_max", 0)
        
        if damage_min == 0 and damage_max == 0:
                var legacy_damage = weapon.get("damage", 10)
                damage_min = legacy_damage * 0.8
                damage_max = legacy_damage * 1.2
        
        var base_damage = (damage_min + damage_max) * 0.5
        
        var zone_mult = zone_multipliers.get(zone, 1.0)
        
        var attacker_id = _get_prop(attacker, "net_id", -1)
        var combo_mult = 1.0
        if combo_counts.has(attacker_id):
                var combo = combo_counts[attacker_id]
                combo_mult = 1.0 + (combo * 0.15)
                combo_mult = min(combo_mult, 2.0)
        
        var crit_chance = weapon.get("critical_chance", 0.05)
        var is_crit = false
        var crit_mult = 1.0
        
        var prog = get_node_or_null("/root/PlayerProgression")
        if prog and attacker:
                var pid = _get_prop(attacker, "net_id", 1)
                crit_chance += prog.get_skill_bonus(pid, "combat") * 0.01
        
        if randf() < crit_chance:
                is_crit = true
                crit_mult = weapon.get("critical_multiplier", 1.5)
        
        var damage_type = weapon.get("damage_type", "slash")
        var type_mult = 1.0
        
        if target and target.has_method("get_armor_type"):
                var armor_type = target.get_armor_type(zone)
                if damage_type_effectiveness.has(damage_type):
                        type_mult = damage_type_effectiveness[damage_type].get(armor_type, 1.0)
        
        var raw_damage = base_damage * zone_mult * combo_mult * crit_mult * type_mult
        
        var armor_value = 0.0
        if target and target.has_method("get_armor_value"):
                armor_value = target.get_armor_value(zone)
        
        var mitigation = clamp(armor_value / 100.0, 0.0, 0.8)
        var final_damage = raw_damage * (1.0 - mitigation)
        
        return {
                "damage": max(1.0, final_damage),
                "raw_damage": raw_damage,
                "is_critical": is_crit,
                "combo_count": combo_counts.get(attacker_id, 0),
                "zone": zone,
                "damage_type": damage_type,
                "mitigation_percent": mitigation * 100
        }

func register_hit(attacker_node, target_node, weapon: Dictionary, zone: String) -> Dictionary:
        var attacker_id = _get_prop(attacker_node, "net_id", -1)
        var target_id = _get_prop(target_node, "net_id", -1)
        
        if attack_cooldowns.get(attacker_id, 0) > 0:
                return {"success": false, "reason": "cooldown"}
        
        var stamina_cost = weapon.get("stamina_cost", 10.0)
        if attacker_node and attacker_node.has_method("get_stamina"):
                var current_stamina = attacker_node.get_stamina()
                if current_stamina < stamina_cost:
                        emit_signal("stamina_depleted", attacker_id)
                        return {"success": false, "reason": "no_stamina"}
                
                if attacker_node.has_method("use_stamina"):
                        attacker_node.use_stamina(stamina_cost)
        
        if parry_windows.has(target_id):
                emit_signal("attack_parried", target_id, attacker_id)
                
                if attacker_node and attacker_node.has_method("apply_stagger"):
                        attacker_node.apply_stagger(1.0)
                
                return {"success": false, "reason": "parried"}
        
        var damage_result = calculate_damage(attacker_node, target_node, weapon, zone)
        var final_damage = damage_result["damage"]
        
        if block_states.get(target_id, false):
                var block_reduction = 0.7
                
                if target_node and target_node.has_method("get_block_power"):
                        block_reduction = target_node.get_block_power()
                
                var blocked_damage = final_damage * block_reduction
                final_damage -= blocked_damage
                
                var block_stamina_drain = blocked_damage * block_stamina_cost_mult
                if target_node and target_node.has_method("use_stamina"):
                        target_node.use_stamina(block_stamina_drain)
                
                emit_signal("attack_blocked", target_id, attacker_id, blocked_damage)
        
        _update_combo(attacker_id)
        
        if target_node and target_node.has_method("apply_damage"):
                target_node.apply_damage(final_damage, attacker_node)
        
        emit_signal("hit_registered", attacker_id, target_id, final_damage, zone)
        
        if damage_result["is_critical"]:
                emit_signal("critical_hit", attacker_id, target_id, final_damage)
        
        if combo_counts.get(attacker_id, 0) >= 3:
                emit_signal("combo_performed", attacker_id, combo_counts[attacker_id], final_damage)
        
        var attack_speed = weapon.get("attack_speed", 1.0)
        attack_cooldowns[attacker_id] = 1.0 / attack_speed
        
        var health = _get_prop(target_node, "health", 100)
        if health <= 0:
                emit_signal("actor_killed", target_id, attacker_id)
        
        return {
                "success": true,
                "damage": final_damage,
                "is_critical": damage_result["is_critical"],
                "combo_count": combo_counts.get(attacker_id, 0)
        }

func _update_combo(attacker_id: int):
        if combo_windows.has(attacker_id):
                combo_counts[attacker_id] = combo_counts.get(attacker_id, 0) + 1
        else:
                combo_counts[attacker_id] = 1
        
        combo_windows[attacker_id] = combo_time_window

func start_block(player_id: int):
        block_states[player_id] = true
        block_timers[player_id] = block_timeout

func end_block(player_id: int):
        block_states[player_id] = false
        block_timers.erase(player_id)

func try_parry(player_node) -> bool:
        var player_id = _get_prop(player_node, "net_id", -1)
        
        if player_node and player_node.has_method("get_stamina"):
                var stamina = player_node.get_stamina()
                if stamina < parry_stamina_cost:
                        return false
                
                if player_node.has_method("use_stamina"):
                        player_node.use_stamina(parry_stamina_cost)
        
        parry_windows[player_id] = parry_window_duration
        return true

func try_dodge(player_node, direction: Vector3) -> bool:
        var player_id = _get_prop(player_node, "net_id", -1)
        
        if dodge_cooldowns.get(player_id, 0) > 0:
                return false
        
        if player_node and player_node.has_method("get_stamina"):
                var stamina = player_node.get_stamina()
                if stamina < dodge_stamina_cost:
                        return false
                
                if player_node.has_method("use_stamina"):
                        player_node.use_stamina(dodge_stamina_cost)
        
        dodge_cooldowns[player_id] = dodge_cooldown
        
        if player_node and player_node.has_method("apply_dodge"):
                player_node.apply_dodge(direction)
        
        return true

func get_combo_count(player_id: int) -> int:
        return combo_counts.get(player_id, 0)

func is_blocking(player_id: int) -> bool:
        return block_states.get(player_id, false)

func is_parry_active(player_id: int) -> bool:
        return parry_windows.has(player_id)

func can_attack(player_id: int) -> bool:
        return attack_cooldowns.get(player_id, 0) <= 0

func reset_combo(player_id: int):
        combo_counts.erase(player_id)
        combo_windows.erase(player_id)

func get_weapon_stats(weapon_id: String) -> Dictionary:
        var inv = get_node_or_null("/root/Inventory")
        if inv and inv.has_method("get_item_info"):
                var info = inv.get_item_info(weapon_id)
                if info:
                        return {
                                "damage_min": info.get("damage", 10) * 0.8,
                                "damage_max": info.get("damage", 10) * 1.2,
                                "attack_speed": info.get("attack_speed", 1.0),
                                "critical_chance": info.get("crit_chance", 0.05),
                                "critical_multiplier": info.get("crit_mult", 1.5),
                                "damage_type": info.get("damage_type", "slash"),
                                "stamina_cost": info.get("stamina_cost", 10.0),
                                "range": info.get("range", 2.0)
                        }
        
        return {
                "damage_min": 8,
                "damage_max": 12,
                "attack_speed": 1.0,
                "critical_chance": 0.05,
                "critical_multiplier": 1.5,
                "damage_type": "blunt",
                "stamina_cost": 5.0,
                "range": 1.5
        }

func _get_prop(obj, prop: String, default = null):
        if obj == null:
                return default
        if prop in obj:
                return obj.get(prop)
        if obj.has_method("get"):
                var val = obj.get(prop)
                if val != null:
                        return val
        return default
