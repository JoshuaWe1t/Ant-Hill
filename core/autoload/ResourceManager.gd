extends Node

# Сигналы для обновления интерфейса
signal resource_changed(type, new_amount)
signal resources_updated(all_resources)

# Типы ресурсов для исключения опечаток в строках
enum ResourceType {
	WATER,
	PROTEIN,
	PHYTOMASS,
	WOOD,
	CLAY,
	RESIN,
	SILK
}

# Дефолтные стартовые значения из GDD (Раздел 2.2)
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

# Вместимость хранилищ (базовая + прирост от зданий Stockpile)
var storage_limits: Dictionary = {}
const DEFAULT_LIMIT: int = 500


func _ready() -> void:
	reset_to_defaults()


## Сброс к стартовым значениям (при перезапуске уровня)
func reset_to_defaults() -> void:
	resources = STARTING_RESOURCES.duplicate()
	for type in ResourceType.values():
		storage_limits[type] = DEFAULT_LIMIT
	resources_updated.emit(resources)


## Получение текущего количества ресурса
func get_resource(type: ResourceType) -> int:
	return resources.get(type, 0)


## Проверка, хватает ли ресурсов на постройку / создание юнита
## cost_dict: { ResourceType: int }
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
	return true


## Начисление ресурсов с учетом лимита складов
func add_resources(gain_dict: Dictionary) -> void:
	for type in gain_dict:
		var current: int = resources.get(type, 0)
		var limit: int = storage_limits.get(type, DEFAULT_LIMIT)
		resources[type] = mini(current + gain_dict[type], limit)
		resource_changed.emit(type, resources[type])
	
	resources_updated.emit(resources)


## Увеличение емкости складов (при завершении постройки Stockpile)
func increase_storage(amount: int) -> void:
	for type in ResourceType.values():
		storage_limits[type] += amount
