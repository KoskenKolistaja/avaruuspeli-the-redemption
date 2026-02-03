extends Node3D

@export var player_scene: PackedScene
@export var player_spawner : PackedScene

# Reference to the node where players will be added
@export var players_container: Node3D

func _ready():
	print(PlayerData.players)
	# We only need to run spawn logic on the server.
	# The MultiplayerSpawner will replicate these spawns to all clients.
	if not multiplayer.is_server():
		spawn_info()
		push_error("This is client thread")
		return
	else:
		push_error("This is server thread")
	
	## 1. Spawn players who are already in the PlayerData dictionary
	## (Host + anyone who joined while in the lobby)
	#for id in PlayerData.players:
		#
		#if id == 999:
			#continue
		#
		#spawn_player(id)
	#
	## 2. Listen for new connections (Late Joiners)
	## If someone joins MID-GAME, this triggers.
	#multiplayer.peer_connected.connect(spawn_player)
	#
	## 3. Clean up when someone leaves
	#multiplayer.peer_disconnected.connect(remove_player)

func spawn_info():
	await get_tree().create_timer(5).timeout

@rpc("any_peer","reliable","call_local")
func request_spawn_player(id : int,exported_position):
	if not multiplayer.is_server():
		return
	spawn_player(id,exported_position)

@rpc("authority","call_local","reliable")
func spawn_player_spawner():
	var spawner_instance = player_spawner.instantiate()
	add_child(spawner_instance)



func spawn_player(id: int, exported_position : Vector3 = Vector3(0, randi_range(10,20), 0)):
	# Instantiate the player
	var player = player_scene.instantiate()
	
	# CRITICAL: Set the node name to the Peer ID.
	# The MultiplayerSpawner uses this to ensure IDs match on all clients.
	player.name = str(id)
	
	# Position logic (Optional: Add spawn points later)
	player.position = exported_position
	
	# Add to the container. The MultiplayerSpawner detects this
	# and immediately instantiates it on all connected clients.
	push_warning(PlayerData.players)
	players_container.add_child(player,true)


func remove_player(id: int):
	# Find the node named after the ID
	var player_node = players_container.get_node_or_null(str(id))
	if player_node:
		player_node.queue_free()
