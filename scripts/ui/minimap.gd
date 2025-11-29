extends Control

@onready var map_texture: TextureRect = $MapPanel/MapTexture
@onready var player_marker: Control = $MapPanel/PlayerMarker
@onready var compass: Label = $MapPanel/Compass

var world_gen = null
var player_ref: Node3D = null
var map_image: Image
var map_size := 128
var world_scale := 8.0

var zoom_level := 1.0
var min_zoom := 0.5
var max_zoom := 3.0
var rotate_with_player := true

var markers := []
var marker_nodes := {}

var marker_colors := {
        "quest": Color(1.0, 0.85, 0.0),
        "quest_objective": Color(0.0, 1.0, 0.5),
        "enemy": Color(1.0, 0.2, 0.2),
        "friendly": Color(0.3, 0.8, 1.0),
        "trader": Color(0.9, 0.7, 0.2),
        "building": Color(0.6, 0.6, 0.6),
        "resource": Color(0.5, 0.9, 0.3),
        "waypoint": Color(1.0, 1.0, 1.0),
        "death": Color(0.5, 0.0, 0.0),
        "home": Color(0.2, 0.6, 1.0)
}

signal marker_clicked(marker_data)

func _ready():
        world_gen = get_node_or_null("/root/WorldGenerator")
        _find_player()
        _generate_map_texture()
        _connect_systems()

func _connect_systems():
        var quest_sys = get_node_or_null("/root/QuestSystem")
        if quest_sys and quest_sys.has_signal("quest_activated"):
                quest_sys.connect("quest_activated", Callable(self, "_on_quest_activated"))
        
        var faction_sys = get_node_or_null("/root/FactionSystem")
        if faction_sys and faction_sys.has_signal("entity_registered"):
                faction_sys.connect("entity_registered", Callable(self, "_on_entity_registered"))

func _on_quest_activated(quest_id: String):
        var quest_sys = get_node_or_null("/root/QuestSystem")
        if quest_sys and quest_sys.has_method("get_quest_location"):
                var loc = quest_sys.get_quest_location(quest_id)
                if loc != Vector3.ZERO:
                        add_marker("quest_" + quest_id, loc, "quest", quest_id)

func _on_entity_registered(entity: Node, faction: String):
        if not is_instance_valid(entity):
                return
        
        var marker_type = "friendly"
        if faction in ["bandits", "monsters", "wild"]:
                marker_type = "enemy"
        elif faction == "traders":
                marker_type = "trader"
        
        if entity.has_method("get_global_position"):
                add_marker("entity_" + str(entity.get_instance_id()), entity.global_position, marker_type, entity.name)

func _find_player():
        var players = get_tree().get_nodes_in_group("players")
        if players.size() > 0:
                player_ref = players[0]

func _process(delta):
        if not player_ref:
                _find_player()
                return
        
        _update_compass()
        _update_player_marker()
        _update_markers()

func _input(event):
        if event is InputEventMouseButton:
                if event.button_index == MOUSE_BUTTON_WHEEL_UP:
                        zoom_in()
                elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
                        zoom_out()
                elif event.button_index == MOUSE_BUTTON_MIDDLE and event.pressed:
                        rotate_with_player = not rotate_with_player

func zoom_in():
        zoom_level = clamp(zoom_level + 0.25, min_zoom, max_zoom)
        _apply_zoom()

func zoom_out():
        zoom_level = clamp(zoom_level - 0.25, min_zoom, max_zoom)
        _apply_zoom()

func _apply_zoom():
        if map_texture:
                map_texture.scale = Vector2(zoom_level, zoom_level)

func add_marker(id: String, world_pos: Vector3, marker_type: String = "waypoint", label: String = ""):
        var existing = markers.filter(func(m): return m.id == id)
        if existing.size() > 0:
                existing[0].world_pos = world_pos
                existing[0].type = marker_type
                existing[0].label = label
                return
        
        var marker_data = {
                "id": id,
                "world_pos": world_pos,
                "type": marker_type,
                "label": label,
                "visible": true
        }
        markers.append(marker_data)
        _create_marker_node(marker_data)

func remove_marker(id: String):
        markers = markers.filter(func(m): return m.id != id)
        if marker_nodes.has(id):
                marker_nodes[id].queue_free()
                marker_nodes.erase(id)

func _create_marker_node(marker_data: Dictionary):
        var marker = Control.new()
        marker.name = "Marker_" + marker_data.id
        marker.custom_minimum_size = Vector2(8, 8)
        
        var color_rect = ColorRect.new()
        color_rect.size = Vector2(6, 6)
        color_rect.position = Vector2(-3, -3)
        color_rect.color = marker_colors.get(marker_data.type, Color.WHITE)
        marker.add_child(color_rect)
        
        if marker_data.label != "":
                var lbl = Label.new()
                lbl.text = marker_data.label
                lbl.add_theme_font_size_override("font_size", 8)
                lbl.position = Vector2(5, -6)
                marker.add_child(lbl)
        
        var map_panel = get_node_or_null("MapPanel")
        if map_panel:
                map_panel.add_child(marker)
        
        marker_nodes[marker_data.id] = marker

func _update_markers():
        if not player_ref or not map_texture:
                return
        
        for marker_data in markers:
                if not marker_nodes.has(marker_data.id):
                        _create_marker_node(marker_data)
                
                var marker_node = marker_nodes[marker_data.id]
                if not is_instance_valid(marker_node):
                        continue
                
                var world_pos = marker_data.world_pos
                var px = world_pos.x
                var pz = world_pos.z
                
                var map_x = (px / world_scale + map_size / 2.0) / map_size * map_texture.size.x
                var map_y = (pz / world_scale + map_size / 2.0) / map_size * map_texture.size.y
                
                var in_bounds = map_x >= 0 and map_x <= map_texture.size.x and map_y >= 0 and map_y <= map_texture.size.y
                marker_node.visible = marker_data.visible and in_bounds
                
                if marker_node.visible:
                        marker_node.position = Vector2(map_x, map_y)

func set_marker_visible(id: String, visible: bool):
        for marker in markers:
                if marker.id == id:
                        marker.visible = visible
                        break

func clear_markers_of_type(marker_type: String):
        var to_remove = []
        for marker in markers:
                if marker.type == marker_type:
                        to_remove.append(marker.id)
        
        for id in to_remove:
                remove_marker(id)

func get_markers_in_range(world_pos: Vector3, radius: float) -> Array:
        var result = []
        for marker in markers:
                var dist = marker.world_pos.distance_to(world_pos)
                if dist <= radius:
                        result.append(marker)
        return result

func _update_compass():
        if not player_ref or not compass:
                return
        
        var rot_y = player_ref.rotation.y
        var degrees = rad_to_deg(-rot_y)
        while degrees < 0:
                degrees += 360
        while degrees >= 360:
                degrees -= 360
        
        var direction = ""
        if degrees >= 337.5 or degrees < 22.5:
                direction = "С"
        elif degrees >= 22.5 and degrees < 67.5:
                direction = "СВ"
        elif degrees >= 67.5 and degrees < 112.5:
                direction = "В"
        elif degrees >= 112.5 and degrees < 157.5:
                direction = "ЮВ"
        elif degrees >= 157.5 and degrees < 202.5:
                direction = "Ю"
        elif degrees >= 202.5 and degrees < 247.5:
                direction = "ЮЗ"
        elif degrees >= 247.5 and degrees < 292.5:
                direction = "З"
        else:
                direction = "СЗ"
        
        compass.text = direction

func _update_player_marker():
        if not player_ref or not player_marker:
                return
        
        var px = player_ref.global_position.x
        var pz = player_ref.global_position.z
        
        var map_x = (px / world_scale + map_size / 2.0) / map_size * map_texture.size.x
        var map_y = (pz / world_scale + map_size / 2.0) / map_size * map_texture.size.y
        
        map_x = clamp(map_x, 5, map_texture.size.x - 5)
        map_y = clamp(map_y, 5, map_texture.size.y - 5)
        
        player_marker.position = Vector2(map_x - 5, map_y - 5)
        player_marker.rotation = -player_ref.rotation.y

func _generate_map_texture():
        if not world_gen:
                _create_fallback_texture()
                return
        
        map_image = Image.create(map_size, map_size, false, Image.FORMAT_RGBA8)
        
        for y in range(map_size):
                for x in range(map_size):
                        var world_x = (x - map_size / 2.0) * world_scale
                        var world_z = (y - map_size / 2.0) * world_scale
                        
                        var height = world_gen.get_height_at(world_x, world_z)
                        var biome = world_gen.get_biome_at(world_x, world_z)
                        var color = _get_map_color(biome, height)
                        
                        map_image.set_pixel(x, y, color)
        
        var tex = ImageTexture.create_from_image(map_image)
        map_texture.texture = tex

func _get_map_color(biome: String, height: float) -> Color:
        if height < 0:
                var depth = clamp(-height / 20.0, 0, 1)
                return Color(0.1, 0.2 + 0.2 * (1 - depth), 0.5 + 0.3 * (1 - depth))
        
        match biome:
                "ocean":
                        return Color(0.1, 0.3, 0.6)
                "beach":
                        return Color(0.9, 0.85, 0.6)
                "plains":
                        return Color(0.4, 0.7, 0.3)
                "forest":
                        return Color(0.2, 0.5, 0.2)
                "taiga":
                        return Color(0.2, 0.4, 0.3)
                "tundra":
                        return Color(0.7, 0.75, 0.8)
                "desert":
                        return Color(0.9, 0.8, 0.5)
                "savanna":
                        return Color(0.7, 0.6, 0.3)
                "swamp":
                        return Color(0.3, 0.4, 0.2)
                "mountains":
                        var h_factor = clamp(height / 50.0, 0, 1)
                        return Color(0.5 + 0.2 * h_factor, 0.5 + 0.2 * h_factor, 0.5 + 0.2 * h_factor)
                "snowy_mountains":
                        return Color(0.9, 0.92, 0.95)
                "hills":
                        return Color(0.5, 0.6, 0.4)
                _:
                        return Color(0.4, 0.5, 0.3)

func _create_fallback_texture():
        map_image = Image.create(map_size, map_size, false, Image.FORMAT_RGBA8)
        map_image.fill(Color(0.3, 0.5, 0.3))
        var tex = ImageTexture.create_from_image(map_image)
        map_texture.texture = tex

func regenerate_map():
        _generate_map_texture()
