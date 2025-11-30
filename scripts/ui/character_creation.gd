extends Control

signal character_created(character_data)

@onready var nickname_input: LineEdit = $VBoxContainer/NicknameSection/NicknameInput
@onready var gender_option: OptionButton = $VBoxContainer/GenderSection/GenderOption
@onready var hair_slider: HSlider = $VBoxContainer/AppearanceSection/HairSlider
@onready var skin_slider: HSlider = $VBoxContainer/AppearanceSection/SkinSlider
@onready var create_button: Button = $VBoxContainer/CreateButton
@onready var back_button: Button = $VBoxContainer/BackButton
@onready var preview_viewport: SubViewport = $PreviewPanel/SubViewportContainer/SubViewport
@onready var error_label: Label = $VBoxContainer/ErrorLabel
@onready var character_preview: Node3D = null

var current_model: Node3D = null
var rotation_speed := 0.5
var model_rotation := 0.0

var character_data := {
        "nickname": "",
        "gender": "male",
        "hair_style": 0,
        "skin_tone": 0,
        "hair_color": Color(0.3, 0.2, 0.1),
        "eye_color": Color(0.4, 0.3, 0.2)
}

var hair_colors := [
        Color(0.1, 0.08, 0.05),
        Color(0.3, 0.2, 0.1),
        Color(0.5, 0.35, 0.2),
        Color(0.7, 0.5, 0.3),
        Color(0.9, 0.8, 0.6),
        Color(0.6, 0.3, 0.15),
        Color(0.2, 0.1, 0.1),
        Color(0.5, 0.5, 0.5)
]

var skin_tones := [
        Color(1.0, 0.87, 0.77),
        Color(0.96, 0.8, 0.69),
        Color(0.87, 0.72, 0.53),
        Color(0.76, 0.57, 0.42),
        Color(0.6, 0.46, 0.33),
        Color(0.45, 0.32, 0.22)
]

func _ready():
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
        _apply_rust_theme()
        _setup_options()
        _connect_signals()
        _update_ui_language()
        
        if error_label:
                error_label.visible = false
        
        if preview_viewport:
                character_preview = preview_viewport.get_node_or_null("CharacterPreview")
        
        call_deferred("_load_character_model")

func _process(delta):
        if current_model:
                model_rotation += rotation_speed * delta
                current_model.rotation.y = model_rotation

func _apply_rust_theme():
        var bg = ColorRect.new()
        bg.name = "BackgroundOverlay"
        bg.color = Color(0.08, 0.06, 0.05, 0.95)
        bg.set_anchors_preset(Control.PRESET_FULL_RECT)
        bg.z_index = -10
        add_child(bg)
        move_child(bg, 0)
        
        var button_style = StyleBoxFlat.new()
        button_style.bg_color = Color(0.2, 0.15, 0.1, 0.9)
        button_style.border_color = Color(0.5, 0.35, 0.2)
        button_style.set_border_width_all(2)
        button_style.set_corner_radius_all(4)
        button_style.set_content_margin_all(12)
        
        var hover_style = StyleBoxFlat.new()
        hover_style.bg_color = Color(0.3, 0.2, 0.15, 0.95)
        hover_style.border_color = Color(0.7, 0.5, 0.3)
        hover_style.set_border_width_all(2)
        hover_style.set_corner_radius_all(4)
        hover_style.set_content_margin_all(12)
        
        for button in [create_button, back_button]:
                if button:
                        button.add_theme_stylebox_override("normal", button_style)
                        button.add_theme_stylebox_override("hover", hover_style)
                        button.add_theme_color_override("font_color", Color(0.9, 0.85, 0.75))
                        button.add_theme_font_size_override("font_size", 18)
        
        if nickname_input:
                var input_style = StyleBoxFlat.new()
                input_style.bg_color = Color(0.15, 0.12, 0.1, 0.9)
                input_style.border_color = Color(0.4, 0.3, 0.2)
                input_style.set_border_width_all(1)
                input_style.set_corner_radius_all(3)
                input_style.set_content_margin_all(8)
                nickname_input.add_theme_stylebox_override("normal", input_style)
                nickname_input.add_theme_color_override("font_color", Color(0.9, 0.85, 0.75))

func _setup_options():
        if gender_option:
                gender_option.clear()
                gender_option.add_item("Мужской / Male", 0)
                gender_option.add_item("Женский / Female", 1)
        
        if hair_slider:
                hair_slider.min_value = 0
                hair_slider.max_value = len(hair_colors) - 1
                hair_slider.step = 1
                hair_slider.value = 1
        
        if skin_slider:
                skin_slider.min_value = 0
                skin_slider.max_value = len(skin_tones) - 1
                skin_slider.step = 1
                skin_slider.value = 1

func _connect_signals():
        if nickname_input:
                nickname_input.text_changed.connect(_on_nickname_changed)
        if gender_option:
                gender_option.item_selected.connect(_on_gender_selected)
        if hair_slider:
                hair_slider.value_changed.connect(_on_hair_changed)
        if skin_slider:
                skin_slider.value_changed.connect(_on_skin_changed)
        if create_button:
                create_button.pressed.connect(_on_create_pressed)
        if back_button:
                back_button.pressed.connect(_on_back_pressed)

func _update_ui_language():
        var gm = get_node_or_null("/root/GameManager")
        var lang = "ru"
        if gm:
                lang = gm.get_language()
        
        if lang == "ru":
                $VBoxContainer/TitleLabel.text = "СОЗДАНИЕ ПЕРСОНАЖА"
                $VBoxContainer/NicknameSection/NicknameLabel.text = "Имя персонажа:"
                $VBoxContainer/GenderSection/GenderLabel.text = "Пол:"
                $VBoxContainer/AppearanceSection/HairLabel.text = "Цвет волос:"
                $VBoxContainer/AppearanceSection/SkinLabel.text = "Тон кожи:"
                create_button.text = "Создать персонажа"
                back_button.text = "Назад"
                nickname_input.placeholder_text = "Введите имя..."
        else:
                $VBoxContainer/TitleLabel.text = "CHARACTER CREATION"
                $VBoxContainer/NicknameSection/NicknameLabel.text = "Character Name:"
                $VBoxContainer/GenderSection/GenderLabel.text = "Gender:"
                $VBoxContainer/AppearanceSection/HairLabel.text = "Hair Color:"
                $VBoxContainer/AppearanceSection/SkinLabel.text = "Skin Tone:"
                create_button.text = "Create Character"
                back_button.text = "Back"
                nickname_input.placeholder_text = "Enter name..."

func _on_nickname_changed(new_text: String):
        character_data["nickname"] = new_text.strip_edges()
        _validate_nickname()

func _on_gender_selected(index: int):
        character_data["gender"] = "male" if index == 0 else "female"
        _update_preview()

func _on_hair_changed(value: float):
        var idx = int(value)
        character_data["hair_style"] = idx
        character_data["hair_color"] = hair_colors[idx]
        _update_preview()

func _on_skin_changed(value: float):
        var idx = int(value)
        character_data["skin_tone"] = idx
        _update_preview()

func _update_preview():
        _load_character_model()

func _load_character_model():
        if not character_preview:
                return
        
        if current_model:
                current_model.queue_free()
                current_model = null
        
        var model_path := ""
        if character_data["gender"] == "female":
                model_path = "res://assets/art_pack2/Characters/Base Characters/Godot/Superhero_Female.gltf"
        else:
                model_path = "res://assets/art_pack2/Characters/Base Characters/Godot/Superhero_Male.gltf"
        
        if not ResourceLoader.exists(model_path):
                _create_placeholder_model()
                return
        
        var scene = load(model_path)
        if scene:
                current_model = scene.instantiate()
                character_preview.add_child(current_model)
                current_model.scale = Vector3(1.0, 1.0, 1.0)
                current_model.position = Vector3(0, 0, 0)
                _apply_skin_tone()
        else:
                _create_placeholder_model()

func _create_placeholder_model():
        if not character_preview:
                return
        
        current_model = Node3D.new()
        character_preview.add_child(current_model)
        
        var body = MeshInstance3D.new()
        var capsule = CapsuleMesh.new()
        capsule.radius = 0.3
        capsule.height = 1.6
        body.mesh = capsule
        body.position.y = 0.8
        
        var material = StandardMaterial3D.new()
        material.albedo_color = skin_tones[character_data["skin_tone"]]
        body.material_override = material
        
        current_model.add_child(body)
        
        var head = MeshInstance3D.new()
        var sphere = SphereMesh.new()
        sphere.radius = 0.2
        head.mesh = sphere
        head.position.y = 1.7
        
        var head_mat = StandardMaterial3D.new()
        head_mat.albedo_color = skin_tones[character_data["skin_tone"]]
        head.material_override = head_mat
        
        current_model.add_child(head)
        
        var hair = MeshInstance3D.new()
        var hair_mesh = SphereMesh.new()
        hair_mesh.radius = 0.22
        hair.mesh = hair_mesh
        hair.position.y = 1.8
        
        var hair_mat = StandardMaterial3D.new()
        hair_mat.albedo_color = hair_colors[character_data["hair_style"]]
        hair.material_override = hair_mat
        
        current_model.add_child(hair)

func _apply_skin_tone():
        if not current_model:
                return
        
        var skin_color = skin_tones[character_data["skin_tone"]]
        
        for child in current_model.get_children():
                if child is MeshInstance3D:
                        var mat = child.get_surface_override_material(0)
                        if mat == null:
                                mat = child.mesh.surface_get_material(0) if child.mesh else null
                        if mat and mat is StandardMaterial3D:
                                var new_mat = mat.duplicate()
                                new_mat.albedo_color = skin_color
                                child.set_surface_override_material(0, new_mat)

func _validate_nickname() -> bool:
        var nickname = character_data["nickname"]
        
        if nickname.length() < 2:
                _show_error("Имя должно быть минимум 2 символа / Name must be at least 2 characters")
                return false
        
        if nickname.length() > 20:
                _show_error("Имя не должно превышать 20 символов / Name must not exceed 20 characters")
                return false
        
        var regex = RegEx.new()
        regex.compile("^[a-zA-Zа-яА-ЯёЁ0-9_\\- ]+$")
        if not regex.search(nickname):
                _show_error("Имя содержит недопустимые символы / Name contains invalid characters")
                return false
        
        _hide_error()
        return true

func _show_error(message: String):
        if error_label:
                error_label.text = message
                error_label.visible = true
                error_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))

func _hide_error():
        if error_label:
                error_label.visible = false

func _on_create_pressed():
        if not _validate_nickname():
                return
        
        var gm = get_node_or_null("/root/GameManager")
        if gm:
                gm.set_player_character(character_data)
        
        emit_signal("character_created", character_data)
        get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_back_pressed():
        get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
