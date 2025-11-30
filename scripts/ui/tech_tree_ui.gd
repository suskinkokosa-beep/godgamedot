extends Control

signal tech_selected(tech_id: String)

var tech_tree_system = null
var player_id: int = 0

var category_colors := {
	0: Color(0.2, 0.6, 0.2),
	1: Color(0.5, 0.4, 0.3),
	2: Color(0.6, 0.4, 0.2),
	3: Color(0.7, 0.2, 0.2),
	4: Color(0.4, 0.4, 0.6),
	5: Color(0.3, 0.6, 0.3),
	6: Color(0.6, 0.2, 0.6),
	7: Color(0.5, 0.5, 0.5),
	8: Color(0.5, 0.2, 0.7),
	9: Color(0.5, 0.3, 0.2),
	10: Color(0.7, 0.6, 0.2),
	11: Color(0.3, 0.3, 0.5)
}

var category_names := {
	0: "Выживание",
	1: "Строительство",
	2: "Металлургия",
	3: "Оружие",
	4: "Броня",
	5: "Сельское хозяйство",
	6: "Медицина",
	7: "Ремесло",
	8: "Магия",
	9: "Осада",
	10: "Торговля",
	11: "Управление"
}

var main_panel: PanelContainer
var tech_grid: GridContainer
var info_panel: PanelContainer
var category_tabs: TabContainer

func _ready():
	visible = false
	_create_ui()
	tech_tree_system = get_node_or_null("/root/TechTree")
	
	if tech_tree_system:
		tech_tree_system.tech_researched.connect(_on_tech_researched)
		tech_tree_system.tech_progress.connect(_on_tech_progress)

func _create_ui():
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0, 0, 0, 0.85)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 50)
	margin.add_theme_constant_override("margin_right", 50)
	margin.add_theme_constant_override("margin_top", 50)
	margin.add_theme_constant_override("margin_bottom", 50)
	add_child(margin)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	margin.add_child(hbox)
	
	var left_panel = VBoxContainer.new()
	left_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_panel.size_flags_stretch_ratio = 2.0
	hbox.add_child(left_panel)
	
	var title_label = Label.new()
	title_label.text = "ТЕХНОЛОГИЧЕСКОЕ ДЕРЕВО"
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left_panel.add_child(title_label)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	left_panel.add_child(spacer)
	
	category_tabs = TabContainer.new()
	category_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_panel.add_child(category_tabs)
	
	_create_category_tabs()
	
	var close_btn = Button.new()
	close_btn.text = "Закрыть [ESC]"
	close_btn.custom_minimum_size = Vector2(150, 40)
	close_btn.pressed.connect(_close_ui)
	left_panel.add_child(close_btn)
	
	info_panel = _create_info_panel()
	info_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_panel.size_flags_stretch_ratio = 1.0
	hbox.add_child(info_panel)

func _create_category_tabs():
	for cat_id in category_names:
		var scroll = ScrollContainer.new()
		scroll.name = category_names[cat_id]
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		
		var vbox = VBoxContainer.new()
		vbox.name = "TechList"
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.add_theme_constant_override("separation", 8)
		scroll.add_child(vbox)
		
		category_tabs.add_child(scroll)

func _create_info_panel() -> PanelContainer:
	var panel = PanelContainer.new()
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.1, 0.08, 0.95)
	style.border_color = Color(0.5, 0.4, 0.3)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(15)
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.name = "InfoContent"
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)
	
	var title = Label.new()
	title.name = "TechName"
	title.text = "Выберите технологию"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1, 0.9, 0.6))
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(title)
	
	var desc = RichTextLabel.new()
	desc.name = "TechDesc"
	desc.bbcode_enabled = true
	desc.fit_content = true
	desc.custom_minimum_size = Vector2(0, 100)
	desc.add_theme_font_size_override("normal_font_size", 16)
	vbox.add_child(desc)
	
	var prereq_label = Label.new()
	prereq_label.name = "Prerequisites"
	prereq_label.text = ""
	prereq_label.add_theme_color_override("font_color", Color(0.8, 0.7, 0.5))
	prereq_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(prereq_label)
	
	var cost_label = Label.new()
	cost_label.name = "Cost"
	cost_label.text = ""
	cost_label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.6))
	cost_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(cost_label)
	
	var time_label = Label.new()
	time_label.name = "ResearchTime"
	time_label.text = ""
	time_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.9))
	vbox.add_child(time_label)
	
	var unlocks_label = Label.new()
	unlocks_label.name = "Unlocks"
	unlocks_label.text = ""
	unlocks_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
	unlocks_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(unlocks_label)
	
	var progress_bar = ProgressBar.new()
	progress_bar.name = "ProgressBar"
	progress_bar.custom_minimum_size = Vector2(0, 25)
	progress_bar.visible = false
	vbox.add_child(progress_bar)
	
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)
	
	var research_btn = Button.new()
	research_btn.name = "ResearchButton"
	research_btn.text = "Исследовать"
	research_btn.custom_minimum_size = Vector2(0, 45)
	research_btn.pressed.connect(_on_research_pressed)
	vbox.add_child(research_btn)
	
	return panel

func refresh_tech_list():
	if not tech_tree_system:
		return
	
	for i in range(category_tabs.get_tab_count()):
		var scroll = category_tabs.get_child(i)
		var vbox = scroll.get_node("TechList")
		
		for child in vbox.get_children():
			child.queue_free()
	
	for tech_id in tech_tree_system.technologies:
		var tech = tech_tree_system.technologies[tech_id]
		var cat_id = tech.category
		
		if cat_id >= category_tabs.get_tab_count():
			continue
		
		var scroll = category_tabs.get_child(cat_id)
		var vbox = scroll.get_node("TechList")
		
		var btn = _create_tech_button(tech_id, tech)
		vbox.add_child(btn)

func _create_tech_button(tech_id: String, tech: Dictionary) -> Button:
	var btn = Button.new()
	btn.name = tech_id
	btn.text = tech.name
	btn.custom_minimum_size = Vector2(0, 40)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	var is_researched = tech_tree_system.is_researched(player_id, tech_id)
	var can_research = tech_tree_system._check_prerequisites(player_id, tech_id)
	
	var style = StyleBoxFlat.new()
	style.set_content_margin_all(10)
	style.set_corner_radius_all(4)
	
	if is_researched:
		style.bg_color = Color(0.2, 0.4, 0.2)
		style.border_color = Color(0.3, 0.6, 0.3)
		btn.text = "[+] " + tech.name
	elif can_research:
		style.bg_color = Color(0.3, 0.25, 0.2)
		style.border_color = Color(0.6, 0.5, 0.3)
	else:
		style.bg_color = Color(0.2, 0.2, 0.2)
		style.border_color = Color(0.4, 0.4, 0.4)
		btn.modulate = Color(0.6, 0.6, 0.6)
	
	style.set_border_width_all(1)
	btn.add_theme_stylebox_override("normal", style)
	
	btn.pressed.connect(_on_tech_button_pressed.bind(tech_id))
	
	return btn

var selected_tech_id: String = ""

func _on_tech_button_pressed(tech_id: String):
	selected_tech_id = tech_id
	_update_info_panel(tech_id)
	emit_signal("tech_selected", tech_id)

func _update_info_panel(tech_id: String):
	if not tech_tree_system or not tech_tree_system.technologies.has(tech_id):
		return
	
	var tech = tech_tree_system.technologies[tech_id]
	var content = info_panel.get_node("InfoContent")
	
	content.get_node("TechName").text = tech.name
	content.get_node("TechDesc").text = tech.description
	
	var prereq_text = ""
	if tech.prerequisites.size() > 0:
		prereq_text = "Требования: "
		var prereq_names = []
		for prereq_id in tech.prerequisites:
			if tech_tree_system.technologies.has(prereq_id):
				prereq_names.append(tech_tree_system.technologies[prereq_id].name)
		prereq_text += ", ".join(prereq_names)
	content.get_node("Prerequisites").text = prereq_text
	
	var cost_text = ""
	if tech.cost.size() > 0:
		cost_text = "Стоимость: "
		var cost_parts = []
		for resource in tech.cost:
			cost_parts.append("%s x%d" % [resource, tech.cost[resource]])
		cost_text += ", ".join(cost_parts)
	content.get_node("Cost").text = cost_text
	
	content.get_node("ResearchTime").text = "Время: %d сек" % int(tech.research_time)
	
	var unlocks_text = ""
	if tech.unlocks.size() > 0:
		unlocks_text = "Открывает: " + ", ".join(tech.unlocks)
	content.get_node("Unlocks").text = unlocks_text
	
	var research_btn = content.get_node("ResearchButton")
	var progress_bar = content.get_node("ProgressBar")
	
	var is_researched = tech_tree_system.is_researched(player_id, tech_id)
	var is_researching = tech_tree_system.active_research.has(player_id) and \
						 tech_tree_system.active_research[player_id].tech_id == tech_id
	var can_research = tech_tree_system._check_prerequisites(player_id, tech_id)
	
	if is_researched:
		research_btn.text = "Изучено"
		research_btn.disabled = true
		progress_bar.visible = false
	elif is_researching:
		research_btn.text = "Отменить"
		research_btn.disabled = false
		progress_bar.visible = true
		var progress = tech_tree_system.active_research[player_id].progress
		var total = tech_tree_system.active_research[player_id].total_time
		progress_bar.value = (progress / total) * 100
	elif can_research:
		research_btn.text = "Исследовать"
		research_btn.disabled = false
		progress_bar.visible = false
	else:
		research_btn.text = "Недоступно"
		research_btn.disabled = true
		progress_bar.visible = false

func _on_research_pressed():
	if not tech_tree_system or selected_tech_id.is_empty():
		return
	
	var is_researching = tech_tree_system.active_research.has(player_id) and \
						 tech_tree_system.active_research[player_id].tech_id == selected_tech_id
	
	if is_researching:
		tech_tree_system.cancel_research(player_id)
	else:
		tech_tree_system.start_research(player_id, selected_tech_id)
	
	refresh_tech_list()
	_update_info_panel(selected_tech_id)

func _on_tech_researched(tech_id: String, pid: int):
	if pid == player_id:
		refresh_tech_list()
		if selected_tech_id == tech_id:
			_update_info_panel(tech_id)
		
		var notif = get_node_or_null("/root/NotificationSystem")
		if notif and tech_tree_system.technologies.has(tech_id):
			var tech_name = tech_tree_system.technologies[tech_id].name
			notif.show_notification("Технология изучена: " + tech_name, "success")

func _on_tech_progress(tech_id: String, progress: float, total: float):
	if selected_tech_id == tech_id:
		var content = info_panel.get_node("InfoContent")
		var progress_bar = content.get_node("ProgressBar")
		progress_bar.value = (progress / total) * 100

func show_ui():
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	refresh_tech_list()

func _close_ui():
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if visible and event.is_action_pressed("ui_cancel"):
		_close_ui()
		get_viewport().set_input_as_handled()
