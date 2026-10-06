class_name Chunk
extends Area2D

signal status_changed(new_status: Status)

enum Status {
	LOCKED,      # Недоступен для стройки, но можно исследовать
	SCOUTING,    # В процессе исследования муравьями
	UNLOCKED     # Исследован, доступен для строительства
}

@export var chunk_size: Vector2 = Vector2(256, 256)
var status: Status = Status.LOCKED : set = _set_status

# Переменные для отслеживания прогресса разведки (45 секунд)
var scout_duration: float = 45.0
var current_scout_time: float = 0.0

# Соседи чанка для проверки доступности разведки
var neighbors: Array[Chunk] = []

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var debug_rect: ColorRect = $ColorRect
@onready var debug_label: Label = $Label
@onready var progress_bar: ProgressBar = get_node_or_null("ProgressBar")


func _ready() -> void:
	_update_shape()
	_update_visuals()
	input_event.connect(_on_input_event)


func _process(delta: float) -> void:
	# Если чанк исследуется, плавно заполняем прогресс-бар
	if status == Status.SCOUTING:
		current_scout_time += delta
		if progress_bar:
			progress_bar.value = current_scout_time


func setup(size: Vector2, initial_status: Status = Status.LOCKED) -> void:
	chunk_size = size
	status = initial_status
	if is_inside_tree():
		_update_shape()
		_update_visuals()


func _update_shape() -> void:
	if not collision_shape:
		return
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = chunk_size
	collision_shape.shape = rect_shape
	collision_shape.position = chunk_size / 2.0


func _set_status(value: Status) -> void:
	status = value
	_update_visuals()
	status_changed.emit(status)


func _update_visuals() -> void:
	if not debug_rect:
		return
	debug_rect.size = chunk_size

	match status:
		Status.LOCKED:
			debug_rect.color = Color(0.18, 0.12, 0.08, 0.95)
			if debug_label:
				debug_label.text = "Locked"
			if progress_bar:
				progress_bar.visible = false
		Status.SCOUTING:
			debug_rect.color = Color(0.6, 0.45, 0.1, 0.8)
			if debug_label:
				debug_label.text = "Scouting..."
			# Настраиваем и показываем прогресс-бар по центру чанка
			if progress_bar:
				progress_bar.max_value = scout_duration
				progress_bar.value = current_scout_time
				progress_bar.size = Vector2(chunk_size.x * 0.6, 16.0) # Ширина 60% от размера чанка
				progress_bar.position = (chunk_size / 2.0) - (progress_bar.size / 2.0)
				progress_bar.visible = true
		Status.UNLOCKED:
			debug_rect.color = Color(0.35, 0.25, 0.18, 0.4)
			if debug_label:
				debug_label.text = "Available"
			if progress_bar:
				progress_bar.visible = false


## Можно ли начать разведку этого чанка?
func can_be_scouted() -> bool:
	if status != Status.LOCKED:
		return false
	for n in neighbors:
		if n.status == Status.UNLOCKED:
			return true
	return false


## Старт процесса разведки
func start_scouting() -> void:
	if can_be_scouted():
		current_scout_time = 0.0
		status = Status.SCOUTING


## Завершение разведки
func complete_scouting() -> void:
	status = Status.UNLOCKED


## Клик по чанку для выбора цели разведки / постройки
func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		var space_state := get_world_2d().direct_space_state
		var point_params := PhysicsPointQueryParameters2D.new()
		point_params.position = get_global_mouse_position()
		point_params.collision_mask = 2 # Слой 2: Entities
		point_params.collide_with_areas = true
		point_params.collide_with_bodies = true
		
		var hits := space_state.intersect_point(point_params)
		if hits.size() > 0:
			return

		if has_node("/root/EventBus"):
			EventBus.chunk_clicked.emit(self)
		print("Клик по чанку: ", name, " | Статус: ", status, " | Разведка возможна: ", can_be_scouted())
