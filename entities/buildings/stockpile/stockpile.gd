class_name Stockpile
extends BuildingBase

@export var storage_capacity_bonus: int = 500 ## Увеличивает суммарный склад колонии


func _init() -> void:
	building_id = "stockpile"
	building_name = "Общее хранилище (Stockpile)"
	build_duration = 35.0 # 35 сек по GDD
	required_workers = 2
	building_size = Vector2(150, 150) # 150x150 px по GDD


func _on_operational_ready() -> void:
	if is_instance_valid(ResourceManager):
		ResourceManager.increase_storage(storage_capacity_bonus)
		print("Хранилище построено! Вместимость склада увеличена на +%d ед." % storage_capacity_bonus)
		EventBus.show_notification.emit("Storage built! Warehouse capacity increased by +%d units."  % storage_capacity_bonus, 
		Color(0.547, 0.492, 0.223, 1.0))


func _exit_tree() -> void:
	if current_state == BuildState.OPERATIONAL and is_instance_valid(ResourceManager):
		ResourceManager.decrease_storage(storage_capacity_bonus)
