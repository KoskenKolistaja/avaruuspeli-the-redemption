extends Control
class_name MainMenuController

# --- Configuration ---
const PORT = 7000
const DEFAULT_SERVER_IP = "127.0.0.1"
const MAX_CLIENTS = 10

@export_file("*.tscn") var game_scene_path: String

# --- Local Player Info ---
var local_player_name: String = "Player"

# --- UI References (Make sure these exist in your scene with Unique Names) ---
@onready var start_button = %StartButton
@onready var ip_input = %IPInput
@onready var status_label = %StatusLabel

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
	
	# Host setup
	PlayerData.reset_data()
	PlayerData.my_id = 1
	
	print("Hosting started.")
	_update_status("Hosting as " + local_player_name)
	
	# 1. Add Host to PlayerData
	# Note: We don't need to RPC this yet, we will sync it when people join
	PlayerData.add_player_data(1, local_player_name)
	
	if start_button: start_button.show()

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

func start_game() -> void:
	if multiplayer.is_server():
		load_world.rpc(game_scene_path)

# ==============================================================================
# 📡 HANDSHAKE (The Sync Fix)
# ==============================================================================

# CLIENT: Connected successfully
func _on_connected_to_server():
	print("Connected to server!")
	PlayerData.my_id = multiplayer.get_unique_id()
	_update_status("Connected! Sending info...")
	
	# 2. Ask Server to let us in
	_request_register_player.rpc_id(1, local_player_name)

# SERVER: Receive request from new Client
@rpc("any_peer", "call_remote", "reliable")
func _request_register_player(name_str: String):
	if not multiplayer.is_server(): return
	
	var new_id = multiplayer.get_remote_sender_id()
	print("Server: Registering ID ", new_id)
	
	# 3. Broadcast the NEW player to EVERYONE (including the new player)
	# This adds the new guy to the server's list and everyone else's
	_register_player_client.rpc(new_id, name_str)
	
	# 4. Catch the new player up on EXISTING players (Host, ID 999, other clients)
	for existing_id in PlayerData.players:
		if existing_id != new_id:
			var existing_name = PlayerData.player_names[existing_id]
			# Send only to the new guy
			_register_player_client.rpc_id(new_id, existing_id, existing_name)

# EVERYONE: Execute the data change
@rpc("authority", "call_local", "reliable")
func _register_player_client(id: int, name_str: String):
	# We don't pass an icon here, PlayerData will use the default "null_icon"
	PlayerData.add_player_data(id, name_str)

@rpc("authority", "call_local", "reliable")
func load_world(scene_path: String):
	get_tree().change_scene_to_file(scene_path)

# ==============================================================================
# 🔌 DISCONNECTION HANDLERS
# ==============================================================================

func _on_peer_disconnected(id: int):
	print("Peer disconnected: ", id)
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

func _on_peer_connected(id: int):
	# Server doesn't do anything here, it waits for the RPC request
	pass

# ==============================================================================
# 🖥️ UI INPUTS
# ==============================================================================

func _on_host_button_pressed():
	host_game()

func _on_join_button_pressed():
	var ip = ip_input.text if ip_input else ""
	join_game(ip)

func _on_start_button_pressed():
	start_game()

func _update_status(msg: String):
	if status_label: status_label.text = msg
