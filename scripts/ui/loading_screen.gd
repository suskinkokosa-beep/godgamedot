extends CanvasLayer

signal loading_complete()

@onready var background = $Background
@onready var title_label = $TitleLabel
@onready var tip_label = $TipLabel
@onready var progress_bar = $ProgressBar
@onready var progress_label = $ProgressLabel
@onready var icon_label = $IconLabel

var tips := [
	"Постройте укрытие до наступления ночи",
	"Следите за голодом и жаждой - они влияют на выносливость",
	"Костёр согреет вас и отпугнёт хищников",
	"Торговцы продают редкие ресурсы и рецепты",
	"Высокая репутация с фракцией открывает новые возможности",
	"Комбо-атаки наносят больше урона",
	"Крафтите инструменты для добычи лучших ресурсов",
	"Исследуйте руины - там можно найти ценный лут",
	"Ночью враги становятся агрессивнее",
	"Стройте верстаки для создания продвинутого снаряжения",
	"Блокируйте атаки врагов для уменьшения урона",
	"Выполняйте квесты для получения опыта и наград",
	"Ваша температура тела влияет на здоровье",
	"Стаи волков охотятся вместе - будьте осторожны",
	"Сохраняйтесь регулярно с помощью F5",
	"Изучайте биомы - в каждом уникальные ресурсы",
	"Улучшайте навыки для бонусов к действиям",
	"Парируйте в нужный момент для контратаки",
	"Медведи защищают свою территорию",
	"Собирайте травы для создания лекарств"
]

var loading_icons := [".", "..", "...", "....", ".....", "......"]
var icon_index := 0
var icon_timer := 0.0

var current_progress := 0.0
var target_progress := 0.0
var tip_timer := 0.0
var tip_change_interval := 5.0

func _ready():
	_setup_ui()
	_show_random_tip()

func _setup_ui():
	layer = 100
	
	if not background:
		background = ColorRect.new()
		background.name = "Background"
		background.color = Color(0.08, 0.06, 0.05, 1.0)
		background.anchor_right = 1.0
		background.anchor_bottom = 1.0
		add_child(background)
	
	if not title_label:
		title_label = Label.new()
		title_label.name = "TitleLabel"
		title_label.text = "EPOCH SETTLEMENTS"
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_label.add_theme_font_size_override("font_size", 48)
		title_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.6))
		title_label.anchor_left = 0.5
		title_label.anchor_right = 0.5
		title_label.anchor_top = 0.3
		title_label.offset_left = -200
		title_label.offset_right = 200
		add_child(title_label)
	
	if not icon_label:
		icon_label = Label.new()
		icon_label.name = "IconLabel"
		icon_label.text = "..."
		icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_label.add_theme_font_size_override("font_size", 24)
		icon_label.add_theme_color_override("font_color", Color(0.7, 0.6, 0.5))
		icon_label.anchor_left = 0.5
		icon_label.anchor_right = 0.5
		icon_label.anchor_top = 0.45
		icon_label.offset_left = -50
		icon_label.offset_right = 50
		add_child(icon_label)
	
	if not progress_bar:
		progress_bar = ProgressBar.new()
		progress_bar.name = "ProgressBar"
		progress_bar.max_value = 100
		progress_bar.value = 0
		progress_bar.show_percentage = false
		progress_bar.anchor_left = 0.25
		progress_bar.anchor_right = 0.75
		progress_bar.anchor_top = 0.55
		progress_bar.offset_top = 0
		progress_bar.offset_bottom = 20
		progress_bar.custom_minimum_size = Vector2(0, 12)
		
		var bar_style = StyleBoxFlat.new()
		bar_style.bg_color = Color(0.4, 0.35, 0.25)
		bar_style.set_corner_radius_all(4)
		progress_bar.add_theme_stylebox_override("fill", bar_style)
		
		var bg_style = StyleBoxFlat.new()
		bg_style.bg_color = Color(0.15, 0.12, 0.1)
		bg_style.set_corner_radius_all(4)
		progress_bar.add_theme_stylebox_override("background", bg_style)
		add_child(progress_bar)
	
	if not progress_label:
		progress_label = Label.new()
		progress_label.name = "ProgressLabel"
		progress_label.text = "Загрузка..."
		progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		progress_label.add_theme_font_size_override("font_size", 16)
		progress_label.add_theme_color_override("font_color", Color(0.8, 0.75, 0.65))
		progress_label.anchor_left = 0.25
		progress_label.anchor_right = 0.75
		progress_label.anchor_top = 0.55
		progress_label.offset_top = 30
		add_child(progress_label)
	
	if not tip_label:
		tip_label = Label.new()
		tip_label.name = "TipLabel"
		tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tip_label.add_theme_font_size_override("font_size", 18)
		tip_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.5))
		tip_label.anchor_left = 0.15
		tip_label.anchor_right = 0.85
		tip_label.anchor_top = 0.75
		tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		add_child(tip_label)

func _process(delta):
	icon_timer += delta
	if icon_timer >= 0.3:
		icon_timer = 0.0
		icon_index = (icon_index + 1) % loading_icons.size()
		if icon_label:
			icon_label.text = loading_icons[icon_index]
	
	tip_timer += delta
	if tip_timer >= tip_change_interval:
		tip_timer = 0.0
		_show_random_tip()
	
	current_progress = lerp(current_progress, target_progress, delta * 5.0)
	if progress_bar:
		progress_bar.value = current_progress

func _show_random_tip():
	if tip_label and tips.size() > 0:
		tip_label.text = "TIP: " + tips[randi() % tips.size()]

func set_progress(progress: float, message: String = ""):
	target_progress = clamp(progress, 0.0, 100.0)
	if progress_label and message != "":
		progress_label.text = message

func set_loading_stage(stage: String):
	match stage:
		"init":
			set_progress(10, "Инициализация систем...")
		"world":
			set_progress(30, "Генерация мира...")
		"terrain":
			set_progress(50, "Создание ландшафта...")
		"resources":
			set_progress(65, "Размещение ресурсов...")
		"mobs":
			set_progress(80, "Спавн существ...")
		"player":
			set_progress(90, "Подготовка игрока...")
		"complete":
			set_progress(100, "Готово!")
			_finish_loading()

func _finish_loading():
	await get_tree().create_timer(0.5).timeout
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(_on_fade_complete)

func _on_fade_complete():
	emit_signal("loading_complete")
	queue_free()

func show_loading():
	visible = true
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)

func hide_loading():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): visible = false)
