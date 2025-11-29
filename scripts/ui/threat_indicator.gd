extends Control

var player: Node3D = null
var threat_indicators := []
var indicator_radius := 80.0
var max_threats := 8
var threat_fade_distance := 30.0
var threat_alert_distance := 15.0

var threat_colors := {
	"hostile": Color(1.0, 0.2, 0.2, 0.8),
	"aggressive": Color(1.0, 0.5, 0.2, 0.8),
	"neutral": Color(0.8, 0.8, 0.2, 0.6),
	"fleeing": Color(0.5, 0.5, 0.5, 0.5)
}

var alert_pulse_time := 0.0
var audio_manager = null

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	call_deferred("_find_player")
	audio_manager = get_node_or_null("/root/AudioManager")

func _find_player():
	var players = get_tree().get_nodes_in_group("players")
	if players.size() > 0:
		player = players[0]

func _process(delta):
	if not player:
		_find_player()
		return
	
	alert_pulse_time += delta * 3.0
	_update_threats()
	queue_redraw()

func _update_threats():
	threat_indicators.clear()
	
	var enemies = get_tree().get_nodes_in_group("enemies")
	var sorted_enemies := []
	
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy is Node3D:
			continue
		
		var distance = player.global_position.distance_to(enemy.global_position)
		if distance < threat_fade_distance:
			sorted_enemies.append({"node": enemy, "distance": distance})
	
	sorted_enemies.sort_custom(func(a, b): return a["distance"] < b["distance"])
	
	var count = 0
	for enemy_data in sorted_enemies:
		if count >= max_threats:
			break
		
		var enemy = enemy_data["node"]
		var distance = enemy_data["distance"]
		
		var to_enemy = enemy.global_position - player.global_position
		var angle = atan2(to_enemy.x, to_enemy.z)
		var player_yaw = player.rotation.y
		var relative_angle = angle + player_yaw
		
		var threat_level = "hostile"
		if enemy.has_method("get_threat_level"):
			threat_level = enemy.get_threat_level()
		elif enemy.get("is_fleeing"):
			threat_level = "fleeing"
		elif enemy.get("is_aggressive"):
			threat_level = "aggressive"
		
		var indicator = {
			"angle": relative_angle,
			"distance": distance,
			"threat_level": threat_level,
			"is_alert": distance < threat_alert_distance
		}
		
		threat_indicators.append(indicator)
		count += 1
	
	var close_threats = threat_indicators.filter(func(t): return t["is_alert"])
	if close_threats.size() > 0 and int(alert_pulse_time) % 2 == 0:
		if audio_manager and randf() < 0.01:
			audio_manager.play_event_sound("enemy_alert")

func _draw():
	var center = size / 2.0
	
	draw_arc(center, indicator_radius, 0, TAU, 64, Color(0.3, 0.3, 0.3, 0.2), 2.0)
	
	for indicator in threat_indicators:
		var angle = indicator["angle"]
		var distance = indicator["distance"]
		var threat_level = indicator["threat_level"]
		var is_alert = indicator["is_alert"]
		
		var base_color = threat_colors.get(threat_level, Color.RED)
		var alpha = clamp(1.0 - (distance / threat_fade_distance), 0.2, 1.0)
		var color = base_color
		color.a *= alpha
		
		if is_alert:
			var pulse = (sin(alert_pulse_time) + 1.0) / 2.0
			color = color.lerp(Color.WHITE, pulse * 0.3)
		
		var indicator_distance = indicator_radius * (1.0 - distance / threat_fade_distance * 0.3)
		var pos = center + Vector2(sin(angle), -cos(angle)) * indicator_distance
		
		var arrow_size = 12.0 if is_alert else 8.0
		var points := PackedVector2Array([
			pos + Vector2(sin(angle), -cos(angle)) * arrow_size,
			pos + Vector2(sin(angle + 2.5), -cos(angle + 2.5)) * (arrow_size * 0.5),
			pos + Vector2(sin(angle - 2.5), -cos(angle - 2.5)) * (arrow_size * 0.5)
		])
		
		draw_colored_polygon(points, color)
		
		if is_alert:
			draw_circle(pos, arrow_size * 1.5, Color(color.r, color.g, color.b, 0.2))

func get_nearest_threat() -> Dictionary:
	if threat_indicators.size() == 0:
		return {}
	return threat_indicators[0]

func get_threat_count() -> int:
	return threat_indicators.size()

func get_alert_count() -> int:
	return threat_indicators.filter(func(t): return t["is_alert"]).size()

func has_threats() -> bool:
	return threat_indicators.size() > 0

func has_close_threats() -> bool:
	return get_alert_count() > 0
