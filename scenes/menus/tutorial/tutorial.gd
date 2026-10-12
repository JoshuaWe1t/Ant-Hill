extends Control

# Массив с данными страниц (текстура и описание)
var pages: Array = [
	{
		"texture": preload("res://scenes/menus/tutorial/toturial-main_data1.png"),
		"text": "Use WASD or arrow keys to move the camera up/left/down/right.\nUse the mouse wheel to zoom in and out."
	},
	{
		"texture": preload("res://scenes/menus/tutorial/toturial-main_data2.png"),
		"text": "Click on the Queen in the center of the screen or on her icon in the bottom left to open the Command and Construction panels."
	},
	{
		"texture": preload("res://scenes/menus/tutorial/tutorial-queen_panel1.png"),
		"text": "To the right of the active Queen icon is the ant command panel."
	},
	{
		"texture": preload("res://scenes/menus/tutorial/tutorial-queen_panel2.png"),
		"text": "To the right of the command panel is the construction panel with available structures."
	},
	{
		"texture": preload("res://scenes/menus/tutorial/tutorial-discover.png"),
		"text": "The Discover command allows you to explore new territories\nthat are adjacent to available territories.\n1. Select the command\n2. Left-click on an unexplored territory"
	},
	{
		"texture": preload("res://scenes/menus/tutorial/toturial-collect.png"),
		"text": "The Collect resources command allows you to replenish the colony's storage.\n1. Select the command\n2. Mark the required resources\n3. Click Collect"
	},
	{
		"texture": preload("res://scenes/menus/tutorial/toturial-spawn.png"),
		"text": "The Spawn command allows you to create new ant hill inhabitants.\n1. Click on the command\n2. Select the required ant type"
	},
	{
		"texture": preload("res://scenes/menus/tutorial/toturial-main_data3.png"),
		"text": "The upper-left corner displays the session timer.\nIf the timer expires, you will lose unless you complete the key task."
	},
	{
		"texture": preload("res://scenes/menus/tutorial/toturial-main_data4.png"),
		"text": "The upper-left corner displays the task you need to complete."
	},
	{
		"texture": preload("res://scenes/menus/tutorial/toturial-main_data5.png"),
		"text": "The upper-right corner displays the resources used to spawn new ants\nand consumed by every ant (including the Queen) every few seconds"
	},
	{
		"texture": preload("res://scenes/menus/tutorial/toturial-main_data6.png"),
		"text": "The right side displays the resources required for constructing buildings."
	},
	{
		"texture": preload("res://scenes/menus/tutorial/toturial-main_data7.png"),
		"text": "The total ant population icon is located below the resources."
	},
	{
		"texture": preload("res://scenes/menus/tutorial/toturial-main_data8.png"),
		"text": "Next is the icon for the Worker Ant."
	},
	{
		"texture": preload("res://scenes/menus/tutorial/toturial-main_data9.png"),
		"text": "Next is the icon for the Soldier Ant."
	},
	{
		"texture": preload("res://scenes/menus/tutorial/toturial-main_data10.png"),
		"text": "Next is the icon for the Nurse Ant."
	},
	{
		"texture": preload("res://scenes/menus/tutorial/toturial-main_data11.png"),
		"text": "The final icon represents the ant hill's storage capacity."
	}
]

var current_page_index: int = 0

# Ссылки на узлы сцены
@onready var label: Label = $Label
@onready var btn_next: TextureButton = $BtnNext
@onready var btn_prev: TextureButton = $BtnPrev
@onready var texture_rect: TextureRect = $TextureRect


func _ready() -> void:
	btn_next.pressed.connect(_on_btn_next_pressed)
	btn_prev.pressed.connect(_on_btn_prev_pressed)
	
	btn_next.show()
	btn_prev.hide()
	
	# Отображаем первую страницу при старте
	update_page()


func _process(_delta: float) -> void:
	if current_page_index <= 0:
		btn_prev.hide()
	else:
		btn_prev.show()
	
	if current_page_index == pages.size() - 1:
		btn_next.hide()
	else:
		btn_next.show()


# Функция обновления контента на экране
func update_page() -> void:
	var current_data = pages[current_page_index]
	
	label.text = current_data.get("text", "")
	texture_rect.texture = current_data.get("texture", "")


# Сигнал от левой кнопки (назад)
func _on_btn_prev_pressed() -> void:
	if current_page_index > 0:
		current_page_index -= 1
		update_page()
	#else:
		## Опционально: закольцевать перелистывание
		#current_page_index = pages.size() - 1
		#update_page()


# Сигнал от правой кнопки (вперед)"justification_flags"
func _on_btn_next_pressed() -> void:
	if current_page_index < pages.size() - 1:
		current_page_index += 1
		update_page()
	#else:
		## Опционально: закольцевать перелистывание
		#current_page_index = 0
		#update_page()


func _on_button_pressed() -> void:
	# Укажите путь к сцене вашего главного меню
	get_tree().change_scene_to_file("res://scenes/menus/main_menu/main_menu.tscn")
