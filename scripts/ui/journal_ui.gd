extends Control

@onready var quest_list = $QuestList
@onready var quest_details = $QuestDetails
@onready var objectives_list = $ObjectivesList
@onready var rewards_panel = $RewardsPanel

var selected_quest := ""
var entries := []

func _ready():
	_refresh_quests()
	
	if quest_list:
		quest_list.connect("item_selected", Callable(self, "_on_quest_selected"))
	
	var quest_sys = get_node_or_null("/root/QuestSystem")
	if quest_sys:
		quest_sys.connect("quest_started", Callable(self, "_on_quest_changed"))
		quest_sys.connect("quest_completed", Callable(self, "_on_quest_changed"))
		quest_sys.connect("objective_updated", Callable(self, "_on_objective_updated"))

func add_entry(text: String):
	entries.append(text)
	_refresh_entries()

func _refresh_entries():
	var scroll_label = get_node_or_null("Scroll/Label")
	if scroll_label:
		scroll_label.text = ""
		for e in entries:
			scroll_label.text += "- " + e + "\n"

func _on_quest_changed(_quest_id):
	_refresh_quests()

func _on_objective_updated(_quest_id, _obj_id, _current, _target):
	if selected_quest == _quest_id:
		_show_quest_details(selected_quest)

func _refresh_quests():
	if not quest_list:
		return
	quest_list.clear()
	
	var quest_sys = get_node_or_null("/root/QuestSystem")
	if not quest_sys:
		return
	
	var active = quest_sys.get_active_quests(1)
	
	for quest in active:
		var progress = _calculate_progress(quest)
		var text = "%s (%d%%)" % [quest.name, progress]
		quest_list.add_item(text)
		quest_list.set_item_metadata(quest_list.get_item_count() - 1, quest.id)

func _calculate_progress(quest: Dictionary) -> int:
	var total := 0
	var completed := 0
	
	for obj in quest.objectives:
		total += obj.amount
		completed += obj.current
	
	if total == 0:
		return 100
	return int(float(completed) / float(total) * 100)

func _on_quest_selected(index: int):
	selected_quest = quest_list.get_item_metadata(index)
	_show_quest_details(selected_quest)

func _show_quest_details(quest_id: String):
	_clear_details()
	
	var quest_sys = get_node_or_null("/root/QuestSystem")
	if not quest_sys:
		return
	
	var quest = quest_sys.get_quest_progress(1, quest_id)
	if quest.is_empty():
		return
	
	if quest_details:
		var title = Label.new()
		title.text = quest.name
		title.add_theme_font_size_override("font_size", 20)
		quest_details.add_child(title)
		
		var desc = Label.new()
		desc.text = quest.description
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD
		quest_details.add_child(desc)
	
	if objectives_list:
		var obj_title = Label.new()
		obj_title.text = "Цели:"
		obj_title.add_theme_color_override("font_color", Color(0.8, 0.8, 0.2))
		objectives_list.add_child(obj_title)
		
		for obj in quest.objectives:
			var obj_label = Label.new()
			var status = "✓" if obj.current >= obj.amount else "○"
			obj_label.text = "%s %s (%d/%d)" % [status, _get_objective_text(obj), obj.current, obj.amount]
			
			if obj.current >= obj.amount:
				obj_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
			else:
				obj_label.add_theme_color_override("font_color", Color(1, 1, 1))
			
			objectives_list.add_child(obj_label)
	
	if rewards_panel:
		var rewards = quest.get("rewards", {})
		
		var reward_title = Label.new()
		reward_title.text = "Награды:"
		reward_title.add_theme_color_override("font_color", Color(1, 0.8, 0))
		rewards_panel.add_child(reward_title)
		
		if rewards.has("xp"):
			var xp_label = Label.new()
			xp_label.text = "  +%d опыта" % rewards.xp
			rewards_panel.add_child(xp_label)
		
		if rewards.has("items"):
			for item_id in rewards.items.keys():
				var item_label = Label.new()
				item_label.text = "  %s x%d" % [_get_item_name(item_id), rewards.items[item_id]]
				rewards_panel.add_child(item_label)

func _clear_details():
	if quest_details:
		for child in quest_details.get_children():
			child.queue_free()
	if objectives_list:
		for child in objectives_list.get_children():
			child.queue_free()
	if rewards_panel:
		for child in rewards_panel.get_children():
			child.queue_free()

func _get_objective_text(obj: Dictionary) -> String:
	match obj.type:
		"gather":
			return "Собрать %s" % _get_item_name(obj.target)
		"craft":
			return "Создать %s" % _get_item_name(obj.target)
		"build":
			if obj.target == "any":
				return "Построить любые структуры"
			return "Построить %s" % _get_item_name(obj.target)
		"kill":
			return "Уничтожить %s" % _get_mob_name(obj.target)
		"visit_biome":
			return "Посетить %s" % _get_biome_name(obj.target)
		"settlement_population":
			return "Население поселения"
		_:
			return obj.id

func _get_item_name(item_id: String) -> String:
	var names := {
		"wood": "Дерево",
		"stone": "Камень",
		"stone_axe": "Каменный топор",
		"stone_pickaxe": "Каменная кирка",
		"wooden_foundation": "Деревянный фундамент",
		"wooden_wall": "Деревянная стена",
		"bandage": "Бинт",
		"torch": "Факел",
		"cooked_meat": "Жареное мясо",
		"iron_ore": "Железная руда",
		"iron_ingot": "Железный слиток",
		"workbench_2": "Продвинутый верстак"
	}
	return names.get(item_id, item_id)

func _get_mob_name(mob_id: String) -> String:
	var names := {
		"mob_basic": "Враждебные существа"
	}
	return names.get(mob_id, mob_id)

func _get_biome_name(biome_id: String) -> String:
	var names := {
		"forest": "Лес",
		"desert": "Пустыня",
		"tundra": "Тундра",
		"plains": "Равнины"
	}
	return names.get(biome_id, biome_id)
