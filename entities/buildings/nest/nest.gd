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
