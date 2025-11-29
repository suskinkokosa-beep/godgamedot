extends Control

@onready var recipe_list = $RecipeList
@onready var req_panel = $ReqPanel
@onready var craft_btn = $CraftBtn
@onready var category_tabs = $CategoryTabs
@onready var workbench_label = $WorkbenchLabel

var current_category := "all"
var current_workbench_tier := 0
var selected_recipe := ""

func _ready():
        _setup_ui()
        _refresh_recipes()
        
        if recipe_list:
                recipe_list.connect("item_selected", Callable(self, "_on_recipe_selected"))
        if craft_btn:
                craft_btn.connect("pressed", Callable(self, "_on_craft_pressed"))
        if category_tabs:
                category_tabs.connect("tab_changed", Callable(self, "_on_category_changed"))

func _setup_ui():
        if not category_tabs:
                return
        category_tabs.clear_tabs()
        category_tabs.add_tab("Все")
        category_tabs.add_tab("Инструменты")
        category_tabs.add_tab("Оружие")
        category_tabs.add_tab("Броня")
        category_tabs.add_tab("Еда")
        category_tabs.add_tab("Постройки")

func set_workbench_tier(tier: int):
        current_workbench_tier = tier
        if workbench_label:
                var tier_names = ["Руки", "Базовый верстак", "Продвинутый верстак", "Мастерский верстак"]
                workbench_label.text = tier_names[clamp(tier, 0, 3)]
        _refresh_recipes()

func _refresh_recipes():
        if not recipe_list:
                return
        recipe_list.clear()
        
        var craft = get_node_or_null("/root/CraftSystem")
        if not craft:
                _load_fallback_recipes()
                return
        
        var recipes = craft.get_all_recipes_for_tier(current_workbench_tier)
        for recipe_id in recipes.keys():
                var recipe = recipes[recipe_id]
                if current_category != "all" and recipe.get("category", "") != current_category:
                        continue
                recipe_list.add_item(_get_localized_name(recipe_id))
                recipe_list.set_item_metadata(recipe_list.get_item_count() - 1, recipe_id)

func _load_fallback_recipes():
        var fallback := {
                "axe": "Топор",
                "pickaxe": "Кирка",
                "campfire": "Костёр",
                "wooden_wall": "Деревянная стена"
        }
        for id in fallback.keys():
                recipe_list.add_item(fallback[id])
                recipe_list.set_item_metadata(recipe_list.get_item_count() - 1, id)

func _get_localized_name(recipe_id: String) -> String:
        var names := {
                "axe": "Топор",
                "pickaxe": "Кирка",
                "shovel": "Лопата",
                "hammer": "Молоток",
                "wooden_sword": "Деревянный меч",
                "stone_sword": "Каменный меч",
                "iron_sword": "Железный меч",
                "leather_armor": "Кожаная броня",
                "iron_armor": "Железная броня",
                "campfire": "Костёр",
                "workbench_1": "Базовый верстак",
                "workbench_2": "Продвинутый верстак",
                "workbench_3": "Мастерский верстак",
                "cooked_meat": "Жареное мясо",
                "bread": "Хлеб",
                "bandage": "Бинт",
                "wooden_foundation": "Деревянный фундамент",
                "wooden_wall": "Деревянная стена",
                "wooden_floor": "Деревянный пол",
                "wooden_door": "Деревянная дверь"
        }
        return names.get(recipe_id, recipe_id)

func _on_category_changed(tab: int):
        var categories = ["all", "tools", "weapons", "armor", "food", "buildings"]
        current_category = categories[clamp(tab, 0, categories.size() - 1)]
        _refresh_recipes()

func _on_recipe_selected(index: int):
        selected_recipe = recipe_list.get_item_metadata(index)
        _show_requirements(selected_recipe)

func _show_requirements(recipe_id: String):
        for child in req_panel.get_children():
                child.queue_free()
        
        var craft = get_node_or_null("/root/CraftSystem")
        var inv = get_node_or_null("/root/Inventory")
        
        if not craft:
                return
        
        var recipe = craft.get_recipe(recipe_id)
        var materials = recipe.get("inputs", {})
        
        for mat_id in materials.keys():
                var needed = materials[mat_id]
                var have = 0
                if inv:
                        have = inv.get_item_count(mat_id)
                
                var label = Label.new()
                var mat_name = _get_material_name(mat_id)
                label.text = "%s: %d / %d" % [mat_name, have, needed]
                
                if have >= needed:
                        label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
                else:
                        label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))
                
                req_panel.add_child(label)
        
        var result_label = Label.new()
        result_label.text = "= %s x%d" % [_get_localized_name(recipe.get("result", recipe_id)), recipe.get("amount", 1)]
        result_label.add_theme_color_override("font_color", Color(1, 0.8, 0))
        req_panel.add_child(result_label)

func _get_material_name(mat_id: String) -> String:
        var names := {
                "wood": "Дерево",
                "stone": "Камень",
                "iron_ore": "Железная руда",
                "iron_ingot": "Железный слиток",
                "fiber": "Волокно",
                "leather": "Кожа",
                "cloth": "Ткань",
                "raw_meat": "Сырое мясо",
                "flour": "Мука",
                "herb": "Трава"
        }
        return names.get(mat_id, mat_id)

func _on_craft_pressed():
        if selected_recipe == "":
                return
        
        var craft = get_node_or_null("/root/CraftSystem")
        var inv = get_node_or_null("/root/Inventory")
        var prog = get_node_or_null("/root/PlayerProgression")
        
        if not craft or not inv:
                print("Системы крафта или инвентаря недоступны")
                return
        
        var player_id = 1
        var player_nodes = get_tree().get_nodes_in_group("players")
        if player_nodes.size() > 0:
                var player = player_nodes[0]
                if player.get("net_id"):
                        player_id = player.net_id
        
        var result = craft.craft_item(selected_recipe, inv, current_workbench_tier)
        
        if result.success:
                _show_craft_success(selected_recipe)
                _refresh_recipes()
                _show_requirements(selected_recipe)
        else:
                _show_craft_error(result.get("error", "Не удалось создать"))

func _show_craft_success(recipe_id: String):
        var popup = AcceptDialog.new()
        popup.dialog_text = "Создано: %s" % _get_localized_name(recipe_id)
        popup.title = "Успех!"
        add_child(popup)
        popup.popup_centered()
        await get_tree().create_timer(1.5).timeout
        if is_instance_valid(popup):
                popup.queue_free()

func _show_craft_error(error: String):
        var popup = AcceptDialog.new()
        popup.dialog_text = error
        popup.title = "Ошибка"
        add_child(popup)
        popup.popup_centered()
