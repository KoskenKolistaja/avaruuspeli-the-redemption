extends Node

@export var ship_scene: PackedScene

var current_shipment_index = 0

var test = false

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



var trade_pending


var shipment_dictionaries: Array[Dictionary] = []
var trade_dictionaries: Array[Dictionary] = []


func _ready():
	if get_parent().planet_id == 1:
		test = true
		print("Test = true")


func assing_new_shipment(exported_shipment_dictionary):
	shipment_dictionaries.append(exported_shipment_dictionary)

func assing_new_trade(exported_trade_dictionary):
	trade_dictionaries.append(exported_trade_dictionary)

func get_shipment_dictionaries():
	return shipment_dictionaries

func get_trade_dictionaries():
	return trade_dictionaries


func delete_shipment(index_to_be_deleted):
	shipment_dictionaries.remove_at(index_to_be_deleted)


func _on_timer_timeout() -> void:
	if shipment_dictionaries.is_empty():
		return
		
	if current_shipment_index >= shipment_dictionaries.size():
		current_shipment_index = shipment_dictionaries.size() - 1
	
	request_send(shipment_dictionaries[current_shipment_index])
	
	current_shipment_index += 1
	
	if current_shipment_index >= shipment_dictionaries.size():
		current_shipment_index = 0
	





func request_delete_trade():
	pass



func check_owners(trade_data):
	var validator_id = trade_data["validator_id"]
	var participant_id = trade_data["participant_id"]
	
	var validator_planet_owner_id = PlanetData.get_planet(trade_data["validator_planet_id"]).get_owner_id()
	var participant_planet_owner_id = PlanetData.get_planet(trade_data["participant_planet_id"]).get_owner_id()
	
	print(validator_id)
	print(participant_id)
	print(validator_planet_owner_id)
	print(participant_planet_owner_id)
	
	
	if not validator_id == validator_planet_owner_id:
		return false
	if not participant_id == participant_planet_owner_id:
		return false
	
	return true


func request_send_trade(trade_data : Dictionary) -> void:
	
	var owners_are_correct = check_owners(trade_data)
	
	
	assert(owners_are_correct,"Owners are not correct!")
	
	
	for shipment_data in trade_data["shipments"]:
		var planet = PlanetData.get_planet(shipment_data["sender_id"])
		var auto_sender = planet.get_auto_sender()
		var rules_passed = auto_sender.check_rules(shipment_data["rules"])
		var cargo_sendable = auto_sender.is_cargo_sendable(shipment_data)
		
		if not rules_passed:
			print("Shipment rules were not met in trade")
			return
		if not cargo_sendable:
			print("Cargo is not sendable in trade")
			return
	
	
	
	
	for shipment_data in trade_data["shipments"]:
		var planet = PlanetData.get_planet(shipment_data["sender_id"])
		var auto_sender = planet.get_auto_sender()
		auto_sender.send_trade_ship(shipment_data)
	
	print("Trade sent succesfully")


func request_send(shipment_data: Dictionary) -> void:
	# 1. Check Rules
	var rules_passed = check_rules(shipment_data["rules"])
	if not rules_passed:
		print("--------------------------")
		return # Stop here so we don't spam errors

	# 2. Check Cargo
	var cargo_ready = is_cargo_sendable(shipment_data)
	if not cargo_ready:
		print("--------------------------")
		return

	# 3. Send
	if rules_passed and cargo_ready:
		send_ship(shipment_data)

func is_cargo_sendable(shipment_data: Dictionary) -> bool:
	var sender_id = shipment_data["sender_id"]
	var planet = PlanetData.get_planet(sender_id)
	
	if planet == null:
		print("[Error] Cargo Check Failed: Sender planet %s does not exist." % sender_id)
		return false
	
	
	for key in shipment_data["cargo"]:
		var resource_name = key
		var required_amount = shipment_data["cargo"][key]
		var current_amount = planet.get(resource_name)
		
		
		if required_amount == 0:
			continue
		
		# Safety check for null resources
		if current_amount == null:
			print("[Error] Cargo Check Failed: Sender %s does not have a property/variable named '%s'." % [sender_id, resource_name])
			return false
		
		if current_amount >= required_amount:
			return true
		else:
			print("[Fail] Cargo Check Failed: Sender %s has %s '%s', needs %s." % [sender_id, current_amount, resource_name, required_amount])
			return false
	
	return true



func check_rules(exported_rules: Dictionary) -> bool:
	for rule_key in exported_rules:
		var rule = exported_rules[rule_key]
		print(exported_rules)
		var planet = PlanetData.get_planet(rule["subject"])
		
		if planet == null:
			print("[Error] Rule %s Failed: Subject planet %s not found." % [rule_key, rule["subject"]])
			return false
			
		var resource_amount = planet.get(rule["resource"])
		var threshold = rule["amount"]
		var cond = rule["condition"]
		
		if resource_amount == null:
			print("[Error] Rule %s Failed: Planet %s has no resource '%s'." % [rule_key, rule["subject"], rule["resource"]])
			return false
		
		# Return FALSE only if a rule is VIOLATED
		match cond:
			"<":
				if resource_amount >= threshold: 
					print("[Fail] Rule %s Failed: Planet %s has %s '%s'. Needed < %s." % [rule_key, rule["subject"], resource_amount, rule["resource"], threshold])
					return false
			">":
				if resource_amount <= threshold: 
					print("[Fail] Rule %s Failed: Planet %s has %s '%s'. Needed > %s." % [rule_key, rule["subject"], resource_amount, rule["resource"], threshold])
					return false
			"=":
				if resource_amount != threshold: 
					print("[Fail] Rule %s Failed: Planet %s has %s '%s'. Needed == %s." % [rule_key, rule["subject"], resource_amount, rule["resource"], threshold])
					return false
	
	return true

func send_ship(shipment_data: Dictionary) -> void:
	if ship_scene == null:
		push_error("Ship Scene not assigned!")
		return
	print("[Success] shipment executed successfully.")
	
	# --- 1. DEDUCT RESOURCES ---
	var sender_planet = PlanetData.get_planet(shipment_data["sender_id"])
	
	for key in shipment_data["cargo"]:
		var resource_name = key
		var amount = shipment_data["cargo"][key]
		
		var current_sender_amount = sender_planet.get(resource_name)
		sender_planet.set(resource_name, current_sender_amount - amount)
		# Print deduction for verification
		print("[Log] Deducted %s '%s' from Sender %s. New Balance: %s" % [amount, resource_name, shipment_data["sender_id"], current_sender_amount - amount])
	
	# --- 2. SPAWN SHIP ---
	var ship_instance = ship_scene.instantiate()
	print(shipment_data["cargo"])
	ship_instance.set_cargo(shipment_data["cargo"])
	ship_instance.receiver = PlanetData.get_planet(shipment_data["receiver_id"])
	add_child(ship_instance)
	ship_instance.global_position = sender_planet.global_position


func send_trade_ship(shipment_data: Dictionary) -> void:
	if ship_scene == null:
		push_error("Ship Scene not assigned!")
		return
	print("[Success] shipment executed successfully.")
	
	# --- 1. DEDUCT RESOURCES ---
	var sender_planet = PlanetData.get_planet(shipment_data["sender_id"])
	
	for key in shipment_data["cargo"]:
		var resource_name = key
		var amount = shipment_data["cargo"][key]
		
		var current_sender_amount = sender_planet.get(resource_name)
		sender_planet.set(resource_name, current_sender_amount - amount)
		# Print deduction for verification
		print("[Log] Deducted %s '%s' from Sender %s. New Balance: %s" % [amount, resource_name, shipment_data["sender_id"], current_sender_amount - amount])
	
	# --- 2. SPAWN SHIP ---
	var ship_instance = ship_scene.instantiate()
	ship_instance.set_cargo(shipment_data["cargo"])
	ship_instance.is_trade_ship = true
	ship_instance.receiver = PlanetData.get_planet(shipment_data["receiver_id"])
	add_child(ship_instance)
	ship_instance.global_position = sender_planet.global_position




func _on_trade_timer_timeout():
	for item in trade_dictionaries:
		var planet_id = get_parent().planet_id
		var validator_planet_id = item["validator_planet_id"]
		if planet_id == validator_planet_id:
			request_send_trade(item)
