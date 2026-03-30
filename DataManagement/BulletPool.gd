# BulletPool.gd
extends Node3D

@export var bullet_scene: PackedScene
@export var pool_size := 200

var _inactive_bullets: Array[Node3D] = []

var bullet_velocity = 20.0

func _ready():
	for i in pool_size:
		var bullet = bullet_scene.instantiate()
		bullet.visible = false
		bullet.process_mode = Node.PROCESS_MODE_DISABLED
		add_child(bullet)
		_inactive_bullets.append(bullet)

@rpc("any_peer","reliable","call_local")
func request_spawn_bullet(bullet_transform : Transform3D):
	var shooter_id = multiplayer.get_remote_sender_id()
	if not multiplayer.is_server():
		return
	var half_ping = 0
	if shooter_id > 1:
		half_ping = get_client_ping(shooter_id) * 0.5
	
	half_ping = int(half_ping)
	
	spawn_bullet.rpc(bullet_transform,half_ping,shooter_id)
	spawn_bullet(bullet_transform,half_ping,shooter_id)

func request_spawn_npc_bullet(bullet_transform : Transform3D):
	spawn_bullet.rpc(bullet_transform,0,null)
	spawn_bullet(bullet_transform,0,null)




@rpc("authority")
func spawn_bullet(bullet_transform: Transform3D,half_ping: int,shooter_id):
	if _inactive_bullets.is_empty():
		return null
	
	
	
	var bullet = _inactive_bullets.pop_front()

	# --- LATENCY COMPENSATION ---
	var latency = half_ping
	
	if not multiplayer.is_server():
		latency += get_local_half_rtt()
	
	
	# Fast-forward spawn position
	var compensated_transform = bullet_transform
	var direction = bullet_transform.basis.y
	compensated_transform.origin += direction * (latency/1000.0) * bullet_velocity
	
	print("SHOOTER_ID in shooter function: " + str(shooter_id))
	
	# --- APPLY ---
	bullet.global_transform = compensated_transform
	bullet.direction = direction * bullet_velocity
	bullet.shooter_id = shooter_id
	print(bullet.shooter_id)
	bullet.visible = true
	bullet.process_mode = Node.PROCESS_MODE_INHERIT
	bullet.activate()


func despawn_bullet(bullet: Node3D):
	bullet.visible = false
	bullet.shooter_id = null
	_inactive_bullets.append(bullet)
	bullet.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)

func get_client_ping(peer_id: int) -> int:
	var peer = multiplayer.multiplayer_peer
	if peer is ENetMultiplayerPeer:
		var enet_peer = peer.get_peer(peer_id)
		# Returns RTT in milliseconds
		return enet_peer.get_statistic(ENetPacketPeer.PEER_ROUND_TRIP_TIME)
	return 0

func get_local_half_rtt() -> float:
	var peer := multiplayer.multiplayer_peer
	if peer is ENetMultiplayerPeer:
		var server_peer = peer.get_peer(1)
		if server_peer:
			# FIX: Use get_statistic with PEER_ROUND_TRIP_TIME
			return server_peer.get_statistic(ENetPacketPeer.PEER_ROUND_TRIP_TIME) * 0.5
	return 0.0
