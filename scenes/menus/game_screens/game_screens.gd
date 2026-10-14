extends CanvasLayer

@export var main_menu_path: String = "res://scenes/menus/main_menu/main_menu.tscn"

@onready var bg: ColorRect = $DimBackground
@onready var pause_panel: Control = $PausePanel
@onready var victory_panel: Control = $VictoryPanel
@onready var defeat_panel: Control = $DefeatPanel

@onready var btn_resume: Button = $PausePanel/VBox/BtnResume
@onready var btn_how_to_play: Button = $PausePanel/VBox/BtnHowToPlay

@onready var v_stats: Label = $VictoryPanel/VBox/StatsLabel
@onready var v_btn_menu: Button = $VictoryPanel/VBox/BtnMenu

@onready var d_reason: Label = $DefeatPanel/VBox/ReasonLabel
@onready var d_stats: Label = $DefeatPanel/VBox/StatsLabel
@onready var d_btn_restart: Button = $DefeatPanel/VBox/BtnRestart
@onready var d_btn_menu: Button = $DefeatPanel/VBox/BtnMenu

var time: float = 0.0
var speed: float = 1.5 # Скорость перелива


func _ready() -> void:
	# Убедимся, что сами панели тоже могут обрабатывать клики во время паузы
	process_mode = Node.PROCESS_MODE_ALWAYS
	pause_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	victory_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	defeat_panel.process_mode = Node.PROCESS_MODE_ALWAYS

	bg.hide()
	pause_panel.hide()
	victory_panel.hide()
	defeat_panel.hide()
	
	btn_resume.pressed.connect(_resume_game)
	btn_how_to_play.pressed.connect(_how_to_play)
	
	v_btn_menu.pressed.connect(_go_to_menu)
	d_btn_restart.pressed.connect(_restart_level)
	d_btn_menu.pressed.connect(_go_to_menu)
	
	if is_instance_valid(VictoryManager):
		VictoryManager.victory_achieved.connect(_on_victory)
		VictoryManager.defeat_achieved.connect(_on_defeat)


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


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if victory_panel.visible or defeat_panel.visible:
			return 
		_toggle_pause()

func _toggle_pause() -> void:
	var is_paused = get_tree().paused
	if is_paused:
		_resume_game()
	else:
		get_tree().paused = true
		bg.show()
		pause_panel.show()


func _resume_game() -> void:
	# Сначала скрываем панели и фон, а потом снимаем паузу
	pause_panel.hide()
	bg.hide()
	get_tree().paused = false


func _how_to_play() -> void:
	print("Открыть окно обучения")


func _on_victory(message: String) -> void:
	get_tree().paused = true
	bg.show()
	victory_panel.show()
	v_stats.text = _generate_statistics(message)


func _on_defeat(message: String) -> void:
	get_tree().paused = true
	bg.show()
	defeat_panel.show()
	d_reason.text = message
	d_stats.text = _generate_statistics("")


func _generate_statistics(extra_message: String) -> String:
	var stats_text := ""
	if extra_message != "":
		stats_text += extra_message + "\n\n"
		
	var population: int = ColonyManager.get_current_population() if is_instance_valid(ColonyManager) else 0
	var time_spent_str := "00:00"
	
	if is_instance_valid(VictoryManager):
		var time_spent = VictoryManager.time_limit_seconds - VictoryManager.time_left
		var minutes = floori(time_spent / 60.0)
		var seconds = int(time_spent) % 60
		time_spent_str = "%02d:%02d" % [minutes, seconds]
		
	stats_text += "Taking time: %s\nAnts total population: %d" % [time_spent_str, population]
	return stats_text


func _restart_level() -> void:
	get_tree().paused = false
	
	# Очистка синглтонов перед перезагрузкой
	if is_instance_valid(VictoryManager):
		VictoryManager.reset_state()
	if is_instance_valid(ColonyManager):
		ColonyManager.clear_colony_data()
	if is_instance_valid(ResourceManager):
		ResourceManager.reset_to_defaults()
		
	get_tree().reload_current_scene()


func _go_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(main_menu_path)
