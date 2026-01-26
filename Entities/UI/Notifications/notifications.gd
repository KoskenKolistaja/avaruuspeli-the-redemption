extends Control


@export var trade_offer_scene : PackedScene




func _ready():
	update_title()


func button_deleted():
	update_title()


func send_trade_to_player(trade_data : Dictionary, player_id : int):
	print("Tähän asti päästiin")
	if player_id == PlayerData.my_id:
		add_trade_notification(trade_data)
		print("Tänne ei menty?")
	else:
		add_trade_notification.rpc_id(player_id,trade_data)

@rpc("any_peer","reliable","call_local")
func add_trade_notification(trade_data):
	var trade_offer_instance = trade_offer_scene.instantiate()
	trade_offer_instance.trade_data = trade_data
	trade_offer_instance.notifications_panel = self
	%NotificationContainer.add_child(trade_offer_instance,true)
	update_title()




func update_title():
	var notifications_amount = %NotificationContainer.get_children().size()
	$FoldableContainer.title = "Notifications " + "(" + str(notifications_amount) +")"
