extends Node








func get_player(exported_id):
	for player in get_tree().get_nodes_in_group("players"):
		if player.id == exported_id:
			return player
	return null
