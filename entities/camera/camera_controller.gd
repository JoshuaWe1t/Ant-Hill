extends Camera2D

# --- Настройки перемещения ---
@export_group("Movement")
@export var base_speed: float = 600.0          ## Базовая скорость камеры (пикселей в секунду)
@export var acceleration: float = 12.0          ## Плавность разгона и остановки (чем выше, тем резче)
@export var edge_margin: int = 18              ## Толщина зоны у края экрана для мыши (в пикселях)
@export var enable_edge_pan: bool = true       ## Включить/выключить смещение мышью у краев

# --- Настройки зума ---
@export_group("Zoom")
@export var zoom_speed: float = 0.15           ## Шаг приближения/отдаления
@export var min_zoom: float = 0.5              ## Максимальное отдаление (вид всей колонии)
@export var max_zoom: float = 2.0              ## Максимальное приближение (детали)
@export var zoom_smoothness: float = 16.0      ## Плавность интерполяции зума

# Внутренние переменные состояния
var _target_zoom: Vector2 = Vector2.ONE
var _target_velocity: Vector2 = Vector2.ZERO


func _ready() -> void:
	_target_zoom = zoom


func _unhandled_input(event: InputEvent) -> void:
	# Обработка зума колесиком мыши
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_apply_zoom(1.0 + zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_apply_zoom(1.0 - zoom_speed)


func _process(delta: float) -> void:
	_handle_movement(delta)
	_handle_zoom_smoothing(delta)


func _handle_movement(delta: float) -> void:
	var input_dir: Vector2 = Vector2.ZERO

	# 1. Считывание клавиш WASD / Стрелок
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input_dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input_dir.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_dir.x += 1.0

	# 2. Смещение мышью у границы окна (Edge Panning)
	if enable_edge_pan and get_viewport():
		var mouse_pos: Vector2 = get_viewport().get_mouse_position()
		var viewport_size: Vector2 = get_viewport_rect().size

		# Проверяем, что курсор находится внутри окна игры
		if Rect2(Vector2.ZERO, viewport_size).has_point(mouse_pos):
			if mouse_pos.x <= edge_margin:
				input_dir.x -= 1.0
			elif mouse_pos.x >= viewport_size.x - edge_margin:
				input_dir.x += 1.0

			if mouse_pos.y <= edge_margin:
				input_dir.y -= 1.0
			elif mouse_pos.y >= viewport_size.y - edge_margin:
				input_dir.y += 1.0

	# Нормализуем направление диагоналей
	input_dir = input_dir.normalized()

	# Скорость корректируется на зум: при отдалении камера летит быстрее, чтобы покрывать масштаб
	var current_speed: float = (base_speed / zoom.x)
	var desired_velocity: Vector2 = input_dir * current_speed

	# Плавная интерполяция скорости
	_target_velocity = _target_velocity.lerp(desired_velocity, acceleration * delta)
	position += _target_velocity * delta


func _apply_zoom(factor: float) -> void:
	var new_zoom_val: float = clampf(_target_zoom.x * factor, min_zoom, max_zoom)
	_target_zoom = Vector2(new_zoom_val, new_zoom_val)


func _handle_zoom_smoothing(delta: float) -> void:
	if zoom.distance_to(_target_zoom) > 0.001:
		# Сохраняем позицию курсора в мировых координатах до зума,
		# чтобы приближение происходило именно к точке, куда смотрит курсор
		var mouse_world_before: Vector2 = get_global_mouse_position()
		zoom = zoom.lerp(_target_zoom, zoom_smoothness * delta)
		var mouse_world_after: Vector2 = get_global_mouse_position()

		# Корректируем позицию камеры на разницу смещения точки курсора
		position += (mouse_world_before - mouse_world_after)
