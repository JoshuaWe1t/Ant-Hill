class_name BuildingBase
extends Area2D

signal construction_progress_updated(current: float, total: float)
signal construction_completed

enum BuildState {
	BLUEPRINT,          # Чертеж: ждет прибытия рабочих
	UNDER_CONSTRUCTION, # Рабочие на объекте, шкала заполняется
	OPERATIONAL         # Здание полностью построено и функционирует
}

@export_group("Construction Profile")
@export var building_id: String = "building_base"
@export var building_name: String = "Постройка"
@export var build_duration: float = 30.0     ## Базовое время строительства (в секундах)
@export var required_workers: int = 2       ## Ровно 2 юнита по GDD (Раздел 4.2)
@export var building_size: Vector2 = Vector2(100, 100)

var current_state: BuildState = BuildState.BLUEPRINT
var build_progress: float = 0.0
var assigned_workers: Array[AntBase] = []

@onready var color_rect: ColorRect = get_node_or_null("ColorRect")
@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")
@onready var progress_bar: ProgressBar = get_node_or_null("ProgressBar")
@onready var status_label: Label = get_node_or_null("StatusLabel")


func _ready() -> void:
	z_index = 2
	collision_layer = 1
	collision_mask = 0

	# Добавляем в группу buildings для валидации превью
	add_to_group("buildings")

	# Настройка формы и коллизии под размеры здания
	_apply_dimensions(building_size)

	if progress_bar:
		progress_bar.max_value = build_duration
		progress_bar.value = 0.0
		progress_bar.visible = true

	# В режиме чертежа постройка отображается полупрозрачной
	_set_visual_alpha(0.4)
	_update_ui_state()


func _process(delta: float) -> void:
	if current_state == BuildState.UNDER_CONSTRUCTION:
		_process_construction(delta)


## Установка габаритов здания
func _apply_dimensions(new_size: Vector2) -> void:
	building_size = new_size
	
	if color_rect:
		color_rect.size = building_size
		color_rect.position = -building_size / 2.0

	if collision_shape:
		var rect_shape := RectangleShape2D.new()
		rect_shape.size = building_size
		collision_shape.shape = rect_shape


## Регистрация рабочего на стройплощадке
func assign_worker(ant: AntBase) -> bool:
	if current_state == BuildState.OPERATIONAL:
		return false
	if assigned_workers.size() >= required_workers:
		return false

	if not assigned_workers.has(ant):
		assigned_workers.append(ant)
		ant.died.connect(_on_worker_died.bind(ant))

	# Когда на стройку пришли все требуемые рабочие (2 юнита) — запускается процесс
	if assigned_workers.size() >= required_workers:
		current_state = BuildState.UNDER_CONSTRUCTION

	_update_ui_state()
	return true


## Снятие рабочего со стройки (ушел или погиб)
func unassign_worker(ant: AntBase) -> void:
	if assigned_workers.has(ant):
		assigned_workers.erase(ant)

	# Если рабочих стало меньше требуемого — стройка возвращается в режим ожидания
	if assigned_workers.size() < required_workers and current_state == BuildState.UNDER_CONSTRUCTION:
		current_state = BuildState.BLUEPRINT

	_update_ui_state()


func _on_worker_died(ant: AntBase) -> void:
	unassign_worker(ant)


## Расчет темпа строительства
func _process_construction(delta: float) -> void:
	# GDD Раздел 4.2: Муравей-рабочий (ant_worker) имеет бонус +15% к скорости строительства
	var speed_multiplier: float = 0.0

	for worker in assigned_workers:
		if is_instance_valid(worker):
			var worker_bonus: float = 1.15 if worker.ant_type == Cocoon.AntType.WORKER else 1.0
			speed_multiplier += (1.0 / float(required_workers)) * worker_bonus

	build_progress += delta * speed_multiplier

	if progress_bar:
		progress_bar.value = build_progress

	construction_progress_updated.emit(build_progress, build_duration)

	if build_progress >= build_duration:
		_complete_construction()


## Завершение возведения
func _complete_construction() -> void:
	current_state = BuildState.OPERATIONAL

	if progress_bar:
		progress_bar.visible = false

	# Здание становится плотным/непрозрачным
	_set_visual_alpha(1.0)

	# Освобождаем строителей от работы
	for worker in assigned_workers:
		if is_instance_valid(worker):
			worker.finish_work()
	assigned_workers.clear()

	_update_ui_state()
	construction_completed.emit()

	if is_instance_valid(EventBus):
		EventBus.building_construction_finished.emit(self)

	_on_operational_ready()


## Переопределяется в конкретных типах комнат (Shelter, Stockpile, Farm и т.д.)
func _on_operational_ready() -> void:
	pass


func _set_visual_alpha(alpha: float) -> void:
	if color_rect:
		color_rect.modulate.a = alpha


func _update_ui_state() -> void:
	if not status_label:
		return

	match current_state:
		BuildState.BLUEPRINT:
			status_label.text = "Ожидание: %d/%d рабочих" % [assigned_workers.size(), required_workers]
		BuildState.UNDER_CONSTRUCTION:
			status_label.text = "Строится..."
		BuildState.OPERATIONAL:
			status_label.text = building_name
