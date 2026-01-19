extends Node

@export var ship_scene: PackedScene

var current_trade_index = 0



var trade_dictionary_example : Dictionary = {
	"sender_id": 1,
	"receiver_id": 2,
	"rules": {
		1: {"subject": 1, "resource": "food", "condition": ">", "amount": 500},
		2: {"subject": 2, "resource": "food", "condition": "<", "amount": 500}
	},
	"cargo": {"resource": "food", "amount": 100}
}

var trade_dictionary_example_2 : Dictionary = {
	"sender_id": 2,
	"receiver_id": 1,
	"rules": {
		1: {"subject": 2, "resource": "uranium", "condition": ">", "amount": 500},
	},
	"cargo": {"resource": "food", "amount": 500}
}



var trade_dictionaries: Array[Dictionary] = []


func assing_new_trade(exported_trade_dictionary):
	trade_dictionaries.append(exported_trade_dictionary)


func get_trade_dictionaries():
	return trade_dictionaries


func delete_trade(index_to_be_deleted):
	trade_dictionaries.remove_at(index_to_be_deleted)


func _on_timer_timeout() -> void:
	if trade_dictionaries.is_empty():
		return
		
	if current_trade_index >= trade_dictionaries.size():
		current_trade_index = trade_dictionaries.size() - 1
	
	request_send(trade_dictionaries[current_trade_index])
	
	current_trade_index += 1
	
	if current_trade_index >= trade_dictionaries.size():
		current_trade_index = 0
	

func request_send(trade_data: Dictionary) -> void:
	# 1. Check Rules
	var rules_passed = check_rules(trade_data["rules"])
	if not rules_passed:
		print("--------------------------")
		return # Stop here so we don't spam errors

	# 2. Check Cargo
	var cargo_ready = is_cargo_sendable(trade_data)
	if not cargo_ready:
		print("--------------------------")
		return

	# 3. Send
	if rules_passed and cargo_ready:
		send_ship(trade_data)

func is_cargo_sendable(trade_data: Dictionary) -> bool:
	var sender_id = trade_data["sender_id"]
	var planet = PlanetData.get_planet(sender_id)
	
	if planet == null:
		print("[Error] Cargo Check Failed: Sender planet %s does not exist." % sender_id)
		return false
	
	var resource_name = trade_data["cargo"]["resource"]
	var required_amount = trade_data["cargo"]["amount"]
	var current_amount = planet.get(resource_name)
	
	# Safety check for null resources
	if current_amount == null:
		print("[Error] Cargo Check Failed: Sender %s does not have a property/variable named '%s'." % [sender_id, resource_name])
		return false
	
	if current_amount >= required_amount:
		return true
	else:
		print("[Fail] Cargo Check Failed: Sender %s has %s '%s', needs %s." % [sender_id, current_amount, resource_name, required_amount])
		return false

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

func send_ship(trade_data: Dictionary) -> void:
	if ship_scene == null:
		push_error("Ship Scene not assigned!")
		return
	print("[Success] Trade executed successfully.")
	
	# --- 1. DEDUCT RESOURCES ---
	var sender_planet = PlanetData.get_planet(trade_data["sender_id"])
	var resource_name = trade_data["cargo"]["resource"]
	var amount = trade_data["cargo"]["amount"]
	
	var current_sender_amount = sender_planet.get(resource_name)
	sender_planet.set(resource_name, current_sender_amount - amount)
	
	# Print deduction for verification
	print("[Log] Deducted %s '%s' from Sender %s. New Balance: %s" % [amount, resource_name, trade_data["sender_id"], current_sender_amount - amount])
	
	# --- 2. SPAWN SHIP ---
	var ship_instance = ship_scene.instantiate()
	ship_instance.set(resource_name, amount)
	ship_instance.receiver = PlanetData.get_planet(trade_data["receiver_id"])
	add_child(ship_instance)
	ship_instance.global_position = sender_planet.global_position
