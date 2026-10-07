extends Node

signal population_updated(current_ants: int, max_ants: int)

# Динамический предел населения (Гнездо: 30, Укрытие: +25 по GDD)
var max_population: int = 0
var alive_ants: Array[AntBase] = []


## Увеличение лимита жилья (при спавне Nest или завершении постройки Shelter)
func add_population_capacity(bonus: int) -> void:
	max_population += bonus
	_emit_update()
	print("Лимит популяции колонии увеличен на %d. Всего мест: %d" % [bonus, max_population])


## Снятие жилых мест (при разрушении здания)
func remove_population_capacity(bonus: int) -> void:
	max_population = maxi(0, max_population - bonus)
	_emit_update()


## Проверка перед заказом или спавном нового муравья
func can_spawn_ant() -> bool:
	_cleanup()
	return alive_ants.size() < max_population


## Регистрация вылупившегося муравья
func register_ant(ant: AntBase) -> bool:
	if not can_spawn_ant():
		print("Невозможно добавить юнита: колония переполнена (%d/%d)!" % [alive_ants.size(), max_population])
		return false

	if not alive_ants.has(ant):
		alive_ants.append(ant)
		ant.died.connect(_on_ant_died.bind(ant))
		_emit_update()
		
		# Если родился рабочий, проверяем, нет ли для него ожидающих строек
		if ant.ant_type == Cocoon.AntType.WORKER:
			call_deferred("check_pending_constructions")

	return true


func _on_ant_died(ant: AntBase) -> void:
	if alive_ants.has(ant):
		alive_ants.erase(ant)
		_emit_update()


## Отправка свободных рабочих на стройплощадку
func dispatch_workers_to(building: Node, count: int = 2) -> int:
	_cleanup()
	var assigned: int = 0

	for ant in alive_ants:
		if ant.ant_type == Cocoon.AntType.WORKER and ant.current_state == AntBase.State.IDLE:
			ant.call("assign_to_construction", building)
			assigned += 1
			if assigned >= count:
				break

	var b_name = building.get("building_name") if "building_name" in building else "Здание"
	print("На стройку '%s' отправлено свободных рабочих: %d/%d" % [b_name, assigned, count])
	return assigned


func get_current_population() -> int:
	_cleanup()
	return alive_ants.size()


func get_max_population() -> int:
	return max_population


func _cleanup() -> void:
	alive_ants = alive_ants.filter(func(a): return is_instance_valid(a))


func _emit_update() -> void:
	_cleanup()
	population_updated.emit(alive_ants.size(), max_population)


## Поиск строек, которым не хватает рабочих
func check_pending_constructions() -> void:
	_cleanup()
	
	var buildings: Array[Node] = get_tree().get_nodes_in_group("buildings")
	
	for b in buildings:
		if "current_state" in b and b.current_state == 0:
			var needed_workers: int = b.required_workers - b.assigned_workers.size()
			if needed_workers > 0:
				dispatch_workers_to(b, needed_workers)


## Отправка 3 свободных рабочих или солдат на разведку выбранного чанка
func dispatch_scouts_to_chunk(target_chunk: Chunk) -> bool:
	if not is_instance_valid(target_chunk) or not target_chunk.can_be_scouted():
		print("Этот чанк нельзя исследовать (закрыт или нет соседа)!")
		return false

	_cleanup()
	var assigned_ants: Array = []

	for ant in alive_ants:
		if ant.current_state == ant.State.IDLE:
			if ant.ant_type == Cocoon.AntType.WORKER or ant.ant_type == Cocoon.AntType.SOLDIER:
				assigned_ants.append(ant)
				if assigned_ants.size() >= 3:
					break

	if assigned_ants.size() < 3:
		print("Недостаточно свободных рабочих/солдат для разведки! Требуется 3, доступно: %d" % assigned_ants.size())
		return false

	target_chunk.start_scouting()

	for ant in assigned_ants:
		var center_pos = target_chunk.global_position + (target_chunk.chunk_size / 2.0)
		ant.call("start_field_task", AntBase.State.SCOUTING, 45.0, center_pos, target_chunk)

	print("Отряд из 3 муравьев отправлен на разведку чанка!")
	return true


## Отправка муравьев на сбор выбранных ресурсов
func dispatch_foragers(target_resources: Array) -> void:
	var max_foragers: int = randi_range(2, 4)
	var sent: int = 0
	
	for ant in alive_ants:
		if ant.current_state == ant.State.IDLE and ant.ant_type == Cocoon.AntType.WORKER:
			var duration: float = randf_range(30.0, 45.0)
			
			# Сохраняем выбранные ресурсы в метаданные конкретного муравья
			ant.set_meta("forage_targets", target_resources)
			
			ant.call("start_field_task", ant.State.FORAGING, duration, ant.global_position)
			sent += 1
			if sent >= max_foragers:
				break
				
	print("Отправлено сборщиков: %d/%d на %d типов ресурсов" % [sent, max_foragers, target_resources.size()])


## Обновленный метод завершения задачи
func complete_ant_task(ant: Node, task_type: int) -> void:
	var loot: Dictionary = {}
	
	if task_type == 7: # FORAGING (или AntBase.State.FORAGING)
		var total_limit: int = randi_range(70, 200)
		
		# Извлекаем целевые ресурсы, которые были назначены этому муравью
		var target_resources: Array = []
		if ant.has_meta("forage_targets"):
			target_resources = ant.get_meta("forage_targets")
			ant.remove_meta("forage_targets")
			
		if target_resources.size() > 0:
			for res_type in target_resources:
				# Делим общий лимит случайно между выбранными ресурсами
				var amount: int = randi_range(5, max(5, int(total_limit / float(target_resources.size()))))
				loot[res_type] = amount
				total_limit -= amount
				
		print("Сборщик вернулся! Собрано: ", loot)
		
	if is_instance_valid(ResourceManager) and not loot.is_empty():
		ResourceManager.add_resources(loot)
		
		# Словарь склонений для красивого вывода
		var res_names_ru = {
			ResourceManager.ResourceType.WATER: "воды",
			ResourceManager.ResourceType.PROTEIN: "белка",
			ResourceManager.ResourceType.PHYTOMASS: "фитомассы",
			ResourceManager.ResourceType.WOOD: "дерева",
			ResourceManager.ResourceType.CLAY: "глины",
			ResourceManager.ResourceType.RESIN: "смолы",
			ResourceManager.ResourceType.SILK: "шелка"
		}
		
		# Отправляем сообщение для каждого принесенного ресурса
		if is_instance_valid(EventBus):
			for res_type in loot:
				var amount = loot[res_type]
				var res_name = res_names_ru.get(res_type, "ресурсов")
				var msg = "Добавлено %d ед. %s" % [amount, res_name]
				EventBus.show_notification.emit(msg)


func clear_colony_data() -> void:
	alive_ants.clear()
	# Сброс других списков задач или счетчиков популяции


## Создание стартового состава колонии при запуске уровня
func spawn_initial_colony() -> void:
	# Получаем точку спавна в стартовой комнате
	var spawn_pos := Vector2.ZERO
	var chunk_manager = get_tree().root.find_child("ChunkManager", true, false)
	if is_instance_valid(chunk_manager) and chunk_manager.has_method("get_starter_spawn_point"):
		spawn_pos = chunk_manager.get_starter_spawn_point()
	
	# Спавним муравьев нужных типов
	# Предполагается, что у вас есть метод создания юнита по типу (WORKER, SOLDIER, BABYSITTER)
	_spawn_specific_ant(Cocoon.AntType.WORKER, 5, spawn_pos)
	_spawn_specific_ant(Cocoon.AntType.SOLDIER, 2, spawn_pos)
	_spawn_specific_ant(Cocoon.AntType.BABYSITTER, 1, spawn_pos)
	
	print("Стартовый отряд успешно размещен в гнезде!")


## Вспомогательная функция для спавна заданного количества муравьев
func _spawn_specific_ant(ant_type: Cocoon.AntType, count: int, pos: Vector2) -> void:
	# Если у вас в Queen или ColonyManager уже настроен инстансинг сцен муравьев,
	# вы можете вызывать его напрямую. Пример через предзагруженную сцену муравья:
	var ant_scene = preload("res://entities/ants/ant_base.tscn") # Укажите ваш путь к сцене муравья
	
	for i in range(count):
		if ant_scene:
			var ant_instance = ant_scene.instantiate()
			ant_instance.position = pos + Vector2(randf_range(-20, 20), randf_range(-20, 20)) # Небольшой разброс
			
			# Устанавливаем тип муравья (если в ant_base.gd есть соответствующая переменная)
			ant_instance.ant_type = ant_type
			
			# Добавляем на сцену (например, в корень текущей сцены или в контейнер сущностей)
			get_tree().current_scene.add_child(ant_instance)
			
			# Регистрируем муравья в общем списке колонии, если он не делает это сам при _ready()
			if not alive_ants.has(ant_instance):
				alive_ants.append(ant_instance)
