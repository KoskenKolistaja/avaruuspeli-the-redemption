extends Panel
class_name BaseItem


var shipment_dictionary_example : Dictionary = {
	"sender_id": 1,
	"receiver_id": 2,
	"rules": {
		1: {"subject": 1, "resource": "food", "condition": ">", "amount": 5},
		2: {"subject": 2, "resource": "food", "condition": "<", "amount": 50000}
	},
	"cargo": {"resource": "food", "amount": 100}
}

func _ready():
	init_data()
	$MarginContainer/HBoxContainer/DeleteButton.connect("pressed",_on_delete_button_pressed)

func is_ready():
	if $MarginContainer/HBoxContainer/Amount.value == 0:
		return false
	else:
		return true

func set_values(resource_name : String , amount : int):
	
	var resource_id = MetaData.get_resource_id(resource_name)
	var resource_index = $MarginContainer/HBoxContainer/ResourceButton.get_item_index(resource_id)
	$MarginContainer/HBoxContainer/ResourceButton.select(resource_index)
	$MarginContainer/HBoxContainer/Amount.value = amount

func init_data():
	for key in MetaData.resource_names:
		var tex = MetaData.resource_icons[key]
		var name = MetaData.resource_names[key]
		$MarginContainer/HBoxContainer/ResourceButton.add_icon_item(tex,name,key)
	$MarginContainer/HBoxContainer/ResourceButton.select(0)

func reset_values():
	$MarginContainer/HBoxContainer/Amount.value = 0
	$MarginContainer/HBoxContainer/ResourceButton.select(0)

func get_amount():
	return floori($MarginContainer/HBoxContainer/Amount.value)


func get_resource_name():
	var btn = $MarginContainer/HBoxContainer/ResourceButton
	var id = btn.get_item_id(btn.selected)
	return MetaData.resource_names[id]


func get_cargo():
	var dic = {"resource" : get_resource_name(),"amount" : get_amount()}
	return dic



func _on_delete_button_pressed():
	hide()
