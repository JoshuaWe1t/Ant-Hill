class_name Shelter
extends BuildingBase

@export var unit_capacity_bonus: int = 25 ## По GDD вместимость 25 юнитов


func _init() -> void:
	building_id = "shelter"
	building_name = "Укрытие (Shelter)"
	build_duration = 30.0 # 30 сек по GDD
	required_workers = 2
	building_size = Vector2(200, 200) # 200x200 px по GDD


## Срабатывает при завершении стройки
func _on_operational_ready() -> void:
	if is_instance_valid(ColonyManager):
		ColonyManager.add_population_capacity(unit_capacity_bonus)
		print("Укрытие построено! Лимит колонии увеличен на +%d юнитов." % unit_capacity_bonus)


func _exit_tree() -> void:
	# Если здание уничтожено или снесено
	if current_state == BuildState.OPERATIONAL and is_instance_valid(ColonyManager):
		ColonyManager.remove_population_capacity(unit_capacity_bonus)
