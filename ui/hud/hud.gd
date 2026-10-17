extends CanvasLayer

# Ссылки на лейблы ресурсов
@onready var water_label: Label = $UIControl/ResourcesPanel/MarginContainer/HBoxContainer/WaterBox/Value
@onready var protein_label: Label = $UIControl/ResourcesPanel/MarginContainer/HBoxContainer/ProteinBox/Value
@onready var phytomass_label: Label = $UIControl/ResourcesPanel/MarginContainer/HBoxContainer/PhytomassBox/Value
@onready var wood_label: Label = $UIControl/ResourcesPanel/MarginContainer/HBoxContainer/WoodBox/Value
@onready var clay_label: Label = $UIControl/ResourcesPanel/MarginContainer/HBoxContainer/ClayBox/Value
@onready var resin_label: Label = $UIControl/ResourcesPanel/MarginContainer/HBoxContainer/ResinBox/Value
@onready var silk_label: Label = $UIControl/ResourcesPanel/MarginContainer/HBoxContainer/SilkBox/Value
# Ссылки на элементы новой панели
@onready var workers_label: Label = $UIControl/ColonyPanel/MarginContainer/HBoxContainer/WorkersBox/Value
@onready var soldiers_label: Label = $UIControl/ColonyPanel/MarginContainer/HBoxContainer/SoldiersBox/Value
@onready var babysitters_label: Label = $UIControl/ColonyPanel/MarginContainer/HBoxContainer/BabysittersBox/Value
@onready var storage_label: Label = $UIControl/ColonyPanel/MarginContainer/HBoxContainer/StorageBox/Value
@onready var ants_total_value: Label = $UIControl/ColonyPanel/MarginContainer/HBoxContainer/AntsTotal/Value
# Блок миссии и таймера (Левый верхний угол по GDD)
@onready var timer_label: Label = $UIControl/MissionContainer/TimerLabel
@onready var quest_label: Label = $UIControl/MissionContainer/QuestLabel
# Кнопки для вывода подсказки при наведении
@onready var water_tip: TextureButton = $UIControl/ResourcesPanel/MarginContainer/HBoxContainer/WaterBox/Icon/WaterTip
@onready var protein_tip: TextureButton = $UIControl/ResourcesPanel/MarginContainer/HBoxContainer/ProteinBox/Icon/ProteinTip
@onready var phytomass_tip: TextureButton = $UIControl/ResourcesPanel/MarginContainer/HBoxContainer/PhytomassBox/Icon/PhytomassTip
@onready var wood_tip: TextureButton = $UIControl/ResourcesPanel/MarginContainer/HBoxContainer/WoodBox/Icon/WoodTip
@onready var clay_tip: TextureButton = $UIControl/ResourcesPanel/MarginContainer/HBoxContainer/ClayBox/Icon/ClayTip
@onready var resin_tip: TextureButton = $UIControl/ResourcesPanel/MarginContainer/HBoxContainer/ResinBox/Icon/ResinTip
@onready var silk_tip: TextureButton = $UIControl/ResourcesPanel/MarginContainer/HBoxContainer/SilkBox/Icon/SilkTip
@onready var ants_tip: TextureButton = $UIControl/ColonyPanel/MarginContainer/HBoxContainer/AntsTotal/Icon/AntsTip
@onready var workers_tip: TextureButton = $UIControl/ColonyPanel/MarginContainer/HBoxContainer/WorkersBox/Icon/WorkersTip
@onready var solder_tip: TextureButton = $UIControl/ColonyPanel/MarginContainer/HBoxContainer/SoldiersBox/Icon/SolderTip
@onready var babysitter_tip: TextureButton = $UIControl/ColonyPanel/MarginContainer/HBoxContainer/BabysittersBox/Icon/BabysitterTip
@onready var storage_tip: TextureButton = $UIControl/ColonyPanel/MarginContainer/HBoxContainer/StorageBox/Icon/StorageTip
# 
@onready var tooltip: PanelContainer = $UIControl/Tooltip
@onready var desc_label: Label = $UIControl/Tooltip/MarginContainer/VBoxContainer/DescLabel

@export var tip_offset: Vector2 = Vector2(45, 25) # Смещение от курсора

@onready var game_timer: Timer
# Настройки времени
@export var time_limit_seconds: float = 600.0
var time_left: float = 0.0

var starvation_tween: Tween = null

# Словарь для быстрого доступа по типу из Enum
var _resource_labels: Dictionary = {}

# Счетчик для смещения текста, чтобы сообщения не слипались в одну кучу
var active_notifications: Array[Label] = []
var current_mission_text: String = ""

func _ready() -> void:

	# Подключаем сигналы шины событий
	if is_instance_valid(EventBus):
		#EventBus.queen_starving.connect(_on_queen_starving)
		#EventBus.queen_fed.connect(_on_queen_fed)
		EventBus.show_notification.connect(_on_show_notification)
				
	# Формируем соответствие enum -> label
	_resource_labels = {
		ResourceManager.ResourceType.WATER: water_label,
		ResourceManager.ResourceType.PROTEIN: protein_label,
		ResourceManager.ResourceType.PHYTOMASS: phytomass_label,
		ResourceManager.ResourceType.WOOD: wood_label,
		ResourceManager.ResourceType.CLAY: clay_label,
		ResourceManager.ResourceType.RESIN: resin_label,
		ResourceManager.ResourceType.SILK: silk_label
	}
	
	game_timer = Timer.new()
	game_timer.wait_time = time_limit_seconds
	time_left = time_limit_seconds
	game_timer.autostart = true
	game_timer.timeout.connect(_on_timeout_game_timer)
	
	# Подписываемся на события менеджера ресурсов
	ResourceManager.resource_changed.connect(_on_resource_changed)
	ResourceManager.resources_updated.connect(_on_resources_updated)
	ResourceManager.storage_limit_updated.connect(_on_storage_limit_updated) # Новая строка
	
	# Первичная инициализация текущими значениями
	_on_resources_updated(ResourceManager.resources)
	_on_storage_limit_updated(ResourceManager.get_total_resources(), ResourceManager.get_max_capacity()) # Новая строкаиями
	_on_resources_updated(ResourceManager.resources)
	
	if is_instance_valid(VictoryManager):
		#VictoryManager.session_time_updated.connect(update_timer_display)
		VictoryManager.victory_achieved.connect(_on_victory_achieved)
		VictoryManager.defeat_achieved.connect(_on_defeat_achieved)
		
		if not VictoryManager.goal_updated.is_connected(_update_goal_text):
			VictoryManager.goal_updated.connect(_update_goal_text)
		
	if is_instance_valid(ColonyManager):
		ColonyManager.population_updated.connect(_on_population_changed)
		# Используем геттер вместо прямого обращения к .size()
		_update_colony_panel(ColonyManager.get_current_population(), ColonyManager.get_max_population())
		
	water_tip.mouse_entered.connect(_on_show_tip.bind(1))
	protein_tip.mouse_entered.connect(_on_show_tip.bind(2))
	phytomass_tip.mouse_entered.connect(_on_show_tip.bind(3))
	wood_tip.mouse_entered.connect(_on_show_tip.bind(4))
	clay_tip.mouse_entered.connect(_on_show_tip.bind(5))
	resin_tip.mouse_entered.connect(_on_show_tip.bind(6))
	silk_tip.mouse_entered.connect(_on_show_tip.bind(7))
	ants_tip.mouse_entered.connect(_on_show_tip.bind(8))
	workers_tip.mouse_entered.connect(_on_show_tip.bind(9))
	solder_tip.mouse_entered.connect(_on_show_tip.bind(10))
	babysitter_tip.mouse_entered.connect(_on_show_tip.bind(11))
	storage_tip.mouse_entered.connect(_on_show_tip.bind(12))

	water_tip.mouse_exited.connect(_on_hide_tip)
	protein_tip.mouse_exited.connect(_on_hide_tip)
	phytomass_tip.mouse_exited.connect(_on_hide_tip)
	wood_tip.mouse_exited.connect(_on_hide_tip)
	clay_tip.mouse_exited.connect(_on_hide_tip)
	resin_tip.mouse_exited.connect(_on_hide_tip)
	silk_tip.mouse_exited.connect(_on_hide_tip)
	ants_tip.mouse_exited.connect(_on_hide_tip)
	workers_tip.mouse_exited.connect(_on_hide_tip)
	solder_tip.mouse_exited.connect(_on_hide_tip)
	babysitter_tip.mouse_exited.connect(_on_hide_tip)
	storage_tip.mouse_exited.connect(_on_hide_tip)


func _process(delta: float) -> void:
	time_left -= delta
	
	update_timer_display(time_left)
	EventBus.timer_update.emit(time_left)
	
	# Добавляем обновление позиции тултипа, если он отображается
	if tooltip and tooltip.visible:
		update_position()


## Точечное обновление при изменении конкретного ресурса
func _on_resource_changed(type: ResourceManager.ResourceType, new_amount: int) -> void:
	if _resource_labels.has(type):
		_resource_labels[type].text = str(new_amount)
	
	if is_instance_valid(VictoryManager) and not VictoryManager.is_game_over:
		_update_goal_text()


## Массовое обновление (на старте или при общем сбросе пулов)
func _on_resources_updated(all_resources: Dictionary) -> void:
	for type in all_resources:
		if _resource_labels.has(type):
			_resource_labels[type].text = str(all_resources[type])


## Публичные методы для обновления таймера
func update_timer_display(seconds_left: float = 0) -> void:
	var total_seconds: int = int(seconds_left)
	var minutes: int = floori(total_seconds / 60.0)
	var seconds: int = total_seconds % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]
	
	if total_seconds <= 0:
		EventBus.timer_is_out.emit()
		game_timer.stop()


func set_quest_text(description: String) -> void:
	quest_label.text = description


### Срабатывает, когда Королеве не хватило ресурсов
#func _on_queen_starving(missing_amount: int) -> void:
	## Прерываем предыдущую анимацию, если она шла
	#if starvation_tween and starvation_tween.is_valid():
		#starvation_tween.kill()
#
	#starvation_tween = create_tween().set_loops(4) # Мигаем 4 раза
	## Пульсирующий красный цвет
	#starvation_tween.tween_property(starvation_banner, "modulate", Color(0.974, 0.822, 0.154, 1.0), 0.4)
	#starvation_tween.tween_property(starvation_banner, "modulate", Color(1.0, 0.2, 0.2, 0.2), 0.4)
	#
	## После завершения пульсации плавно скрываем баннер
	#starvation_tween.finished.connect(func():
		#var fade_out := create_tween()
		#fade_out.tween_property(starvation_banner, "modulate:a", 0.0, 0.5)
	#)


### Срабатывает, когда Королева успешно поела
#func _on_queen_fed() -> void:
	##if not starvation_banner:
		##return
#
	#if starvation_tween and starvation_tween.is_valid():
		#starvation_tween.kill()
#
	## Плавно убираем предупреждение, если запасы восполнены
	#var fade_out := create_tween()
	#fade_out.tween_property(starvation_banner, "modulate:a", 0.0, 0.3)


## Первичное отображение текущей цели при запуске уровня
func _update_goal_text(msg: String = "") -> void:
	if not is_instance_valid(VictoryManager):
		return
	
	# Если передано новое сообщение из сигнала, обновляем сохраненную строку
	if msg != "":
		current_mission_text = msg
		
	# Выводим текущее задание на экран
	set_quest_text(current_mission_text)


## Срабатывает при выполнении условия победы
func _on_victory_achieved(message: String) -> void:
	set_quest_text("ПОБЕДА: " + message)
	
	# Окрашиваем текст квеста в зеленый цвет при победе
	if quest_label:
		quest_label.modulate = Color(0.2, 1.0, 0.2)


## Срабатывает при изменении числа муравьев или лимита жилья
func _on_population_changed(current: int, max_pop: int) -> void:
	_update_colony_panel(current, max_pop)
	
	if is_instance_valid(VictoryManager) and not VictoryManager.is_game_over:
		_update_goal_text()


## Срабатывает при истечении таймера
func _on_defeat_achieved(message: String) -> void:
	set_quest_text("ПОРАЖЕНИЕ: " + message)
	
	# Окрашиваем текст квеста в красный цвет при поражении
	if quest_label:
		quest_label.modulate = Color(1.0, 0.2, 0.2)


func _on_show_notification(message: String, color: Color = Color(0.6, 1.0, 0.6)) -> void:
	var label := Label.new()
	label.text = message
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 18)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.custom_minimum_size.x = 250
	
	$UIControl.add_child(label)
	
	# Очищаем массив от уже исчезнувших узлов
	active_notifications = active_notifications.filter(func(l): return is_instance_valid(l))
	
	var screen_size := get_viewport().get_visible_rect().size
	var base_x := screen_size.x - 280.0
	var base_y := screen_size.y / 2.0
	
	var start_y := base_y
	
	# Если на экране уже есть уведомления, проверяем позицию самого последнего
	if active_notifications.size() > 0:
		var last_label = active_notifications[-1]
		# Требуем, чтобы новое сообщение было как минимум на 30 пикселей НИЖЕ предыдущего
		var required_y = last_label.position.y + 30.0
		# Берем максимальное значение: спавним либо в базовой точке, либо ниже последней строки
		start_y = maxf(base_y, required_y)
	
	label.position = Vector2(base_x, start_y)
	active_notifications.append(label)
	
	# Запускаем анимацию плавного полета вверх и исчезновения
	var tween := create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", start_y - 100.0, 5.0).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 5.0).set_ease(Tween.EASE_IN_OUT)
	
	tween.chain().tween_callback(func():
		if active_notifications.has(label):
			active_notifications.erase(label)
		label.queue_free()
	)


## Динамический пересчет и обновление значений панели колонии
func _update_colony_panel(_current: int, _max_pop: int) -> void:
	var ants_total: int = 0
	if not is_instance_valid(ColonyManager):
		return

	var workers_count: int = 0
	var soldiers_count: int = 0
	var babysitters_count: int = 0

	# Подсчет муравьев по типам
	for ant in ColonyManager.alive_ants:
		if is_instance_valid(ant):
			match ant.ant_type:
				Cocoon.AntType.WORKER:
					workers_count += 1
				Cocoon.AntType.SOLDIER:
					soldiers_count += 1
				Cocoon.AntType.BABYSITTER:
					babysitters_count += 1

	if workers_label:
		workers_label.text = str(workers_count)
	if soldiers_label:
		soldiers_label.text = str(soldiers_count)
	if babysitters_label:
		babysitters_label.text = str(babysitters_count)
	
	ants_total = workers_count + soldiers_count + babysitters_count
	ants_total_value.text = "%d/%d" % [ants_total, ColonyManager.max_population]


## Срабатывает при изменении суммарного объема ресурсов или постройке складов
func _on_storage_limit_updated(current_total: int, max_capacity: int) -> void:
	if storage_label:
		storage_label.text = "%d/%d" % [current_total, max_capacity]


func _on_timeout_game_timer():
	print("HUD: _on_timeout_game_timer")
	EventBus.timer_is_out.emit()
	game_timer.stop()


func _on_show_tip(id: int):
	var tips: Dictionary = {
		1: "Water supplies",
		2: "Protein supplies",
		3: "Phytomass supplies",
		4: "Wood suplplies",
		5: "Clay supplies",
		6: "Resin supplies",
		7: "Silk supplies",
		8: "Colony size",
		9: "Workers",
		10: "Soldiers",
		11: "babysittiers",
		12: "Storage Capacity"		
	}
	var tip = tips.get(id, 0)
	desc_label.text = tip
	
	tooltip.show()


func _on_hide_tip():
	tooltip.hide()


func update_position() -> void:
	var mouse_pos = tooltip.get_global_mouse_position()
	var viewport_size = tooltip.get_viewport_rect().size
	var tooltip_size = tooltip.size

	# Базовая позиция: справа-снизу от курсора с учетом отступа
	var target_pos = mouse_pos + tip_offset

	# --- Проверка по горизонтали (X) ---
	# Если подсказка вылезает за правый край экрана, переносим её влево от курсора
	if target_pos.x + tooltip_size.x > viewport_size.x:
		target_pos.x = mouse_pos.x - tooltip_size.x - tip_offset.x
	# На случай если курсор у самого левого края экрана
	elif target_pos.x < 0:
		target_pos.x = mouse_pos.x + tip_offset.x
		
	# --- Проверка по вертикали (Y) ---
	# Если подсказка вылезает за нижний край экрана, переносим её вверх от курсора
	if target_pos.y + tooltip_size.y > viewport_size.y:
		target_pos.y = mouse_pos.y - tooltip_size.y - tip_offset.y
	# На случай если курсор у самого верхнего края экрана
	elif target_pos.y < 0:
		target_pos.y = mouse_pos.y + tip_offset.y
		
	tooltip.global_position = target_pos
