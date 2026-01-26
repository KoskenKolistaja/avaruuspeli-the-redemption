extends Node

# --- Configuration ---
# If these paths don't exist yet, the script will error. 
# Ensure these files exist or change these lines to 'var null_icon = null' for testing.
var null_icon : Texture2D = preload("res://Assets/Textures/UI Textures/Agent.png")
var npc_icon : Texture2D = preload("res://Assets/Textures/UI Textures/NPC.png")

# --- Signals ---
signal player_list_changed

# --- Data ---
var my_id: int = 0

# Your specific data structure
var players = {
	999: "some_random_multiplayer_key"
}

var player_names = {
	999: "Trade Community"
}

var player_icons = {
	999: npc_icon,
}

# --- Functions ---

func get_player(exported_id):
	# Helper to find physical player nodes in the scene
	for player in get_tree().get_nodes_in_group("player"):
		if "id" in player and player.id == exported_id:
			return player
	return null

func add_player_data(id: int, name_str: String, icon: Texture2D = null) -> void:
	# If no icon is passed via network, use the default
	var icon_to_use = icon if icon else null_icon
	
	# If it is the special ID, force the NPC icon
	if id == 999:
		icon_to_use = npc_icon
		
	players[id] = "auth_key_placeholder" 
	player_names[id] = name_str
	player_icons[id] = icon_to_use
	
	player_list_changed.emit()
	print("PlayerData: Added ", name_str, " ID: ", id)

func remove_player_data(id: int) -> void:
	# Prevent removing the Trade Community if logic requires it staying
	if id == 999: return 
	
	players.erase(id)
	player_names.erase(id)
	player_icons.erase(id)
	player_list_changed.emit()

func reset_data() -> void:
	# Keep the default NPCs/Community IDs, clear the rest
	var keep_ids = [999] 
	var new_players = {}
	var new_names = {}
	var new_icons = {}
	
	# Copy over the keepers
	for id in keep_ids:
		if id in players:
			new_players[id] = players[id]
			new_names[id] = player_names[id]
			new_icons[id] = player_icons[id]
	
	players = new_players
	player_names = new_names
	player_icons = new_icons
	
	my_id = 0
	player_list_changed.emit()
