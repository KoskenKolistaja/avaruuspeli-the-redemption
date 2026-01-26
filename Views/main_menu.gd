extends Control
class_name MainMenuController

# --- Configuration ---
const PORT = 7000
const DEFAULT_SERVER_IP = "127.0.0.1"
const MAX_CLIENTS = 10

@export_file("*.tscn") var game_scene_path: String

# --- Local Player Info ---
var local_player_name: String = "Player"
var local_player_icon_path: String = "res://Assets/Textures/UI Textures/Agent.png"

# --- UI References ---
@onready var start_button = %StartButton
@onready var ip_input = %IPInput
@onready var status_label = %StatusLabel
@onready var name_input = %PlayerName

func _ready():
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	local_player_name = "Player_" + str(randi() % 1000)
	_update_status("Ready. Name: " + local_player_name)

# ==============================================================================
# 🛠️ CONNECTION LOGIC
# ==============================================================================

func host_game() -> void:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_CLIENTS)
	if error != OK:
		push_error("Failed to host: " + str(error))
		return
		
	multiplayer.multiplayer_peer = peer
	
	PlayerData.reset_data()
	PlayerData.my_id = 1
	
	# Add Host to PlayerData using local selections
	PlayerData.add_player_data(1, local_player_name, local_player_icon_path)
	
	print("Hosting started.")
	_update_status("Hosting as " + local_player_name)
	if start_button: start_button.show()
	%PlayerIcon.hide()
	%PlayerName.hide()

func join_game(address: String) -> void:
	if address.is_empty(): address = DEFAULT_SERVER_IP
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, PORT)
	if error != OK:
		push_error("Failed to join: " + str(error))
		return
		
	multiplayer.multiplayer_peer = peer
	PlayerData.reset_data()
	_update_status("Connecting...")
	%PlayerIcon.hide()
	%PlayerName.hide()

func start_game() -> void:
	if multiplayer.is_server():
		load_world.rpc(game_scene_path)

# ==============================================================================
# 📡 HANDSHAKE
# ==============================================================================

func _on_connected_to_server():
	PlayerData.my_id = multiplayer.get_unique_id()
	_update_status("Connected! Sending info...")
	# Send name and icon path to server
	_request_register_player.rpc_id(1, local_player_name, local_player_icon_path)

@rpc("any_peer", "call_remote", "reliable")
func _request_register_player(name_str: String, icon_path: String):
	if not multiplayer.is_server(): return
	var new_id = multiplayer.get_remote_sender_id()
	
	# 1. Tell everyone about the new player
	_register_player_client.rpc(new_id, name_str, icon_path)
	
	# 2. Tell the new player about everyone already here
	for existing_id in PlayerData.players:
		if existing_id != new_id:
			var existing_name = PlayerData.player_names[existing_id]
			var existing_icon_path = PlayerData.player_icons[existing_id].resource_path
			_register_player_client.rpc_id(new_id, existing_id, existing_name, existing_icon_path)

@rpc("authority", "call_local", "reliable")
func _register_player_client(id: int, name_str: String, icon_path: String):
	PlayerData.add_player_data(id, name_str, icon_path)

@rpc("authority", "call_local", "reliable")
func load_world(scene_path: String):
	get_tree().change_scene_to_file(scene_path)

# ==============================================================================
# 🖥️ UI INPUTS & UPDATES
# ==============================================================================

func _on_player_name_text_changed(new_text):
	local_player_name = new_text

#func on_icon_changed(new_icon_path: String):
	#local_player_icon_path = new_icon_path
	## If you want to update the UI button immediately:
	#%PlayerIcon.icon = load(new_icon_path)

func _on_host_button_pressed():
	host_game()

func _on_join_button_pressed():
	var ip = ip_input.text if ip_input else ""
	join_game(ip)

func _on_start_button_pressed():
	start_game()

func _update_status(msg: String):
	if status_label: status_label.text = msg

# ==============================================================================
# 🔌 DISCONNECTION HANDLERS
# ==============================================================================

func _on_peer_disconnected(id: int):
	PlayerData.remove_player_data(id)

func _on_connection_failed():
	_update_status("Connection Failed")
	multiplayer.multiplayer_peer = null
	PlayerData.reset_data()

func _on_server_disconnected():
	_update_status("Server Closed")
	multiplayer.multiplayer_peer = null
	PlayerData.reset_data()
	if start_button: start_button.hide()

func _on_peer_connected(_id: int):
	pass


func _on_player_icon_pressed():
	$PlayerName/IconList.show()


func _on_icon_list_item_selected(index):
	var my_texture = %IconList.get_item_icon(index)
	var path_string = my_texture.resource_path
	local_player_icon_path = path_string
	%PlayerIcon.icon = load(path_string)
	$PlayerName/IconList.hide()
	print("JUUUUUU!!")
