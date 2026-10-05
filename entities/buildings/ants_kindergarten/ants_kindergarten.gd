class_name AntsKindergarten
extends BuildingBase

@export var max_cocoon_capacity: int = 2 ## Вместимость: 2 куколки по GDD
@export var incubation_speed_bonus: float = 0.25 ## +25% к скорости инкубации

var stored_cocoons: Array[Cocoon] = []


func _init() -> void:
	building_id = "kindergarten"
	building_name = "Муравьиный сад (Ants' kindergarten)"
	build_duration = 45.0 # 45 сек по GDD
	required_workers = 2
	building_size = Vector2(250, 300) # 250x300 px по GDD


func _on_operational_ready() -> void:
	print("Муравьиный сад функционирует: готов принимать до 2 куколок.")


## Проверка доступности мест для куколок
func can_accept_cocoon() -> bool:
	_cleanup_cocoons()
	return current_state == BuildState.OPERATIONAL and stored_cocoons.size() < max_cocoon_capacity


## Помещение куколки в ясли
func register_cocoon(cocoon: Cocoon) -> bool:
	if not can_accept_cocoon():
		return false

	stored_cocoons.append(cocoon)
	cocoon.tree_exited.connect(_on_cocoon_removed.bind(cocoon))
	print("Куколка помещена в Муравьиный сад (%d/%d)" % [stored_cocoons.size(), max_cocoon_capacity])
	return true


func _on_cocoon_removed(cocoon: Cocoon) -> void:
	if stored_cocoons.has(cocoon):
		stored_cocoons.erase(cocoon)


func _cleanup_cocoons() -> void:
	stored_cocoons = stored_cocoons.filter(func(c): return is_instance_valid(c))
