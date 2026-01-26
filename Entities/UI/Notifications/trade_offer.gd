extends Button

var notifications_panel : Control
var trade_data : Dictionary

@export var new_trade_panel_scene : PackedScene


func _on_delete_button_pressed():
	assert(notifications_panel,"Notifications panel not found!")
	notifications_panel.button_deleted()
	queue_free()


func _on_pressed():
	spawn_trade_panel()
	queue_free()




func spawn_trade_panel():
	var trade_panel_instance = new_trade_panel_scene.instantiate()
	var base = get_tree().get_first_node_in_group("space")
	trade_panel_instance.saved_trade_data = trade_data
	trade_panel_instance.is_initial = false
	base.add_child(trade_panel_instance,true)
