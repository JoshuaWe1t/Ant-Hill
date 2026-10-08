extends CanvasLayer

# Ссылки на лейблы ресурсов
@onready var water_label: Label = $UIControl/ResourcesPanel/MarginContainer/HBoxContainer/WaterBox/Value
@onready var protein_label: Label = $UIControl/ResourcesPanel/MarginContainer/HBoxContainer/ProteinBox/Value
@onready var phytomass_label: Label = $UIControl/ResourcesPanel/MarginContainer/HBoxContainer/PhytomassBox/Value
@onready var wood_label: Label = $UIControl/ResourcesPanel/MarginContainer/HBoxContainer/WoodBox/Value
@onready var clay_label: Label = $UIControl/ResourcesPanel/MarginContainer/HBoxContainer/ClayBox/Value
@onready var resin_label: Label = $UIControl/ResourcesPanel/MarginContainer/HBoxContainer/ResinBox/Value
@onready var silk_label: Label = $UIControl/ResourcesPanel/MarginContainer/HBoxContainer/SilkBox/Value
@onready var starvation_banner: PanelContainer = $StarvationBanner
@onready var banner_label: Label = $StarvationBanner/BannerLabel
# Ссылки на элементы новой панели
@onready var workers_label: Label = $UIControl/ColonyPanel/MarginContainer/HBoxContainer/WorkersBox/Value
@onready var soldiers_label: Label = $UIControl/ColonyPanel/MarginContainer/HBoxContainer/SoldiersBox/Value
@onready var babysitters_label: Label = $UIControl/ColonyPanel/MarginContainer/HBoxContainer/BabysittersBox/Value
@onready var storage_label: Label = $UIControl/ColonyPanel/MarginContainer/HBoxContainer/StorageBox/Value

# Блок миссии и таймера (Левый верхний угол по GDD)
@onready var timer_label: Label = $UIControl/MissionContainer/TimerLabel
@onready var quest_label: Label = $UIControl/MissionContainer/QuestLabel

var starvation_tween: Tween = null

# Словарь для быстрого доступа по типу из Enum
var _resource_labels: Dictionary = {}

# Счетчик для смещения текста, чтобы сообщения не слипались в одну кучу
var _notification_count: int = 0
var current_mission_text: String = ""

func _ready() -> void:
	if starvation_banner:
		starvation_banner.modulate.a = 0.0

	# Подключаем сигналы шины событий
	if is_instance_valid(EventBus):
		EventBus.queen_starving.connect(_on_queen_starving)
		EventBus.queen_fed.connect(_on_queen_fed)
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
	
	# Подписываемся на события менеджера ресурсов
	ResourceManager.resource_changed.connect(_on_resource_changed)
	ResourceManager.resources_updated.connect(_on_resources_updated)
	ResourceManager.storage_limit_updated.connect(_on_storage_limit_updated) # Новая строка
	
	# Первичная инициализация текущими значениями
	_on_resources_updated(ResourceManager.resources)
	_on_storage_limit_updated(ResourceManager.get_total_resources(), ResourceManager.get_max_capacity()) # Новая строкаиями
	_on_resources_updated(ResourceManager.resources)
	
	if is_instance_valid(VictoryManager):
		VictoryManager.session_time_updated.connect(update_timer_display)
		VictoryManager.victory_achieved.connect(_on_victory_achieved)
		VictoryManager.defeat_achieved.connect(_on_defeat_achieved)
		
		if not VictoryManager.goal_updated.is_connected(_update_goal_text):
			VictoryManager.goal_updated.connect(_update_goal_text)
		
	if is_instance_valid(ColonyManager):
		ColonyManager.population_updated.connect(_on_population_changed)
		# Используем геттер вместо прямого обращения к .size()
		_update_colony_panel(ColonyManager.get_current_population(), ColonyManager.get_max_population())


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


## Публичные методы для обновления таймера и квеста из GameManager
func update_timer_display(seconds_left: float) -> void:
	var total_seconds: int = int(seconds_left)
	var minutes: int = floori(total_seconds / 60.0)
	var seconds: int = total_seconds % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]


func set_quest_text(description: String) -> void:
	quest_label.text = description


## Срабатывает, когда Королеве не хватило ресурсов
func _on_queen_starving(missing_amount: int) -> void:
	if not starvation_banner:
		return

	if banner_label:
		banner_label.text = "КОРОЛЕВА ГОЛОДАЕТ! ДЕФИЦИТ РЕСУРСОВ: %d" % missing_amount

	# Прерываем предыдущую анимацию, если она шла
	if starvation_tween and starvation_tween.is_valid():
		starvation_tween.kill()

	starvation_tween = create_tween().set_loops(4) # Мигаем 4 раза
	# Пульсирующий красный цвет
	starvation_tween.tween_property(starvation_banner, "modulate", Color(0.974, 0.822, 0.154, 1.0), 0.4)
	starvation_tween.tween_property(starvation_banner, "modulate", Color(1.0, 0.2, 0.2, 0.2), 0.4)
	
	# После завершения пульсации плавно скрываем баннер
	starvation_tween.finished.connect(func():
		var fade_out := create_tween()
		fade_out.tween_property(starvation_banner, "modulate:a", 0.0, 0.5)
	)


## Срабатывает, когда Королева успешно поела
func _on_queen_fed() -> void:
	if not starvation_banner:
		return

	if starvation_tween and starvation_tween.is_valid():
		starvation_tween.kill()

	# Плавно убираем предупреждение, если запасы восполнены
	var fade_out := create_tween()
	fade_out.tween_property(starvation_banner, "modulate:a", 0.0, 0.3)


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


## Создает всплывающий текст справа по центру экрана
func _on_show_notification(message: String, color: Color = Color(0.6, 1.0, 0.6)) -> void:
	var label := Label.new()
	label.text = message
	label.add_theme_color_override("font_color", color) # Приятный зеленый цвет
	label.add_theme_font_size_override("font_size", 18)
	
	# Добавляем на слой UIControl, чтобы текст был поверх всего
	$UIControl.add_child(label)
	
	var screen_size := get_viewport().get_visible_rect().size
	# X: отступ справа (около 280 пикселей от края)
	# Y: по центру, плюс смещение вниз, если висит несколько уведомлений
	var start_x := screen_size.x - 280.0
	var start_y := (screen_size.y / 2.0) + (_notification_count * 25.0) 
	
	label.position = Vector2(start_x, start_y)
	_notification_count += 1
	
	# Создаем анимацию
	var tween := create_tween().set_parallel(true)
	# Движение вверх на 100px за 3 секунды
	tween.tween_property(label, "position:y", start_y - 100.0, 5.0).set_ease(Tween.EASE_OUT)
	# Плавное исчезновение
	tween.tween_property(label, "modulate:a", 0.0, 5.0).set_ease(Tween.EASE_IN_OUT)
	
	# По завершении удаляем узел и откатываем счетчик
	tween.chain().tween_callback(func():
		label.queue_free()
		_notification_count -= 1
		if _notification_count < 0:
			_notification_count = 0
	)

## Динамический пересчет и обновление значений панели колонии
func _update_colony_panel(current: int, max_pop: int) -> void:
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


## Срабатывает при изменении суммарного объема ресурсов или постройке складов
func _on_storage_limit_updated(current_total: int, max_capacity: int) -> void:
	if storage_label:
		storage_label.text = "%d/%d" % [current_total, max_capacity]
