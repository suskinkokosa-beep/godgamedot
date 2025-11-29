extends Node

signal temperature_changed(player_id: int, temperature: float)

@export var cold_threshold := 0.0
@export var hot_threshold := 35.0
@export var cold_damage_interval := 5.0
@export var hot_damage_interval := 5.0
@export var comfort_zone_min := 15.0
@export var comfort_zone_max := 30.0

var timers := {}
var player_temps := {}

var biome_temperatures := {
        "deep_ocean": 8.0,
        "ocean": 12.0,
        "frozen_lake": -15.0,
        "beach": 28.0,
        "plains": 22.0,
        "meadow": 24.0,
        "forest": 18.0,
        "dense_forest": 16.0,
        "birch_forest": 15.0,
        "taiga": 5.0,
        "tundra": -5.0,
        "snow": -15.0,
        "snow_mountain": -25.0,
        "desert": 42.0,
        "red_desert": 40.0,
        "savanna": 35.0,
        "jungle": 32.0,
        "swamp": 25.0,
        "marsh": 20.0,
        "mountain": 8.0,
        "volcanic": 45.0,
        "canyon": 30.0,
        "river": 18.0,
        "lake": 16.0,
        "oasis": 28.0
}

func _is_server() -> bool:
        var mp = multiplayer
        if mp == null:
                return true
        if not mp.has_multiplayer_peer():
                return true
        return mp.is_server()

func _process(delta):
        if not _is_server():
                return
        var players = get_tree().get_nodes_in_group("players")
        for p in players:
                if not is_instance_valid(p): continue
                var pid = p.get("net_id") if "net_id" in p else -1
                var temp = _estimate_temp_for_player(p)
                player_temps[pid] = temp
                
                if temp <= cold_threshold or temp >= hot_threshold:
                        timers[pid] = timers.get(pid, 0.0) + delta
                        var interval = cold_damage_interval if temp <= cold_threshold else hot_damage_interval
                        if timers[pid] >= interval:
                                timers[pid] = 0.0
                                if p.has_method("apply_damage"):
                                        var damage = 2 if temp <= cold_threshold else 3
                                        p.apply_damage(damage, null)
                else:
                        timers[pid] = 0.0

func _estimate_temp_for_player(p) -> float:
        var pos = p.global_transform.origin if p else Vector3.ZERO
        var ambient = _get_ambient_temp(pos)
        var clothing_bonus = _get_clothing_insulation(p)
        var near_fire = _check_near_heat_source(p)
        
        var effective_temp = ambient
        
        if ambient < comfort_zone_min:
                effective_temp += clothing_bonus * 0.5
                if near_fire:
                        effective_temp += 15.0
        elif ambient > comfort_zone_max:
                effective_temp -= clothing_bonus * 0.2
        
        return effective_temp

func calculate_body_temp(pos: Vector3, current_temp: float, delta: float) -> float:
        var ambient = _get_ambient_temp(pos)
        var diff = ambient - current_temp
        
        var target_body_temp = 37.0
        if ambient < comfort_zone_min:
                target_body_temp = lerp(37.0, 35.0, clamp((comfort_zone_min - ambient) / 30.0, 0.0, 1.0))
        elif ambient > comfort_zone_max:
                target_body_temp = lerp(37.0, 40.0, clamp((ambient - comfort_zone_max) / 20.0, 0.0, 1.0))
        
        var rate = 0.05 * delta
        return current_temp + (target_body_temp - current_temp) * rate

func _get_ambient_temp(pos: Vector3) -> float:
        var base := 20.0
        
        var world_gen = get_node_or_null("/root/WorldGenerator")
        if world_gen and world_gen.has_method("get_biome_at"):
                var biome = world_gen.get_biome_at(pos.x, pos.z)
                if biome_temperatures.has(biome):
                        base = biome_temperatures[biome]
        else:
                var bs = get_node_or_null("/root/BiomeSystem")
                if bs and bs.has_method("get_biome_at"):
                        var biome_data = bs.get_biome_at(pos)
                        if biome_data and biome_data is Dictionary and biome_data.has("base_temp"):
                                base = biome_data["base_temp"]
        
        var ws = get_node_or_null("/root/WeatherSystem")
        if ws:
                var weather_delta = ws.get("temp_delta")
                if weather_delta != null:
                        base += weather_delta
                
                var current_weather = ws.get("current_weather")
                if current_weather != null:
                        match current_weather:
                                "rain":
                                        base -= 3.0
                                "heavy_rain", "storm", "thunderstorm":
                                        base -= 6.0
                                "snow", "blizzard":
                                        base -= 12.0
                                "fog":
                                        base -= 2.0
                                "heat_wave":
                                        base += 10.0
        
        var dn = get_node_or_null("/root/DayNightCycle")
        if dn:
                if dn.has_method("is_night") and dn.is_night():
                        base -= 8.0
                elif dn.has_method("get_time_of_day"):
                        var time = dn.get_time_of_day()
                        if time != null:
                                if time >= 0.0 and time < 0.25:
                                        base -= 5.0
                                elif time >= 0.25 and time < 0.5:
                                        base += 3.0
                                elif time >= 0.5 and time < 0.75:
                                        base += 0.0
                                else:
                                        base -= 3.0
        
        if pos.y > 50:
                var altitude_factor = (pos.y - 50) / 100.0
                base -= altitude_factor * 10.0
        
        return base

func _get_clothing_insulation(player) -> float:
        if not player:
                return 0.0
        
        var insulation := 0.0
        var inv = get_node_or_null("/root/Inventory")
        
        if inv and inv.has_method("get_equipped_items"):
                var equipped = inv.get_equipped_items()
                for item in equipped:
                        if item is Dictionary:
                                insulation += item.get("warmth", 0.0)
                                insulation += item.get("insulation", 0.0)
        
        return insulation

func _check_near_heat_source(player) -> bool:
        if not player:
                return false
        
        var campfires = get_tree().get_nodes_in_group("heat_sources")
        for fire in campfires:
                if is_instance_valid(fire):
                        var dist = player.global_position.distance_to(fire.global_position)
                        if dist < 5.0:
                                return true
        
        if player.has_method("has_item_equipped"):
                if player.has_item_equipped("torch"):
                        return true
        
        var arms = player.get_node_or_null("Camera3D/FirstPersonArms")
        if arms and arms.has_method("get_held_item_id"):
                if arms.get_held_item_id() == "torch":
                        return true
        
        return false

func get_player_temperature(player_id: int) -> float:
        return player_temps.get(player_id, 20.0)

func get_temperature_status(player_id: int) -> String:
        var temp = player_temps.get(player_id, 20.0)
        
        if temp <= -10.0:
                return "freezing"
        elif temp <= cold_threshold:
                return "cold"
        elif temp <= comfort_zone_min:
                return "chilly"
        elif temp <= comfort_zone_max:
                return "comfortable"
        elif temp <= hot_threshold:
                return "warm"
        else:
                return "overheating"

func get_temperature_color(player_id: int) -> Color:
        var status = get_temperature_status(player_id)
        match status:
                "freezing":
                        return Color(0.3, 0.5, 1.0)
                "cold":
                        return Color(0.5, 0.7, 1.0)
                "chilly":
                        return Color(0.7, 0.85, 1.0)
                "comfortable":
                        return Color(0.4, 1.0, 0.4)
                "warm":
                        return Color(1.0, 0.8, 0.4)
                "overheating":
                        return Color(1.0, 0.4, 0.3)
        return Color.WHITE
