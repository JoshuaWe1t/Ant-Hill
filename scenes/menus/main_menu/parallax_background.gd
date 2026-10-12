extends ParallaxBackground

# Скорость движения фона (в пикселях в секунду)
@export var scroll_speed: float = 50.0

func _process(delta: float) -> void:
	# Меняем базовое смещение всего параллакса
	scroll_offset.x -= scroll_speed * delta
