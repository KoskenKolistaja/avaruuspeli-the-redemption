extends Node



var resource_amount = 5

var resource_names = {
	1: "population",
	2: "food",
	3: "technology",
	4: "iron",
	5: "uranium"
}

var population_icon = preload("res://Assets/Textures/UI Textures/Resources/People.png")
var food_icon = preload("res://Assets/Textures/UI Textures/Resources/Food.png")
var technology_icon = preload("res://Assets/Textures/UI Textures/Resources/Cog.png")
var iron_icon = preload("res://Assets/Textures/UI Textures/Resources/Ingot.png")
var uranium_icon = preload("res://Assets/Textures/UI Textures/Resources/Ingot.png")

var resource_icons = {
	1: population_icon,
	2: food_icon,
	3: technology_icon,
	4: iron_icon,
	5: uranium_icon,
}


var population_tresholds = [0,20,40,60,80,100]


func get_resource_id(resource_name : String) -> int:
	for key in resource_names:
		if resource_names[key] == resource_name:
			return key
	return -1
