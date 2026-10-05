class_name BuildingPreview
extends Area2D

@export var valid_color: Color = Color(0.2, 0.9, 0.2, 0.6)
@export var invalid_color: Color = Color(0.9, 0.2, 0.2, 0.6)

var building_id: String = ""
var building_size: Vector2 = Vector2(100, 100)
var build_cost: Dictionary = {}

var is_valid_placement: bool = false
var overlapping_buildings_count: int = 0

@onready var color_rect: ColorRect = $ColorRect
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func setup(id: String, size: Vector2, cost: Dictionary) -> void:
	building_id = id
	building_size = size
	build_cost = cost

	if color_rect:
		color_rect.size = building_size
		color_rect.position = -building_size / 2.0

	if collision_shape:
		var rect_shape := RectangleShape2D.new()
		rect_shape.size = building_size
		collision_shape.shape = rect_shape


func _ready() -> void:
	z_index = 30
	collision_layer = 0
	collision_mask = 1 # Слой зданий (Layer 1)

	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)


func _process(_delta: float) -> void:
	global_position = get_global_mouse_position()
	_update_validation()


func _update_validation() -> void:
	var has_enough_resources: bool = ResourceManager.has_resources(build_cost)
	var is_space_free: bool = (overlapping_buildings_count == 0)
	var is_inside_unlocked_territory: bool = _check_inside_unlocked_chunk()

	is_valid_placement = has_enough_resources and is_space_free and is_inside_unlocked_territory
	modulate = valid_color if is_valid_placement else invalid_color


func _check_inside_unlocked_chunk() -> bool:
	var chunk_mgr: ChunkManager = get_tree().root.find_child("ChunkManager", true, false)
	if not chunk_mgr:
		return false

	var half_size: Vector2 = building_size / 2.0
	var corners: Array[Vector2] = [
		global_position + Vector2(-half_size.x, -half_size.y),
		global_position + Vector2(half_size.x, -half_size.y),
		global_position + Vector2(-half_size.x, half_size.y),
		global_position + Vector2(half_size.x, half_size.y)
	]

	for corner_pos in corners:
		var chunk: Chunk = chunk_mgr.get_chunk_at_position(corner_pos)
		if chunk == null or chunk.status != Chunk.Status.UNLOCKED:
			return false

	return true

#
#func _on_area_entered(area: Area2D) -> void:
	#if area is Nest or area is BuildingBase or area.is_in_group("buildings"):
		#overlapping_buildings_count += 1
#
#
#func _on_area_exited(area: Area2D) -> void:
	#if area is Nest or area is BuildingBase or area.is_in_group("buildings"):
		#overlapping_buildings_count = maxi(0, overlapping_buildings_count - 1)

func _on_area_entered(area: Area2D) -> void:
	if area is Nest or area.is_in_group("buildings"):
		overlapping_buildings_count += 1


func _on_area_exited(area: Area2D) -> void:
	if area is Nest or area.is_in_group("buildings"):
		overlapping_buildings_count = maxi(0, overlapping_buildings_count - 1)
