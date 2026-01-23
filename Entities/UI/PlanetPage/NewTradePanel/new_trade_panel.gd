extends Control



var their_id = null
var your_planet_id = null
var their_planet_id = null

var is_initial = true


var null_texture = preload("res://Assets/Textures/UI Textures/Cross.png")


var shipment_dictionary_example : Dictionary = {
	"sender_id": 1,
	"receiver_id": 2,
	"rules": {
		1: {"subject": 1, "resource": "food", "condition": ">", "amount": 5},
		2: {"subject": 2, "resource": "food", "condition": "<", "amount": 50000}
	},
	"cargo": {
		"population" : 0,
		"food" : 100,
		"technology" : 0,
		"iron" : 0,
		"uranium" : 0,
		}
}

var shipment_dictionary_example2 : Dictionary = {
	"sender_id": 2,
	"receiver_id": 1,
	"rules": {
		1: {"subject": 1, "resource": "food", "condition": ">", "amount": 5},
		2: {"subject": 2, "resource": "food", "condition": "<", "amount": 50000}
	},
	"cargo": {
		"population" : 0,
		"food" : 100,
		"technology" : 0,
		"iron" : 0,
		"uranium" : 0,
		}
}


var trade_dictionary_example : Dictionary = {
	"shipments" : [shipment_dictionary_example,shipment_dictionary_example2],
	"validator_id" : 1,
	"participant_id" : 1,
	"validator_planet_id" : 1,
	"participant_planet_id" : 2,
}


var saved_trade_data


func _ready():
	init_data()
	await get_tree().create_timer(0.1).timeout
	if saved_trade_data:
		init_from_dictionary(saved_trade_data)


#This function is used when player has incoming trade offer. It reverses participant/validator roles
func init_from_dictionary(trade_data : Dictionary):
	var your_planet_index = %YourPlanetsOptionButton.get_item_index(trade_data["participant_planet_id"])
	%YourPlanetsOptionButton.select(your_planet_index)
	_on_your_planets_option_button_item_selected(your_planet_index)
	var their_planet_index = %TheirPlanetsOptionButton.get_item_index(trade_data["validator_planet_id"])
	%TheirPlanetsOptionButton.select(their_planet_index)
	_on_their_planets_option_button_item_selected(their_planet_index)
	
	var their_id = trade_data["validator_id"]
	
	%PlayersOptionButton.select(their_id)
	_on_players_option_button_item_selected(their_id)
	
	var your_shipment = trade_data["shipments"][1]
	var their_shipment = trade_data["shipments"][0]
	
	%YourRulesContainer.set_rules_from_dictionary(your_shipment["rules"])
	%TheirRulesContainer.set_rules_from_dictionary(their_shipment["rules"])
	
	%YourItemsContainer.set_items_from_dictionary(your_shipment["cargo"])
	%TheirItemsContainer.set_items_from_dictionary(their_shipment["cargo"])
	


var trade_dictionary = {
	"shipments" : ["shipment1","shipment2"],
	"validator_id" : PlayerData.my_id,
	"participant_id" : their_id,
	"validator_planet_id" : your_planet_id,
	"participant_planet_id" : their_planet_id,
}




func trade_is_ready():
	if not their_id:
		%InfoLabel.text = "Missing their id!"
		return false
	if not their_planet_id:
		%InfoLabel.text = "Missing their planet id! " + str(their_planet_id)
		return false
	if not your_planet_id:
		%InfoLabel.text = "Missing your planet id!"
		return false
	
	if not %YourItemsContainer.is_ready():
		%InfoLabel.text = "No items assigned to you"
		return false
	
	if not %TheirItemsContainer.is_ready():
		%InfoLabel.text = "No items assigned to them"
		return false
	
	return true



func parse_trade():
	
	
	if not trade_is_ready():
		return
	
	
	var shipment1_rules = $%YourRulesContainer.get_rules()
	
	for key in shipment1_rules:
		shipment1_rules[key]["subject"] = your_planet_id
	
	var cargo = %YourItemsContainer.get_cargo()
	
	
	var shipment1 = {
		"sender_id" : your_planet_id,
		"receiver_id" : their_planet_id,
		"rules" : shipment1_rules,
		"cargo" : cargo
		
	}
	

	var shipment2_rules = %TheirRulesContainer.get_rules()
	
	for key in shipment1_rules:
		shipment1_rules[key]["subject"] = their_planet_id
	
	var cargo2 = %TheirItemsContainer.get_cargo()
	
	var shipment2 = {
		"sender_id" : their_planet_id,
		"receiver_id" : your_planet_id,
		"rules" : shipment2_rules,
		"cargo" : cargo2
		
	}
	
	var trade_dictionary = {
		"shipments" : [shipment1,shipment2],
		"validator_id" : PlayerData.my_id,
		"participant_id" : their_id,
		"validator_planet_id" : your_planet_id,
		"participant_planet_id" : their_planet_id,
	}
	
	return trade_dictionary





func init_data():
	update_buttons()
	update_player_list()
	update_your_planets()
	update_their_planets()


func update_buttons():
	if is_initial:
		%AcceptButton.hide()
		%DenyButton.hide()
		%CounterOfferButton.hide()
	else:
		%SendButton.hide()


func update_player_list():
	%PlayersOptionButton.add_item("<Choose Player>")
	
	for id in PlayerData.players:
		#if id == PlayerData.my_id:
			#continue
		var tex : Texture = PlayerData.player_icons[id]
		var name : String = PlayerData.player_names[id]
		%PlayersOptionButton.add_icon_item(tex,name,id)


func update_your_planets():
	%YourPlanetsOptionButton.clear()
	var owned_planets = PlanetData.get_planet_ids_by_owner_id(PlayerData.my_id)
	for id in owned_planets:
		var tex : Texture = PlanetData.planet_icons[id]
		var name : String = PlanetData.planet_names[id]
		%YourPlanetsOptionButton.add_icon_item(tex,name,id)
	
	%YourPlanetsOptionButton.select(0)
	_on_your_planets_option_button_item_selected(0)

func update_their_planets():
	%TheirPlanetsOptionButton.clear()
	
	if not their_id:
		%TheirPlanetsOptionButton.add_item("<No player chosen>")
		return
	
	var their_owned_planets = PlanetData.get_planet_ids_by_owner_id(their_id)
	for id in their_owned_planets:
		var tex : Texture = PlanetData.planet_icons[id]
		var name : String = PlanetData.planet_names[id]
		%TheirPlanetsOptionButton.add_icon_item(tex,name,id)
	
	%TheirPlanetsOptionButton.select(0)
	_on_their_planets_option_button_item_selected(0)




func _on_players_option_button_item_selected(index):
	their_id = %PlayersOptionButton.get_item_id(index)
	update_their_planets()

func _on_your_planets_option_button_item_selected(index):
	your_planet_id = %YourPlanetsOptionButton.get_item_id(index)


func _on_their_planets_option_button_item_selected(index):
	their_planet_id = %TheirPlanetsOptionButton.get_item_id(index)
	%InfoLabel.text = "Their planet id is: " + str(their_planet_id)


func _on_accept_button_pressed():
	var trade_data = parse_trade()
	
	var planet1 = PlanetData.get_planet(trade_data["validator_planet_id"])
	var planet2 = PlanetData.get_planet(trade_data["participant_planet_id"])
	
	planet1.assign_new_trade(trade_data)
	planet2.assign_new_trade(trade_data)
	
	queue_free()

func _on_send_button_pressed():
	var trade_data = parse_trade()
	
	if not trade_data:
		return
	
	if trade_data["participant_id"] == 999:
		_on_accept_button_pressed()
		return
	
	var notifications = get_tree().get_first_node_in_group("notifications")
	notifications.send_trade_to_player(trade_data,their_id)
	if trade_is_ready():
		queue_free()


func _on_reset_button_pressed():
	if saved_trade_data:
		init_from_dictionary(saved_trade_data)


func _on_cancel_button_pressed():
	queue_free()
