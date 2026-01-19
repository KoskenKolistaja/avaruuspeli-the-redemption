extends Panel

var receiver_id = null
var sender_id = 1 # Make sure this is set! (e.g., usually the player's planet ID)

@export var planet_icon : Texture

func _ready():
	# Populate the OptionButton
	# argument 3 is the ID we want to retrieve later
	for key in PlanetData.planet_references:
		$CargoContainer/PlanetButton.add_icon_item(planet_icon, PlanetData.planet_names[key], key)

func parse_rules():
	if not send_settings_are_correct():
		print("Send settings are not correct!")
		return

	# 1. Setup the Dictionary
	var shipment_packet = {
		"sender_id": sender_id,
		"receiver_id": receiver_id,
		"rules": {},
		"cargo": {}
	}

	# 2. Rules Loop (Restored your applies() check)
	var rule_id_counter = 1
	for rule in $RuleContainer.get_children():
		# Use your existing checks
		if rule.visible and rule.has_method("applies") and rule.applies():
			
			var rule_data = {}
			
			match rule.get_subject():
				"sender": rule_data["subject"] = sender_id
				"receiver": rule_data["subject"] = receiver_id
				_: continue # Skip if subject is invalid
			
			rule_data["resource"] = rule.get_resource()
			rule_data["condition"] = rule.get_condition()
			rule_data["amount"] = rule.get_amount()
			
			# Add to dictionary using unique ID
			shipment_packet["rules"][rule_id_counter] = rule_data
			rule_id_counter += 1

	# 3. Cargo Logic (The Fix)
	var resource_btn = $CargoContainer/ResourceButton
	var selected_idx = resource_btn.selected
	
	# Option A: Get the visible text (e.g., "Food")
	var resource_name = resource_btn.get_item_text(selected_idx)
	
	# Option B: If you use Metadata for internal names (e.g., text is "Food Unit", data is "food")
	# var resource_name = resource_btn.get_selected_metadata()
	
	if resource_name == "":
		print("Error: Resource name is empty! Check your OptionButton items.")
		return

	shipment_packet["cargo"] = {
		"resource": resource_name.to_lower(), 
		"amount": int($CargoContainer/SpinBox.value)
	}

	print("Sending Packet:", shipment_packet)
	get_parent().assign_new_shipment(shipment_packet)
	queue_free()

func send_settings_are_correct() -> bool:
	if sender_id == null:
		print("Error: Sender ID is not set.")
		return false
	if receiver_id == null:
		print("Error: No Receiver selected.")
		return false
	if $CargoContainer/ResourceButton.selected == -1:
		return false
	if $CargoContainer/SpinBox.value <= 0:
		return false
	
	return true

func show_next_rule():
	for c in $RuleContainer.get_children():
		if not c.visible:
			c.show()
			# If this was the last one, hide the "Add Rule" button
			if c.get_index() == $RuleContainer.get_child_count() - 1:
				$RuleContainer/Button.hide()
			return

func _on_button_pressed():
	show_next_rule()

func _on_assign_button_pressed():
	parse_rules()

func _on_exit_button_pressed():
	queue_free()

func _on_planet_button_item_selected(index):
	# FIX: 'index' is just the row number (0, 1, 2...). 
	# We need the actual Planet ID we stored in _ready
	receiver_id = $CargoContainer/PlanetButton.get_item_id(index)
