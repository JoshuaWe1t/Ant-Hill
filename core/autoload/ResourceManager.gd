extends Node

# Сигналы для обновления интерфейса
signal resource_changed(type, new_amount)
signal resources_updated(all_resources: Dictionary)
signal storage_limit_updated(current_total: int, max_capacity: int)

# 7 типов ресурсов колонии
enum ResourceType {
	WATER,
	PROTEIN,
	PHYTOMASS,
	WOOD,
	CLAY,
	RESIN,
	SILK
}

# Стартовые значения из GDD
const STARTING_RESOURCES: Dictionary = {
	ResourceType.WATER: 100,
	ResourceType.PROTEIN: 50,
	ResourceType.PHYTOMASS: 50,
	ResourceType.WOOD: 100,
	ResourceType.CLAY: 100,
	ResourceType.RESIN: 50,
	ResourceType.SILK: 25
}

# Текущий баланс ресурсов
var resources: Dictionary = {}

# Общая суммарная вместимость всех ресурсов (наращивается зданиями Nest, Stockpile и т.д.)
var max_resource_capacity: int = 0


func _ready() -> void:
	reset_to_defaults()


## Сброс к стартовым значениям (при старте или рестарте уровня)
func reset_to_defaults() -> void:
	resources = STARTING_RESOURCES.duplicate()
	max_resource_capacity = 0 # Заполняется зданиями при их спавне
	resources_updated.emit(resources)
	storage_limit_updated.emit(get_total_resources(), max_resource_capacity)


## Суммарное количество всех хранящихся ресурсов в колонии
func get_total_resources() -> int:
	var total: int = 0
	for amount in resources.values():
		total += amount
	print("RESOURCES: " + str(total), '\n', resources)
	return total

## Текущий максимальный лимит складаt
func get_max_capacity() -> int:
	return max_resource_capacity


## Получение текущего количества конкретного ресурса
func get_resource(type: ResourceType) -> int:
	return resources.get(type, 0)


## Проверка, хватает ли ресурсов на постройку / создание юнита
func has_resources(cost_dict: Dictionary) -> bool:
	for type in cost_dict:
		var required_amount: int = cost_dict[type]
		if get_resource(type) < required_amount:
			return false
	return true


## Списание ресурсов. Возвращает true при успехе
func spend_resources(cost_dict: Dictionary) -> bool:
	if not has_resources(cost_dict):
		return false
	
	for type in cost_dict:
		resources[type] -= cost_dict[type]
		resource_changed.emit(type, resources[type])
	
	resources_updated.emit(resources)
	storage_limit_updated.emit(get_total_resources(), max_resource_capacity)
	return true


## Начисление ресурсов с учетом общей суммарной емкости склада
func add_resources(gain_dict: Dictionary) -> void:
	var current_total: int = get_total_resources()
	var free_space: int = maxi(0, max_resource_capacity - current_total)

	if free_space <= 0:
		print("Склады колонии переполнены! Ресурсы не могут быть приняты.")
		return

	# Считаем, сколько суммарно единиц пытаются занести
	var incoming_total: int = 0
	for amount in gain_dict.values():
		incoming_total += amount

	# Если всё помещается целиком
	if incoming_total <= free_space:
		for type in gain_dict:
			resources[type] = resources.get(type, 0) + gain_dict[type]
			resource_changed.emit(type, resources[type])
	else:
		# Если места меньше, чем пришло — заполняем остаток пропорционально
		print("Склад почти полон. Часть ресурсов не поместилась.")
		var ratio: float = float(free_space) / float(incoming_total)
		for type in gain_dict:
			var accepted: int = int(round(gain_dict[type] * ratio))
			resources[type] = resources.get(type, 0) + accepted
			resource_changed.emit(type, resources[type])

	resources_updated.emit(resources)
	storage_limit_updated.emit(get_total_resources(), max_resource_capacity)


## Увеличение емкости складов (при спавне Nest: +500 или постройке Stockpile: +N)
func increase_storage(amount: int) -> void:
	max_resource_capacity += amount
	storage_limit_updated.emit(get_total_resources(), max_resource_capacity)
	print("Вместимость склада увеличена на %d. Всего мест: %d" % [amount, max_resource_capacity])


## Уменьшение емкости складов (при разрушении здания склада)
func decrease_storage(amount: int) -> void:
	max_resource_capacity = maxi(0, max_resource_capacity - amount)
	storage_limit_updated.emit(get_total_resources(), max_resource_capacity)
