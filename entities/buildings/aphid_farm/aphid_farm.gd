class_name AphidFarm
extends BuildingBase

@export var production_interval: float = 15.0 ## 15 сек по GDD
@export var max_worker_capacity: int = 5      ## Вместимость: 5 юнитов по GDD

# Производство ресурсов за 1 такт по GDD (Раздел 4.2)
@export var production_yield: Dictionary = {
	ResourceManager.ResourceType.WATER: 20,
	ResourceManager.ResourceType.PROTEIN: 20,
	ResourceManager.ResourceType.PHYTOMASS: 20,
	ResourceManager.ResourceType.SILK: 5
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
	print("Ферма тли готова и начала производство ресурсов каждые %f сек." % [production_interval])
	EventBus.show_notification.emit("The aphid farm is ready and has started producing resources every %f seconds" % [production_interval], 
		Color(0.547, 0.492, 0.223, 1.0))


func _on_production_tick() -> void:
	if is_instance_valid(ResourceManager):
		ResourceManager.add_resources(production_yield)
		print("Ферма тли произвела партию ресурсов: ", production_yield)
	# Начисление и вывод уведомлений в EventBus
	if is_instance_valid(ResourceManager) and not production_yield.is_empty():
		ResourceManager.add_resources(production_yield)
		
		var res_names_ru = {
			ResourceManager.ResourceType.WATER: "water",
			ResourceManager.ResourceType.PROTEIN: "proteins",
			ResourceManager.ResourceType.PHYTOMASS: "phytomasses",
			ResourceManager.ResourceType.WOOD: "woods",
			ResourceManager.ResourceType.CLAY: "clays",
			ResourceManager.ResourceType.RESIN: "resins",
			ResourceManager.ResourceType.SILK: "silks"
		}
		
		if is_instance_valid(EventBus):
			for res_type in production_yield:
				var amount = production_yield[res_type]
				var res_name = res_names_ru.get(res_type, "ресурсов")
				var msg = "Added %d %s" % [amount, res_name]
				EventBus.show_notification.emit(msg, Color(0.2, 1.0, 0.2))
