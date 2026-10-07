extends CanvasLayer

@onready var main_panel: Panel = $MainPanel
@onready var spawn_popup: Panel = $SpawnPopup
@onready var forage_popup: Panel = $ForagePopup # Новая панель сбора

# Кнопки основной панели
@onready var btn_scout: Button = $MainPanel/VBox/BtnScout
@onready var btn_forage: Button = $MainPanel/VBox/BtnForage
@onready var btn_spawn: Button = $MainPanel/VBox/BtnSpawn

# Кнопки окна пополнения
@onready var btn_worker: TextureButton = $SpawnPopup/HBox/BtnWorker
@onready var btn_soldier: TextureButton = $SpawnPopup/HBox/BtnSoldier
@onready var btn_babysitter: TextureButton = $SpawnPopup/HBox/BtnBabysitter

# Элементы окна сбора ресурсов
@onready var btn_dispatch: TextureButton = $ForagePopup/VBox/BtnDispatch
@onready var check_water: CheckBox = $ForagePopup/VBox/Grid/CheckWater
@onready var check_protein: CheckBox = $ForagePopup/VBox/Grid/CheckProtein
@onready var check_phytomass: CheckBox = $ForagePopup/VBox/Grid/CheckPhytomass
@onready var check_wood: CheckBox = $ForagePopup/VBox/Grid/CheckWood
@onready var check_clay: CheckBox = $ForagePopup/VBox/Grid/CheckClay
@onready var check_resin: CheckBox = $ForagePopup/VBox/Grid/CheckResin
@onready var check_silk: CheckBox = $ForagePopup/VBox/Grid/CheckSilk

var is_menu_open: bool = false
var is_scout_mode: bool = false

var tween: Tween
var hidden_y: float
var visible_y: float

func _ready() -> void:
	visible_y = main_panel.position.y
	hidden_y = get_viewport().get_visible_rect().size.y + 50.0
	
	main_panel.position.y = hidden_y
	main_panel.show()
	spawn_popup.hide()
	forage_popup.hide() # Прячем новую панель при старте
	
	btn_scout.pressed.connect(_on_scout_pressed)
	btn_forage.pressed.connect(_on_forage_pressed)
	btn_spawn.pressed.connect(_on_spawn_pressed)
	
	btn_worker.pressed.connect(_request_spawn.bind(Cocoon.AntType.WORKER))
	btn_soldier.pressed.connect(_request_spawn.bind(Cocoon.AntType.SOLDIER))
	btn_babysitter.pressed.connect(_request_spawn.bind(Cocoon.AntType.BABYSITTER))
	
	# Подключение кнопки отправки
	btn_dispatch.pressed.connect(_on_dispatch_pressed)
	
	if is_instance_valid(EventBus):
		EventBus.queen_selected.connect(_set_menu_state)
		EventBus.toggle_queen_commands.connect(_set_menu_state)

func _set_menu_state(open: bool) -> void:
	if is_menu_open == open:
		return
	is_menu_open = open

	if not is_menu_open:
		spawn_popup.hide()
		forage_popup.hide() # Закрываем меню сбора при скрытии команд
		_cancel_scout_mode()

	if tween and tween.is_valid():
		tween.kill()
		
	tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var target_y = visible_y if is_menu_open else hidden_y
	tween.tween_property(main_panel, "position:y", target_y, 0.4)

func _on_scout_pressed() -> void:
	is_scout_mode = !is_scout_mode
	if is_instance_valid(EventBus):
		EventBus.toggle_scout_mode.emit(is_scout_mode)

func _on_forage_pressed() -> void:
	spawn_popup.hide()
	forage_popup.visible = !forage_popup.visible # Показываем плашку выбора ресурсов

func _on_spawn_pressed() -> void:
	forage_popup.hide()
	spawn_popup.visible = !spawn_popup.visible

func _cancel_scout_mode() -> void:
	is_scout_mode = false
	if is_instance_valid(EventBus):
		EventBus.toggle_scout_mode.emit(false)

func _request_spawn(ant_type: Cocoon.AntType) -> void:
	var queen: Queen = get_tree().root.find_child("Queen", true, false)
	if is_instance_valid(queen):
		queen.produce_cocoon(ant_type)

## Сбор отмеченных чекбоксов и отправка команды в ColonyManager
func _on_dispatch_pressed() -> void:
	var selected_resources: Array = []
	
	if check_water.button_pressed: selected_resources.append(ResourceManager.ResourceType.WATER)
	if check_protein.button_pressed: selected_resources.append(ResourceManager.ResourceType.PROTEIN)
	if check_phytomass.button_pressed: selected_resources.append(ResourceManager.ResourceType.PHYTOMASS)
	if check_wood.button_pressed: selected_resources.append(ResourceManager.ResourceType.WOOD)
	if check_clay.button_pressed: selected_resources.append(ResourceManager.ResourceType.CLAY)
	if check_resin.button_pressed: selected_resources.append(ResourceManager.ResourceType.RESIN)
	if check_silk.button_pressed: selected_resources.append(ResourceManager.ResourceType.SILK)
	
	if selected_resources.is_empty():
		print("Не выбрано ни одного ресурса для сбора!")
		return
		
	if is_instance_valid(ColonyManager):
		ColonyManager.dispatch_foragers(selected_resources)
		
	forage_popup.hide()

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
