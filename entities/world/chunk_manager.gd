class_name ChunkManager
extends Node2D

@export var chunk_scene: PackedScene
@export var ground_y_level: float = 0.0 ## Линия поверхности (земли)

# Настройки плотной сетки чанков
@export var grid_columns: int = 8 ## Четное число, чтобы чанк 2х2 стоял ровно по центру
@export var grid_rows: int = 5    ## Глубина подземного мира (в чанках)
@export var cell_size: Vector2 = Vector2(256, 256) ## Базовый размер маленькой ячейки

var all_chunks: Array[Chunk] = []
var starter_chunk: Chunk = null ## Ссылка на стартовую комнату муравейника


func _ready() -> void:
	generate_underground()


## Генерация сплошного массива чанков с огромным стартовым центром
func generate_underground() -> void:
	var start_x: float = -(grid_columns * cell_size.x) / 2.0
	
	# Определяем координаты для большого стартового чанка (размер 2x2 ячейки)
	var starter_col: int = int(grid_columns / 2.0) - 1
	var starter_row: int = 0
	
	# 1. Спавним огромный стартовый чанк
	var starter_pos := Vector2(start_x + starter_col * cell_size.x, ground_y_level)
	var starter_size := cell_size * 2.0 # В 2 раза больше по ширине и высоте (512x512)
	starter_chunk = _spawn_chunk(starter_pos, starter_size, Chunk.Status.UNLOCKED)
	starter_chunk.name = "StarterChunk"

	# 2. Генерируем остальную сетку вокруг него
	for row in range(grid_rows):
		for col in range(grid_columns):
			# Пропускаем генерацию маленьких ячеек там, где уже стоит большой стартовый чанк
			if row >= starter_row and row < starter_row + 2:
				if col >= starter_col and col < starter_col + 2:
					continue
			
			var pos := Vector2(start_x + col * cell_size.x, ground_y_level + row * cell_size.y)
			_spawn_chunk(pos, cell_size, Chunk.Status.LOCKED)

	# 3. Обновляем граф смежности (он автоматически свяжет большой чанк со всеми мелкими соседями)
	_build_adjacency_graph()


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

			# Если прямоугольники соприкасаются (с запасом погрешности 2px для стыков сетки)
			if rect1.grow(2.0).intersects(rect2):
				if not c1.neighbors.has(c2):
					c1.neighbors.append(c2)
				if not c2.neighbors.has(c1):
					c2.neighbors.append(c1)


## Проверка: разрешено ли строить здание в точке мира?
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


## Возвращает мировую позицию центра стартовой комнаты
func get_starter_spawn_point() -> Vector2:
	if starter_chunk:
		return starter_chunk.global_position + (starter_chunk.chunk_size / 2.0)
	return Vector2(0.0, 150.0)
