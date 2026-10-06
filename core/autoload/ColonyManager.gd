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


## Отправка муравьев на сбор
func dispatch_foragers() -> void:
	var sent: int = 0
	for ant in alive_ants:
		if ant.current_state == ant.State.IDLE:
			ant.call("start_field_task", AntBase.State.FORAGING, 20.0, ant.global_position)
			sent += 1
			if sent >= 2:
				break
	print("Отправлено сборщиков: %d/2" % sent)


## Завершение задачи и начисление ресурсов
func complete_ant_task(ant: Node, task_type: AntBase.State) -> void:
	var loot: Dictionary = {}
	var types = ResourceManager.ResourceType.values()
	types.shuffle()
	
	if task_type == AntBase.State.SCOUTING:
		# Награда за разведку выдается чанком. Здесь просто логируем возвращение бойца.
		print("Разведчик вернулся на базу!")
		return
			
	elif task_type == AntBase.State.FORAGING:
		var total_limit = randi_range(50, 150)
		for i in range(4):
			var amount = randi_range(5, max(5, int(total_limit / (4.0 - i))))
			loot[types[i]] = amount
			total_limit -= amount
		print("Сборщик вернулся! Собрано: ", loot)
		
		if is_instance_valid(ResourceManager) and not loot.is_empty():
			ResourceManager.add_resources(loot)
