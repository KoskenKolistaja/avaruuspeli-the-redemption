extends Area3D



@export var player_node : CharacterBody3D


var player_id




func _ready():
	if not multiplayer.is_server():
		return
	player_id = player_node.player_id
	
	for area in get_overlapping_areas():
		area.enable_sync_for(player_id)

func _on_area_entered(area):
	if multiplayer.is_server():
		area.enable_sync_for(player_id)


func _on_area_exited(area):
	if multiplayer.is_server():
		if player_id == 1:
			return
		area.disable_sync_for(player_id)
