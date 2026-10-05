class_name BuildingDatabase

static var DATA: Dictionary = {
	"shelter": {
		"id": "shelter",
		"name": "Укрытие",
		"size": Vector2(200, 200),
		"cost": {
			ResourceManager.ResourceType.WOOD: 10,
			ResourceManager.ResourceType.CLAY: 2
		},
		"scene": preload("res://entities/buildings/shelter/shelter.tscn")
	},
	"stockpile": {
		"id": "stockpile",
		"name": "Общее хранилище",
		"size": Vector2(150, 150),
		"cost": {
			ResourceManager.ResourceType.WOOD: 10,
			ResourceManager.ResourceType.CLAY: 10,
			ResourceManager.ResourceType.RESIN: 5
		},
		"scene": preload("res://entities/buildings/stockpile/stockpile.tscn")
	},
	"kindergarten": {
		"id": "kindergarten",
		"name": "Муравьиный сад",
		"size": Vector2(250, 300),
		"cost": {
			ResourceManager.ResourceType.WATER: 3,
			ResourceManager.ResourceType.WOOD: 15,
			ResourceManager.ResourceType.CLAY: 5
		},
		"scene": preload("res://entities/buildings/ants_kindergarten/ants_kindergarten.tscn")
	},
	"aphid_farm": {
		"id": "aphid_farm",
		"name": "Ферма тли",
		"size": Vector2(300, 150),
		"cost": {
			ResourceManager.ResourceType.WATER: 2,
			ResourceManager.ResourceType.PROTEIN: 2,
			ResourceManager.ResourceType.PHYTOMASS: 2,
			ResourceManager.ResourceType.WOOD: 5,
			ResourceManager.ResourceType.CLAY: 2,
			ResourceManager.ResourceType.RESIN: 2
		},
		"scene": preload("res://entities/buildings/aphid_farm/aphid_farm.tscn")
	}
}
