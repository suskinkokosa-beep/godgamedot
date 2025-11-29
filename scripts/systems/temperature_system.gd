extends Node

# monitors player temperature exposure and applies debuffs
@export var cold_threshold := 0.0
@export var hot_threshold := 35.0
@export var cold_damage_interval := 5.0
@export var hot_damage_interval := 5.0

var timers := {} # player_id -> timer

func _is_server() -> bool:
    var mp = multiplayer
    if mp == null:
        return true
    if not mp.has_multiplayer_peer():
        return true
    return mp.is_server()

func _process(delta):
    # server authoritative: apply damage if extreme
    if not _is_server():
        return
    var players = get_tree().get_nodes_in_group("players")
    for p in players:
        if not is_instance_valid(p): continue
        var pid = p.get("net_id") if "net_id" in p else -1
        var temp = _estimate_temp_for_player(p)
        if temp <= cold_threshold or temp >= hot_threshold:
            timers[pid] = timers.get(pid, 0.0) + delta
            var interval = cold_damage_interval if temp <= cold_threshold else hot_damage_interval
            if timers[pid] >= interval:
                timers[pid] = 0.0
                # apply small damage or stamina drain
                if p.has_method("apply_damage"):
                    p.apply_damage(1, null)
        else:
            timers[pid] = 0.0

func _estimate_temp_for_player(p):
        var gm = get_node_or_null("/root/GameManager")
        var ws = get_node_or_null("/root/WeatherSystem")
        var bs = get_node_or_null("/root/BiomeSystem")
        var base = gm.get_temperature() if gm and gm.has_method("get_temperature") else 15.0
        if bs and bs.has_method("get_biome_at"):
                var biome = bs.get_biome_at(p.global_transform.origin)
                if biome and biome is Dictionary and biome.has("base_temp"):
                        base = biome.base_temp
        if ws:
                base += ws.temp_delta
        return base

func calculate_body_temp(pos: Vector3, current_temp: float, delta: float) -> float:
        var ambient = _get_ambient_temp(pos)
        var diff = ambient - current_temp
        var rate = 0.1 * delta
        return current_temp + diff * rate

func _get_ambient_temp(pos: Vector3) -> float:
        var base := 20.0
        var ws = get_node_or_null("/root/WeatherSystem")
        var dn = get_node_or_null("/root/DayNightCycle")
        
        if ws and ws.get("temp_delta") != null:
                base += ws.temp_delta
        
        if dn and dn.has_method("is_night"):
                if dn.is_night():
                        base -= 5.0
        
        return base
