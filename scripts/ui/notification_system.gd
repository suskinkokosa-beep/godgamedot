extends CanvasLayer

var notification_queue := []
var current_notifications := []
const MAX_VISIBLE := 5
const NOTIFICATION_DURATION := 3.0
const SLIDE_DURATION := 0.3

var container: VBoxContainer = null

enum NotificationType { INFO, SUCCESS, WARNING, ERROR, XP, LEVEL_UP, ITEM, ACHIEVEMENT }

const TYPE_COLORS := {
	NotificationType.INFO: Color(0.4, 0.6, 0.8),
	NotificationType.SUCCESS: Color(0.3, 0.7, 0.3),
	NotificationType.WARNING: Color(0.8, 0.7, 0.2),
	NotificationType.ERROR: Color(0.8, 0.3, 0.3),
	NotificationType.XP: Color(0.7, 0.6, 1.0),
	NotificationType.LEVEL_UP: Color(1.0, 0.85, 0.2),
	NotificationType.ITEM: Color(0.6, 0.5, 0.4),
	NotificationType.ACHIEVEMENT: Color(1.0, 0.75, 0.0)
}

const TYPE_ICONS := {
	NotificationType.INFO: "ℹ️",
	NotificationType.SUCCESS: "✅",
	NotificationType.WARNING: "⚠️",
	NotificationType.ERROR: "❌",
	NotificationType.XP: "⭐",
	NotificationType.LEVEL_UP: "🎉",
	NotificationType.ITEM: "📦",
	NotificationType.ACHIEVEMENT: "🏆"
}

func _ready():
	_create_container()

func _create_container():
	container = VBoxContainer.new()
	container.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	container.offset_left = -320
	container.offset_right = -10
	container.offset_top = 80
	container.offset_bottom = 400
	container.add_theme_constant_override("separation", 5)
	add_child(container)

func _process(_delta):
	_process_queue()

func _process_queue():
	while notification_queue.size() > 0 and current_notifications.size() < MAX_VISIBLE:
		var notif = notification_queue.pop_front()
		_display_notification(notif)

func notify(message: String, type: NotificationType = NotificationType.INFO, duration: float = NOTIFICATION_DURATION):
	notification_queue.append({
		"message": message,
		"type": type,
		"duration": duration
	})

func notify_xp(amount: int):
	notify("+%d опыта" % amount, NotificationType.XP, 2.0)

func notify_level_up(new_level: int):
	notify("Уровень %d!" % new_level, NotificationType.LEVEL_UP, 4.0)

func notify_item_pickup(item_name: String, count: int = 1):
	if count > 1:
		notify("+%d %s" % [count, item_name], NotificationType.ITEM, 2.0)
	else:
		notify("+" + item_name, NotificationType.ITEM, 2.0)

func notify_achievement(achievement_name: String):
	notify("Достижение: " + achievement_name, NotificationType.ACHIEVEMENT, 5.0)

func notify_error(message: String):
	notify(message, NotificationType.ERROR, 3.0)

func notify_warning(message: String):
	notify(message, NotificationType.WARNING, 3.0)

func notify_success(message: String):
	notify(message, NotificationType.SUCCESS, 2.5)

func _display_notification(data: Dictionary):
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(300, 40)
	panel.modulate.a = 0
	panel.position.x = 50
	
	var style = StyleBoxFlat.new()
	var color = TYPE_COLORS.get(data["type"], Color(0.5, 0.5, 0.5))
	style.bg_color = Color(color.r * 0.2, color.g * 0.2, color.b * 0.2, 0.9)
	style.border_color = color
	style.border_width_left = 4
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	panel.add_theme_stylebox_override("panel", style)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	panel.add_child(hbox)
	
	var icon = Label.new()
	icon.text = TYPE_ICONS.get(data["type"], "•")
	icon.add_theme_font_size_override("font_size", 18)
	hbox.add_child(icon)
	
	var label = Label.new()
	label.text = data["message"]
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(label)
	
	container.add_child(panel)
	current_notifications.append(panel)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "modulate:a", 1.0, SLIDE_DURATION)
	tween.tween_property(panel, "position:x", 0.0, SLIDE_DURATION).set_ease(Tween.EASE_OUT)
	
	await get_tree().create_timer(data["duration"]).timeout
	
	_remove_notification(panel)

func _remove_notification(panel: PanelContainer):
	if not is_instance_valid(panel):
		return
	
	current_notifications.erase(panel)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "modulate:a", 0.0, SLIDE_DURATION)
	tween.tween_property(panel, "position:x", 50.0, SLIDE_DURATION)
	tween.set_parallel(false)
	tween.tween_callback(panel.queue_free)

func clear_all():
	for panel in current_notifications:
		if is_instance_valid(panel):
			panel.queue_free()
	current_notifications.clear()
	notification_queue.clear()
