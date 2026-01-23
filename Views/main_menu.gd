extends Control
class_name MainMenuController

# --- Configuration ---
const PORT = 7000
const DEFAULT_SERVER_IP = "127.0.0.1"
const MAX_CLIENTS = 10

# Reference to the scene to load when game starts
@export_file("*.tscn") var game_scene_path: String

# --- Local Player Info ---
var local_player_name: String = "Player"

func _ready():
	# Hook up multiplayer signals
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	# Randomize name for testing if not set
	local_player_name = "Player_" + str(randi() % 1000)

# ==============================================================================
# 🛠️ MODULAR CONNECTION FUNCTIONS
# ==============================================================================

## Starts the server and registers the host as player 1
func host_game() -> void:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_CLIENTS)
	
	if error != OK:
		push_error("Failed to host game: " + str(error))
		return
		
	multiplayer.multiplayer_peer = peer
	
	print("Hosting started on port %s" % PORT)
	PlayerData.reset_data()
	
	# Host is always ID 1 in ENet
	PlayerData.my_id = 1
	_register_player.rpc(1, local_player_name)
	
	# Transition UI to "Lobby" state here (e.g., hide connect buttons, show list)
	_update_lobby_ui("Hosting...")


## Joins a server at the specified IP
func join_game(address: String) -> void:
	if address.is_empty():
		address = DEFAULT_SERVER_IP
		
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, PORT)
	
	if error != OK:
		push_error("Failed to join game: " + str(error))
		return
		
	multiplayer.multiplayer_peer = peer
	PlayerData.reset_data()
	_update_lobby_ui("Connecting to %s..." % address)


## Closes connection and resets data
func leave_game() -> void:
	multiplayer.multiplayer_peer = null
	PlayerData.reset_data()
	_update_lobby_ui("Disconnected.")


## Starts the actual gameplay (Server only)
func start_game() -> void:
	if not multiplayer.is_server():
		return
	
	# Use a remote procedure call to tell everyone to switch scenes
	load_world.rpc(game_scene_path)


# ==============================================================================
# 📡 NETWORK SIGNALS & HANDSHAKE
# ==============================================================================

# Called on Server and Clients when a new player connects
func _on_peer_connected(id: int):
	print("Peer connected: ", id)
	# (Server Only) We don't do anything yet, we wait for them to send their info via RPC
	$VBoxContainer/StartButton.show()

# Called on Clients when they successfully connect to Server
func _on_connected_to_server():
	print("Connected to server!")
	PlayerData.my_id = multiplayer.get_unique_id()
	
	# Send OUR info to the server (and others)
	_register_player.rpc_id(1, PlayerData.my_id, local_player_name)

# Called on Server and Clients when a player disconnects
func _on_peer_disconnected(id: int):
	print("Peer disconnected: ", id)
	PlayerData.remove_player_data(id)

func _on_connection_failed():
	print("Connection failed.")
	leave_game()

func _on_server_disconnected():
	print("Server kicked us or closed.")
	leave_game()

# ==============================================================================
# 🔄 DATA SYNC (RPCs)
# ==============================================================================

## Register a new player. Called on all peers.
## 'any_peer' allows clients to call this. 'call_local' runs it on the sender too.
@rpc("any_peer", "call_local", "reliable")
func _register_player(id: int, name_str: String):
	# Update local data
	PlayerData.add_player_data(id, name_str)
	
	# SERVER LOGIC: If I am the server, I must ensure the new guy gets the *existing* list
	if multiplayer.is_server():
		for existing_id in PlayerData.players:
			if existing_id != id: # Don't send their own info back immediately (redundant)
				var existing_name = PlayerData.player_names[existing_id]
				# Send existing player info to the NEW player only
				_register_player.rpc_id(id, existing_id, existing_name)

## Loads the game world. 
@rpc("authority", "call_local", "reliable")
func load_world(scene_path: String):
	print("Starting game, loading: ", scene_path)
	# In Godot 4, simple scene switching:
	get_tree().change_scene_to_file(scene_path)

# ==============================================================================
# 🖥️ UI HELPERS (Connect your buttons here)
# ==============================================================================

func _on_host_button_pressed():
	host_game()

func _on_join_button_pressed():
	# Assuming you have a LineEdit node named "IPInput"
	var ip = %IPInput.text
	
	if ip == "":
		ip = "localhost"
	
	join_game(ip)

func _on_start_game_button_pressed():
	start_game()

func _update_lobby_ui(status_message: String):
	# Example: Update a status label
	if has_node("UI/StatusLabel"):
		$UI/StatusLabel.text = status_message


func _on_start_button_pressed():
	start_game()
