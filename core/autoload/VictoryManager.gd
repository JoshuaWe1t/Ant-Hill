class_name VictoryManagerClass
extends Node

#signal session_time_updated(time_left: float)
signal victory_achieved(condition_name: String)
signal defeat_achieved(reason: String)
@warning_ignore("unused_signal")
signal goal_updated(msg: String)
@warning_ignore("unused_signal")
signal send_mission_data(data: Dictionary)

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
@export var time_limit_seconds: float = 600.0
var time_left: float = 0.0

var is_game_over: bool = false
var is_timer_active: bool = true

const CHECK_INTERVAL: float = 0.16 # Проверка примерно каждые 10 кадров (при 60 FPS)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	time_left = time_limit_seconds
	
	EventBus.timer_update.connect(_on_timer_update)
	EventBus.timer_is_out.connect(_on_time_is_out)
	
	print('VictoryManager', time_left)

func _process(_delta: float) -> void:
	if not is_timer_active or is_game_over:
		return


func _on_timer_update(time):
	time_left = time


func _check_victory_conditions() -> void:
	if is_game_over:
		return

	match active_condition:
		VictoryConditionType.TOTAL_ANTS:
			if is_instance_valid(ColonyManager):
				if ColonyManager.get_current_population() >= target_total_ants:
					_trigger_victory("The population has reached %d ants!" % target_total_ants)

		VictoryConditionType.SPECIFIC_ANT_TYPE:
			if is_instance_valid(ColonyManager):
				var matching_ants = 0
				for ant in ColonyManager.alive_ants:
					if is_instance_valid(ant) and ant.ant_type == target_ant_type:
						matching_ants += 1
				if matching_ants >= target_ant_type_count:
					_trigger_victory("Hatched %d elite units!" % target_ant_type_count)

		VictoryConditionType.OPENED_CHUNKS_AREA:
			var chunk_manager = get_tree().root.find_child("ChunkManager", true, false)
			if chunk_manager and "all_chunks" in chunk_manager:
				var unlocked_count = 0
				for chunk in chunk_manager.all_chunks:
					if is_instance_valid(chunk) and chunk.status == Chunk.Status.UNLOCKED:
						unlocked_count += 1
				if unlocked_count >= target_unlocked_chunks:
					_trigger_victory("Explored %d chunks!" % target_unlocked_chunks)

		VictoryConditionType.COLLECT_RESOURCES:
			if is_instance_valid(ResourceManager):
				var goals_met = true
				for res_type in target_resources.keys():
					if ResourceManager.get_resource(res_type) < target_resources[res_type]:
						goals_met = false
						break
				if goals_met:
					_trigger_victory("Resources are collected!")


func _trigger_victory(message: String) -> void:
	is_game_over = true
	is_timer_active = false
	victory_achieved.emit(message)
	print("🏆 ПОБЕДА! Осталось времени: %s. Причина: %s" % [format_time(time_left), message])


func _trigger_defeat(message: String) -> void:
	is_game_over = true
	is_timer_active = false
	defeat_achieved.emit(message)
	print("💀 DEFET! %s" % message)


func format_time(time_in_sec: float) -> String:
	var minutes = int(time_in_sec) / 60.0
	var seconds = int(time_in_sec) % 60
	return "%02d:%02d" % [minutes, seconds]


func reset_state() -> void:
	is_game_over = false
	time_left = time_limit_seconds


## Проверка условий поражения колонии
func _check_defeat_conditions() -> void:
	if is_game_over:
		return

	# 1. Проверка Королевы: здоровье <= 0 или узел уничтожен
	var queen: Node = get_tree().root.find_child("Queen", true, false)
	if not is_instance_valid(queen) or (queen.has_method("get_health") and queen.get_health() <= 0):
		_trigger_defeat("Queen died!")
		return

	# 2. Проверка рабочих муравьев и их куколок
	if is_instance_valid(ColonyManager):
		var active_workers = 0
		for ant in ColonyManager.alive_ants:
			if is_instance_valid(ant) and ant.ant_type == Cocoon.AntType.WORKER:
				active_workers += 1
				
		var cocoon_workers = 0
		# Если в ColonyManager есть метод для подсчета куколок, используем его.
		# Замените этот вызов на вашу фактическую логику хранения куколок, если она отличается.
		if ColonyManager.has_method("get_cocoon_count_by_type"):
			cocoon_workers = ColonyManager.get_cocoon_count_by_type(Cocoon.AntType.WORKER)
			
		# Если нет ни живых рабочих, ни куколок, из которых они могут вылупиться
		if active_workers == 0 and cocoon_workers == 0:
			# Даем небольшую фору в 10 секунд со старта игры на случай загрузки сцены
			if (time_limit_seconds - time_left) > 10.0:
				_trigger_defeat("All ant-workers had dead")
				return


## Выбирает случайное задание для новой сессии и настраивает его параметры
func randomize_mission() -> void:
	var all_conditions = VictoryConditionType.values()
	active_condition = all_conditions.pick_random()

	var mission_text: String = ""
	var mission_obj: Dictionary = {}

	match active_condition:
		
		VictoryConditionType.TOTAL_ANTS:
			target_total_ants = randi_range(40, 80)
			mission_text = "Quest: Reach %d ants population" % target_total_ants
			mission_obj = {
				"type": VictoryConditionType.TOTAL_ANTS,
				"text": mission_text,
				"total": target_total_ants,
				"specific": -1
			}
			
		VictoryConditionType.SPECIFIC_ANT_TYPE:
			var type_name: String = "" 
			# Случайно выбираем, кого нужно вырастить
			target_ant_type = [Cocoon.AntType.SOLDIER, Cocoon.AntType.WORKER, Cocoon.AntType.BABYSITTER].pick_random()
			target_ant_type_count = randi_range(15, 30)
			
			if target_ant_type == Cocoon.AntType.SOLDIER:
				type_name = "solders"
			elif target_ant_type == Cocoon.AntType.BABYSITTER:
				type_name =  "babysitters"
			else:
				type_name =  "workers"
				
			mission_text = "Quest: Grow %d %s" % [target_ant_type_count, type_name]
			mission_obj = {
				"type": VictoryConditionType.SPECIFIC_ANT_TYPE,
				"text": mission_text,
				"total": target_ant_type_count,
				"specific": target_ant_type
			}
			
		VictoryConditionType.OPENED_CHUNKS_AREA:
			target_unlocked_chunks = randi_range(6, 12)
			mission_text = "Quest: Discover %d chunk" % target_unlocked_chunks
			mission_obj = {
				"type": VictoryConditionType.OPENED_CHUNKS_AREA,
				"text": mission_text,
				"total": target_unlocked_chunks,
				"specific": -1
			}
			
		VictoryConditionType.COLLECT_RESOURCES:
			# 1. Получаем числовое значение ресурса (int / enum)
			var key_resource: int = ResourceManager.ResourceType.values().pick_random()
			var target_amount: int = randi_range(80, 200)

			target_resources = {
				key_resource: target_amount
			}

			# 2. Словарь склонений для красивого вывода в миссии
			var res_names_ru: Dictionary = {
				ResourceManager.ResourceType.WATER: "water",
				ResourceManager.ResourceType.PROTEIN: "proteins",
				ResourceManager.ResourceType.PHYTOMASS: "phytomass",
				ResourceManager.ResourceType.WOOD: "woods",
				ResourceManager.ResourceType.CLAY: "clays",
				ResourceManager.ResourceType.RESIN: "resins",
				ResourceManager.ResourceType.SILK: "silks"
			}

			var res_name: String = res_names_ru.get(key_resource, "ресурсов")
			mission_text = "Quest: Collect %d %s" % [target_amount, res_name]
			mission_obj = {
				"type": VictoryConditionType.COLLECT_RESOURCES,
				"text": target_amount,
				"total": target_unlocked_chunks,
				"specific": key_resource
			}

	print("Новая миссия: ", mission_text)
	print(mission_obj)
	goal_updated.emit(mission_text)


func _on_time_is_out():
	print("VICTORYMANAGER - TIME IS OUT")
	_trigger_defeat("Time is out!")
