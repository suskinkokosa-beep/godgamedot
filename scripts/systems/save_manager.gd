extends Node

signal save_completed(slot_name: String)
signal load_completed(slot_name: String)
signal save_failed(error: String)
signal load_failed(error: String)

const SAVE_DIR := "user://saves/"
const MAX_SLOTS := 5

var current_slot := ""
var autosave_enabled := true
var autosave_interval := 300.0
var autosave_timer := 0.0

func _ready():
        var dir = DirAccess.open("user://")
        if dir and not dir.dir_exists("saves"):
                dir.make_dir("saves")

func _process(delta: float):
        if autosave_enabled and current_slot != "":
                autosave_timer += delta
                if autosave_timer >= autosave_interval:
                        autosave_timer = 0
                        save_game(current_slot, true)

func get_save_slots() -> Array:
        var slots := []
        var dir = DirAccess.open(SAVE_DIR)
        if not dir:
                return slots
        
        dir.list_dir_begin()
        var file_name = dir.get_next()
        while file_name != "":
                if file_name.ends_with(".sav"):
                        var slot_name = file_name.trim_suffix(".sav")
                        var meta = _load_save_meta(slot_name)
                        slots.append({
                                "name": slot_name,
                                "timestamp": meta.get("timestamp", 0),
                                "playtime": meta.get("playtime", 0),
                                "level": meta.get("level", 1),
                                "date": meta.get("date", ""),
                                "is_autosave": meta.get("is_autosave", false)
                        })
                file_name = dir.get_next()
        dir.list_dir_end()
        
        slots.sort_custom(func(a, b): return a.timestamp > b.timestamp)
        return slots

func save_game(slot_name: String, is_autosave: bool = false) -> bool:
        current_slot = slot_name
        
        var save_data := {
                "version": 1,
                "timestamp": Time.get_unix_time_from_system(),
                "date": Time.get_datetime_string_from_system(),
                "is_autosave": is_autosave,
                "player": _serialize_player(),
                "inventory": _serialize_inventory(),
                "progression": _serialize_progression(),
                "world": _serialize_world(),
                "buildings": _serialize_buildings(),
                "time": _serialize_time()
        }
        
        var file_path = SAVE_DIR + slot_name + ".sav"
        var file = FileAccess.open(file_path, FileAccess.WRITE)
        if not file:
                emit_signal("save_failed", "Не удалось открыть файл для записи")
                return false
        
        var json = JSON.stringify(save_data, "\t")
        file.store_string(json)
        file.close()
        
        emit_signal("save_completed", slot_name)
        print("Игра сохранена: ", slot_name)
        return true

func load_game(slot_name: String) -> bool:
        var file_path = SAVE_DIR + slot_name + ".sav"
        
        if not FileAccess.file_exists(file_path):
                emit_signal("load_failed", "Файл сохранения не найден")
                return false
        
        var file = FileAccess.open(file_path, FileAccess.READ)
        if not file:
                emit_signal("load_failed", "Не удалось открыть файл")
                return false
        
        var json_str = file.get_as_text()
        file.close()
        
        var json = JSON.new()
        var error = json.parse(json_str)
        if error != OK:
                emit_signal("load_failed", "Ошибка парсинга JSON")
                return false
        
        var save_data = json.data
        if not save_data is Dictionary:
                emit_signal("load_failed", "Неверный формат данных")
                return false
        
        current_slot = slot_name
        
        _deserialize_player(save_data.get("player", {}))
        _deserialize_inventory(save_data.get("inventory", {}))
        _deserialize_progression(save_data.get("progression", {}))
        _deserialize_time(save_data.get("time", {}))
        _deserialize_world(save_data.get("world", {}))
        _deserialize_buildings(save_data.get("buildings", {}))
        
        emit_signal("load_completed", slot_name)
        print("Игра загружена: ", slot_name)
        return true

func delete_save(slot_name: String) -> bool:
        var file_path = SAVE_DIR + slot_name + ".sav"
        var dir = DirAccess.open(SAVE_DIR)
        if dir and dir.file_exists(slot_name + ".sav"):
                dir.remove(slot_name + ".sav")
                return true
        return false

func has_save(slot_name: String) -> bool:
        return FileAccess.file_exists(SAVE_DIR + slot_name + ".sav")

func _load_save_meta(slot_name: String) -> Dictionary:
        var file_path = SAVE_DIR + slot_name + ".sav"
        if not FileAccess.file_exists(file_path):
                return {}
        
        var file = FileAccess.open(file_path, FileAccess.READ)
        if not file:
                return {}
        
        var json_str = file.get_as_text()
        file.close()
        
        var json = JSON.new()
        if json.parse(json_str) != OK:
                return {}
        
        var data = json.data
        if not data is Dictionary:
                return {}
        
        var player_data = data.get("player", {})
        var progression_data = data.get("progression", {})
        
        return {
                "timestamp": data.get("timestamp", 0),
                "date": data.get("date", ""),
                "playtime": data.get("playtime", 0),
                "level": progression_data.get("level", 1),
                "is_autosave": data.get("is_autosave", false)
        }

func _serialize_player() -> Dictionary:
        var players = get_tree().get_nodes_in_group("players")
        if players.size() == 0:
                return {}
        
        var player = players[0]
        return {
                "position": {
                        "x": player.global_position.x,
                        "y": player.global_position.y,
                        "z": player.global_position.z
                },
                "rotation_y": player.rotation.y,
                "health": player.get("health"),
                "stamina": player.get("stamina"),
                "hunger": player.get("hunger"),
                "thirst": player.get("thirst"),
                "sanity": player.get("sanity"),
                "blood": player.get("blood"),
                "body_temperature": player.get("body_temperature")
        }

func _deserialize_player(data: Dictionary):
        if data.is_empty():
                return
        
        var players = get_tree().get_nodes_in_group("players")
        if players.size() == 0:
                return
        
        var player = players[0]
        
        if data.has("position"):
                var pos = data["position"]
                player.global_position = Vector3(pos.x, pos.y, pos.z)
                player.set("is_spawning", false)
                player.set("spawn_grace_timer", 3.0)
        
        if data.has("rotation_y"):
                player.rotation.y = data["rotation_y"]
        
        for stat in ["health", "stamina", "hunger", "thirst", "sanity", "blood", "body_temperature"]:
                if data.has(stat) and player.get(stat) != null:
                        player.set(stat, data[stat])

func _serialize_inventory() -> Dictionary:
        var inv = get_node_or_null("/root/Inventory")
        if not inv:
                return {}
        
        var items := []
        var bag = inv.get("bag")
        if bag:
                for item in bag:
                        if item != null and item is Dictionary:
                                items.append(item.duplicate())
        
        var hotbar := []
        var hb = inv.get("hotbar")
        if hb:
                for item in hb:
                        if item != null and item is Dictionary:
                                hotbar.append(item.duplicate())
                        else:
                                hotbar.append(null)
        
        var equipment := []
        var eq = inv.get("equipment")
        if eq:
                for item in eq:
                        if item != null and item is Dictionary:
                                equipment.append(item.duplicate())
                        else:
                                equipment.append(null)
        
        return {
                "bag": items,
                "hotbar": hotbar,
                "equipment": equipment,
                "selected_slot": inv.get("selected_hotbar_slot")
        }

func _deserialize_inventory(data: Dictionary):
        if data.is_empty():
                return
        
        var inv = get_node_or_null("/root/Inventory")
        if not inv:
                return
        
        if data.has("bag") and inv.has_method("clear_bag"):
                inv.clear_bag()
                for item in data["bag"]:
                        if item != null and item is Dictionary:
                                inv.add_item(item.get("id", ""), item.get("count", 1))
        elif data.has("bag"):
                var bag = inv.get("bag")
                if bag != null:
                        bag.clear()
                        for item in data["bag"]:
                                if item != null:
                                        bag.append(item)
        
        if data.has("hotbar"):
                var hotbar = inv.get("hotbar")
                if hotbar != null:
                        for i in range(min(hotbar.size(), data["hotbar"].size())):
                                hotbar[i] = data["hotbar"][i]
        
        if data.has("equipment"):
                var eq = inv.get("equipment")
                if eq != null:
                        for i in range(min(eq.size(), data["equipment"].size())):
                                eq[i] = data["equipment"][i]
        
        if data.has("selected_slot"):
                inv.set("selected_hotbar_slot", data["selected_slot"])
        
        inv.emit_signal("inventory_changed")
        inv.emit_signal("hotbar_changed")

func _serialize_progression() -> Dictionary:
        var prog = get_node_or_null("/root/PlayerProgression")
        if not prog:
                return {}
        
        var p = prog.get_player(1)
        if p.is_empty():
                return {}
        
        return {
                "level": p.get("level", 1),
                "xp": p.get("xp", 0),
                "perk_points": p.get("perk_points", 0),
                "stats": p.get("stats", {}),
                "attributes": p.get("attributes", {}),
                "skills": p.get("skills", {}),
                "skill_xp": p.get("skill_xp", {}),
                "debuffs": p.get("debuffs", {})
        }

func _deserialize_progression(data: Dictionary):
        if data.is_empty():
                return
        
        var prog = get_node_or_null("/root/PlayerProgression")
        if not prog:
                return
        
        prog.ensure_player(1)
        var p = prog.players[1]
        
        for key in ["level", "xp", "perk_points"]:
                if data.has(key):
                        p[key] = data[key]
        
        for key in ["stats", "attributes", "skills", "skill_xp", "debuffs"]:
                if data.has(key) and data[key] is Dictionary:
                        for k in data[key].keys():
                                if p[key].has(k):
                                        p[key][k] = data[key][k]

func _serialize_world() -> Dictionary:
        var weather_sys = get_node_or_null("/root/WeatherSystem")
        var world_data := {}
        
        if weather_sys:
                world_data["weather"] = {
                        "current_weather": weather_sys.get("current_weather"),
                        "temperature": weather_sys.get("temperature")
                }
        
        return world_data

func _deserialize_world(data: Dictionary):
        if data.is_empty():
                return
        
        var weather_sys = get_node_or_null("/root/WeatherSystem")
        if weather_sys and data.has("weather"):
                var w = data["weather"]
                if w.has("current_weather"):
                        weather_sys.set("current_weather", w["current_weather"])
                if w.has("temperature"):
                        weather_sys.set("temperature", w["temperature"])

func _serialize_buildings() -> Dictionary:
        var build_sys = get_node_or_null("/root/BuildSystem")
        if not build_sys:
                return {}
        
        var buildings := []
        var placed = build_sys.get_placed_structures()
        
        for structure in placed:
                if not is_instance_valid(structure):
                        continue
                
                var structure_data := {
                        "type": structure.get_meta("structure_type", "unknown"),
                        "health": structure.get_meta("health", 100),
                        "max_health": structure.get_meta("max_health", 100),
                        "position": {
                                "x": structure.global_position.x,
                                "y": structure.global_position.y,
                                "z": structure.global_position.z
                        },
                        "rotation": {
                                "x": structure.global_rotation.x,
                                "y": structure.global_rotation.y,
                                "z": structure.global_rotation.z
                        }
                }
                buildings.append(structure_data)
        
        return {"buildings": buildings, "count": buildings.size()}

func _deserialize_buildings(data: Dictionary):
        if data.is_empty() or not data.has("buildings"):
                return
        
        var build_sys = get_node_or_null("/root/BuildSystem")
        if not build_sys:
                return
        
        var buildings_to_load = data.get("buildings", [])
        if buildings_to_load.is_empty():
                return
        
        for existing in build_sys.get_placed_structures():
                if is_instance_valid(existing):
                        existing.queue_free()
        build_sys.placed_structures.clear()
        
        for building_data in buildings_to_load:
                if not building_data is Dictionary:
                        continue
                
                var structure_type = building_data.get("type", "")
                if structure_type == "" or structure_type == "unknown":
                        continue
                
                var pos = Vector3(
                        building_data["position"].get("x", 0),
                        building_data["position"].get("y", 0),
                        building_data["position"].get("z", 0)
                )
                var rot = Vector3(
                        building_data["rotation"].get("x", 0),
                        building_data["rotation"].get("y", 0),
                        building_data["rotation"].get("z", 0)
                )
                
                build_sys._place_structure(structure_type, pos, rot)
                
                var placed_list = build_sys.placed_structures
                if placed_list.size() > 0:
                        var last_structure = placed_list[placed_list.size() - 1]
                        if is_instance_valid(last_structure):
                                last_structure.global_rotation = rot
                                last_structure.set_meta("health", building_data.get("health", 100))
                                last_structure.set_meta("max_health", building_data.get("max_health", 100))

func _serialize_time() -> Dictionary:
        var day_night = get_node_or_null("/root/DayNightCycle")
        if not day_night:
                return {}
        
        return {
                "time_of_day": day_night.get("time_of_day"),
                "day": day_night.get("current_day")
        }

func _deserialize_time(data: Dictionary):
        if data.is_empty():
                return
        
        var day_night = get_node_or_null("/root/DayNightCycle")
        if not day_night:
                return
        
        if data.has("time_of_day"):
                day_night.set("time_of_day", data["time_of_day"])
        if data.has("day"):
                day_night.set("current_day", data["day"])

func get_formatted_date(timestamp: int) -> String:
        var dt = Time.get_datetime_dict_from_unix_time(timestamp)
        return "%02d.%02d.%d %02d:%02d" % [dt.day, dt.month, dt.year, dt.hour, dt.minute]

func get_formatted_playtime(seconds: int) -> String:
        var hours = seconds / 3600
        var mins = (seconds % 3600) / 60
        return "%dч %02dм" % [hours, mins]
