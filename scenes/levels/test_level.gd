extends Node2D

@export var nest_scene: PackedScene
@export var queen_scene: PackedScene
@export var preview_scene: PackedScene
@export var building_base_scene: PackedScene

@onready var chunk_manager: ChunkManager = $ChunkManager
@onready var entities_container: Node2D = get_node_or_null("Entities")

var queen: Queen = null
var nest: Nest = null
var current_preview: BuildingPreview = null
var current_selected_building_id: String = "shelter"
var is_build_mode: bool = false
var is_commands_mode: bool = false
var is_scouting_mode: bool = false # Ждем ли мы клика по чанку

func _ready() -> void:
	if not entities_container:
		entities_container = self

	if not nest_scene or not queen_scene:
		push_error("Не назначены Nest Scene или Queen Scene в TestLevel!")
		return

	if chunk_manager and chunk_manager.all_chunks.is_empty():
		chunk_manager.generate_underground()

	var spawn_pos: Vector2 = Vector2.ZERO
	if chunk_manager:
		spawn_pos = chunk_manager.get_starter_spawn_point()

	# 1. Спавн Гнезда
	nest = nest_scene.instantiate()
	nest.global_position = spawn_pos
	entities_container.add_child(nest)

	# 2. Спавн Королевы
	queen = queen_scene.instantiate()
	queen.global_position = spawn_pos
	queen.home_nest = nest
	entities_container.add_child(queen)
	
	# Спавним стартовых муравьев в гнезде
	ColonyManager.spawn_initial_colony()
	
	# Подключение глобальных сигналов с проверкой
	if is_instance_valid(EventBus):
		if not EventBus.build_button_pressed.is_connected(_on_ui_build_requested):
			EventBus.build_button_pressed.connect(_on_ui_build_requested)
			
		if not EventBus.toggle_scout_mode.is_connected(_on_scout_mode_toggled):
			EventBus.toggle_scout_mode.connect(_on_scout_mode_toggled)
			
		# Безопасное подключение клика по чанку (сигнал должен быть объявлен в EventBus)
		if EventBus.has_signal("chunk_clicked") and not EventBus.is_connected("chunk_clicked", _on_chunk_clicked):
			EventBus.chunk_clicked.connect(_on_chunk_clicked)
	
	# Настраиваем условия победы для этого конкретного уровня
	if is_instance_valid(VictoryManager):
		VictoryManager.active_condition = VictoryManager.VictoryConditionType.SPECIFIC_ANT_TYPE
		VictoryManager.target_ant_type = Cocoon.AntType.SOLDIER # Например, нужны солдаты
		VictoryManager.target_ant_type_count = 5 # Нужно 5 штук
		
		VictoryManager.goal_updated.emit()


## Обработка мыши с наивысшим приоритетом
func _input(event: InputEvent) -> void:
	# Если включен режим разведки, клик ЛКМ перехватывается для выбора чанка
	if is_scouting_mode and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		# Клик обрабатывается через сигнал самого чанка (_on_chunk_clicked)
		return

	if not is_instance_valid(current_preview):
		return

	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_LEFT:
			print("Тест: Нажат ЛКМ! Статус валидности: ", current_preview.is_valid_placement)
			if current_preview.is_valid_placement:
				_confirm_placement()
			else:
				print("Строительство заблокировано! Проверьте условия (красный цвет).")
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			print("Тест: Нажат ПКМ, отмена превью.")
			_cancel_preview()
			get_viewport().set_input_as_handled()


## Обработка клавиатуры
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		
		# Клавиша B: Меню строительства
		if event.keycode == KEY_B:
			is_build_mode = !is_build_mode
			if is_instance_valid(EventBus):
				EventBus.toggle_build_menu.emit(is_build_mode)
			get_viewport().set_input_as_handled()
			
		#elif event.keycode == KEY_T:
			#ResourceManager.add_resources({
				#ResourceManager.ResourceType.WOOD: 50,
				#ResourceManager.ResourceType.CLAY: 20
			#})
			#print("Тест: начислены ресурсы")
			#
		## Горячие клавиши для превью
		#elif event.keycode == KEY_3: _start_preview_for("shelter")
		#elif event.keycode == KEY_4: _start_preview_for("stockpile")
		#elif event.keycode == KEY_5: _start_preview_for("kindergarten")
		#elif event.keycode == KEY_6: _start_preview_for("aphid_farm")

		## Спавн муравьев
		#if event.keycode == KEY_1:
			#queen.produce_cocoon(Cocoon.AntType.WORKER)
		#elif event.keycode == KEY_2:
			#queen.produce_cocoon(Cocoon.AntType.SOLDIER)
		
		# Клавиша C: Меню команд Королевы
		elif event.keycode == KEY_C:
			is_commands_mode = !is_commands_mode
			if is_instance_valid(EventBus):
				EventBus.toggle_queen_commands.emit(is_commands_mode)
			get_viewport().set_input_as_handled()


func _cancel_preview() -> void:
	if is_instance_valid(current_preview):
		current_preview.queue_free()
		current_preview = null


func _confirm_placement() -> void:
	if not current_preview:
		return

	var data: Dictionary = BuildingDatabase.DATA[current_selected_building_id]

	if not ResourceManager.spend_resources(current_preview.build_cost):
		print("Недостаточно ресурсов для постройки!")
		return

	var new_building: BuildingBase = data.scene.instantiate()
	new_building.global_position = current_preview.global_position
	new_building.building_size = data.size
	
	entities_container.add_child(new_building)
	print("Установлен чертеж здания: ", data.name)

	if is_instance_valid(ColonyManager):
		var sent: int = ColonyManager.dispatch_workers_to(new_building, 2)
		if sent < 2:
			print("Внимание: Найдено только %d свободных рабочих из 2!" % sent)

	_cancel_preview()
	
	if is_build_mode:
		is_build_mode = false
		if is_instance_valid(EventBus):
			EventBus.toggle_build_menu.emit(false)


func _start_preview_for(bldg_id: String) -> void:
	_cancel_preview()
	current_selected_building_id = bldg_id
	var data: Dictionary = BuildingDatabase.DATA[bldg_id]

	current_preview = preview_scene.instantiate()
	add_child(current_preview)
	current_preview.setup(data.id, data.size, data.cost)


func _on_ui_build_requested(bldg_id: String) -> void:
	_cancel_preview()
	
	if not preview_scene:
		push_error("В TestLevel не назначена preview_scene!")
		return

	current_selected_building_id = bldg_id
	var data: Dictionary = BuildingDatabase.DATA[bldg_id]
	
	current_preview = preview_scene.instantiate()
	add_child(current_preview)
	current_preview.setup(data.id, data.size, data.cost)


func _on_scout_mode_toggled(is_active: bool) -> void:
	is_scouting_mode = is_active
	print("Режим ожидания выбора чанка для разведки: ", is_scouting_mode)


## Обработка клика по чанку
func _on_chunk_clicked(chunk: Chunk) -> void:
	if not is_scouting_mode:
		return

	if is_instance_valid(ColonyManager) and chunk.can_be_scouted():
		var success = ColonyManager.dispatch_scouts_to_chunk(chunk)
		if success:
			is_scouting_mode = false
			if is_instance_valid(EventBus):
				EventBus.toggle_scout_mode.emit(false)
	else:
		print("Нельзя исследовать этот чанк! Выберите закрытый чанк, граничащий с открытым.")
