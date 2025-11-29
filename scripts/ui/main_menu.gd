extends Control

@onready var multiplayer_panel = $MultiplayerPanel
@onready var settings_panel = $SettingsPanel
@onready var main_buttons = $VBoxContainer
@onready var ip_input = $MultiplayerPanel/VBox/IPInput
@onready var lang_option = $SettingsPanel/VBox/LangOption
@onready var sens_slider = $SettingsPanel/VBox/SensSlider
@onready var sens_value = $SettingsPanel/VBox/SensValue

var current_sensitivity := 0.06

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_setup_language_options()
	_load_settings()
	sens_slider.value_changed.connect(_on_sens_changed)

func _setup_language_options():
	lang_option.clear()
	lang_option.add_item("English", 0)
	lang_option.add_item("Русский", 1)
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		var lang = gm.get_language()
		if lang == "ru":
			lang_option.select(1)
		else:
			lang_option.select(0)

func _load_settings():
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		var lang = gm.get_language()
		_update_ui_language(lang)
		if gm.get("mouse_sensitivity") != null:
			current_sensitivity = gm.mouse_sensitivity
			sens_slider.value = current_sensitivity
			sens_value.text = str(snapped(current_sensitivity, 0.01))

func _on_sens_changed(value: float):
	current_sensitivity = value
	sens_value.text = str(snapped(value, 0.01))

func _update_ui_language(lang: String):
	if lang == "ru":
		$VBoxContainer/StartButton.text = "Начать игру"
		$VBoxContainer/MultiplayerButton.text = "Мультиплеер"
		$VBoxContainer/SettingsButton.text = "Настройки"
		$VBoxContainer/QuitButton.text = "Выход"
		$MultiplayerPanel/VBox/Title.text = "Мультиплеер"
		$MultiplayerPanel/VBox/HostButton.text = "Создать сервер"
		$MultiplayerPanel/VBox/JoinButton.text = "Подключиться"
		$MultiplayerPanel/VBox/BackButton.text = "Назад"
		$SettingsPanel/VBox/Title.text = "Настройки"
		$SettingsPanel/VBox/LangLabel.text = "Язык:"
		$SettingsPanel/VBox/SensLabel.text = "Чувствительность мыши:"
		$SettingsPanel/VBox/BackButton.text = "Назад"
	else:
		$VBoxContainer/StartButton.text = "Start Game"
		$VBoxContainer/MultiplayerButton.text = "Multiplayer"
		$VBoxContainer/SettingsButton.text = "Settings"
		$VBoxContainer/QuitButton.text = "Quit"
		$MultiplayerPanel/VBox/Title.text = "Multiplayer"
		$MultiplayerPanel/VBox/HostButton.text = "Host Server"
		$MultiplayerPanel/VBox/JoinButton.text = "Join Server"
		$MultiplayerPanel/VBox/BackButton.text = "Back"
		$SettingsPanel/VBox/Title.text = "Settings"
		$SettingsPanel/VBox/LangLabel.text = "Language:"
		$SettingsPanel/VBox/SensLabel.text = "Mouse Sensitivity:"
		$SettingsPanel/VBox/BackButton.text = "Back"

func _on_start_pressed():
	_save_settings()
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_multiplayer_pressed():
	main_buttons.visible = false
	multiplayer_panel.visible = true

func _on_settings_pressed():
	main_buttons.visible = false
	settings_panel.visible = true

func _on_quit_pressed():
	get_tree().quit()

func _on_host_pressed():
	_save_settings()
	var net = get_node_or_null("/root/Network")
	if net:
		net.host(7777)
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_join_pressed():
	_save_settings()
	var ip = ip_input.text if ip_input.text != "" else "127.0.0.1"
	var net = get_node_or_null("/root/Network")
	if net:
		net.join(ip, 7777)
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_mp_back_pressed():
	multiplayer_panel.visible = false
	main_buttons.visible = true

func _on_settings_back_pressed():
	_save_settings()
	settings_panel.visible = false
	main_buttons.visible = true

func _save_settings():
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		var lang = "en" if lang_option.selected == 0 else "ru"
		gm.set_language(lang)
		gm.mouse_sensitivity = current_sensitivity
		_update_ui_language(lang)
