extends Node

#ID returns scene
var planet_references = {}

#ID returns name
#var planet_names = {
	#995: "test_planet",
	#996: "test_planet2",
	#997: "test_planet3",
	#998: "test_planet4",
	#999: "test_planet5"
#}

var planet_names = {}

#ID returns icon
var planet_icons = {}

#ID returns player ID
var planet_owners = {}



var planet_amount = 0




func assign_planet(planet_id,planet_name,planet):
	
	planet_icons[planet_id] = planet.planet_icon
	planet_references[planet_id] = planet
	planet_names[planet_id] = planet_name
	planet_amount += 1




func get_planet(exported_id):
	var planets = get_tree().get_nodes_in_group("planet")
	
	for p in planets:
		if p.planet_id == exported_id:
			return p
	assert("Planet with corresponding id not found!")


func get_planets_by_owner_id(exported_id):
	var planets = get_tree().get_nodes_in_group("planet")
	var returned = []
	for p in planets:
		if p.owner_id == exported_id:
			returned.append(p)
	return returned

func get_planet_ids_by_owner_id(exported_id):
	var planets = get_tree().get_nodes_in_group("planet")
	var returned = []
	for p in planets:
		if p.owner_id == exported_id:
			returned.append(p.planet_id)
	return returned
