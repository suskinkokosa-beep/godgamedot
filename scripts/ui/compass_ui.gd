extends Control

@onready var compass_bar = $CompassBar
@onready var direction_label = $DirectionLabel
@onready var markers_container = $MarkersContainer

var player: Node3D = null
var tracked_markers := []
var compass_width := 400.0

var cardinal_directions := {
	0.0: "N",
	45.0: "NE", 
	90.0: "E",
	135.0: "SE",
	180.0: "S",
	225.0: "SW",
	270.0: "W",
	315.0: "NW"
}

var marker_icons := {
	"quest": "!",
	"enemy": "X",
	"poi": "*",
	"home": "H",
	"trader": "$",
	"waypoint": ">"
}

var marker_colors := {
	"quest": Color(1.0, 0.8, 0.2),
	"enemy": Color(1.0, 0.2, 0.2),
	"poi": Color(0.5, 0.8, 1.0),
	"home": Color(0.2, 1.0, 0.4),
	"trader": Color(0.9, 0.7, 0.3),
	"waypoint": Color(1.0, 1.0, 1.0)
}

func _ready():
	_setup_ui()
	call_deferred("_find_player")

func _setup_ui():
	custom_minimum_size = Vector2(compass_width, 40)
	
	if not compass_bar:
		compass_bar = ColorRect.new()
		compass_bar.name = "CompassBar"
		compass_bar.color = Color(0.1, 0.1, 0.1, 0.7)
		compass_bar.custom_minimum_size = Vector2(compass_width, 30)
		add_child(compass_bar)
	
	if not direction_label:
		direction_label = Label.new()
		direction_label.name = "DirectionLabel"
		direction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		direction_label.add_theme_font_size_override("font_size", 14)
		add_child(direction_label)
	
	if not markers_container:
		markers_container = Control.new()
		markers_container.name = "MarkersContainer"
		markers_container.custom_minimum_size = Vector2(compass_width, 30)
		add_child(markers_container)

func _find_player():
	var players = get_tree().get_nodes_in_group("players")
	if players.size() > 0:
		player = players[0]

func _process(_delta):
	if not player:
		_find_player()
		return
	
	_update_compass()
	_update_markers()

func _update_compass():
	var yaw = 0.0
	
	if player is Node3D:
		yaw = rad_to_deg(-player.rotation.y)
		yaw = fmod(yaw + 360.0, 360.0)
	
	var direction = _get_cardinal_direction(yaw)
	if direction_label:
		direction_label.text = direction + " (" + str(int(yaw)) + ")"
	
	_draw_compass_directions(yaw)

func _get_cardinal_direction(yaw: float) -> String:
	var closest = "N"
	var min_diff = 360.0
	
	for angle in cardinal_directions.keys():
		var diff = abs(yaw - angle)
		diff = min(diff, 360.0 - diff)
		if diff < min_diff:
			min_diff = diff
			closest = cardinal_directions[angle]
	
	return closest

func _draw_compass_directions(player_yaw: float):
	for child in compass_bar.get_children():
		child.queue_free()
	
	for angle in cardinal_directions.keys():
		var relative_angle = angle - player_yaw
		relative_angle = fmod(relative_angle + 180.0, 360.0) - 180.0
		
		if abs(relative_angle) > 90:
			continue
		
		var x_pos = (relative_angle / 90.0) * (compass_width / 2.0) + (compass_width / 2.0)
		
		var label = Label.new()
		label.text = cardinal_directions[angle]
		label.position = Vector2(x_pos - 8, 5)
		
		if cardinal_directions[angle] in ["N", "S", "E", "W"]:
			label.add_theme_font_size_override("font_size", 16)
			label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.7))
		else:
			label.add_theme_font_size_override("font_size", 12)
			label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		
		compass_bar.add_child(label)

func _update_markers():
	if not markers_container:
		return
	
	for child in markers_container.get_children():
		child.queue_free()
	
	var player_pos = player.global_position if player else Vector3.ZERO
	var player_yaw = rad_to_deg(-player.rotation.y) if player else 0.0
	
	for marker in tracked_markers:
		var marker_pos = marker.get("position", Vector3.ZERO)
		var marker_type = marker.get("type", "poi")
		
		var to_marker = marker_pos - player_pos
		var angle_to_marker = rad_to_deg(atan2(to_marker.x, to_marker.z))
		angle_to_marker = fmod(angle_to_marker + 360.0, 360.0)
		
		var relative_angle = angle_to_marker - player_yaw
		relative_angle = fmod(relative_angle + 180.0, 360.0) - 180.0
		
		if abs(relative_angle) > 90:
			continue
		
		var x_pos = (relative_angle / 90.0) * (compass_width / 2.0) + (compass_width / 2.0)
		var distance = to_marker.length()
		
		var label = Label.new()
		label.text = marker_icons.get(marker_type, "*")
		label.position = Vector2(x_pos - 6, 2)
		label.add_theme_color_override("font_color", marker_colors.get(marker_type, Color.WHITE))
		label.add_theme_font_size_override("font_size", 18)
		
		if distance < 100:
			label.modulate.a = 1.0
		else:
			label.modulate.a = clamp(1.0 - (distance - 100) / 200.0, 0.3, 1.0)
		
		markers_container.add_child(label)

func add_marker(id: String, position: Vector3, marker_type: String = "poi"):
	for marker in tracked_markers:
		if marker.get("id") == id:
			marker["position"] = position
			marker["type"] = marker_type
			return
	
	tracked_markers.append({
		"id": id,
		"position": position,
		"type": marker_type
	})

func remove_marker(id: String):
	for i in range(tracked_markers.size() - 1, -1, -1):
		if tracked_markers[i].get("id") == id:
			tracked_markers.remove_at(i)

func clear_markers():
	tracked_markers.clear()

func update_enemy_markers():
	for marker in tracked_markers.duplicate():
		if marker.get("type") == "enemy":
			tracked_markers.erase(marker)
	
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy is Node3D:
			var distance = 0.0
			if player:
				distance = player.global_position.distance_to(enemy.global_position)
			
			if distance < 50.0:
				add_marker("enemy_" + str(enemy.get_instance_id()), enemy.global_position, "enemy")
