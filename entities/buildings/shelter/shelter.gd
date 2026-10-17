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
		EventBus.show_notification.emit("Shelter built! Colony limit increased by +%d units."  % unit_capacity_bonus, 
		Color(0.547, 0.492, 0.223, 1.0))


func _exit_tree() -> void:
	# Если здание уничтожено или снесено
	if current_state == BuildState.OPERATIONAL and is_instance_valid(ColonyManager):
		ColonyManager.remove_population_capacity(unit_capacity_bonus)
