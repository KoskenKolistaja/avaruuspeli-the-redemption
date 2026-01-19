extends Node

#ID returns scene
var planet_references = {}

#ID returns name
var planet_names = {}

#ID returns icon
var planet_icons = {}

#ID returns player ID
var planet_owners = {}



var planet_amount = 0



func assign_planet(planet_id,planet_name,planet):
	
	
	planet_references[planet_id] = planet
	planet_names[planet_id] = planet_name
	planet_amount += 1




func get_planet(exported_id):
	var planets = get_tree().get_nodes_in_group("planet")
	
	for p in planets:
		if p.planet_id == exported_id:
			return p
	assert("Planet with corresponding id not found!")
