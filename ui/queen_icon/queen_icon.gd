extends CanvasLayer

@export_group("Queen Sprites")
@export var sprite_healthy: Texture2D   ## Здоровье == 100
@export var sprite_damaged: Texture2D   ## Здоровье от 41 до 99
@export var sprite_critical: Texture2D  ## Здоровье от 1 до 40
@export var sprite_dead: Texture2D      ## Здоровье == 0

@onready var button: TextureButton = $TextureButton


func _ready() -> void:
	if is_instance_valid(EventBus):
		EventBus.queen_health_updated.connect(_on_health_updated)
		EventBus.queen_died.connect(_on_queen_died)
		
	button.pressed.connect(_on_button_pressed)
	
	# Устанавливаем стартовое состояние (полное здоровье)
	_update_icon(100.0)


func _on_health_updated(current_hp: float, _max_hp: float) -> void:
	_update_icon(current_hp)


func _on_queen_died() -> void:
	_update_icon(0.0)
	button.disabled = true # Отключаем клики, если королева мертва


## Логика смены спрайта по порогам здоровья
func _update_icon(current_hp: float) -> void:
	if current_hp <= 0.0:
		button.texture_normal = sprite_dead
	elif current_hp <= 40.0:
		button.texture_normal = sprite_critical
	elif current_hp < 100.0:
		button.texture_normal = sprite_damaged
	else:
		button.texture_normal = sprite_healthy


## Обработка клика игроком
func _on_button_pressed() -> void:
	if is_instance_valid(EventBus):
		EventBus.ui_queen_icon_clicked.emit()
