extends Node


var my_id = 1


var null_icon : Texture = preload("res://Assets/Textures/UI Textures/Agent.png")
var npc_icon : Texture = preload("res://Assets/Textures/UI Textures/NPC.png")

signal player_list_changed

var players = {
	1: "some_random_multiplayer_key",
	2: "some_random_multiplayer_key",
	999: "some_random_multiplayer_key"
}

var player_names = {
	1: "Kolistaja",
	2: "leo_peltola",
	999: "Trade Community"
}

var player_icons = {
	1: null_icon,
	2: null_icon,
	999: npc_icon,
}


func get_player(exported_id):
	for player in get_tree().get_nodes_in_group("players"):
		if player.id == exported_id:
			return player
	return null

func add_player_data(id: int, name_str: String, icon: Texture2D = null_icon) -> void:
	players[id] = "auth_key_placeholder" # Replace with actual auth if needed
	player_names[id] = name_str
	player_icons[id] = icon if icon else null_icon
	player_list_changed.emit()

func remove_player_data(id: int) -> void:
	players.erase(id)
	player_names.erase(id)
	player_icons.erase(id)
	player_list_changed.emit()

func reset_data() -> void:
	# Keep your default NPCs/Community IDs if necessary, clear the rest
	var keep_ids = [999] 
	var new_players = {}
	var new_names = {}
	var new_icons = {}
	
	for id in keep_ids:
		if id in players:
			new_players[id] = players[id]
			new_names[id] = player_names[id]
			new_icons[id] = player_icons[id]
	
	players = new_players
	player_names = new_names
	player_icons = new_icons
	player_list_changed.emit()
