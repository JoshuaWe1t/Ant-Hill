extends Control

@export var scroll_speed: Vector2 = Vector2(50.0, 0.0) # Скорость движения фона
@export var test_level_path: String = "res://scenes/levels/test_level.tscn" # Укажите точный путь до вашей сцены уровня

@onready var parallax_bg: ParallaxBackground = $ParallaxBackground
@onready var btn_start: Button = $CenterContainer/VBoxContainer/BtnStart
@onready var btn_settings: Button = $CenterContainer/VBoxContainer/BtnSettings
@onready var btn_how_to_play: Button = $CenterContainer/VBoxContainer/BtnHowToPlay

func _ready() -> void:
	# Подключаем сигналы нажатия кнопок
	btn_start.pressed.connect(_on_start_pressed)
	btn_settings.pressed.connect(_on_settings_pressed)
	btn_how_to_play.pressed.connect(_on_how_to_play_pressed)

func _process(delta: float) -> void:
	# Бесконечная прокрутка параллакс-фона
	if is_instance_valid(parallax_bg):
		parallax_bg.scroll_offset += scroll_speed * delta

func _on_start_pressed() -> void:
	# Переход на тестовый уровень
	print("Загрузка уровня: ", test_level_path)
	get_tree().change_scene_to_file(test_level_path)

func _on_settings_pressed() -> void:
	# Заглушка для настроек
	print("Раздел 'Настройки' пока не реализован.")

func _on_how_to_play_pressed() -> void:
	# Заглушка для обучения
	print("Раздел 'Как играть' пока не реализован.")
