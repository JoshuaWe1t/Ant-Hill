extends Control

@export var scroll_speed: Vector2 = Vector2(50.0, 0.0) # Скорость движения фона
@export var test_level_path: String = "res://scenes/levels/test_level.tscn" # Укажите точный путь до вашей сцены уровня

@onready var parallax_bg: ParallaxBackground = $ParallaxBackground
@onready var btn_start: TextureButton = $CenterContainer/VBoxContainer/BtnStart
@onready var btn_settings: TextureButton = $CenterContainer/VBoxContainer/BtnSettings
@onready var btn_how_to_play: TextureButton = $CenterContainer/VBoxContainer/BtnHowToPlay
@onready var bg: ColorRect = $DimBackground

var time: float = 0.0
var speed: float = 1.5 # Скорость перелива

func _ready() -> void:
	# Подключаем сигналы нажатия кнопок
	btn_start.pressed.connect(_on_start_pressed)
	btn_settings.pressed.connect(_on_settings_pressed)
	btn_how_to_play.pressed.connect(_on_how_to_play_pressed)

func _process(delta: float) -> void:
	time += delta * speed
	
	# Переводим синусоиду от -1..1 в диапазон от 0.0 до 1.0
	var wave = (sin(time) + 1.0) / 2.0
	
	# 1. Тон (Hue): плавно меняем в узком диапазоне коричневого (0.05 - 0.11)
	var h = lerp(0.05, 0.11, wave)
	
	# 2. Насыщенность (Saturation): можно слегка менять для живости (0.5 - 0.7)
	# Используем сдвиг по времени sin(time + 2.0), чтобы она менялась несинхронно с тоном
	var wave_s = (sin(time + 2.0) + 1.0) / 2.0
	var s = lerp(0.5, 0.7, wave_s)
	
	# 3. Яркость (Value): держим в темных пределах (0.25 - 0.45)
	var wave_v = (sin(time + 4.0) + 1.0) / 2.0
	var v = lerp(0.25, 0.45, wave_v)
	
	# Создаем цвет из HSV компонентов и задаем альфа-канал (0.5)
	bg.color = Color.from_hsv(h, s, v, 0.5)

func _on_start_pressed() -> void:
	# Переход на тестовый уровень
	print("Загрузка уровня: ", test_level_path)
	get_tree().change_scene_to_file(test_level_path)

func _on_settings_pressed() -> void:
	# Заглушка для настроек
	get_tree().change_scene_to_file("res://scenes/menus/credits/credits.tscn")

func _on_how_to_play_pressed() -> void:
	# Заглушка для обучения
	get_tree().change_scene_to_file("res://scenes/menus/tutorial/tutorial.tscn")
