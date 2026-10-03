class_name Chunk
extends Area2D

signal status_changed(new_status: Status)

enum Status {
	LOCKED,      # Недоступен для стройки, но можно исследовать (туман / земля)
	SCOUTING,    # В процессе исследования муравьями
	UNLOCKED     # Исследован, доступен для строительства
}

@export var chunk_size: Vector2 = Vector2(256, 256)
var status: Status = Status.LOCKED : set = _set_status

# Соседи чанка для проверки доступности разведки
var neighbors: Array[Chunk] = []

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var debug_rect: ColorRect = $ColorRect
@onready var debug_label: Label = $Label


func _ready() -> void:
	_update_shape()
	_update_visuals()
	input_event.connect(_on_input_event)


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
	# Центрируем коллизию относительно позиции узла
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
			# Темно-коричневый / закрытая земля
			debug_rect.color = Color(0.18, 0.12, 0.08, 0.95)
			if debug_label:
				debug_label.text = "Locked"
		Status.SCOUTING:
			# Желтовато-оранжевый / идет разведка
			debug_rect.color = Color(0.6, 0.45, 0.1, 0.8)
			if debug_label:
				debug_label.text = "Scouting..."
		Status.UNLOCKED:
			# Светлая вырытая полость / открыто для застройки
			debug_rect.color = Color(0.35, 0.25, 0.18, 0.4)
			if debug_label:
				debug_label.text = "Available"


## Можно ли начать разведку этого чанка?
## Чанк должен быть LOCKED и хотя бы один его сосед должен быть уже UNLOCKED
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
		status = Status.SCOUTING


## Завершение разведки (вызывается по завершении таймера или возвращении муравьев)
func complete_scouting() -> void:
	status = Status.UNLOCKED


## Клик по чанку для выбора цели разведки / постройки
func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		# Оповещаем шину событий о клике по конкретному чанку
		if has_node("/root/EventBus"):
			get_node("/root/EventBus").emit_signal("chunk_clicked", self)
		print("Клик по чанку: ", name, " | Статус: ", status, " | Разведка возможна: ", can_be_scouted())
