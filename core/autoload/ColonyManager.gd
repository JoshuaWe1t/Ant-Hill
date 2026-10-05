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

	return true


func _on_ant_died(ant: AntBase) -> void:
	if alive_ants.has(ant):
		alive_ants.erase(ant)
		_emit_update()


## Отправка свободных рабочих на стройплощадку
## Ищет рабочих (ant_type == WORKER), находящихся в состоянии IDLE
func dispatch_workers_to(building: BuildingBase, count: int = 2) -> int:
	_cleanup()
	var assigned: int = 0

	for ant in alive_ants:
		# Проверяем, что это рабочий и он ничем не занят
		if ant.ant_type == Cocoon.AntType.WORKER and ant.current_state == AntBase.State.IDLE:
			ant.assign_to_construction(building)
			assigned += 1
			if assigned >= count:
				break

	print("На стройку %s отправлено свободных рабочих: %d/%d" % [building.building_name, assigned, count])
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
