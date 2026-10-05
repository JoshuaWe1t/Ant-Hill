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


## Обработка мыши с наивысшим приоритетом (до того, как ее перехватит Queen или UI)
func _input(event: InputEvent) -> void:
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


## Обработка клавиатуры (клавиши B, T)
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_B:
			_toggle_test_preview()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_T:
			ResourceManager.add_resources({
				ResourceManager.ResourceType.WOOD: 50,
				ResourceManager.ResourceType.CLAY: 20
			})
			print("Тест: начислены ресурсы")
		elif event.keycode == KEY_3: _start_preview_for("shelter")
		elif event.keycode == KEY_4: _start_preview_for("stockpile")
		elif event.keycode == KEY_5: _start_preview_for("kindergarten")
		elif event.keycode == KEY_6: _start_preview_for("aphid_farm")

		# Нажмите 1 — запустить создание рабочего
		if event.keycode == KEY_1:
			queen.produce_cocoon(Cocoon.AntType.WORKER)
		# Нажмите 2 — запустить создание солдата
		elif event.keycode == KEY_2:
			queen.produce_cocoon(Cocoon.AntType.SOLDIER)

func _toggle_test_preview() -> void:
	if is_instance_valid(current_preview):
		_cancel_preview()
		return

	if not preview_scene:
		push_error("В TestLevel не назначена preview_scene!")
		return

	current_preview = preview_scene.instantiate()
	add_child(current_preview)

	# Тестовые данные Укрытия по GDD (Раздел 4.2): 200x200 px, 10 Дерево, 2 Глина[cite: 7]
	var test_size := Vector2(200, 200)
	var test_cost := {
		ResourceManager.ResourceType.WOOD: 10,
		ResourceManager.ResourceType.CLAY: 2
	}
	current_preview.setup("shelter", test_size, test_cost)


func _cancel_preview() -> void:
	if is_instance_valid(current_preview):
		current_preview.queue_free()
		current_preview = null


#func _confirm_placement() -> void:
	#if not current_preview or not building_base_scene:
		#push_error("Ошибка: нет active_preview или building_base_scene!")
		#return
#
	## 1. Проверяем и списываем ресурсы колонии (GDD Раздел 2.1)[cite: 2]
	#if not ResourceManager.spend_resources(current_preview.build_cost):
		#print("Недостаточно ресурсов для строительства! Требовалось: ", current_preview.build_cost)
		#return
#
	## 2. Создаем чертеж здания (GDD Раздел 4.2)[cite: 7]
	#var new_building: BuildingBase = building_base_scene.instantiate()
	#new_building.global_position = current_preview.global_position
	#new_building.building_name = "Укрытие"
	#new_building.build_duration = 30.0 # 30 сек по GDD[cite: 7]
	#new_building.building_size = current_preview.building_size
	#
	#entities_container.add_child(new_building)
	#print("Чертеж здания успешно установлен на позиции: ", new_building.global_position)
#
	## 3. Закрываем режим превью
	#_cancel_preview()


func _confirm_placement() -> void:
	if not current_preview or not building_base_scene:
		return

	# 1. Проверяем и списываем ресурсы колонии
	if not ResourceManager.spend_resources(current_preview.build_cost):
		print("Недостаточно ресурсов для постройки!")
		return

	# 2. Создаем чертеж здания
	var new_building: BuildingBase = building_base_scene.instantiate()
	new_building.global_position = current_preview.global_position
	new_building.building_name = "Укрытие"
	new_building.build_duration = 30.0 # 30 сек по GDD
	new_building.building_size = current_preview.building_size

	entities_container.add_child(new_building)
	print("Чертеж установлен: ", new_building.global_position)

	# 3. Ищем и отправляем ровно 2 свободных рабочих по GDD[cite: 7]
	if is_instance_valid(ColonyManager):
		var sent: int = ColonyManager.dispatch_workers_to(new_building, 2)
		if sent < 2:
			print("Внимание: Найдено только %d свободных рабочих из 2!" % sent)

	# 4. Закрываем превью
	_cancel_preview()


func _start_preview_for(bldg_id: String) -> void:
	_cancel_preview()
	current_selected_building_id = bldg_id
	var data: Dictionary = BuildingDatabase.DATA[bldg_id]

	current_preview = preview_scene.instantiate()
	add_child(current_preview)
	current_preview.setup(data.id, data.size, data.cost)
