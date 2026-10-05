class_name AphidFarm
extends BuildingBase

@export var production_interval: float = 15.0 ## 15 сек по GDD
@export var max_worker_capacity: int = 5      ## Вместимость: 5 юнитов по GDD

# Производство ресурсов за 1 такт по GDD (Раздел 4.2)
@export var production_yield: Dictionary = {
	ResourceManager.ResourceType.WATER: 2,
	ResourceManager.ResourceType.PROTEIN: 2,
	ResourceManager.ResourceType.PHYTOMASS: 5,
	ResourceManager.ResourceType.SILK: 3
}

var production_timer: Timer = null


func _init() -> void:
	building_id = "aphid_farm"
	building_name = "Ферма тли (Aphid farm)"
	build_duration = 50.0 # 50 сек по GDD
	required_workers = 2
	building_size = Vector2(300, 150) # 300x150 px по GDD


func _on_operational_ready() -> void:
	production_timer = Timer.new()
	production_timer.wait_time = production_interval
	production_timer.autostart = true
	production_timer.one_shot = false
	production_timer.timeout.connect(_on_production_tick)
	add_child(production_timer)
	production_timer.start()
	print("Ферма тли готова и начала производство ресурсов каждые 15 сек.")


func _on_production_tick() -> void:
	if is_instance_valid(ResourceManager):
		ResourceManager.add_resources(production_yield)
		print("Ферма тли произвела партию ресурсов: ", production_yield)
