class_name ChunkManager
extends Node2D

@export var chunk_scene: PackedScene
@export var ground_y_level: float = 0.0 ## Линия поверхности (земли)

# Стартовый квадратный чанк
@export var starter_chunk_size: Vector2 = Vector2(300, 300)

# Варианты форм для процедурной генерации комнат муравейника
var chunk_shapes: Array[Vector2] = [
	Vector2(200, 200), # Квадрат поменьше
	Vector2(300, 300), # Стандартный квадрат
	Vector2(450, 200), # Длинный горизонтальный тоннель/галерея
	Vector2(200, 400), # Вертикальная шахта
	Vector2(350, 250)  # Прямоугольная средняя камера
]

var all_chunks: Array[Chunk] = []


func _ready() -> void:
	generate_underground()


## Базовая генерация начальной структуры муравейника
func generate_underground() -> void:
	# 1. Стартовый чанк (всегда UNLOCKED и строго под поверхностью земли)
	var start_pos := Vector2(-starter_chunk_size.x / 2.0, ground_y_level)
	var starter := _spawn_chunk(start_pos, starter_chunk_size, Chunk.Status.UNLOCKED)
	starter.name = "StarterChunk"

	# 2. Создаем ветви/соседей от стартового чанка
	# Слева
	_attach_chunk_to(starter, Vector2.LEFT, chunk_shapes.pick_random())
	# Справа
	_attach_chunk_to(starter, Vector2.RIGHT, chunk_shapes.pick_random())
	# Вглубь (вниз)
	var bottom_chunk := _attach_chunk_to(starter, Vector2.DOWN, chunk_shapes.pick_random())

	# 3. Делаем второй ярус вглубь от нижнего чанка
	if bottom_chunk:
		_attach_chunk_to(bottom_chunk, Vector2.LEFT, chunk_shapes.pick_random())
		_attach_chunk_to(bottom_chunk, Vector2.RIGHT, chunk_shapes.pick_random())
		_attach_chunk_to(bottom_chunk, Vector2.DOWN, chunk_shapes.pick_random())

	# 4. Обновляем граф смежности (кто с кем граничит)
	_build_adjacency_graph()


## Пристыковывает новый чанк к существующему в заданную сторону (LEFT, RIGHT, DOWN)
func _attach_chunk_to(parent_chunk: Chunk, direction: Vector2, new_size: Vector2) -> Chunk:
	var new_pos := Vector2.ZERO

	if direction == Vector2.LEFT:
		new_pos.x = parent_chunk.position.x - new_size.x
		new_pos.y = parent_chunk.position.y
	elif direction == Vector2.RIGHT:
		new_pos.x = parent_chunk.position.x + parent_chunk.chunk_size.x
		new_pos.y = parent_chunk.position.y
	elif direction == Vector2.DOWN:
		new_pos.x = parent_chunk.position.x
		new_pos.y = parent_chunk.position.y + parent_chunk.chunk_size.y

	# Проверяем, чтобы чанк не уходил выше уровня земли
	if new_pos.y < ground_y_level:
		new_pos.y = ground_y_level

	var new_chunk := _spawn_chunk(new_pos, new_size, Chunk.Status.LOCKED)
	return new_chunk


func _spawn_chunk(pos: Vector2, size: Vector2, initial_status: Chunk.Status) -> Chunk:
	var instance: Chunk = chunk_scene.instantiate()
	instance.position = pos
	add_child(instance)
	instance.setup(size, initial_status)
	all_chunks.append(instance)
	return instance


## Поиск соседних соприкасающихся чанков для проверки возможности разведки
func _build_adjacency_graph() -> void:
	for i in range(all_chunks.size()):
		var c1: Chunk = all_chunks[i]
		var rect1 := Rect2(c1.position, c1.chunk_size)

		for j in range(i + 1, all_chunks.size()):
			var c2: Chunk = all_chunks[j]
			var rect2 := Rect2(c2.position, c2.chunk_size)

			# Если прямоугольники соприкасаются (с небольшим запасом погрешности 2px)
			if rect1.grow(2.0).intersects(rect2):
				if not c1.neighbors.has(c2):
					c1.neighbors.append(c2)
				if not c2.neighbors.has(c1):
					c2.neighbors.append(c1)


## Проверка: разрешено ли строить здание в точке мира?
## Точка должна попадать в чанк со статусом UNLOCKED
func is_position_buildable(world_pos: Vector2) -> bool:
	for chunk in all_chunks:
		var rect := Rect2(chunk.position, chunk.chunk_size)
		if rect.has_point(world_pos):
			return chunk.status == Chunk.Status.UNLOCKED
	return false


## Находит чанк, в котором находится заданная точка
func get_chunk_at_position(world_pos: Vector2) -> Chunk:
	for chunk in all_chunks:
		var rect := Rect2(chunk.global_position, chunk.chunk_size)
		if rect.has_point(world_pos):
			return chunk
	return null
