extends Node2D

@onready var queen: Queen = $Queen

func _ready() -> void:
	print("Тестовая сцена запущена. Используйте WASD для камеры, колесико для зума.")
	print("Кликните на Королеву для проверки выделения.")

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.is_pressed()):
		return
		
	# Нажмите [T], чтобы начислить ресурсы и проверить реакцию HUD
	if event.keycode == KEY_T:
		ResourceManager.add_resources({
			ResourceManager.ResourceType.WATER: 25,
			ResourceManager.ResourceType.WOOD: 50
		})
		print("Тест: начислены ресурсы")

	# Нажмите [K], чтобы нанести 20 урона Королеве и проверить здоровье
	elif event.keycode == KEY_K:
		if is_instance_valid(queen):
			queen.take_damage(20.0)
			print("Тест: Королева получила урон")
			
	# Нажмите 1 — запустить создание рабочего
	if event.keycode == KEY_1:
		queen.produce_cocoon(Cocoon.AntType.WORKER)
	# Нажмите 2 — запустить создание солдата
	elif event.keycode == KEY_2:
		queen.produce_cocoon(Cocoon.AntType.SOLDIER)
