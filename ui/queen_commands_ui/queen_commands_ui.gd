extends CanvasLayer

@onready var main_panel: Panel = $MainPanel
@onready var spawn_popup: Panel = $SpawnPopup

# Кнопки основной панели
@onready var btn_scout: Button = $MainPanel/VBox/BtnScout
@onready var btn_forage: Button = $MainPanel/VBox/BtnForage
@onready var btn_spawn: Button = $MainPanel/VBox/BtnSpawn

# Кнопки окна пополнения (с текстурами)
@onready var btn_worker: TextureButton = $SpawnPopup/HBox/BtnWorker
@onready var btn_soldier: TextureButton = $SpawnPopup/HBox/BtnSoldier
@onready var btn_babysitter: TextureButton = $SpawnPopup/HBox/BtnBabysitter

var is_menu_open: bool = false
var is_scout_mode: bool = false

# --- Переменные для анимации ---
var tween: Tween
var hidden_y: float
var visible_y: float

func _ready() -> void:
	# Запоминаем "открытую" позицию Y, которую вы выставили в редакторе (например, 586)
	visible_y = main_panel.position.y
	
	# Вычисляем "закрытую" позицию (за нижней границей экрана)
	hidden_y = get_viewport().get_visible_rect().size.y + 50.0
	
	# Прячем панель за экран при старте
	main_panel.position.y = hidden_y
	main_panel.show() # Оставляем visible = true, так как прячем за счет координат
	spawn_popup.hide()
	
	# Подключение основных команд
	btn_scout.pressed.connect(_on_scout_pressed)
	btn_forage.pressed.connect(_on_forage_pressed)
	btn_spawn.pressed.connect(_on_spawn_pressed)
	
	# Подключение кнопок создания муравьев
	btn_worker.pressed.connect(_request_spawn.bind(Cocoon.AntType.WORKER))
	btn_soldier.pressed.connect(_request_spawn.bind(Cocoon.AntType.SOLDIER))
	btn_babysitter.pressed.connect(_request_spawn.bind(Cocoon.AntType.BABYSITTER))
	
	if is_instance_valid(EventBus):
		EventBus.queen_selected.connect(_set_menu_state)
		EventBus.toggle_queen_commands.connect(_set_menu_state)


func _set_menu_state(open: bool) -> void:
	if is_menu_open == open:
		return
	is_menu_open = open

	if not is_menu_open:
		spawn_popup.hide()
		_cancel_scout_mode()

	# --- АНИМАЦИЯ ВЫЕЗДА ---
	if tween and tween.is_valid():
		tween.kill()
		
	tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var target_y = visible_y if is_menu_open else hidden_y
	# Анимация "снизу-вверх", длительность 0.4 сек
	tween.tween_property(main_panel, "position:y", target_y, 0.4)


func _on_scout_pressed() -> void:
	is_scout_mode = !is_scout_mode
	if is_instance_valid(EventBus):
		EventBus.toggle_scout_mode.emit(is_scout_mode)
	print("Режим выбора чанка для разведки: ", is_scout_mode)


func _on_forage_pressed() -> void:
	if is_instance_valid(ColonyManager):
		ColonyManager.dispatch_foragers()


func _on_spawn_pressed() -> void:
	# Переключаем видимость окна с иконками муравьев
	spawn_popup.visible = !spawn_popup.visible


func _cancel_scout_mode() -> void:
	is_scout_mode = false
	if is_instance_valid(EventBus):
		EventBus.toggle_scout_mode.emit(false)


## Запрос на создание конкретного типа муравья
func _request_spawn(ant_type: Cocoon.AntType) -> void:
	var queen: Queen = get_tree().root.find_child("Queen", true, false)
	if is_instance_valid(queen):
		queen.produce_cocoon(ant_type)


## Обработка горячих клавиш 1, 2, 3 при открытом Popup
func _unhandled_input(event: InputEvent) -> void:
	if spawn_popup.visible and event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_1:
			_request_spawn(Cocoon.AntType.WORKER)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_2:
			_request_spawn(Cocoon.AntType.SOLDIER)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_3:
			_request_spawn(Cocoon.AntType.BABYSITTER)
			get_viewport().set_input_as_handled()
