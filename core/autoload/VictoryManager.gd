class_name VictoryManagerClass
extends Node

signal session_time_updated(time_left: float)
signal victory_achieved(condition_name: String)
signal defeat_achieved(reason: String)
@warning_ignore("unused_signal")
signal goal_updated

enum VictoryConditionType {
	TOTAL_ANTS,
	SPECIFIC_ANT_TYPE,
	OPENED_CHUNKS_AREA,
	COLLECT_RESOURCES
}

@export var target_total_ants: int = 50
@export var target_ant_type: Cocoon.AntType = Cocoon.AntType.SOLDIER
@export var target_ant_type_count: int = 10
@export var target_unlocked_chunks: int = 6
@export var target_resources: Dictionary = {
	ResourceManager.ResourceType.PROTEIN: 100,
	ResourceManager.ResourceType.WATER: 100
}

@export var active_condition: VictoryConditionType = VictoryConditionType.TOTAL_ANTS

# Настройки времени
@export var time_limit_seconds: float = 600.0 # По умолчанию 10 минут (600 сек)
var time_left: float = 0.0

var is_game_over: bool = false
var is_timer_active: bool = true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	time_left = time_limit_seconds


func _process(delta: float) -> void:
	if not is_timer_active or is_game_over:
		return

	time_left -= delta
	
	if time_left <= 0.0:
		time_left = 0.0
		session_time_updated.emit(time_left)
		_trigger_defeat("Время вышло!")
		return

	session_time_updated.emit(time_left)

	# Проверяем условия каждый 10-й кадр для оптимизации
	if Engine.get_process_frames() % 10 == 0:
		_check_victory_conditions()


func _check_victory_conditions() -> void:
	if is_game_over:
		return

	match active_condition:
		VictoryConditionType.TOTAL_ANTS:
			if is_instance_valid(ColonyManager):
				if ColonyManager.get_current_population() >= target_total_ants:
					_trigger_victory("Популяция достигла %d муравьев!" % target_total_ants)

		VictoryConditionType.SPECIFIC_ANT_TYPE:
			if is_instance_valid(ColonyManager):
				var matching_ants = 0
				for ant in ColonyManager.alive_ants:
					if is_instance_valid(ant) and ant.ant_type == target_ant_type:
						matching_ants += 1
				if matching_ants >= target_ant_type_count:
					_trigger_victory("Выращено %d элитных юнитов!" % target_ant_type_count)

		VictoryConditionType.OPENED_CHUNKS_AREA:
			var chunk_manager = get_tree().root.find_child("ChunkManager", true, false)
			if chunk_manager and "all_chunks" in chunk_manager:
				var unlocked_count = 0
				for chunk in chunk_manager.all_chunks:
					if is_instance_valid(chunk) and chunk.status == Chunk.Status.UNLOCKED:
						unlocked_count += 1
				if unlocked_count >= target_unlocked_chunks:
					_trigger_victory("Открыто %d чанков!" % target_unlocked_chunks)

		VictoryConditionType.COLLECT_RESOURCES:
			if is_instance_valid(ResourceManager):
				var goals_met = true
				for res_type in target_resources.keys():
					if ResourceManager.get_resource(res_type) < target_resources[res_type]:
						goals_met = false
						break
				if goals_met:
					_trigger_victory("Ресурсы собраны!")


func _trigger_victory(message: String) -> void:
	is_game_over = true
	is_timer_active = false
	victory_achieved.emit(message)
	print("🏆 ПОБЕДА! Осталось времени: %s. Причина: %s" % [format_time(time_left), message])


func _trigger_defeat(message: String) -> void:
	is_game_over = true
	is_timer_active = false
	defeat_achieved.emit(message)
	print("💀 ПОРАЖЕНИЕ! %s" % message)


func format_time(time_in_sec: float) -> String:
	var minutes = int(time_in_sec) / 60.0
	var seconds = int(time_in_sec) % 60
	return "%02d:%02d" % [minutes, seconds]


func reset_state() -> void:
	is_game_over = false
	time_left = time_limit_seconds
