extends Control


@export var slot_id : int
@export var buildings_panel : Panel

func _ready():
	var button = $Button
	button.pressed.connect(
		func():
			buildings_panel.button_pressed(slot_id)
			
	)
	var delete_button = $Button/DeleteButton
	delete_button.pressed.connect(
		func():
			buildings_panel.delete_button_pressed(slot_id)
			
	)


func change_icon(exported_texture):
	$Button.icon = exported_texture

func change_name(exported_name : String):
	$BuildingName.text = exported_name
