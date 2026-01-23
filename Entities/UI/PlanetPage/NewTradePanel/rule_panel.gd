extends Panel
class_name BaseRule



var shipment_dictionary_example : Dictionary = {
	"sender_id": 1,
	"receiver_id": 2,
	"rules": {
		1: {"subject": 1, "resource": "food", "condition": ">", "amount": 5},
		2: {"subject": 2, "resource": "food", "condition": "<", "amount": 50000}
	},
	"cargo": {"resource": "food", "amount": 100}
}



func get_rule():
	var dic = {
		"subject" : "to_be_assigned",
		"resource" : get_resource_name(),
		"condition" : get_condition(),
		"amount": get_amount()
		}
	
	return dic


var example_dic = {"subject": 1, "resource": "food", "condition": ">", "amount": 5}



func set_values_from_dictionary(dic : Dictionary):
	print(dic)
	var resource_id = MetaData.get_resource_id(dic["resource"])
	var resource_index = $MarginContainer/HBoxContainer/ResourceButton.get_item_index(resource_id)
	print(resource_index)
	$MarginContainer/HBoxContainer/ResourceButton.select(resource_index)
	set_condition(dic["condition"])
	$MarginContainer/HBoxContainer/Amount.value = dic["amount"]

func set_condition(condition : String):
	match condition:
		">":
			$MarginContainer/HBoxContainer/ConditionButton.select(0)
		"=":
			$MarginContainer/HBoxContainer/ConditionButton.select(1)
		"<":
			$MarginContainer/HBoxContainer/ConditionButton.select(2)



func _ready():
	
	$MarginContainer/HBoxContainer/DeleteButton.connect("pressed",_on_delete_button_pressed)
	
	init_data()
	$MarginContainer/HBoxContainer/ResourceButton.select(0)
	$MarginContainer/HBoxContainer/ConditionButton.select(0)
	

func rule_test():
	print(get_rule())


func get_amount():
	return floori($MarginContainer/HBoxContainer/Amount.value)


func get_resource_name():
	var btn = $MarginContainer/HBoxContainer/ResourceButton
	var id = btn.get_item_id(btn.selected)
	return MetaData.resource_names[id]

func get_condition():
	var selected_index = $MarginContainer/HBoxContainer/ConditionButton.selected
	match selected_index:
		0:
			return ">"
		1:
			return "="
		2:
			return "<"


func reset_values():
	$MarginContainer/HBoxContainer/Amount.value = 0
	$MarginContainer/HBoxContainer/ResourceButton.select(0)
	$MarginContainer/HBoxContainer/ConditionButton.select(0)

func init_data():
	for key in MetaData.resource_names:
		var tex = MetaData.resource_icons[key]
		var name = MetaData.resource_names[key]
		$MarginContainer/HBoxContainer/ResourceButton.add_icon_item(tex,name,key)
	


func _on_delete_button_pressed():
	hide()
