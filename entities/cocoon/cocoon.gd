class_name Cocoon
extends Area2D

signal creation_completed
signal hatched(ant_type: AntType, spawn_position: Vector2)
signal destroyed

enum AntType {
	WORKER,
	SOLDIER,
	BABYSITTER
}

enum Phase {
	CREATING,  # Стадия создания/формирования куколки
	MATURING   # Стадия созревания и роста муравья
}

@export var ant_scene: PackedScene

@export var ant_type: AntType = AntType.WORKER
@export var max_health: float = 4.0 ## Здоровье куколки по GDD (4 ед.)

# Время стадии создания (в секундах по GDD)
const CREATION_TIMES: Dictionary = {
	AntType.WORKER: 5.0,
	AntType.SOLDIER: 5.0,
	AntType.BABYSITTER: 5.0
}

# Время стадии созревания (в секундах по GDD)
const MATURATION_TIMES: Dictionary = {
	AntType.WORKER: 10.0,
	AntType.SOLDIER: 35.0,
	AntType.BABYSITTER: 15.0
}

var current_phase: Phase = Phase.CREATING
var current_health: float = 4.0
var phase_duration: float = 5.0

@onready var timer: Timer = $IncubationTimer
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var sprite: CanvasItem = get_node_or_null("Sprite2D")


func _ready() -> void:
	current_health = max_health
	timer.timeout.connect(_on_timer_timeout)
	_start_creation_phase()


func setup(target_type: AntType) -> void:
	ant_type = target_type
	if is_inside_tree() and timer:
		_start_creation_phase()


func _process(_delta: float) -> void:
	if progress_bar and not timer.is_stopped():
		progress_bar.value = phase_duration - timer.time_left


## 1. Запуск стадии создания
func _start_creation_phase() -> void:
	current_phase = Phase.CREATING
	phase_duration = CREATION_TIMES.get(ant_type, 5.0)
	
	if progress_bar:
		progress_bar.max_value = phase_duration
		progress_bar.value = 0.0

	# Полупрозрачный / бледный вид пока формируется
	if sprite:
		sprite.modulate = Color(1.0, 1.0, 1.0, 0.45)

	timer.start(phase_duration)
	print("Куколка: началась стадия создания (%s сек)" % phase_duration)


## 2. Запуск стадии созревания
func _start_maturation_phase() -> void:
	current_phase = Phase.MATURING
	phase_duration = MATURATION_TIMES.get(ant_type, 10.0)
	
	if progress_bar:
		progress_bar.max_value = phase_duration
		progress_bar.value = 0.0

	# Куколка плотная и готовая к росту
	if sprite:
		sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)

	timer.start(phase_duration)
	creation_completed.emit()
	print("Куколка сформирована! Началось созревание (%s сек)" % phase_duration)


func _on_timer_timeout() -> void:
	if current_phase == Phase.CREATING:
		_start_maturation_phase()
	elif current_phase == Phase.MATURING:
		_hatch()


func _hatch() -> void:
	print("Куколка созрела! Вылупляется муравей типа: ", ant_type)

	if ant_scene:
		# 1. Проверяем глобальный лимит колонии
		if is_instance_valid(ColonyManager) and not ColonyManager.can_spawn_ant():
			print("Вылупление отменено: нет свободных мест в колонии!")
			# Можно уничтожить куколку или отложить вылупление
			queue_free()
			return

		# 2. Создаем инстанс муравья
		var ant: AntBase = ant_scene.instantiate()
		ant.ant_type = ant_type
		ant.global_position = global_position
		ant.enable_aging = false

		# 3. Назначаем домашний открытый чанк
		var chunk_manager: ChunkManager = get_tree().root.find_child("ChunkManager", true, false)
		if chunk_manager:
			var home_chunk: Chunk = chunk_manager.get_chunk_at_position(global_position)
			if home_chunk and home_chunk.status == Chunk.Status.UNLOCKED:
				ant.assign_chunk(home_chunk)

		# 4. Добавляем муравья в мир
		get_parent().add_child(ant)

		# 5. СВЯЗКА С COLONY MANAGER: регистрируем живого юнита в колонии
		if is_instance_valid(ColonyManager):
			ColonyManager.register_ant(ant)

		# 6. Также регистрируем в Nest (если используется локальный учет в гнезде)
		var nest: Nest = get_tree().root.find_child("Nest", true, false)
		if nest:
			nest.register_unit(ant)

	# Оповещаем системы через сигналы
	hatched.emit(ant_type, global_position)
	if is_instance_valid(EventBus):
		EventBus.ant_spawned.emit(ant_type)

	queue_free()


func take_damage(amount: float) -> void:
	current_health = maxf(0.0, current_health - amount)
	if current_health <= 0.0:
		destroyed.emit()
		queue_free()
