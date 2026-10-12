extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _on_button_pressed() -> void:
	# Укажите путь к сцене вашего главного меню
	get_tree().change_scene_to_file("res://scenes/menus/main_menu/main_menu.tscn")
