extends Control


@export var new_shipment_panel_scene : PackedScene
@export var shipment_button_scene : PackedScene


var planet


func assign_new_shipment(exported_dictionary):
	get_parent().assign_new_shipment(exported_dictionary)
	update()

func _ready():
	update()


func request_delete_shipment(index):
	planet.request_delete_shipment(index)
	update()

var shipment_dictionary_example : Dictionary = {
	"sender_id": 1,
	"receiver_id": 2,
	"rules": {
		1: {"subject": 1, "resource": "food", "condition": ">", "amount": 500},
		2: {"subject": 2, "resource": "food", "condition": "<", "amount": 500}
	},
	"cargo": {"resource": "food", "amount": 100}
}


func update():
	if not planet:
		push_warning("No assigned planet for shipment panel!")
		return
	
	for c in %ShipmentContainer.get_children():
		c.queue_free()
	
	var shipments_array : Array = planet.get_shipment_dictionaries()
	
	# CHANGE HERE: Use range(shipments_array.size()) to get 0, 1, 2, etc.
	for index in range(shipments_array.size()):
		
		# Now you retrieve the dictionary using the index
		var dic = shipments_array[index]
		
		var button = shipment_button_scene.instantiate()
		button.resource_type = dic["cargo"]["resource"]
		button.resource_amount = dic["cargo"]["amount"]
		button.receiver_id = dic["receiver_id"]
		button.root_parent = self
		
		# Now you have the correct index to assign
		button.shipment_index = index 
		
		%ShipmentContainer.add_child(button)






func _on_new_shipment_button_pressed():
	var panel_instance = new_shipment_panel_scene.instantiate()
	panel_instance.sender_id = get_parent().planet.planet_id
	add_child(panel_instance)


func _on_exit_button_pressed():
	hide()
