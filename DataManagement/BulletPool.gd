# BulletPool.gd
extends Node3D

@export var bullet_scene: PackedScene
@export var pool_size := 200

var _inactive_bullets: Array[Node3D] = []

var bullet_velocity = 20

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
	spawn_bullet.rpc(bullet_transform,Time.get_ticks_msec(),shooter_id)


@rpc("authority","call_local",)
func spawn_bullet(bullet_transform: Transform3D,server_time_ms: int,shooter_id):
	if _inactive_bullets.is_empty():
		return null
	
	
	var bullet = _inactive_bullets.pop_back()

	# --- LATENCY COMPENSATION ---
	var now = Time.get_ticks_msec()
	var latency = max(0, now - server_time_ms) * 0.001

	# Fast-forward spawn position
	var compensated_transform = bullet_transform
	var direction = bullet_transform.basis.y
	compensated_transform.origin += direction * latency
	
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
	bullet.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
	bullet.shooter_id = null
	_inactive_bullets.append(bullet)
