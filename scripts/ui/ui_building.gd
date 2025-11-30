extends Control

@onready var build_list = $BuildList
@onready var info_panel = $InfoPanel
@onready var build_btn = $BuildBtn
@onready var rotate_btn = $RotateBtn
@onready var cancel_btn = $CancelBtn

var selected_building := ""
var is_building_mode := false
var current_category := "all"
var player_id := 1

var category_names := {
	"all": {"ru": "Все", "en": "All"},
	"foundation": {"ru": "Фундамент", "en": "Foundations"},
	"wall": {"ru": "Стены", "en": "Walls"},
	"floor": {"ru": "Полы", "en": "Floors"},
	"roof": {"ru": "Крыши", "en": "Roofs"},
	"door": {"ru": "Двери", "en": "Doors"},
	"furniture": {"ru": "Мебель", "en": "Furniture"},
	"crafting": {"ru": "Крафт", "en": "Crafting"},
	"storage": {"ru": "Хранение", "en": "Storage"}
}

var building_categories := {
	"wooden_foundation": "foundation",
	"stone_foundation": "foundation",
	"wooden_wall": "wall",
	"stone_wall": "wall",
	"metal_wall": "wall",
	"wooden_floor": "floor",
	"stone_floor": "floor",
	"wooden_roof": "roof",
	"wooden_door": "door",
	"wooden_doorframe": "door",
	"wooden_window": "wall",
	"metal_door": "door",
	"armored_door": "door",
	"wooden_stairs": "floor",
	"tool_cupboard": "storage",
	"storage_box": "storage",
	"large_storage": "storage",
	"workbench_1": "crafting",
	"workbench_2": "crafting",
	"workbench_3": "crafting",
	"furnace": "crafting",
	"campfire": "crafting",
	"sleeping_bag": "furniture",
	"bed": "furniture"
}

var localized_names := {
	"wooden_foundation": {"ru": "Деревянный фундамент", "en": "Wooden Foundation"},
	"wooden_wall": {"ru": "Деревянная стена", "en": "Wooden Wall"},
	"wooden_floor": {"ru": "Деревянный пол", "en": "Wooden Floor"},
	"wooden_door": {"ru": "Деревянная дверь", "en": "Wooden Door"},
	"wooden_doorframe": {"ru": "Деревянная рама двери", "en": "Wooden Door Frame"},
	"wooden_window": {"ru": "Деревянное окно", "en": "Wooden Window"},
	"wooden_roof": {"ru": "Деревянная крыша", "en": "Wooden Roof"},
	"wooden_stairs": {"ru": "Деревянная лестница", "en": "Wooden Stairs"},
	"stone_foundation": {"ru": "Каменный фундамент", "en": "Stone Foundation"},
	"stone_wall": {"ru": "Каменная стена", "en": "Stone Wall"},
	"stone_floor": {"ru": "Каменный пол", "en": "Stone Floor"},
	"metal_door": {"ru": "Металлическая дверь", "en": "Metal Door"},
	"armored_door": {"ru": "Бронированная дверь", "en": "Armored Door"},
	"metal_wall": {"ru": "Металлическая стена", "en": "Metal Wall"},
	"tool_cupboard": {"ru": "Шкаф для инструментов", "en": "Tool Cupboard"},
	"storage_box": {"ru": "Ящик хранения", "en": "Storage Box"},
	"large_storage": {"ru": "Большой ящик", "en": "Large Storage"},
	"workbench_1": {"ru": "Верстак уровень 1", "en": "Workbench Level 1"},
	"workbench_2": {"ru": "Верстак уровень 2", "en": "Workbench Level 2"},
	"workbench_3": {"ru": "Верстак уровень 3", "en": "Workbench Level 3"},
	"furnace": {"ru": "Печь", "en": "Furnace"},
	"campfire": {"ru": "Костёр", "en": "Campfire"},
	"sleeping_bag": {"ru": "Спальный мешок", "en": "Sleeping Bag"},
	"bed": {"ru": "Кровать", "en": "Bed"}
}

var material_names := {
	"wood": {"ru": "Дерево", "en": "Wood"},
	"stone": {"ru": "Камень", "en": "Stone"},
	"iron_ingot": {"ru": "Железный слиток", "en": "Iron Ingot"},
	"steel_ingot": {"ru": "Стальной слиток", "en": "Steel Ingot"},
	"plant_fiber": {"ru": "Растительное волокно", "en": "Plant Fiber"},
	"hide": {"ru": "Шкура", "en": "Hide"}
}

func _ready():
	_create_category_buttons()
	_populate_build_list()
	
	if build_list:
		build_list.connect("item_selected", Callable(self, "_on_building_selected"))
	if build_btn:
		build_btn.connect("pressed", Callable(self, "_on_build_pressed"))
	if rotate_btn:
		rotate_btn.connect("pressed", Callable(self, "_on_rotate_pressed"))
	if cancel_btn:
		cancel_btn.connect("pressed", Callable(self, "_on_cancel_pressed"))

func _create_category_buttons():
	var panel = get_node_or_null("Panel")
	if not panel:
		return
	
	var existing_container = panel.get_node_or_null("CategoryContainer")
	if existing_container:
		existing_container.queue_free()
	
	var container = HBoxContainer.new()
	container.name = "CategoryContainer"
	container.set_anchors_preset(Control.PRESET_TOP_WIDE)
	container.offset_top = 35
	container.offset_bottom = 65
	container.offset_left = 10
	container.offset_right = -10
	
	var lang = _get_current_language()
	
	for cat_id in ["all", "foundation", "wall", "door", "floor", "crafting", "storage"]:
		var btn = Button.new()
		btn.text = category_names[cat_id].get(lang, cat_id)
		btn.custom_minimum_size = Vector2(80, 25)
		btn.pressed.connect(_on_category_selected.bind(cat_id))
		container.add_child(btn)
	
	panel.add_child(container)

func _get_current_language() -> String:
	var loc = get_node_or_null("/root/LocalizationService")
	if loc and loc.has_method("get_current_language"):
		return loc.get_current_language()
	return "ru"

func _populate_build_list():
	if not build_list:
		return
	build_list.clear()
	
	var build_sys = get_node_or_null("/root/BuildSystem")
	var blueprint_book = get_node_or_null("/root/BlueprintBook")
	
	if not build_sys:
		_load_fallback_buildings()
		return
	
	var lang = _get_current_language()
	
	for part_id in build_sys.building_parts.keys():
		if current_category != "all":
			var part_category = building_categories.get(part_id, "misc")
			if part_category != current_category:
				continue
		
		var is_unlocked = true
		if blueprint_book:
			is_unlocked = blueprint_book.is_blueprint_unlocked(player_id, part_id)
		
		var display_name = _get_localized_name(part_id)
		
		if not is_unlocked:
			display_name = "[Заблокировано] " + display_name if lang == "ru" else "[Locked] " + display_name
		
		build_list.add_item(display_name)
		build_list.set_item_metadata(build_list.get_item_count() - 1, part_id)
		
		if not is_unlocked:
			build_list.set_item_custom_fg_color(build_list.get_item_count() - 1, Color(0.5, 0.5, 0.5))

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
	var lang = _get_current_language()
	if localized_names.has(part_id):
		return localized_names[part_id].get(lang, part_id)
	return part_id.replace("_", " ").capitalize()

func _on_category_selected(category: String):
	current_category = category
	_populate_build_list()

func _on_building_selected(index: int):
	selected_building = build_list.get_item_metadata(index)
	_show_building_info(selected_building)

func _show_building_info(part_id: String):
	for child in info_panel.get_children():
		child.queue_free()
	
	var build_sys = get_node_or_null("/root/BuildSystem")
	var inv = get_node_or_null("/root/Inventory")
	var blueprint_book = get_node_or_null("/root/BlueprintBook")
	
	if not build_sys:
		return
	
	var part_data = build_sys.building_parts.get(part_id, {})
	var cost = part_data.get("cost", {})
	var lang = _get_current_language()
	
	var title = Label.new()
	title.text = _get_localized_name(part_id)
	title.add_theme_font_size_override("font_size", 18)
	info_panel.add_child(title)
	
	var is_unlocked = true
	if blueprint_book:
		is_unlocked = blueprint_book.is_blueprint_unlocked(player_id, part_id)
	
	if not is_unlocked:
		var lock_label = Label.new()
		lock_label.text = "Требуется чертёж" if lang == "ru" else "Blueprint required"
		lock_label.add_theme_color_override("font_color", Color(0.8, 0.4, 0.2))
		info_panel.add_child(lock_label)
		
		if blueprint_book:
			var bp = blueprint_book.get_blueprint(part_id)
			if bp:
				var source = bp.get("unlock_source", "")
				var source_label = Label.new()
				if source == "workbench_1":
					source_label.text = "Открывается на Верстаке 1" if lang == "ru" else "Unlocked at Workbench 1"
				elif source == "workbench_2":
					source_label.text = "Открывается на Верстаке 2" if lang == "ru" else "Unlocked at Workbench 2"
				elif source == "workbench_3":
					source_label.text = "Открывается на Верстаке 3" if lang == "ru" else "Unlocked at Workbench 3"
				else:
					source_label.text = "Источник: " + source if lang == "ru" else "Source: " + source
				source_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
				info_panel.add_child(source_label)
		return
	
	var health_label = Label.new()
	health_label.text = ("Прочность: %d" if lang == "ru" else "Durability: %d") % part_data.get("health", 100)
	info_panel.add_child(health_label)
	
	var material_label = Label.new()
	var mat_type = part_data.get("material", "wood")
	material_label.text = ("Материал: %s" if lang == "ru" else "Material: %s") % _get_material_display_name(mat_type)
	info_panel.add_child(material_label)
	
	var cost_title = Label.new()
	cost_title.text = "Стоимость:" if lang == "ru" else "Cost:"
	cost_title.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	info_panel.add_child(cost_title)
	
	var can_build = true
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
			can_build = false
		
		info_panel.add_child(label)
	
	if build_btn:
		build_btn.disabled = not can_build

func _get_material_display_name(mat_type: String) -> String:
	var lang = _get_current_language()
	var display := {
		"wood": {"ru": "Дерево", "en": "Wood"},
		"stone": {"ru": "Камень", "en": "Stone"},
		"metal": {"ru": "Металл", "en": "Metal"},
		"iron": {"ru": "Железо", "en": "Iron"},
		"steel": {"ru": "Сталь", "en": "Steel"},
		"cloth": {"ru": "Ткань", "en": "Cloth"}
	}
	return display.get(mat_type, {}).get(lang, mat_type)

func _get_material_name(mat_id: String) -> String:
	var lang = _get_current_language()
	if material_names.has(mat_id):
		return material_names[mat_id].get(lang, mat_id)
	return mat_id.replace("_", " ").capitalize()

func _on_build_pressed():
	if selected_building == "":
		return
	
	var blueprint_book = get_node_or_null("/root/BlueprintBook")
	if blueprint_book and not blueprint_book.is_blueprint_unlocked(player_id, selected_building):
		var notification = get_node_or_null("/root/NotificationSystem")
		if notification and notification.has_method("show_notification"):
			var lang = _get_current_language()
			var msg = "Требуется чертёж!" if lang == "ru" else "Blueprint required!"
			notification.show_notification(msg, "warning")
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
	var lang = _get_current_language()
	if rotate_btn:
		rotate_btn.visible = is_building_mode
	if cancel_btn:
		cancel_btn.visible = is_building_mode
	if build_btn:
		build_btn.text = ("Разместить" if lang == "ru" else "Place") if is_building_mode else ("Строить" if lang == "ru" else "Build")

func set_player_id(pid: int):
	player_id = pid
	_populate_build_list()
