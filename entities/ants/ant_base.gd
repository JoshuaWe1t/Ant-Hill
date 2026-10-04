class_name AntBase
extends CharacterBody2D

signal died(ant_instance: AntBase)

enum State {
	IDLE,       # Ожидание / легкое блуждание
	MOVE_TO,    # Перемещение к цели (здание, чанк, склад)
	WORK,       # Выполнение работы (строительство, уход за куколками)
	DEAD        # Состояние смерти
}

# --- Параметры по GDD (Раздел 4.2) ---
@export_group("Ant Profile")
@export var ant_type: Cocoon.AntType = Cocoon.AntType.WORKER
@export var max_health: float = 12.0 ## ant_worker: 12, ant_soldier: 20, ant_babysitter: 8
@export var move_speed: float = 60.0  ## Базовая скорость передвижения (пикселей в секунду)

# Потребление ресурсов за период (GDD: 1 вода, 1 протеин для рабочего)
@export_group("Upkeep (Maintenance)")
@export var water_upkeep: int = 1
@export var protein_upkeep: int = 1
@export var phytomass_upkeep: int = 1
@export var hunger_interval: float = 15.0 ## Интервал списания ресурсов на поддержание жизни

# --- Система старения (Опциональная заготовка) ---
@export_group("Aging System")
@export var enable_aging: bool = false     ## Флаг: включена ли смертность от старости
@export var lifespan: float = 120.0        ## ant_worker: 120, soldier: 240, babysitter: 320

# --- Спрайты под каждую специализацию ---
@export_group("Visuals")
@export var worker_texture: Texture2D
@export var soldier_texture: Texture2D
@export var babysitter_texture: Texture2D

var current_health: float = 12.0
var current_state: State = State.IDLE

# Навигация и перемещение
var target_position: Vector2 = Vector2.ZERO
var arrive_distance: float = 8.0
var wander_timer: float = 0.0

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var hunger_timer: Timer = $HungerTimer
@onready var aging_timer: Timer = $AgingTimer
@onready var state_label: Label = get_node_or_null("StateLabel")
@onready var sprite: CanvasItem = get_node_or_null("Sprite2D")

# Ссылка на чанк, в котором сейчас обитает муравей
var current_chunk: Chunk = null

func _ready() -> void:
	z_index = 5
	_apply_stats_from_gdd()
	_apply_visuals() # Накладываем нужный спрайт
	current_health = max_health
	
	# Настройка таймера голода / содержания
	if hunger_timer:
		hunger_timer.wait_time = hunger_interval
		hunger_timer.timeout.connect(_on_hunger_tick)
		hunger_timer.start()

	# Настройка заготовки для старения
	if aging_timer:
		aging_timer.wait_time = lifespan
		aging_timer.one_shot = true
		aging_timer.timeout.connect(_on_aging_timeout)
		if enable_aging:
			aging_timer.start()

	_set_state(State.IDLE)


## Назначение параметров из матрицы баланса GDD в зависимости от специализации
func _apply_stats_from_gdd() -> void:
	match ant_type:
		Cocoon.AntType.WORKER:
			max_health = 12.0
			lifespan = 120.0
			move_speed = 70.0
			water_upkeep = 1
			protein_upkeep = 1
			phytomass_upkeep = 3
		Cocoon.AntType.SOLDIER:
			max_health = 20.0
			lifespan = 240.0
			move_speed = 50.0
			water_upkeep = 5
			protein_upkeep = 10
			phytomass_upkeep = 2
		Cocoon.AntType.BABYSITTER:
			max_health = 8.0
			lifespan = 320.0
			move_speed = 60.0
			water_upkeep = 2
			protein_upkeep = 1
			phytomass_upkeep = 4


func _physics_process(delta: float) -> void:
	match current_state:
		State.IDLE:
			_process_idle(delta)
		State.MOVE_TO:
			_process_move_to(delta)
		State.WORK:
			velocity = Vector2.ZERO
		State.DEAD:
			velocity = Vector2.ZERO

	move_and_slide()


### 1. Поведение IDLE: небольшое случайное блуждание по чанку
#func _process_idle(delta: float) -> void:
	#wander_timer -= delta
	#if wander_timer <= 0.0:
		## Выбираем случайную точку неподалеку (в пределах 60 пикселей)
		#var random_dir := Vector2.from_angle(randf_range(0.0, TAU))
		#target_position = global_position + (random_dir * randf_range(60.0, 200.0))
		#wander_timer = randf_range(3.0, 6.0)
#
	## Двигаемся к точке блуждания
	#if global_position.distance_to(target_position) > arrive_distance:
		#var dir := (target_position - global_position).normalized()
		#velocity = dir * (move_speed * 0.4) # Медленно бродит
		#_flip_sprite(dir.x)
	#else:
		#velocity = Vector2.ZERO


## Обновленная логика IDLE: блуждание строго внутри открытого чанка
func _process_idle(delta: float) -> void:
	wander_timer -= delta
	if wander_timer <= 0.0:
		target_position = _get_random_point_in_chunk()
		wander_timer = randf_range(3.0, 6.0)

	# Движение к выбранной точке внутри чанка
	if global_position.distance_to(target_position) > arrive_distance:
		var dir := (target_position - global_position).normalized()
		velocity = dir * (move_speed * 0.4)
		_flip_sprite(dir.x)
	else:
		velocity = Vector2.ZERO


## 2. Поведение MOVE_TO: направленное движение к рабочей задаче
func _process_move_to(_delta: float) -> void:
	var dist: float = global_position.distance_to(target_position)
	if dist <= arrive_distance:
		velocity = Vector2.ZERO
		_on_target_reached()
	else:
		var dir := (target_position - global_position).normalized()
		velocity = dir * move_speed
		_flip_sprite(dir.x)


## Приказ на перемещение в конкретную точку
func move_to_location(world_pos: Vector2) -> void:
	target_position = world_pos
	_set_state(State.MOVE_TO)


func _on_target_reached() -> void:
	_set_state(State.IDLE)


## 3. Периодическое потребление ресурсов колонии
func _on_hunger_tick() -> void:
	var upkeep_cost: Dictionary = {
		ResourceManager.ResourceType.WATER: water_upkeep,
		ResourceManager.ResourceType.PROTEIN: protein_upkeep,
		ResourceManager.ResourceType.PHYTOMASS: phytomass_upkeep
	}

	# Если колония может прокормить муравья — списываем ресурсы
	if ResourceManager.spend_resources(upkeep_cost):
		pass
	else:
		# Ресурсов нет — муравей получает урон от истощения
		print("Колония голодает! Муравей %s теряет здоровье." % name)
		take_damage(2.0)


## 4. Заготовка таймера старения (Пока без реальной смерти)
func _on_aging_timeout() -> void:
	if not enable_aging:
		return

	print("Муравей %s достиг предельного возраста (%s сек)." % [name, lifespan])
	# Заготовка под будущие штрафы к скорости / смерть:
	# _die("starost")


## Переключение FSM состояний
func _set_state(new_state: State) -> void:
	current_state = new_state
	if state_label:
		match current_state:
			State.IDLE: state_label.text = "Idle"
			State.MOVE_TO: state_label.text = "Move"
			State.WORK: state_label.text = "Work"
			State.DEAD: state_label.text = "Dead"


func take_damage(amount: float) -> void:
	if current_state == State.DEAD:
		return
	current_health = maxf(0.0, current_health - amount)
	if current_health <= 0.0:
		_die("damage")


func _die(_reason: String) -> void:
	_set_state(State.DEAD)
	died.emit(self)
	print("Муравей погиб. Причина: ", _reason)
	queue_free()


func _flip_sprite(dir_x: float) -> void:
	if sprite and abs(dir_x) > 0.1:
		sprite.scale.x = abs(sprite.scale.x) if dir_x > 0 else -abs(sprite.scale.x)

### Подстановка текстуры в зависимости от ant_type
#func _apply_visuals() -> void:
	#if not sprite_2d:
		#return
#
	#match ant_type:
		#Cocoon.AntType.WORKER:
			#if worker_texture:
				#sprite_2d.texture = worker_texture
		#Cocoon.AntType.SOLDIER:
			#if soldier_texture:
				#sprite_2d.texture = soldier_texture
		#Cocoon.AntType.BABYSITTER:
			#if babysitter_texture:
				#sprite_2d.texture = babysitter_texture

func _apply_visuals() -> void:
	if not sprite_2d:
		return

	match ant_type:
		Cocoon.AntType.WORKER:
			sprite_2d.modulate = Color(0.149, 0.569, 0.059, 1.0) # Коричневый
		Cocoon.AntType.SOLDIER:
			sprite_2d.modulate = Color(0.9, 0.2, 0.2) # Красный
		Cocoon.AntType.BABYSITTER:
			sprite_2d.modulate = Color(0.2, 0.7, 0.9) # Голубой


## Назначение домашнего чанка (вызывается при спавне или переходе)
func assign_chunk(chunk: Chunk) -> void:
	current_chunk = chunk


## Генерация случайной точки внутри границ чанка
func _get_random_point_in_chunk() -> Vector2:
	# Если чанк назначен — выбираем точку внутри его прямоугольника с небольшим отступом от стен
	if is_instance_valid(current_chunk):
		var margin: float = 16.0 # Отступ от границ, чтобы муравей не застревал в стенах
		var min_x: float = current_chunk.global_position.x + margin
		var max_x: float = current_chunk.global_position.x + current_chunk.chunk_size.x - margin
		var min_y: float = current_chunk.global_position.y + margin
		var max_y: float = current_chunk.global_position.y + current_chunk.chunk_size.y - margin

		# На случай, если чанк слишком маленький для отступов
		if min_x < max_x and min_y < max_y:
			return Vector2(randf_range(min_x, max_x), randf_range(min_y, max_y))

	# Запасной вариант: если чанк не найден, блуждаем вокруг текущей точки
	var random_dir := Vector2.from_angle(randf_range(0.0, TAU))
	return global_position + (random_dir * randf_range(15.0, 45.0))
