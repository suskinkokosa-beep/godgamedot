extends Node

signal dialogue_started(npc_name: String)
signal dialogue_ended()
signal dialogue_line_shown(text: String, speaker: String)
signal choice_selected(choice_id: String)

var current_dialogue: Dictionary = {}
var current_node_id: String = ""
var is_active := false
var current_npc = null

var dialogue_ui: Control = null

var dialogues := {
        "trader_greeting": {
                "start": {
                        "speaker": "Торговец",
                        "text_ru": "Привет, путник! Хочешь посмотреть мой товар?",
                        "text_en": "Hello, traveler! Want to see my wares?",
                        "choices": [
                                {"id": "trade", "text_ru": "Открыть торговлю", "text_en": "Open trade", "next": "trade_open"},
                                {"id": "quest", "text_ru": "Есть работа?", "text_en": "Got any work?", "next": "quest_offer"},
                                {"id": "bye", "text_ru": "До свидания", "text_en": "Goodbye", "next": "end"}
                        ]
                },
                "trade_open": {
                        "speaker": "Торговец",
                        "text_ru": "Вот что у меня есть...",
                        "text_en": "Here's what I have...",
                        "action": "open_trade",
                        "next": "end"
                },
                "quest_offer": {
                        "speaker": "Торговец",
                        "text_ru": "Да, мне нужно 10 единиц дерева. Принесёшь — заплачу.",
                        "text_en": "Yes, I need 10 wood. Bring it and I'll pay you.",
                        "action": "offer_quest:gather_wood",
                        "choices": [
                                {"id": "accept", "text_ru": "Согласен", "text_en": "I accept", "next": "quest_accepted"},
                                {"id": "decline", "text_ru": "Не сейчас", "text_en": "Not now", "next": "start"}
                        ]
                },
                "quest_accepted": {
                        "speaker": "Торговец",
                        "text_ru": "Отлично! Возвращайся, когда соберёшь.",
                        "text_en": "Great! Come back when you have it.",
                        "action": "start_quest:gather_wood",
                        "next": "end"
                }
        },
        "guard_greeting": {
                "start": {
                        "speaker": "Охранник",
                        "text_ru": "Стой! Кто идёт?",
                        "text_en": "Halt! Who goes there?",
                        "choices": [
                                {"id": "friendly", "text_ru": "Я просто путник", "text_en": "Just a traveler", "next": "friendly_response"},
                                {"id": "hostile", "text_ru": "Не твоё дело!", "text_en": "None of your business!", "next": "hostile_response"}
                        ]
                },
                "friendly_response": {
                        "speaker": "Охранник",
                        "text_ru": "Ладно, проходи. Но без глупостей.",
                        "text_en": "Alright, move along. But no funny business.",
                        "action": "reputation:+5",
                        "next": "end"
                },
                "hostile_response": {
                        "speaker": "Охранник",
                        "text_ru": "Ты нарываешься на неприятности!",
                        "text_en": "You're asking for trouble!",
                        "action": "reputation:-10",
                        "next": "end"
                }
        },
        "citizen_greeting": {
                "start": {
                        "speaker": "Житель",
                        "text_ru": "Добрый день! Как дела в поселении?",
                        "text_en": "Good day! How are things in the settlement?",
                        "choices": [
                                {"id": "info", "text_ru": "Что нового?", "text_en": "What's new?", "next": "news"},
                                {"id": "rumors", "text_ru": "Слышал какие-нибудь слухи?", "text_en": "Heard any rumors?", "next": "rumors"},
                                {"id": "bye", "text_ru": "Всего хорошего", "text_en": "Take care", "next": "end"}
                        ]
                },
                "news": {
                        "speaker": "Житель",
                        "text_ru": "Слышал, на востоке видели волков. Будь осторожен!",
                        "text_en": "I heard wolves were spotted to the east. Be careful!",
                        "next": "end"
                },
                "rumors": {
                        "speaker": "Житель",
                        "text_ru": "Говорят, в горах есть заброшенная шахта, полная сокровищ. Но там опасно...",
                        "text_en": "They say there's an abandoned mine in the mountains, full of treasures. But it's dangerous...",
                        "action": "reveal_location:abandoned_mine",
                        "next": "end"
                }
        },
        "hunter_greeting": {
                "start": {
                        "speaker": "Охотник",
                        "text_ru": "Привет! Я только что вернулся с охоты.",
                        "text_en": "Hello! I just came back from hunting.",
                        "choices": [
                                {"id": "buy", "text_ru": "Можешь продать шкуры?", "text_en": "Can you sell furs?", "next": "sell_furs"},
                                {"id": "hunt", "text_ru": "Где хорошая охота?", "text_en": "Where's good hunting?", "next": "hunting_tips"},
                                {"id": "quest", "text_ru": "Нужна помощь?", "text_en": "Need any help?", "next": "hunter_quest"},
                                {"id": "bye", "text_ru": "Удачной охоты!", "text_en": "Good hunting!", "next": "end"}
                        ]
                },
                "sell_furs": {
                        "speaker": "Охотник",
                        "text_ru": "Конечно! У меня есть волчьи и лисьи шкуры.",
                        "text_en": "Sure! I have wolf and fox furs.",
                        "action": "open_trade",
                        "next": "end"
                },
                "hunting_tips": {
                        "speaker": "Охотник",
                        "text_ru": "На севере много оленей. На востоке - волки, опасно, но шкуры дорогие.",
                        "text_en": "Lots of deer to the north. Wolves to the east - dangerous, but valuable furs.",
                        "action": "reveal_location:hunting_grounds",
                        "next": "end"
                },
                "hunter_quest": {
                        "speaker": "Охотник",
                        "text_ru": "Да! Принеси мне 5 волчьих клыков. Заплачу хорошо.",
                        "text_en": "Yes! Bring me 5 wolf fangs. I'll pay well.",
                        "choices": [
                                {"id": "accept", "text_ru": "Принесу!", "text_en": "I'll bring them!", "action": "start_quest:wolf_fangs", "next": "quest_accepted"},
                                {"id": "decline", "text_ru": "Может позже", "text_en": "Maybe later", "next": "start"}
                        ]
                },
                "quest_accepted": {
                        "speaker": "Охотник",
                        "text_ru": "Удачи! Волки водятся в восточном лесу.",
                        "text_en": "Good luck! Wolves roam the eastern forest.",
                        "next": "end"
                }
        },
        "farmer_greeting": {
                "start": {
                        "speaker": "Фермер",
                        "text_ru": "Хорошего дня! Урожай в этом году неплох.",
                        "text_en": "Good day! The harvest is decent this year.",
                        "choices": [
                                {"id": "buy", "text_ru": "Можешь продать еду?", "text_en": "Can you sell food?", "next": "sell_food"},
                                {"id": "help", "text_ru": "Нужна помощь на ферме?", "text_en": "Need help on the farm?", "next": "farm_work"},
                                {"id": "info", "text_ru": "Как дела в поселении?", "text_en": "How's the settlement?", "next": "settlement_info"},
                                {"id": "bye", "text_ru": "До свидания", "text_en": "Goodbye", "next": "end"}
                        ]
                },
                "sell_food": {
                        "speaker": "Фермер",
                        "text_ru": "Есть пшеница, морковь и яблоки. Смотри сам.",
                        "text_en": "Got wheat, carrots and apples. Take a look.",
                        "action": "open_trade",
                        "next": "end"
                },
                "farm_work": {
                        "speaker": "Фермер",
                        "text_ru": "Вообще-то да. Помоги собрать 20 единиц пшеницы, дам тебе еды.",
                        "text_en": "Actually yes. Help gather 20 wheat, I'll give you food.",
                        "choices": [
                                {"id": "accept", "text_ru": "С удовольствием", "text_en": "Gladly", "action": "start_quest:gather_wheat", "next": "farm_quest_accepted"},
                                {"id": "decline", "text_ru": "Сейчас занят", "text_en": "I'm busy now", "next": "start"}
                        ]
                },
                "farm_quest_accepted": {
                        "speaker": "Фермер",
                        "text_ru": "Спасибо! Пшеница растёт на полях к югу от деревни.",
                        "text_en": "Thanks! Wheat grows in the fields south of the village.",
                        "next": "end"
                },
                "settlement_info": {
                        "speaker": "Фермер",
                        "text_ru": "Говорят, скоро будет праздник урожая. Надеюсь, бандиты не испортят всё...",
                        "text_en": "They say the harvest festival is coming. Hope bandits don't ruin it...",
                        "next": "end"
                }
        },
        "blacksmith_greeting": {
                "start": {
                        "speaker": "Кузнец",
                        "text_ru": "*стук молота* А, клиент! Чего желаешь?",
                        "text_en": "*hammer clangs* Ah, a customer! What do you need?",
                        "choices": [
                                {"id": "buy", "text_ru": "Покажи оружие", "text_en": "Show me weapons", "next": "show_weapons"},
                                {"id": "repair", "text_ru": "Можешь починить снаряжение?", "text_en": "Can you repair my gear?", "next": "repair"},
                                {"id": "craft", "text_ru": "Можешь сковать что-нибудь?", "text_en": "Can you forge something?", "next": "custom_craft"},
                                {"id": "bye", "text_ru": "Удачи в работе", "text_en": "Good luck with work", "next": "end"}
                        ]
                },
                "show_weapons": {
                        "speaker": "Кузнец",
                        "text_ru": "Мечи, топоры, копья - всё лучшего качества!",
                        "text_en": "Swords, axes, spears - all top quality!",
                        "action": "open_trade",
                        "next": "end"
                },
                "repair": {
                        "speaker": "Кузнец",
                        "text_ru": "Конечно. Давай посмотрю... Это будет стоить 50 золота.",
                        "text_en": "Sure. Let me see... It'll cost 50 gold.",
                        "choices": [
                                {"id": "accept", "text_ru": "Хорошо, чини", "text_en": "Okay, repair it", "action": "repair_all", "next": "repair_done"},
                                {"id": "decline", "text_ru": "Дороговато...", "text_en": "Too expensive...", "next": "start"}
                        ]
                },
                "repair_done": {
                        "speaker": "Кузнец",
                        "text_ru": "Готово! Теперь как новое. Удачи в бою!",
                        "text_en": "Done! Good as new. Good luck in battle!",
                        "next": "end"
                },
                "custom_craft": {
                        "speaker": "Кузнец",
                        "text_ru": "Принеси материалы - 10 железа и 5 угля - скую тебе хороший меч.",
                        "text_en": "Bring materials - 10 iron and 5 coal - I'll forge you a good sword.",
                        "action": "start_quest:gather_smithing_materials",
                        "next": "end"
                }
        },
        "priest_greeting": {
                "start": {
                        "speaker": "Жрец",
                        "text_ru": "Благословение богов на тебя, путник.",
                        "text_en": "Blessings of the gods upon you, traveler.",
                        "choices": [
                                {"id": "heal", "text_ru": "Можешь исцелить меня?", "text_en": "Can you heal me?", "next": "healing"},
                                {"id": "bless", "text_ru": "Прошу благословения", "text_en": "I seek a blessing", "next": "blessing"},
                                {"id": "learn", "text_ru": "Расскажи о богах", "text_en": "Tell me about the gods", "next": "lore"},
                                {"id": "bye", "text_ru": "Благодарю", "text_en": "Thank you", "next": "end"}
                        ]
                },
                "healing": {
                        "speaker": "Жрец",
                        "text_ru": "Конечно, дитя. *возлагает руки* Исцеляйся.",
                        "text_en": "Of course, child. *lays hands* Be healed.",
                        "action": "heal_player:full",
                        "next": "end"
                },
                "blessing": {
                        "speaker": "Жрец",
                        "text_ru": "Да хранят тебя боги. *благословляет*",
                        "text_en": "May the gods protect you. *blesses*",
                        "action": "buff:protection:300",
                        "next": "end"
                },
                "lore": {
                        "speaker": "Жрец",
                        "text_ru": "Древние боги создали этот мир. Они наблюдают за нами и направляют достойных.",
                        "text_en": "The ancient gods created this world. They watch over us and guide the worthy.",
                        "next": "end"
                }
        },
        "innkeeper_greeting": {
                "start": {
                        "speaker": "Трактирщик",
                        "text_ru": "Добро пожаловать в нашу таверну! Чего изволите?",
                        "text_en": "Welcome to our tavern! What'll it be?",
                        "choices": [
                                {"id": "drink", "text_ru": "Налей эля", "text_en": "Pour me an ale", "next": "order_drink"},
                                {"id": "food", "text_ru": "Что есть поесть?", "text_en": "What's to eat?", "next": "order_food"},
                                {"id": "room", "text_ru": "Есть свободная комната?", "text_en": "Any rooms available?", "next": "rent_room"},
                                {"id": "rumors", "text_ru": "Слышал какие-нибудь слухи?", "text_en": "Heard any rumors?", "next": "tavern_rumors"},
                                {"id": "bye", "text_ru": "Пока ничего", "text_en": "Nothing for now", "next": "end"}
                        ]
                },
                "order_drink": {
                        "speaker": "Трактирщик",
                        "text_ru": "Вот, лучший эль в округе! 5 золотых.",
                        "text_en": "Here, best ale around! 5 gold.",
                        "action": "buy_item:ale:5",
                        "next": "end"
                },
                "order_food": {
                        "speaker": "Трактирщик",
                        "text_ru": "Жаркое из оленины, свежий хлеб. 10 золотых за порцию.",
                        "text_en": "Venison stew, fresh bread. 10 gold per serving.",
                        "action": "buy_item:meal:10",
                        "next": "end"
                },
                "rent_room": {
                        "speaker": "Трактирщик",
                        "text_ru": "Есть! 20 золотых за ночь. Отдохнёшь и восстановишь силы.",
                        "text_en": "Yes! 20 gold per night. You'll rest and recover.",
                        "choices": [
                                {"id": "accept", "text_ru": "Беру", "text_en": "I'll take it", "action": "rest_at_inn:20", "next": "room_rented"},
                                {"id": "decline", "text_ru": "Дороговато", "text_en": "Too expensive", "next": "start"}
                        ]
                },
                "room_rented": {
                        "speaker": "Трактирщик",
                        "text_ru": "Приятного отдыха! Комната наверху, первая дверь направо.",
                        "text_en": "Enjoy your rest! Room upstairs, first door on the right.",
                        "next": "end"
                },
                "tavern_rumors": {
                        "speaker": "Трактирщик",
                        "text_ru": "Говорят, в подземельях под старым замком прячут древние сокровища. Но там кишит нежитью...",
                        "text_en": "They say ancient treasures are hidden in the dungeons beneath the old castle. But it's crawling with undead...",
                        "action": "reveal_location:old_castle_dungeon",
                        "next": "end"
                }
        }
}

func _ready():
        _create_dialogue_ui()

func _create_dialogue_ui():
        dialogue_ui = Control.new()
        dialogue_ui.name = "DialogueUI"
        dialogue_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
        dialogue_ui.visible = false
        dialogue_ui.mouse_filter = Control.MOUSE_FILTER_STOP
        
        var bg = ColorRect.new()
        bg.name = "Background"
        bg.color = Color(0, 0, 0, 0.7)
        bg.set_anchors_preset(Control.PRESET_FULL_RECT)
        dialogue_ui.add_child(bg)
        
        var panel = PanelContainer.new()
        panel.name = "DialoguePanel"
        panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
        panel.anchor_top = 0.6
        panel.anchor_bottom = 0.95
        panel.anchor_left = 0.1
        panel.anchor_right = 0.9
        panel.offset_top = 0
        panel.offset_bottom = 0
        panel.offset_left = 0
        panel.offset_right = 0
        dialogue_ui.add_child(panel)
        
        var style = StyleBoxFlat.new()
        style.bg_color = Color(0.15, 0.12, 0.1, 0.95)
        style.border_color = Color(0.6, 0.4, 0.2)
        style.set_border_width_all(2)
        style.set_corner_radius_all(8)
        style.set_content_margin_all(20)
        panel.add_theme_stylebox_override("panel", style)
        
        var vbox = VBoxContainer.new()
        vbox.name = "VBox"
        vbox.add_theme_constant_override("separation", 15)
        panel.add_child(vbox)
        
        var speaker_label = Label.new()
        speaker_label.name = "SpeakerLabel"
        speaker_label.add_theme_font_size_override("font_size", 20)
        speaker_label.add_theme_color_override("font_color", Color(1, 0.8, 0.4))
        vbox.add_child(speaker_label)
        
        var text_label = RichTextLabel.new()
        text_label.name = "TextLabel"
        text_label.bbcode_enabled = true
        text_label.fit_content = true
        text_label.custom_minimum_size = Vector2(0, 80)
        text_label.add_theme_font_size_override("normal_font_size", 18)
        vbox.add_child(text_label)
        
        var choices_container = VBoxContainer.new()
        choices_container.name = "ChoicesContainer"
        choices_container.add_theme_constant_override("separation", 8)
        vbox.add_child(choices_container)
        
        var close_btn = Button.new()
        close_btn.name = "CloseButton"
        close_btn.text = "Закрыть"
        close_btn.custom_minimum_size = Vector2(100, 40)
        close_btn.pressed.connect(_on_close_pressed)
        close_btn.visible = false
        vbox.add_child(close_btn)
        
        call_deferred("_add_ui_to_scene")

func _add_ui_to_scene():
        var canvas = CanvasLayer.new()
        canvas.name = "DialogueCanvas"
        canvas.layer = 100
        canvas.add_child(dialogue_ui)
        get_tree().root.add_child(canvas)

func start_dialogue(npc, dialogue_id: String):
        if not dialogues.has(dialogue_id):
                push_warning("Dialogue not found: " + dialogue_id)
                return
        
        current_npc = npc
        current_dialogue = dialogues[dialogue_id]
        current_node_id = "start"
        is_active = true
        
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
        
        dialogue_ui.visible = true
        _show_current_node()
        
        emit_signal("dialogue_started", dialogue_id)

func _show_current_node():
        if not current_dialogue.has(current_node_id):
                end_dialogue()
                return
        
        var node = current_dialogue[current_node_id]
        var lang = _get_language()
        
        var speaker_label = dialogue_ui.get_node("DialoguePanel/VBox/SpeakerLabel")
        var text_label = dialogue_ui.get_node("DialoguePanel/VBox/TextLabel")
        var choices_container = dialogue_ui.get_node("DialoguePanel/VBox/ChoicesContainer")
        var close_btn = dialogue_ui.get_node("DialoguePanel/VBox/CloseButton")
        
        speaker_label.text = node.get("speaker", "???")
        
        var text_key = "text_" + lang
        text_label.text = node.get(text_key, node.get("text_ru", "..."))
        
        emit_signal("dialogue_line_shown", text_label.text, speaker_label.text)
        
        for child in choices_container.get_children():
                child.queue_free()
        
        if node.has("action"):
                _execute_action(node["action"])
        
        if node.has("choices"):
                close_btn.visible = false
                for choice in node["choices"]:
                        var btn = Button.new()
                        var choice_text_key = "text_" + lang
                        btn.text = choice.get(choice_text_key, choice.get("text_ru", "..."))
                        btn.custom_minimum_size = Vector2(0, 35)
                        btn.pressed.connect(_on_choice_selected.bind(choice))
                        choices_container.add_child(btn)
        elif node.has("next"):
                if node["next"] == "end":
                        close_btn.visible = true
                        close_btn.text = "Закрыть" if lang == "ru" else "Close"
                else:
                        var continue_btn = Button.new()
                        continue_btn.text = "Продолжить" if lang == "ru" else "Continue"
                        continue_btn.custom_minimum_size = Vector2(0, 35)
                        continue_btn.pressed.connect(_on_continue_pressed.bind(node["next"]))
                        choices_container.add_child(continue_btn)
        else:
                close_btn.visible = true
                close_btn.text = "Закрыть" if lang == "ru" else "Close"

func _on_choice_selected(choice: Dictionary):
        emit_signal("choice_selected", choice.get("id", ""))
        
        if choice.has("action"):
                _execute_action(choice["action"])
        
        if choice.has("next"):
                if choice["next"] == "end":
                        end_dialogue()
                else:
                        current_node_id = choice["next"]
                        _show_current_node()
        else:
                end_dialogue()

func _on_continue_pressed(next_node: String):
        if next_node == "end":
                end_dialogue()
        else:
                current_node_id = next_node
                _show_current_node()

func _on_close_pressed():
        end_dialogue()

func _execute_action(action: String):
        var parts = action.split(":")
        var action_type = parts[0]
        var action_param = parts[1] if parts.size() > 1 else ""
        
        match action_type:
                "open_trade":
                        if current_npc and current_npc.has_method("open_trade"):
                                call_deferred("_open_trade_deferred")
                
                "offer_quest":
                        var quest_system = get_node_or_null("/root/QuestSystem")
                        if quest_system and quest_system.has_method("can_start_quest"):
                                pass
                
                "start_quest":
                        var quest_system = get_node_or_null("/root/QuestSystem")
                        if quest_system and quest_system.has_method("start_quest"):
                                quest_system.start_quest(action_param)
                
                "complete_quest":
                        var quest_system = get_node_or_null("/root/QuestSystem")
                        if quest_system and quest_system.has_method("complete_quest"):
                                quest_system.complete_quest(action_param)
                
                "reputation":
                        var faction_system = get_node_or_null("/root/FactionSystem")
                        if faction_system and current_npc:
                                var faction = "town"
                                if current_npc.has_method("get") and current_npc.get("faction"):
                                        faction = current_npc.faction
                                var amount = int(action_param)
                                if faction_system.has_method("modify_relation"):
                                        faction_system.modify_relation("player", faction, amount)
                
                "give_item":
                        var inv = get_node_or_null("/root/Inventory")
                        if inv and inv.has_method("add_item"):
                                inv.add_item(action_param, 1, 1.0)
                
                "heal_player":
                        var players = get_tree().get_nodes_in_group("players")
                        if players.size() > 0:
                                var player = players[0]
                                if player.has_method("heal"):
                                        if action_param == "full":
                                                player.heal(player.max_health if player.has("max_health") else 100)
                                        else:
                                                player.heal(int(action_param))
                
                "buff":
                        var parts2 = action_param.split(":")
                        if parts2.size() >= 2:
                                var buff_type = parts2[0]
                                var duration = float(parts2[1])
                                var debuff_sys = get_node_or_null("/root/DebuffSystem")
                                if debuff_sys and debuff_sys.has_method("apply_buff"):
                                        var players = get_tree().get_nodes_in_group("players")
                                        if players.size() > 0:
                                                debuff_sys.apply_buff(players[0], buff_type, duration)
                
                "reveal_location":
                        var notif = get_node_or_null("/root/NotificationSystem")
                        if notif:
                                notif.show_notification("Новая локация открыта: " + action_param, "info")
                
                "buy_item":
                        var item_parts = action_param.split(":")
                        if item_parts.size() >= 2:
                                var item_id = item_parts[0]
                                var cost = int(item_parts[1])
                                var inv = get_node_or_null("/root/Inventory")
                                if inv:
                                        if inv.has_method("get_gold") and inv.get_gold() >= cost:
                                                inv.remove_gold(cost)
                                                inv.add_item(item_id, 1, 1.0)
                                                var notif = get_node_or_null("/root/NotificationSystem")
                                                if notif:
                                                        notif.show_notification("Куплено: " + item_id, "success")
                                        else:
                                                var notif = get_node_or_null("/root/NotificationSystem")
                                                if notif:
                                                        notif.show_notification("Недостаточно золота!", "error")
                
                "rest_at_inn":
                        var cost = int(action_param)
                        var inv = get_node_or_null("/root/Inventory")
                        if inv and inv.has_method("get_gold") and inv.get_gold() >= cost:
                                inv.remove_gold(cost)
                                var players = get_tree().get_nodes_in_group("players")
                                if players.size() > 0:
                                        var player = players[0]
                                        if player.has_method("heal"):
                                                player.heal(9999)
                                        if player.has_method("restore_stamina"):
                                                player.restore_stamina(9999)
                                var notif = get_node_or_null("/root/NotificationSystem")
                                if notif:
                                        notif.show_notification("Вы отдохнули и восстановили силы", "success")
                
                "repair_all":
                        var inv = get_node_or_null("/root/Inventory")
                        if inv and inv.has_method("repair_all_items"):
                                inv.repair_all_items()
                        var notif = get_node_or_null("/root/NotificationSystem")
                        if notif:
                                notif.show_notification("Снаряжение отремонтировано", "success")

func _open_trade_deferred():
        end_dialogue()
        if current_npc and current_npc.has_method("open_trade"):
                current_npc.open_trade()

func end_dialogue():
        is_active = false
        dialogue_ui.visible = false
        
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
        
        current_npc = null
        current_dialogue = {}
        current_node_id = ""
        
        emit_signal("dialogue_ended")

func _get_language() -> String:
        var settings = get_node_or_null("/root/SettingsManager")
        if settings and settings.has_method("get_current_language"):
                return settings.get_current_language()
        return "ru"

func add_dialogue(dialogue_id: String, dialogue_data: Dictionary):
        dialogues[dialogue_id] = dialogue_data

func has_dialogue(dialogue_id: String) -> bool:
        return dialogues.has(dialogue_id)

func _input(event):
        if not is_active:
                return
        
        if event.is_action_pressed("ui_cancel"):
                end_dialogue()
                get_viewport().set_input_as_handled()
