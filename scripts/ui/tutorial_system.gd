extends Node

signal tutorial_step_completed(step_id: String)
signal tutorial_completed()
signal tutorial_started()

var is_active := false
var current_step := 0
var tutorial_steps := []
var completed_steps := {}
var tutorial_ui: Control = null

var default_steps := [
        {
                "id": "welcome",
                "title": "Добро пожаловать!",
                "text": "Добро пожаловать в «Эпоха Поселений»!\n\nЭто игра о выживании, строительстве и развитии поселений.",
                "condition": "none",
                "highlight": ""
        },
        {
                "id": "movement",
                "title": "Передвижение",
                "text": "Используйте клавиши WASD для передвижения.\n\nW — вперёд\nS — назад\nA — влево\nD — вправо",
                "condition": "move",
                "highlight": ""
        },
        {
                "id": "look",
                "title": "Осмотр",
                "text": "Двигайте мышь, чтобы осматриваться вокруг.",
                "condition": "look",
                "highlight": ""
        },
        {
                "id": "jump",
                "title": "Прыжок",
                "text": "Нажмите ПРОБЕЛ, чтобы прыгнуть.\n\nВы можете прыгнуть дважды в воздухе!",
                "condition": "jump",
                "highlight": ""
        },
        {
                "id": "sprint",
                "title": "Бег",
                "text": "Удерживайте SHIFT во время движения, чтобы бежать.\n\nБег расходует выносливость.",
                "condition": "sprint",
                "highlight": "stamina"
        },
        {
                "id": "crouch",
                "title": "Присесть",
                "text": "Нажмите CTRL, чтобы присесть.\n\nПрисев, вы двигаетесь тише.",
                "condition": "crouch",
                "highlight": ""
        },
        {
                "id": "stats",
                "title": "Статы выживания",
                "text": "Следите за показателями:\n\n❤ Здоровье\n⚡ Выносливость\n🍖 Голод\n💧 Жажда\n🩸 Кровь\n🧠 Рассудок",
                "condition": "none",
                "highlight": "stats"
        },
        {
                "id": "inventory",
                "title": "Инвентарь",
                "text": "Нажмите I, чтобы открыть инвентарь.\n\nЗдесь вы управляете предметами и экипировкой.",
                "condition": "open_inventory",
                "highlight": ""
        },
        {
                "id": "hotbar",
                "title": "Быстрый доступ",
                "text": "Используйте клавиши 1-8 для быстрого выбора предметов.\n\nПеретащите предметы из инвентаря на панель быстрого доступа.",
                "condition": "none",
                "highlight": "hotbar"
        },
        {
                "id": "interact",
                "title": "Взаимодействие",
                "text": "Нажмите E, чтобы взаимодействовать с объектами.\n\nПодойдите к ресурсам и нажмите E для сбора.",
                "condition": "interact",
                "highlight": ""
        },
        {
                "id": "attack",
                "title": "Атака",
                "text": "Нажмите ЛКМ (левая кнопка мыши), чтобы атаковать.\n\nВозьмите оружие для большего урона.",
                "condition": "attack",
                "highlight": ""
        },
        {
                "id": "craft",
                "title": "Крафт",
                "text": "Нажмите C, чтобы открыть меню крафта.\n\nСоздавайте инструменты, оружие и строительные материалы.",
                "condition": "none",
                "highlight": ""
        },
        {
                "id": "build",
                "title": "Строительство",
                "text": "Нажмите B, чтобы открыть меню строительства.\n\nПостройте укрытие для защиты от врагов и непогоды.",
                "condition": "none",
                "highlight": ""
        },
        {
                "id": "food",
                "title": "Питание",
                "text": "Ешьте еду для восполнения голода.\n\nВыберите еду и нажмите ПКМ или перетащите в быстрый слот и нажмите F.",
                "condition": "none",
                "highlight": "hunger"
        },
        {
                "id": "save",
                "title": "Сохранение",
                "text": "F5 — быстрое сохранение\nF9 — быстрая загрузка\n\nИгра также сохраняется автоматически каждые 5 минут.",
                "condition": "none",
                "highlight": ""
        },
        {
                "id": "complete",
                "title": "Туториал завершён!",
                "text": "Вы изучили основы выживания!\n\nТеперь исследуйте мир, собирайте ресурсы и постройте своё поселение.\n\nУдачи!",
                "condition": "none",
                "highlight": ""
        }
]

var conditions_met := {
        "move": false,
        "look": false,
        "jump": false,
        "sprint": false,
        "crouch": false,
        "open_inventory": false,
        "interact": false,
        "attack": false
}

func _ready():
        tutorial_steps = default_steps.duplicate(true)
        _load_progress()

func start_tutorial():
        if is_active:
                return
        
        is_active = true
        current_step = 0
        completed_steps.clear()
        conditions_met = {
                "move": false,
                "look": false,
                "jump": false,
                "sprint": false,
                "crouch": false,
                "open_inventory": false,
                "interact": false,
                "attack": false
        }
        
        emit_signal("tutorial_started")
        _show_step(current_step)

func skip_tutorial():
        is_active = false
        current_step = tutorial_steps.size()
        _hide_ui()
        emit_signal("tutorial_completed")

func next_step():
        if not is_active:
                return
        
        if current_step < tutorial_steps.size():
                var step = tutorial_steps[current_step]
                completed_steps[step["id"]] = true
                emit_signal("tutorial_step_completed", step["id"])
        
        current_step += 1
        
        if current_step >= tutorial_steps.size():
                _complete_tutorial()
        else:
                _show_step(current_step)

func previous_step():
        if current_step > 0:
                current_step -= 1
                _show_step(current_step)

func _complete_tutorial():
        is_active = false
        _save_progress()
        _hide_ui()
        emit_signal("tutorial_completed")
        
        var notif = get_node_or_null("/root/NotificationSystem")
        if notif:
                notif.show_notification("Туториал завершён!", "success")

func _show_step(step_index: int):
        if step_index < 0 or step_index >= tutorial_steps.size():
                return
        
        var step = tutorial_steps[step_index]
        
        if not tutorial_ui:
                _create_tutorial_ui()
        
        tutorial_ui.visible = true
        _update_ui(step)

func _hide_ui():
        if tutorial_ui:
                tutorial_ui.visible = false

func _create_tutorial_ui():
        tutorial_ui = Control.new()
        tutorial_ui.name = "TutorialUI"
        tutorial_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
        tutorial_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
        
        var panel = Panel.new()
        panel.name = "Panel"
        panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
        panel.offset_left = -250
        panel.offset_top = -200
        panel.offset_right = 250
        panel.offset_bottom = -20
        
        var style = StyleBoxFlat.new()
        style.bg_color = Color(0.1, 0.1, 0.12, 0.95)
        style.border_color = Color(0.6, 0.5, 0.3, 0.8)
        style.set_border_width_all(2)
        style.set_corner_radius_all(8)
        style.set_content_margin_all(15)
        panel.add_theme_stylebox_override("panel", style)
        
        var vbox = VBoxContainer.new()
        vbox.name = "VBox"
        vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
        vbox.offset_left = 15
        vbox.offset_top = 15
        vbox.offset_right = -15
        vbox.offset_bottom = -15
        
        var title_label = Label.new()
        title_label.name = "TitleLabel"
        title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        title_label.add_theme_font_size_override("font_size", 20)
        title_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.7))
        
        var text_label = Label.new()
        text_label.name = "TextLabel"
        text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
        text_label.add_theme_font_size_override("font_size", 14)
        
        var progress_label = Label.new()
        progress_label.name = "ProgressLabel"
        progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        progress_label.add_theme_font_size_override("font_size", 12)
        progress_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
        
        var button_container = HBoxContainer.new()
        button_container.name = "Buttons"
        button_container.alignment = BoxContainer.ALIGNMENT_CENTER
        button_container.add_theme_constant_override("separation", 20)
        
        var skip_btn = Button.new()
        skip_btn.name = "SkipButton"
        skip_btn.text = "Пропустить"
        skip_btn.pressed.connect(skip_tutorial)
        
        var next_btn = Button.new()
        next_btn.name = "NextButton"
        next_btn.text = "Далее →"
        next_btn.pressed.connect(next_step)
        
        button_container.add_child(skip_btn)
        button_container.add_child(next_btn)
        
        vbox.add_child(title_label)
        vbox.add_child(text_label)
        vbox.add_child(progress_label)
        vbox.add_child(button_container)
        
        panel.add_child(vbox)
        tutorial_ui.add_child(panel)
        
        var canvas = CanvasLayer.new()
        canvas.layer = 100
        canvas.add_child(tutorial_ui)
        add_child(canvas)

func _update_ui(step: Dictionary):
        if not tutorial_ui:
                return
        
        var panel = tutorial_ui.get_node("Panel")
        var vbox = panel.get_node("VBox")
        
        var title_label = vbox.get_node("TitleLabel")
        var text_label = vbox.get_node("TextLabel")
        var progress_label = vbox.get_node("ProgressLabel")
        var next_btn = vbox.get_node("Buttons/NextButton")
        
        title_label.text = step["title"]
        text_label.text = step["text"]
        progress_label.text = "Шаг %d из %d" % [current_step + 1, tutorial_steps.size()]
        
        if step["condition"] == "none":
                next_btn.text = "Далее →"
                next_btn.disabled = false
        else:
                next_btn.text = "Выполните действие..."
                next_btn.disabled = not conditions_met.get(step["condition"], false)

func _process(delta):
        if not is_active or current_step >= tutorial_steps.size():
                return
        
        _check_player_input()
        
        var step = tutorial_steps[current_step]
        var condition = step.get("condition", "none")
        
        if condition != "none" and conditions_met.get(condition, false):
                _update_ui(step)

func _check_player_input():
        if Input.is_action_pressed("move_forward") or Input.is_action_pressed("move_back") or Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right"):
                conditions_met["move"] = true
        
        if Input.is_action_pressed("sprint"):
                conditions_met["sprint"] = true
        
        if Input.is_action_pressed("crouch"):
                conditions_met["crouch"] = true
        
        if Input.is_action_just_pressed("jump"):
                conditions_met["jump"] = true
        
        if Input.is_action_just_pressed("attack"):
                conditions_met["attack"] = true
        
        if Input.is_action_just_pressed("interact"):
                conditions_met["interact"] = true
        
        if Input.is_action_just_pressed("inventory"):
                conditions_met["open_inventory"] = true
        
        var mouse_motion = Input.get_last_mouse_velocity()
        if mouse_motion.length() > 10:
                conditions_met["look"] = true

func on_player_moved():
        conditions_met["move"] = true

func on_player_looked():
        conditions_met["look"] = true

func on_player_jumped():
        conditions_met["jump"] = true

func on_player_sprinted():
        conditions_met["sprint"] = true

func on_player_crouched():
        conditions_met["crouch"] = true

func on_inventory_opened():
        conditions_met["open_inventory"] = true

func on_player_interacted():
        conditions_met["interact"] = true

func on_player_attacked():
        conditions_met["attack"] = true

func _save_progress():
        var config = ConfigFile.new()
        config.set_value("tutorial", "completed", true)
        config.set_value("tutorial", "completed_steps", completed_steps)
        config.save("user://tutorial_progress.cfg")

func _load_progress():
        var config = ConfigFile.new()
        var err = config.load("user://tutorial_progress.cfg")
        if err == OK:
                completed_steps = config.get_value("tutorial", "completed_steps", {})

func has_completed_tutorial() -> bool:
        var config = ConfigFile.new()
        var err = config.load("user://tutorial_progress.cfg")
        if err == OK:
                return config.get_value("tutorial", "completed", false)
        return false

func reset_tutorial():
        var config = ConfigFile.new()
        config.set_value("tutorial", "completed", false)
        config.set_value("tutorial", "completed_steps", {})
        config.save("user://tutorial_progress.cfg")
        completed_steps.clear()
