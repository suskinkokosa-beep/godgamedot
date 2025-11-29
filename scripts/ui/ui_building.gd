extends Control

@onready var build_list = $BuildList
@onready var info_panel = $InfoPanel
@onready var build_btn = $BuildBtn
@onready var rotate_btn = $RotateBtn
@onready var cancel_btn = $CancelBtn

var selected_building := ""
var is_building_mode := false

func _ready():
	_populate_build_list()
	
	if build_list:
		build_list.connect("item_selected", Callable(self, "_on_building_selected"))
	if build_btn:
		build_btn.connect("pressed", Callable(self, "_on_build_pressed"))
	if rotate_btn:
		rotate_btn.connect("pressed", Callable(self, "_on_rotate_pressed"))
	if cancel_btn:
		cancel_btn.connect("pressed", Callable(self, "_on_cancel_pressed"))

func _populate_build_list():
	if not build_list:
		return
	build_list.clear()
	
	var build_sys = get_node_or_null("/root/BuildSystem")
	if not build_sys:
		_load_fallback_buildings()
		return
	
	for part_id in build_sys.building_parts.keys():
		build_list.add_item(_get_localized_name(part_id))
		build_list.set_item_metadata(build_list.get_item_count() - 1, part_id)

func _load_fallback_buildings():
	var fallback := {
		"wooden_foundation": "Деревянный фундамент",
		"wooden_wall": "Деревянная стена",
		"wooden_floor": "Деревянный пол",
		"wooden_door": "Деревянная дверь"
	}
	for id in fallback.keys():
		build_list.add_item(fallback[id])
		build_list.set_item_metadata(build_list.get_item_count() - 1, id)

func _get_localized_name(part_id: String) -> String:
	var names := {
		"wooden_foundation": "Деревянный фундамент",
		"wooden_wall": "Деревянная стена",
		"wooden_floor": "Деревянный пол",
		"wooden_door": "Деревянная дверь",
		"stone_foundation": "Каменный фундамент",
		"stone_wall": "Каменная стена",
		"metal_door": "Металлическая дверь"
	}
	return names.get(part_id, part_id)

func _on_building_selected(index: int):
	selected_building = build_list.get_item_metadata(index)
	_show_building_info(selected_building)

func _show_building_info(part_id: String):
	for child in info_panel.get_children():
		child.queue_free()
	
	var build_sys = get_node_or_null("/root/BuildSystem")
	var inv = get_node_or_null("/root/Inventory")
	
	if not build_sys:
		return
	
	var part_data = build_sys.building_parts.get(part_id, {})
	var cost = part_data.get("cost", {})
	
	var title = Label.new()
	title.text = _get_localized_name(part_id)
	title.add_theme_font_size_override("font_size", 18)
	info_panel.add_child(title)
	
	var health_label = Label.new()
	health_label.text = "Прочность: %d" % part_data.get("health", 100)
	info_panel.add_child(health_label)
	
	var cost_title = Label.new()
	cost_title.text = "Стоимость:"
	cost_title.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	info_panel.add_child(cost_title)
	
	for mat_id in cost.keys():
		var needed = cost[mat_id]
		var have = 0
		if inv:
			have = inv.get_item_count(mat_id)
		
		var label = Label.new()
		label.text = "  %s: %d / %d" % [_get_material_name(mat_id), have, needed]
		
		if have >= needed:
			label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
		else:
			label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))
		
		info_panel.add_child(label)

func _get_material_name(mat_id: String) -> String:
	var names := {
		"wood": "Дерево",
		"stone": "Камень",
		"iron_ingot": "Железный слиток"
	}
	return names.get(mat_id, mat_id)

func _on_build_pressed():
	if selected_building == "":
		return
	
	var build_sys = get_node_or_null("/root/BuildSystem")
	if not build_sys:
		return
	
	if build_sys.start_build(selected_building):
		is_building_mode = true
		_update_buttons()
		hide()

func _on_rotate_pressed():
	var build_sys = get_node_or_null("/root/BuildSystem")
	if build_sys:
		build_sys.rotate_preview()

func _on_cancel_pressed():
	var build_sys = get_node_or_null("/root/BuildSystem")
	if build_sys:
		build_sys.cancel_build()
	is_building_mode = false
	_update_buttons()

func _update_buttons():
	if rotate_btn:
		rotate_btn.visible = is_building_mode
	if cancel_btn:
		cancel_btn.visible = is_building_mode
	if build_btn:
		build_btn.text = "Разместить" if is_building_mode else "Строить"
