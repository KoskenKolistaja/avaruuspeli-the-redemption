extends VBoxContainer

@onready var rules: Array[Panel] = []




func _ready():
	for child in get_children():
		if child is Panel:
			rules.append(child)
			child.visible = false
	
	$AddConditionButton.pressed.connect(show_next_rule)

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

func set_rules_from_dictionary(rules_dictionary : Dictionary):
	for id_key in rules_dictionary:
		activate_next_rule(rules_dictionary[id_key])

func activate_next_rule(rule_dictionary):
	for rule in rules:
		if not rule.visible:
			rule.set_values_from_dictionary(rule_dictionary)
			rule.visible = true
			return
	# kaikki näkyvissä → ei tehdä mitään


func show_next_rule():
	for rule in rules:
		if not rule.visible:
			rule.visible = true
			rule.reset_values()
			return
	# kaikki näkyvissä → ei tehdä mitään


func get_rules() -> Dictionary:
	var result: Dictionary = {}
	var id := 1

	for child in get_children():
		if child is BaseRule and child.visible:
			result[id] = child.get_rule()
			id += 1

	return result


#func _on_accept_button_pressed():
	#print(get_rules())
