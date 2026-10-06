class_name Queen
extends Area2D

signal health_changed(current_hp: float, max_hp: float)
signal queen_selected(is_selected: bool)
signal queen_died

@export_group("Stats")
@export var max_health: float = 100.0

# --- Жизнеобеспечение и питание Королевы ---
@export_group("Upkeep & Hunger")
@export var upkeep_interval: float = 60.0 ## Интервал потребления (60 сек / 1 минута)
@export var water_upkeep: int = 20
@export var protein_upkeep: int = 20
@export var phytomass_upkeep: int = 20

var current_health: float = 100.0
var is_selected: bool = false : set = _set_selected
# Ссылка на домашнее гнездо
var home_nest: Nest = null

# Используем get_node_or_null, чтобы скрипт не падал, если узлы временно названы иначе
@onready var selection_indicator: CanvasItem = get_node_or_null("SelectionIndicator")
@onready var health_bar: ProgressBar = get_node_or_null("HealthBar")
@onready var upkeep_timer: Timer = Timer.new()

# Экспортируем сцену куколки
@export var cocoon_scene: PackedScene


# Стоимость создания куколки по GDD (Раздел 4.2)
const SPAWN_COSTS: Dictionary = {
	Cocoon.AntType.WORKER: {
		ResourceManager.ResourceType.WATER: 1,
		ResourceManager.ResourceType.PROTEIN: 2,
		ResourceManager.ResourceType.PHYTOMASS: 2
	},
	Cocoon.AntType.SOLDIER: {
		ResourceManager.ResourceType.WATER: 2,
		ResourceManager.ResourceType.PROTEIN: 5,
		ResourceManager.ResourceType.PHYTOMASS: 2
	},
	Cocoon.AntType.BABYSITTER: {
		ResourceManager.ResourceType.WATER: 1,
		ResourceManager.ResourceType.PROTEIN: 3,
		ResourceManager.ResourceType.PHYTOMASS: 3
	}
}

# Время откладывания куколки Королевой (в секундах по GDD)
const SPAWN_DELAYS: Dictionary = {
	Cocoon.AntType.WORKER: 5.0,
	Cocoon.AntType.SOLDIER: 15.0,
	Cocoon.AntType.BABYSITTER: 10.0
}

var is_laying_egg: bool = false

func _ready() -> void:
	current_health = max_health
	input_pickable = true # Принудительно включаем отслеживание мыши для Area2D
	
	if selection_indicator:
		selection_indicator.visible = false
		
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
		health_bar.visible = false

	# Создаем и запускаем таймер ежеминутного питания
	add_child(upkeep_timer)
	upkeep_timer.wait_time = upkeep_interval
	upkeep_timer.autostart = true
	upkeep_timer.one_shot = false
	upkeep_timer.timeout.connect(_on_upkeep_tick)
	upkeep_timer.start()

	# Подключаем сигнал клика
	if not input_event.is_connected(_on_input_event):
		input_event.connect(_on_input_event)
	
	if is_instance_valid(EventBus):
		EventBus.ui_queen_icon_clicked.connect(_on_ui_icon_clicked)
	
	print("Королева инициализирована. Pickable: ", input_pickable)


## Обработка клика по физическому телу Королевы
func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		print(">> Зафиксирован клик по Королеве!")
		select_queen()
		# КРИТИЧЕСКИ ВАЖНО: помечаем ввод как обработанный, 
		# чтобы _unhandled_input не сбросил выделение в этом же кадре!
		get_viewport().set_input_as_handled()


## Выбор королевы
func select_queen() -> void:
	if is_selected:
		return
	self.is_selected = true
	EventBus.queen_selected.emit(true)
	print("Королева выбрана (is_selected = true)")


## Снятие выделения
func deselect_queen() -> void:
	if not is_selected:
		return
	self.is_selected = false
	EventBus.queen_selected.emit(false)
	print("Выделение с Королевы снято")


func _set_selected(value: bool) -> void:
	is_selected = value
	if selection_indicator:
		selection_indicator.visible = is_selected
	if health_bar:
		health_bar.visible = is_selected or (current_health < max_health)
	queen_selected.emit(is_selected)


## Получение урона
func take_damage(amount: float) -> void:
	if current_health <= 0.0:
		return

	current_health = maxf(0.0, current_health - amount)
	health_changed.emit(current_health, max_health)
	
	if health_bar:
		health_bar.value = current_health
		health_bar.visible = true

	EventBus.queen_health_updated.emit(current_health, max_health)

	if current_health <= 0.0:
		_die()


## Лечение королевы
func heal(amount: float) -> void:
	current_health = minf(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)
	
	if health_bar:
		health_bar.value = current_health

	EventBus.queen_health_updated.emit(current_health, max_health)


func _die() -> void:
	queen_died.emit()
	EventBus.queen_died.emit()
	print("Королева погибла! Условие поражения.")


## Снятие выделения по клику мимо Королевы в пустое место
func _unhandled_input(event: InputEvent) -> void:
	if is_selected and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		deselect_queen()


## Задайте радиус кликабельной зоны под размер спрайта (например, 32-48 пикселей)
#@export var click_radius: float = 40.0
#
#
#func _unhandled_input(event: InputEvent) -> void:
	#if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()):
		#return
#
	#var mouse_world_pos: Vector2 = get_global_mouse_position()
	#var distance_to_click: float = global_position.distance_to(mouse_world_pos)
#
	## 1. Если клик попал в радиус Королевы — выбираем её
	#if distance_to_click <= click_radius:
		#print("Клик по Королеве зафиксирован по координатам! Дистанция: ", distance_to_click)
		#select_queen()
		#get_viewport().set_input_as_handled()
	#
	## 2. Если клик был за пределами радиуса, а Королева уже была выбрана — снимаем выбор
	#elif is_selected:
		#deselect_queen()


### Запрос на производство куколки: создается сразу же
#func produce_cocoon(type: Cocoon.AntType) -> bool:
	#if not cocoon_scene:
		#push_error("В инспекторе Королевы не назначена cocoon_scene!")
		#return false
#
	#var cost: Dictionary = SPAWN_COSTS.get(type, {})
	#
	## 1. Проверяем ресурсы и списываем их
	#if not ResourceManager.spend_resources(cost):
		#print("Недостаточно ресурсов для создания муравья!")
		#return false
#
	## 2. Мгновенно спавним куколку возле Королевы
	#var cocoon: Cocoon = cocoon_scene.instantiate()
	#var spawn_offset := Vector2(randf_range(-45, 45), randf_range(15, 40))
	#cocoon.global_position = global_position + spawn_offset
	#
	#get_parent().add_child(cocoon)
	#cocoon.setup(type)
	#
	#print("Королева моментально отложила куколку рядом с собой!")
	#return true


### Запрос на производство куколки: создается вокруг крупного спрайта Королевы
#func produce_cocoon(type: Cocoon.AntType) -> bool:
	#if not cocoon_scene:
		#push_error("В инспекторе Королевы не назначена cocoon_scene!")
		#return false
#
	#var cost: Dictionary = SPAWN_COSTS.get(type, {})
	#
	#if not ResourceManager.spend_resources(cost):
		#print("Недостаточно ресурсов для создания муравья!")
		#return false
#
	#var cocoon: Cocoon = cocoon_scene.instantiate()
	#
	## Генерируем угол и расстояние за пределы тела 128x128 (радиус 75..95 px)
	#var random_angle: float = randf_range(0.0, TAU)
	#var spawn_distance: float = randf_range(75.0, 95.0)
	#var spawn_offset := Vector2.from_angle(random_angle) * spawn_distance
	#
	#cocoon.global_position = global_position + spawn_offset
	#
	#get_parent().add_child(cocoon)
	#cocoon.setup(type)
	#
	#print("Куколка отложена на позицию: ", cocoon.global_position)
	#return true


## Запрос на производство куколки
func produce_cocoon(type: Cocoon.AntType) -> bool:
	if not cocoon_scene:
		push_error("В инспекторе Королевы не назначена cocoon_scene!")
		return false

	# 1. Проверяем глобальный лимит населения колонии через ColonyManager
	if is_instance_valid(ColonyManager) and not ColonyManager.can_spawn_ant():
		print("Невозможно создать куколку: достигнут общий лимит населения колонии (%d)!" % ColonyManager.get_max_population())
		return false

	var cost: Dictionary = SPAWN_COSTS.get(type, {})
	
	# 2. Проверяефм и списываем ресурсы (GDD Раздел 4.2)[cite: 7]
	if not ResourceManager.spend_resources(cost):
		print("Недостаточно ресурсов для создания муравья!")
		return false

	# 3. Спавним куколку в радиусе 65-85 px от Королевы
	var cocoon: Cocoon = cocoon_scene.instantiate()
	var random_angle: float = randf_range(0.0, TAU)
	var spawn_distance: float = randf_range(65.0, 85.0)
	var spawn_offset := Vector2.from_angle(random_angle) * spawn_distance
	
	cocoon.global_position = global_position + spawn_offset
	get_parent().add_child(cocoon)
	cocoon.setup(type)
	print("Куколка отложена: ", Cocoon.AntType.keys()[type])
	return true


func _spawn_cocoon_instance(type: Cocoon.AntType) -> void:
	if not cocoon_scene:
		push_error("В инспекторе Королевы не назначена cocoon_scene!")
		return

	var cocoon: Cocoon = cocoon_scene.instantiate()
	# Спавним куколку рядом с Королевой со случайным небольшим смещением
	var spawn_offset := Vector2(randf_range(-30, 30), randf_range(10, 30))
	cocoon.global_position = global_position + spawn_offset
	
	get_parent().add_child(cocoon)
	cocoon.setup(type)
	print("Куколка успешно отложена на позицию: ", cocoon.global_position)


## Ежеминутный тик питания Королевы
func _on_upkeep_tick() -> void:
	if current_health <= 0.0:
		return

	var required: Dictionary = {
		ResourceManager.ResourceType.WATER: water_upkeep,
		ResourceManager.ResourceType.PROTEIN: protein_upkeep,
		ResourceManager.ResourceType.PHYTOMASS: phytomass_upkeep
	}

	# 1. Проверяем наличие ресурсов и считаем недостачу
	var missing_amount: int = 0
	var to_spend: Dictionary = {}

	for res_type in required.keys():
		var needed: int = required[res_type]
		var available: int = ResourceManager.get_resource(res_type)
		
		if available >= needed:
			to_spend[res_type] = needed
		else:
			# Забираем всё, что есть на складе, а разницу отправляем в дефицит
			to_spend[res_type] = available
			missing_amount += (needed - available)

	# 2. Списываем доступные ресурсы со склада
	if not to_spend.is_empty():
		ResourceManager.spend_resources(to_spend)

	# 3. Обработка сытости / голода
	if missing_amount > 0:
		# Голодание: наносим урон в размере суммарной нехватки ресурсов
		print("Королева голодает! Не хватило ресурсов: %d. Получен урон." % missing_amount)
		take_damage(float(missing_amount))
		if is_instance_valid(EventBus):
			EventBus.queen_starving.emit(missing_amount)
	else:
		# Сытость: если здоровье не полное, восстанавливаем 50% от потерянного HP
		var lost_health: float = max_health - current_health
		if lost_health > 0.0:
			var heal_amount: float = lost_health * 0.5
			print("Королева сыта. Восстановление 50%% потерянного здоровья (+%.1f HP)." % heal_amount)
			heal(heal_amount)
		if is_instance_valid(EventBus):
			EventBus.queen_fed.emit()
		else:
			print("Королева сыта, здоровье на максимуме.")


# Добавьте эту новую функцию в конец скрипта
func _on_ui_icon_clicked() -> void:
	if current_health > 0:
		select_queen()
		print("Королева выбрана через UI-иконку!")
