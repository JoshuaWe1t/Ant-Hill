class_name BuildingDatabase

static var DATA: Dictionary = {
	"shelter": {
		"id": "shelter",
		"name": "Shelter",
		"size": Vector2(200, 200),
		"cost": {
			ResourceManager.ResourceType.WOOD: 10,
			ResourceManager.ResourceType.CLAY: 2
		},
		"scene": preload("res://entities/buildings/shelter/shelter.tscn"),
		"texture": preload("res://assets/textures/shelter.png"),
		"description": "DESCRIPTION OF BUILDING",
		"workers_needed": 2,
		"build_duration": 30
	},
	"stockpile": {
		"id": "stockpile",
		"name": "Stockpile",
		"size": Vector2(150, 150),
		"cost": {
			ResourceManager.ResourceType.WOOD: 10,
			ResourceManager.ResourceType.CLAY: 10,
			ResourceManager.ResourceType.RESIN: 5
		},
		"scene": preload("res://entities/buildings/stockpile/stockpile.tscn"),
		"texture": preload("res://assets/textures/stockpie.png"),
		"description": "DESCRIPTION OF BUILDING",
		"workers_needed": 2,
		"build_duration": 35
	},
	"kindergarten": {
		"id": "kindergarten",
		"name": "Ants kindergarten",
		"size": Vector2(250, 300),
		"cost": {
			ResourceManager.ResourceType.WATER: 3,
			ResourceManager.ResourceType.WOOD: 15,
			ResourceManager.ResourceType.CLAY: 5
		},
		"scene": preload("res://entities/buildings/ants_kindergarten/ants_kindergarten.tscn"),
		"texture": preload("res://assets/textures/babies-place.png"),
		"description": "DESCRIPTION OF BUILDING",
		"workers_needed": 2,
		"build_duration": 45
	},
	"aphid_farm": {
		"id": "aphid_farm",
		"name": "Aphid_farm",
		"size": Vector2(300, 150),
		"cost": {
			ResourceManager.ResourceType.WATER: 2,
			ResourceManager.ResourceType.PROTEIN: 2,
			ResourceManager.ResourceType.PHYTOMASS: 2,
			ResourceManager.ResourceType.WOOD: 5,
			ResourceManager.ResourceType.CLAY: 2,
			ResourceManager.ResourceType.RESIN: 2
		},
		"scene": preload("res://entities/buildings/aphid_farm/aphid_farm.tscn"),
		"texture": preload("res://assets/textures/farm.png"),
		"description": "DESCRIPTION OF BUILDING",
		"workers_needed": 2,
		"build_duration": 50
	}
}
