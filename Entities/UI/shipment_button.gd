extends Panel

var trade_index = 0
var root_parent
var resource_type : String
var resource_amount : int
var receiver_id : int

@export var population_icon : Texture
@export var food_icon : Texture
@export var technology_icon : Texture
@export var iron_icon : Texture
@export var uranium_icon : Texture

func _ready():
	$MarginContainer/HBoxContainer/DeleteButton.connect("pressed",_on_delete_button_pressed)
	
	update()



func update():
	for key in PlanetData.planet_references:
		var planet_icon = PlanetData.get_planet(key).planet_icon
		$MarginContainer/HBoxContainer/PlanetButton.add_icon_item(planet_icon, PlanetData.planet_names[key], key)
	
	select_planet_by_id(receiver_id)
	
	$MarginContainer/HBoxContainer/Amount.value = resource_amount
	
	update_icon()

func select_planet_by_id(target_id):
	var option_button = $MarginContainer/HBoxContainer/PlanetButton
	
	# 1. Find which index corresponds to your target_id
	var index_to_select = option_button.get_item_index(target_id)
	
	# 2. Select that index (if valid)
	if index_to_select != -1:
		option_button.select(index_to_select)
	else:
		push_warning("ID " + str(target_id) + " not found in OptionButton!")



func update_icon():
	match resource_type:
		"population":
			$MarginContainer/HBoxContainer/ResourceIcon.texture = population_icon
		"food":
			$MarginContainer/HBoxContainer/ResourceIcon.texture = food_icon
		"technology":
			$MarginContainer/HBoxContainer/ResourceIcon.texture = technology_icon
		"iron":
			$MarginContainer/HBoxContainer/ResourceIcon.texture = iron_icon
		"uranium":
			$MarginContainer/HBoxContainer/ResourceIcon.texture = uranium_icon












func _on_delete_button_pressed():
	root_parent.request_delete_trade(trade_index)
