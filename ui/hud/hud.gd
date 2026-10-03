extends CanvasLayer

# Ссылки на лейблы ресурсов
@onready var water_label: Label = $UIControl/ResourcesPanel/MarginContainer/HBoxContainer/WaterBox/Value
@onready var protein_label: Label = $UIControl/ResourcesPanel/MarginContainer/HBoxContainer/ProteinBox/Value
@onready var phytomass_label: Label = $UIControl/ResourcesPanel/MarginContainer/HBoxContainer/PhytomassBox/Value
@onready var wood_label: Label = $UIControl/ResourcesPanel/MarginContainer/HBoxContainer/WoodBox/Value
@onready var clay_label: Label = $UIControl/ResourcesPanel/MarginContainer/HBoxContainer/ClayBox/Value
@onready var resin_label: Label = $UIControl/ResourcesPanel/MarginContainer/HBoxContainer/ResinBox/Value
@onready var silk_label: Label = $UIControl/ResourcesPanel/MarginContainer/HBoxContainer/SilkBox/Value

# Блок миссии и таймера (Левый верхний угол по GDD)
@onready var timer_label: Label = $UIControl/MissionContainer/TimerLabel
@onready var quest_label: Label = $UIControl/MissionContainer/QuestLabel

# Словарь для быстрого доступа по типу из Enum
var _resource_labels: Dictionary = {}


func _ready() -> void:
	# Формируем соответствие enum -> label
	_resource_labels = {
		ResourceManager.ResourceType.WATER: water_label,
		ResourceManager.ResourceType.PROTEIN: protein_label,
		ResourceManager.ResourceType.PHYTOMASS: phytomass_label,
		ResourceManager.ResourceType.WOOD: wood_label,
		ResourceManager.ResourceType.CLAY: clay_label,
		ResourceManager.ResourceType.RESIN: resin_label,
		ResourceManager.ResourceType.SILK: silk_label
	}
	
	# Подписываемся на события менеджера ресурсов
	ResourceManager.resource_changed.connect(_on_resource_changed)
	ResourceManager.resources_updated.connect(_on_resources_updated)
	
	# Первичная инициализация текущими значениями
	_on_resources_updated(ResourceManager.resources)


## Точечное обновление при изменении конкретного ресурса
func _on_resource_changed(type: ResourceManager.ResourceType, new_amount: int) -> void:
	if _resource_labels.has(type):
		_resource_labels[type].text = str(new_amount)


## Массовое обновление (на старте или при общем сбросе пулов)
func _on_resources_updated(all_resources: Dictionary) -> void:
	for type in all_resources:
		if _resource_labels.has(type):
			_resource_labels[type].text = str(all_resources[type])


## Публичные методы для обновления таймера и квеста из GameManager
func update_timer_display(seconds_left: float) -> void:
	var total_seconds: int = int(seconds_left)
	var minutes: int = floori(total_seconds / 60.0)
	var seconds: int = total_seconds % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]


func set_quest_text(description: String) -> void:
	quest_label.text = description


func _unhandled_input(event: InputEvent) -> void:
	# Нажмите T для симуляции сбора 10 воды и 5 дерева
	if event is InputEventKey and event.pressed and event.keycode == KEY_T:
		ResourceManager.add_resources({
			ResourceManager.ResourceType.WATER: 10,
			ResourceManager.ResourceType.WOOD: 5
		})
