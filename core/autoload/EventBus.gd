extends Node

# Сигналы Королевы
@warning_ignore("unused_signal")
signal queen_selected(is_selected: bool)
@warning_ignore("unused_signal")
signal queen_health_updated(current_hp: float, max_hp: float)
@warning_ignore("unused_signal")
signal queen_died

# Сигналы мира и чанков
@warning_ignore("unused_signal")
signal chunk_clicked(chunk: Node)
@warning_ignore("unused_signal")
signal scout_mission_started(target_chunk: Node)

# Сигналы строительства и юнитов
@warning_ignore("unused_signal")
signal spawn_place(building_type: int, position: Vector2)
@warning_ignore("unused_signal")
signal ant_spawned(ant_type: int)

# Сигналы голода Королевы
@warning_ignore("unused_signal")
signal queen_starving(missing_amount: int)
@warning_ignore("unused_signal")
signal queen_fed

# Сигналы строительства зданий 
@warning_ignore("unused_signal")
signal building_placement_requested(building_id: String)
@warning_ignore("unused_signal")
signal building_placed(building_instance: Node2D)
@warning_ignore("unused_signal")
signal building_construction_finished(building_instance: Node2D)

# Сигнал для активации/скрытия меню (через клавишу B или выбор королевы)
@warning_ignore("unused_signal")
signal toggle_build_menu(is_open: bool)

# Сигнал запроса на старт превью постройки из меню
@warning_ignore("unused_signal")
signal build_button_pressed(building_id: String)

# Сигнал отправляется при клике на иконку королевы в интерфейсе
@warning_ignore("unused_signal")
signal ui_queen_icon_clicked

# Управление меню команд Королевы
@warning_ignore("unused_signal")
signal toggle_queen_commands(is_open: bool)

# Режим выбора чанка для разведки
@warning_ignore("unused_signal")
signal toggle_scout_mode(is_active: bool)

@warning_ignore("unused_signal")
signal show_notification(message: String)
