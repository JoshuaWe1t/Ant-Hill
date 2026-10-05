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
