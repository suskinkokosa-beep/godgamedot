extends Node
signal inventory_changed()
signal equip_changed()
signal hotbar_changed()

var slots := []
var max_slots := 40
var max_weight := 80.0

var hotbar := [null, null, null, null, null, null, null, null]
var selected_hotbar_slot := 0

var equipment := {
        "head": null,
        "torso": null,
        "legs": null,
        "hands": null,
        "feet": null,
        "weapon": null,
        "offhand": null,
        "backpack": null
}

var item_database := {
        "wood": {"name": "Дерево", "weight": 0.5, "stackable": true, "max_stack": 99, "type": "resource"},
        "stone": {"name": "Камень", "weight": 1.0, "stackable": true, "max_stack": 99, "type": "resource"},
        "stick": {"name": "Палка", "weight": 0.2, "stackable": true, "max_stack": 99, "type": "resource"},
        "plant_fiber": {"name": "Растительное волокно", "weight": 0.1, "stackable": true, "max_stack": 99, "type": "resource"},
        "iron_ore": {"name": "Железная руда", "weight": 2.0, "stackable": true, "max_stack": 50, "type": "resource"},
        "copper_ore": {"name": "Медная руда", "weight": 1.8, "stackable": true, "max_stack": 50, "type": "resource"},
        "gold_ore": {"name": "Золотая руда", "weight": 3.0, "stackable": true, "max_stack": 30, "type": "resource"},
        "silver_ore": {"name": "Серебряная руда", "weight": 2.5, "stackable": true, "max_stack": 30, "type": "resource"},
        "iron_ingot": {"name": "Железный слиток", "weight": 1.5, "stackable": true, "max_stack": 50, "type": "resource"},
        "copper_ingot": {"name": "Медный слиток", "weight": 1.2, "stackable": true, "max_stack": 50, "type": "resource"},
        "steel_ingot": {"name": "Стальной слиток", "weight": 2.0, "stackable": true, "max_stack": 50, "type": "resource"},
        "silver_ingot": {"name": "Серебряный слиток", "weight": 2.0, "stackable": true, "max_stack": 30, "type": "resource"},
        "gold_ingot": {"name": "Золотой слиток", "weight": 2.5, "stackable": true, "max_stack": 20, "type": "resource"},
        "hide": {"name": "Шкура", "weight": 0.8, "stackable": true, "max_stack": 30, "type": "resource"},
        "bone": {"name": "Кость", "weight": 0.3, "stackable": true, "max_stack": 50, "type": "resource"},
        "flint": {"name": "Кремень", "weight": 0.3, "stackable": true, "max_stack": 50, "type": "resource"},
        "cloth": {"name": "Ткань", "weight": 0.2, "stackable": true, "max_stack": 50, "type": "resource"},
        "leather": {"name": "Кожа", "weight": 0.5, "stackable": true, "max_stack": 30, "type": "resource"},
        "rope": {"name": "Верёвка", "weight": 0.3, "stackable": true, "max_stack": 30, "type": "resource"},
        "coal": {"name": "Уголь", "weight": 0.5, "stackable": true, "max_stack": 50, "type": "resource"},
        "sulfur": {"name": "Сера", "weight": 0.8, "stackable": true, "max_stack": 50, "type": "resource"},
        "gunpowder": {"name": "Порох", "weight": 0.2, "stackable": true, "max_stack": 50, "type": "resource"},
        "herbs": {"name": "Травы", "weight": 0.1, "stackable": true, "max_stack": 50, "type": "resource"},
        "mushroom": {"name": "Грибы", "weight": 0.2, "stackable": true, "max_stack": 30, "type": "food", "hunger_restore": 5},
        "wheat": {"name": "Пшеница", "weight": 0.2, "stackable": true, "max_stack": 99, "type": "resource"},
        "fish": {"name": "Рыба", "weight": 0.4, "stackable": true, "max_stack": 20, "type": "food", "hunger_restore": 15},
        "meat": {"name": "Мясо", "weight": 0.5, "stackable": true, "max_stack": 20, "type": "food", "hunger_restore": 25},
        "cooked_meat": {"name": "Жареное мясо", "weight": 0.4, "stackable": true, "max_stack": 20, "type": "food", "hunger_restore": 40},
        "cooked_fish": {"name": "Жареная рыба", "weight": 0.3, "stackable": true, "max_stack": 20, "type": "food", "hunger_restore": 30},
        "berries": {"name": "Ягоды", "weight": 0.1, "stackable": true, "max_stack": 50, "type": "food", "hunger_restore": 5},
        "berry_mix": {"name": "Ягодная смесь", "weight": 0.2, "stackable": true, "max_stack": 20, "type": "food", "hunger_restore": 15},
        "stew": {"name": "Похлёбка", "weight": 0.5, "stackable": true, "max_stack": 10, "type": "food", "hunger_restore": 50, "thirst_restore": 20},
        "bread": {"name": "Хлеб", "weight": 0.3, "stackable": true, "max_stack": 20, "type": "food", "hunger_restore": 35},
        "grilled_vegetables": {"name": "Жареные овощи", "weight": 0.3, "stackable": true, "max_stack": 20, "type": "food", "hunger_restore": 25},
        "carrot": {"name": "Морковь", "weight": 0.1, "stackable": true, "max_stack": 50, "type": "food", "hunger_restore": 8},
        "water_bottle": {"name": "Бутылка воды", "weight": 0.5, "stackable": true, "max_stack": 10, "type": "drink", "thirst_restore": 30},
        "bandage": {"name": "Бинт", "weight": 0.1, "stackable": true, "max_stack": 20, "type": "medical", "heal_amount": 20},
        "medkit": {"name": "Аптечка", "weight": 0.5, "stackable": true, "max_stack": 5, "type": "medical", "heal_amount": 50},
        "medicine": {"name": "Лекарство", "weight": 0.2, "stackable": true, "max_stack": 10, "type": "medical", "heal_amount": 30},
        "antidote": {"name": "Антидот", "weight": 0.2, "stackable": true, "max_stack": 10, "type": "medical"},
        "blood_pack": {"name": "Пакет крови", "weight": 0.4, "stackable": true, "max_stack": 5, "type": "medical", "blood_restore": 30},
        "splint": {"name": "Шина", "weight": 0.3, "stackable": true, "max_stack": 10, "type": "medical"},
        "painkiller": {"name": "Обезболивающее", "weight": 0.1, "stackable": true, "max_stack": 10, "type": "medical"},
        "anti_rad": {"name": "Антирадин", "weight": 0.3, "stackable": true, "max_stack": 10, "type": "medical"},
        "warm_potion": {"name": "Согревающее зелье", "weight": 0.3, "stackable": true, "max_stack": 10, "type": "medical"},
        "cooling_potion": {"name": "Охлаждающее зелье", "weight": 0.3, "stackable": true, "max_stack": 10, "type": "medical"},
        "stone_axe": {"name": "Каменный топор", "weight": 2.0, "stackable": false, "type": "tool", "damage": 10, "gather_speed": 1.2},
        "stone_pickaxe": {"name": "Каменная кирка", "weight": 2.0, "stackable": false, "type": "tool", "damage": 8, "gather_speed": 1.3},
        "stone_knife": {"name": "Каменный нож", "weight": 0.8, "stackable": false, "type": "tool", "damage": 12},
        "iron_axe": {"name": "Железный топор", "weight": 3.0, "stackable": false, "type": "tool", "damage": 18, "gather_speed": 1.8},
        "iron_pickaxe": {"name": "Железная кирка", "weight": 3.0, "stackable": false, "type": "tool", "damage": 12, "gather_speed": 2.0},
        "steel_axe": {"name": "Стальной топор", "weight": 3.5, "stackable": false, "type": "tool", "damage": 25, "gather_speed": 2.5},
        "steel_pickaxe": {"name": "Стальная кирка", "weight": 3.5, "stackable": false, "type": "tool", "damage": 15, "gather_speed": 2.8},
        "hammer": {"name": "Молоток", "weight": 1.5, "stackable": false, "type": "tool", "damage": 5},
        "repair_hammer": {"name": "Ремонтный молоток", "weight": 2.0, "stackable": false, "type": "tool"},
        "fishing_rod": {"name": "Удочка", "weight": 0.8, "stackable": false, "type": "tool"},
        "wooden_spear": {"name": "Деревянное копьё", "weight": 1.5, "stackable": false, "type": "weapon", "damage": 20},
        "iron_sword": {"name": "Железный меч", "weight": 2.5, "stackable": false, "type": "weapon", "damage": 30},
        "steel_sword": {"name": "Стальной меч", "weight": 3.0, "stackable": false, "type": "weapon", "damage": 45},
        "bow": {"name": "Лук", "weight": 1.5, "stackable": false, "type": "weapon", "damage": 25, "ranged": true},
        "crossbow": {"name": "Арбалет", "weight": 3.0, "stackable": false, "type": "weapon", "damage": 40, "ranged": true},
        "arrow": {"name": "Стрела", "weight": 0.1, "stackable": true, "max_stack": 99, "type": "ammo"},
        "iron_arrow": {"name": "Железная стрела", "weight": 0.15, "stackable": true, "max_stack": 99, "type": "ammo"},
        "bolt": {"name": "Болт", "weight": 0.2, "stackable": true, "max_stack": 99, "type": "ammo"},
        "torch": {"name": "Факел", "weight": 0.3, "stackable": true, "max_stack": 20, "type": "light"},
        "campfire": {"name": "Костёр", "weight": 5.0, "stackable": false, "type": "placeable"},
        "sleeping_bag": {"name": "Спальный мешок", "weight": 3.0, "stackable": false, "type": "placeable"},
        "workbench_1": {"name": "Базовый верстак", "weight": 10.0, "stackable": false, "type": "placeable"},
        "workbench_2": {"name": "Продвинутый верстак", "weight": 15.0, "stackable": false, "type": "placeable"},
        "workbench_3": {"name": "Мастерский верстак", "weight": 20.0, "stackable": false, "type": "placeable"},
        "furnace": {"name": "Печь", "weight": 20.0, "stackable": false, "type": "placeable"},
        "storage_box": {"name": "Ящик", "weight": 8.0, "stackable": false, "type": "placeable"},
        "large_storage": {"name": "Большой ящик", "weight": 15.0, "stackable": false, "type": "placeable"},
        "tool_cupboard": {"name": "Шкаф инструментов", "weight": 12.0, "stackable": false, "type": "placeable"},
        "wooden_foundation": {"name": "Деревянный фундамент", "weight": 15.0, "stackable": true, "max_stack": 10, "type": "building"},
        "wooden_wall": {"name": "Деревянная стена", "weight": 8.0, "stackable": true, "max_stack": 10, "type": "building"},
        "wooden_floor": {"name": "Деревянный пол", "weight": 6.0, "stackable": true, "max_stack": 10, "type": "building"},
        "wooden_door": {"name": "Деревянная дверь", "weight": 10.0, "stackable": true, "max_stack": 5, "type": "building"},
        "wooden_doorframe": {"name": "Деревянный дверной проём", "weight": 7.0, "stackable": true, "max_stack": 10, "type": "building"},
        "wooden_window": {"name": "Деревянное окно", "weight": 6.0, "stackable": true, "max_stack": 10, "type": "building"},
        "wooden_roof": {"name": "Деревянная крыша", "weight": 8.0, "stackable": true, "max_stack": 10, "type": "building"},
        "wooden_stairs": {"name": "Деревянная лестница", "weight": 10.0, "stackable": true, "max_stack": 5, "type": "building"},
        "stone_foundation": {"name": "Каменный фундамент", "weight": 25.0, "stackable": true, "max_stack": 10, "type": "building"},
        "stone_wall": {"name": "Каменная стена", "weight": 15.0, "stackable": true, "max_stack": 10, "type": "building"},
        "stone_floor": {"name": "Каменный пол", "weight": 12.0, "stackable": true, "max_stack": 10, "type": "building"},
        "metal_door": {"name": "Металлическая дверь", "weight": 20.0, "stackable": true, "max_stack": 5, "type": "building"},
        "armored_door": {"name": "Бронированная дверь", "weight": 30.0, "stackable": true, "max_stack": 3, "type": "building"},
        "leather_vest": {"name": "Кожаный жилет", "weight": 2.0, "stackable": false, "type": "armor", "armor": 10, "slot": "torso"},
        "leather_pants": {"name": "Кожаные штаны", "weight": 1.5, "stackable": false, "type": "armor", "armor": 8, "slot": "legs"},
        "leather_boots": {"name": "Кожаные ботинки", "weight": 1.0, "stackable": false, "type": "armor", "armor": 5, "slot": "feet"},
        "leather_gloves": {"name": "Кожаные перчатки", "weight": 0.5, "stackable": false, "type": "armor", "armor": 3, "slot": "hands"},
        "leather_helmet": {"name": "Кожаный шлем", "weight": 1.2, "stackable": false, "type": "armor", "armor": 8, "slot": "head"},
        "iron_armor_chest": {"name": "Железный нагрудник", "weight": 8.0, "stackable": false, "type": "armor", "armor": 25, "slot": "torso"},
        "iron_armor_legs": {"name": "Железные поножи", "weight": 6.0, "stackable": false, "type": "armor", "armor": 20, "slot": "legs"},
        "iron_helmet": {"name": "Железный шлем", "weight": 3.0, "stackable": false, "type": "armor", "armor": 18, "slot": "head"},
        "steel_armor_chest": {"name": "Стальной нагрудник", "weight": 10.0, "stackable": false, "type": "armor", "armor": 40, "slot": "torso"},
        "steel_armor_legs": {"name": "Стальные поножи", "weight": 7.0, "stackable": false, "type": "armor", "armor": 30, "slot": "legs"},
        "steel_helmet": {"name": "Стальной шлем", "weight": 4.0, "stackable": false, "type": "armor", "armor": 28, "slot": "head"}
}

func _ready():
        slots = []
        _add_starting_items()

func _add_starting_items():
        add_item("stone_axe", 1, 2.0)
        add_item("torch", 3, 0.3)
        add_item("berries", 10, 0.1)
        add_item("water_bottle", 2, 0.5)
        add_item("bandage", 5, 0.1)
        add_item("wood", 20, 0.5)
        add_item("stone", 15, 1.0)
        
        hotbar[0] = {"id": "stone_axe", "count": 1}
        hotbar[1] = {"id": "torch", "count": 1}

func get_item_info(item_id: String) -> Dictionary:
        return item_database.get(item_id, {"name": item_id, "weight": 1.0, "stackable": true, "max_stack": 99, "type": "misc"})

func total_weight() -> float:
        var w = 0.0
        for s in slots:
                var info = get_item_info(s["id"])
                w += float(info.get("weight", 1.0)) * int(s.get("count", 1))
        for k in equipment.keys():
                var it = equipment[k]
                if it:
                        var info = get_item_info(it["id"])
                        w += float(info.get("weight", 0.0))
        for h in hotbar:
                if h:
                        var info = get_item_info(h["id"])
                        w += float(info.get("weight", 1.0)) * int(h.get("count", 1))
        return w

func can_add(item_id, count=1, item_weight=1.0):
        if total_weight() + item_weight * count > max_weight:
                return false
        for s in slots:
                if s["id"] == item_id:
                        return true
        return slots.size() < max_slots

func add_item(item_id, count=1, weight=1.0):
        for s in slots:
                if s["id"] == item_id:
                        s["count"] += count
                        emit_signal("inventory_changed")
                        return true
        if slots.size() < max_slots and total_weight() + weight * count <= max_weight:
                slots.append({"id": item_id, "count": count, "weight": weight})
                emit_signal("inventory_changed")
                return true
        return false

func remove_item(item_id, count=1):
        for i in range(slots.size() - 1, -1, -1):
                if slots[i]["id"] == item_id:
                        slots[i]["count"] -= count
                        if slots[i]["count"] <= 0:
                                slots.remove_at(i)
                        emit_signal("inventory_changed")
                        return true
        return false

func has_item(item_id, count=1):
        for s in slots:
                if s["id"] == item_id and s["count"] >= count:
                        return true
        return false

func get_items():
        return slots

func equip(slot_name: String, item: Dictionary) -> bool:
        if not equipment.has(slot_name):
                return false
        if equipment[slot_name] != null:
                var prev = equipment[slot_name]
                var info = get_item_info(prev["id"])
                if not add_item(prev["id"], 1, info.get("weight", 1.0)):
                        return false
        if not remove_item(item["id"], 1):
                return false
        equipment[slot_name] = item
        emit_signal("equip_changed")
        return true

func unequip(slot_name: String) -> bool:
        if not equipment.has(slot_name):
                return false
        var it = equipment[slot_name]
        if it == null:
                return false
        var info = get_item_info(it["id"])
        if not add_item(it["id"], 1, info.get("weight", 1.0)):
                return false
        equipment[slot_name] = null
        emit_signal("equip_changed")
        return true

func get_equipment():
        return equipment

func set_hotbar_slot(slot_index: int, item: Dictionary):
        if slot_index < 0 or slot_index >= 8:
                return false
        hotbar[slot_index] = item
        emit_signal("hotbar_changed")
        return true

func get_hotbar_slot(slot_index: int):
        if slot_index < 0 or slot_index >= 8:
                return null
        return hotbar[slot_index]

func get_hotbar() -> Array:
        return hotbar

func select_hotbar_slot(slot_index: int):
        if slot_index >= 0 and slot_index < 8:
                selected_hotbar_slot = slot_index
                emit_signal("hotbar_changed")

func get_selected_hotbar_slot() -> int:
        return selected_hotbar_slot

func get_selected_item():
        return hotbar[selected_hotbar_slot]

func move_to_hotbar(item_id: String, hotbar_slot: int) -> bool:
        if hotbar_slot < 0 or hotbar_slot >= 8:
                return false
        
        for i in range(slots.size()):
                if slots[i]["id"] == item_id:
                        var item = slots[i].duplicate()
                        item["count"] = 1
                        slots[i]["count"] -= 1
                        if slots[i]["count"] <= 0:
                                slots.remove_at(i)
                        
                        if hotbar[hotbar_slot] != null:
                                add_item(hotbar[hotbar_slot]["id"], hotbar[hotbar_slot]["count"])
                        
                        hotbar[hotbar_slot] = item
                        emit_signal("inventory_changed")
                        emit_signal("hotbar_changed")
                        return true
        return false

func move_from_hotbar(hotbar_slot: int) -> bool:
        if hotbar_slot < 0 or hotbar_slot >= 8:
                return false
        if hotbar[hotbar_slot] == null:
                return false
        
        var item = hotbar[hotbar_slot]
        if add_item(item["id"], item["count"]):
                hotbar[hotbar_slot] = null
                emit_signal("hotbar_changed")
                return true
        return false

func use_item(item_id: String, player: Node = null) -> bool:
        var info = get_item_info(item_id)
        var item_type = info.get("type", "misc")
        
        match item_type:
                "food":
                        if player and player.has_method("consume_food"):
                                var amount = info.get("hunger_restore", 10)
                                player.consume_food(amount)
                                remove_item(item_id, 1)
                                return true
                "drink":
                        if player and player.has_method("consume_water"):
                                var amount = info.get("thirst_restore", 10)
                                player.consume_water(amount)
                                remove_item(item_id, 1)
                                return true
                "medical":
                        if player and player.has_method("heal"):
                                var amount = info.get("heal_amount", 20)
                                player.heal(amount)
                                remove_item(item_id, 1)
                                return true
        
        return false

func use_selected_hotbar_item(player: Node = null) -> bool:
        var item = hotbar[selected_hotbar_slot]
        if item == null:
                return false
        
        var info = get_item_info(item["id"])
        var item_type = info.get("type", "misc")
        
        match item_type:
                "food":
                        if player and player.has_method("consume_food"):
                                player.consume_food(info.get("hunger_restore", 10))
                                item["count"] -= 1
                                if item["count"] <= 0:
                                        hotbar[selected_hotbar_slot] = null
                                emit_signal("hotbar_changed")
                                return true
                "drink":
                        if player and player.has_method("consume_water"):
                                player.consume_water(info.get("thirst_restore", 10))
                                item["count"] -= 1
                                if item["count"] <= 0:
                                        hotbar[selected_hotbar_slot] = null
                                emit_signal("hotbar_changed")
                                return true
                "medical":
                        if player and player.has_method("heal"):
                                player.heal(info.get("heal_amount", 20))
                                item["count"] -= 1
                                if item["count"] <= 0:
                                        hotbar[selected_hotbar_slot] = null
                                emit_signal("hotbar_changed")
                                return true
        
        return false

func get_total_item_count(item_id: String) -> int:
        var count = 0
        for s in slots:
                if s["id"] == item_id:
                        count += s["count"]
        for h in hotbar:
                if h != null and h["id"] == item_id:
                        count += h["count"]
        return count

func drop_random_items(percentage: float) -> Array:
        var dropped = []
        var num_to_drop = int(slots.size() * percentage)
        
        for i in range(num_to_drop):
                if slots.size() > 0:
                        var idx = randi() % slots.size()
                        var drop_count = max(1, int(slots[idx]["count"] * 0.5))
                        dropped.append({"id": slots[idx]["id"], "count": drop_count})
                        slots[idx]["count"] -= drop_count
                        if slots[idx]["count"] <= 0:
                                slots.remove_at(idx)
        
        emit_signal("inventory_changed")
        return dropped

func clear_inventory():
        slots.clear()
        hotbar = [null, null, null, null, null, null, null, null]
        emit_signal("inventory_changed")
        emit_signal("hotbar_changed")
