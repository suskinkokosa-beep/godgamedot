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
                                {"id": "bye", "text_ru": "Всего хорошего", "text_en": "Take care", "next": "end"}
                        ]
                },
                "news": {
                        "speaker": "Житель",
                        "text_ru": "Слышал, на востоке видели волков. Будь осторожен!",
                        "text_en": "I heard wolves were spotted to the east. Be careful!",
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
                        if faction_system and current_npc and faction_system.has_method("add_reputation"):
                                var faction = current_npc.get("faction") if current_npc else "neutral"
                                var amount = int(action_param)
                                faction_system.add_reputation(faction, amount)
                
                "give_item":
                        var inv = get_node_or_null("/root/Inventory")
                        if inv and inv.has_method("add_item"):
                                inv.add_item(action_param, 1, 1.0)

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
