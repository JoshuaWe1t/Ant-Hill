extends CanvasLayer

@onready var build_panel: Panel = $MainControl/BuildPanel
@onready var hbox: HBoxContainer = $MainControl/BuildPanel/ScrollContainer/HBoxContainer
@onready var tooltip: PanelContainer = $MainControl/TooltipPanel
@onready var name_label: Label = $MainControl/TooltipPanel/VBoxContainer/NameLabel
@onready var desc_label: Label = $MainControl/TooltipPanel/VBoxContainer/DescLabel
@onready var req_label: Label = $MainControl/TooltipPanel/VBoxContainer/ReqLabel

var is_menu_open: bool = false
var tween: Tween
var hidden_y: float
var visible_y: float

func _ready() -> void:
	# Вычисляем позиции для анимации (считаем, что точка привязки сверху панели)
	var viewport_size := get_viewport().get_visible_rect().size
	hidden_y = viewport_size.y + 20.0
	visible_y = viewport_size.y - build_panel.size.y - 20.0 # 20px отступ от низа
	
	build_panel.position.y = hidden_y
	tooltip.hide()

	_populate_buttons()

	# Подписка на глобальные события
	if is_instance_valid(EventBus):
		EventBus.queen_selected.connect(_on_queen_selected)
		EventBus.toggle_build_menu.connect(_set_menu_state)


func _populate_buttons() -> void:
	for bldg_id in BuildingDatabase.DATA.keys():
		var data: Dictionary = BuildingDatabase.DATA[bldg_id]
		
		var btn := TextureButton.new()
		btn.custom_minimum_size = Vector2(100, 100)
		btn.ignore_texture_size = true
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		
		# Если есть текстуры зданий, подгружаем их:
		btn.texture_normal = data.get("texture")
		
		# Заглушка, если нет текстур (зеленый квадрат):
		#var placeholder = PlaceholderTexture2D.new()
		#placeholder.size = Vector2(100, 100)
		#btn.texture_normal = placeholder
		
		# Подключение событий наведения и клика
		btn.mouse_entered.connect(_on_btn_hovered.bind(data, btn))
		btn.mouse_exited.connect(_on_btn_exited)
		btn.pressed.connect(_on_btn_pressed.bind(bldg_id))
		
		hbox.add_child(btn)


func _set_menu_state(open: bool) -> void:
	if is_menu_open == open:
		return
	is_menu_open = open

	if tween and tween.is_valid():
		tween.kill()
		
	tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var target_y = visible_y if is_menu_open else hidden_y
	# Анимация "снизу-вверх", длительность 0.4 сек (не слишком быстро)
	tween.tween_property(build_panel, "position:y", target_y, 0.4)
	
	if not is_menu_open:
		tooltip.hide()


func _on_queen_selected(is_selected: bool) -> void:
	_set_menu_state(is_selected)


func _on_btn_hovered(data: Dictionary, btn: TextureButton) -> void:
	name_label.text = data.get("name", "Здание")
	desc_label.text = "Требуется рабочих: %d\nВремя постройки: %s сек" % [data.get("workers_needed", 2), data.get("build_duration", 30)]
	
	var cost_str = "Цена: "
	var cost_dict: Dictionary = data.get("cost", {})
	for res_type in cost_dict.keys():
		var res_name = ResourceManager.ResourceType.keys()[res_type]
		cost_str += "%s: %d  " % [res_name, cost_dict[res_type]]
	req_label.text = cost_str
	
	tooltip.show()


func _process(_delta: float) -> void:
	# Если тултип видим, он плавно следует за мышью (чуть выше курсора)
	if tooltip.visible:
		var mouse_pos = get_viewport().get_mouse_position()
		tooltip.global_position = mouse_pos - Vector2(tooltip.size.x / 2, tooltip.size.y + 15)


func _on_btn_exited() -> void:
	tooltip.hide()


func _on_btn_pressed(bldg_id: String) -> void:
	print("Выбрано здание для постройки: ", bldg_id)
	if is_instance_valid(EventBus):
		EventBus.build_button_pressed.emit(bldg_id)
