#class_name Nest
#extends Area2D
#
#signal capacity_updated(current_units: int, max_units: int, current_res: int, max_res: int)
#
#@export_group("Limits")
#@export var max_unit_capacity: int = 30     ## Не более 30 юнитов
#@export var max_resource_capacity: int = 500 ## Суммарный объем всех ресурсов не более 500
#
#var registered_ants: Array[AntBase] = []
#
#@onready var info_label: Label = get_node_or_null("InfoLabel")
#@onready var selection_indicator: CanvasItem = get_node_or_null("SelectionIndicator")
#
#
#func _ready() -> void:
	#ResourceManager.increase_storage(500)
	#z_index = 2
	#if selection_indicator:
		#selection_indicator.visible = false
#
	## Подписываемся на события шины ресурсов и спавна муравьев
	#if is_instance_valid(EventBus):
		#if EventBus.has_signal("ant_spawned"):
			#EventBus.ant_spawned.connect(_on_ant_spawned)
#
	#_update_display()
#
#
### Проверка: можно ли добавить еще одного муравья в колонию
#func can_accept_unit() -> bool:
	#_cleanup_dead_units()
	#return registered_ants.size() < max_unit_capacity
#
#
### Регистрация нового муравья
#func register_unit(ant: AntBase) -> bool:
	#if not can_accept_unit():
		#print("Гнездо переполнено! Максимум %d юнитов." % max_unit_capacity)
		#return false
#
	#registered_ants.append(ant)
	#ant.died.connect(_on_ant_died)
	#_update_display()
	#return true
#
#
#func _on_ant_died(ant: AntBase) -> void:
	#if registered_ants.has(ant):
		#registered_ants.erase(ant)
		#_update_display()
#
#
#func _on_ant_spawned(_ant_type: int) -> void:
	#_update_display()
#
#
### Проверка суммарной вместимости ресурсов по всем типам
#func get_total_stored_resources() -> int:
	#var total: int = 0
	## Складываем значения всех 7 типов ресурсов колонии
	#for res_type in ResourceManager.ResourceType.values():
		#total += ResourceManager.get_resource(res_type)
	#return total
#
#
### Проверка перед добавлением ресурсов на склад
#func can_store_resources(amount_to_add: int) -> bool:
	#return (get_total_stored_resources() + amount_to_add) <= max_resource_capacity
#
#
#func _cleanup_dead_units() -> void:
	#registered_ants = registered_ants.filter(func(a): return is_instance_valid(a))
#
#
#func _update_display() -> void:
	#_cleanup_dead_units()
	#var cur_units: int = registered_ants.size()
	#var cur_res: int = get_total_stored_resources()
#
	#if info_label:
		#info_label.text = "Гнездо\nЮниты: %d/%d\nСклад: %d/%d" % [
			#cur_units, max_unit_capacity,
			#cur_res, max_resource_capacity
		#]
#
	#capacity_updated.emit(cur_units, max_unit_capacity, cur_res, max_resource_capacity)
class_name Nest
extends Area2D

signal capacity_updated(current_units: int, max_units: int, current_res: int, max_res: int)

@export_group("Limits")
@export var max_unit_capacity: int = 30     ## Стартовая вместимость колонии: 30 юнитов
@export var max_resource_capacity: int = 500 ## Стартовая вместимость склада: 500 ед.

@onready var info_label: Label = get_node_or_null("InfoLabel")
@onready var selection_indicator: CanvasItem = get_node_or_null("SelectionIndicator")


func _ready() -> void:
	z_index = 2
	if selection_indicator:
		selection_indicator.visible = false

	# 1. Регистрируем стартовые бонусы в глобальных менеджерах
	if is_instance_valid(ResourceManager):
		ResourceManager.increase_storage(max_resource_capacity)
		ResourceManager.storage_limit_updated.connect(_on_storage_updated)

	if is_instance_valid(ColonyManager):
		ColonyManager.add_population_capacity(max_unit_capacity)
		ColonyManager.population_updated.connect(_on_population_updated)

	_update_display()


func _exit_tree() -> void:
	# Если Гнездо будет уничтожено — снимаем его бонусы
	if is_instance_valid(ResourceManager):
		ResourceManager.decrease_storage(max_resource_capacity)
	if is_instance_valid(ColonyManager):
		ColonyManager.remove_population_capacity(max_unit_capacity)


## Для обратной совместимости, если где-то остался вызов nest.register_unit()
func register_unit(ant: AntBase) -> bool:
	if is_instance_valid(ColonyManager):
		return ColonyManager.register_ant(ant)
	return false


func _on_population_updated(_cur_pop: int, _max_pop: int) -> void:
	_update_display()


func _on_storage_updated(_cur_res: int, _max_storage: int) -> void:
	_update_display()


func _update_display() -> void:
	var cur_pop: int = ColonyManager.get_current_population() if is_instance_valid(ColonyManager) else 0
	var max_pop: int = ColonyManager.get_max_population() if is_instance_valid(ColonyManager) else max_unit_capacity
	
	var cur_res: int = ResourceManager.get_total_resources() if is_instance_valid(ResourceManager) else 0
	var max_res: int = ResourceManager.get_max_capacity() if is_instance_valid(ResourceManager) else max_resource_capacity

	if info_label:
		info_label.text = "Гнездо\nЮниты: %d/%d\nСклад: %d/%d" % [
			cur_pop, max_pop,
			cur_res, max_res
		]

	capacity_updated.emit(cur_pop, max_pop, cur_res, max_res)


## Проверка возможности принять юнита через ColonyManager
func can_accept_unit() -> bool:
	if is_instance_valid(ColonyManager):
		return ColonyManager.can_spawn_ant()
	return true
