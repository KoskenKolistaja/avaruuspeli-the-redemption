extends VBoxContainer

@onready var items: Array[Panel] = []

func _ready():
	for child in get_children():
		if child is Panel:
			items.append(child)
	
	$AddItemButton.pressed.connect(show_next_item)


var example_dic = {
	"population" : 0,
	"food" : 100,
	"technology" : 0,
	"iron" : 0,
	"uranium" : 0,
	}


func set_items_from_dictionary(dic : Dictionary):
	for key in dic:
		if dic[key] > 0:
			activate_next_item(key,dic[key])


func activate_next_item(resource_name : String , amount : int):
	for item in items:
		if not item.visible:
			item.visible = true
			item.set_values(resource_name,amount)
			return
	# kaikki näkyvissä → ei tehdä mitään


func show_next_item():
	for item in items:
		if not item.visible:
			item.visible = true
			item.reset_values()
			return
	# kaikki näkyvissä → ei tehdä mitään


func get_cargo() -> Dictionary:
	var example_dic = {"resource" : "technology","amount" : 100}
	var result: Dictionary = {
		"population" : 0,
		"food" : 0,
		"technology" : 0,
		"iron" : 0,
		"uranium" : 0,
	}
	
	for child in get_children():
		if child is BaseItem and child.visible:
			var dic = child.get_cargo()
			result[dic["resource"]] += result[dic["resource"]] + dic["amount"]

	return result


func is_ready():
	if $Item.is_ready():
		return true
	else:
		return false
