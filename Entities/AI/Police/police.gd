extends CharacterBody3D



var speed = 10

@export var synced_velocity : Vector3
@export var sync_position : Vector3
@export var sync_rotation_z : float

func _physics_process(delta):
	if not multiplayer.is_server():
		_client_interpolate(delta)
		return
	else:
		handle_movement(delta)
	

func handle_movement(delta):
	var vector = Vector3.UP
	var direction = Vector3(vector.x,vector.y,0).normalized()
	
	rotate_toward_direction(direction)
	
	var velocity = direction * speed * 60
	synced_velocity = velocity
	
	
	global_position += velocity * delta
	sync_position = global_position
	sync_rotation_z = rotation.z

func _client_interpolate(delta):
	# Smoothly move position
	sync_position += synced_velocity * delta
	#global_position = global_position.lerp(sync_position, 0.01)
	global_position = sync_position
	# Smoothly interpolate rotation (using lerp_angle to prevent 360-degree snapping)
	rotation.z = lerp_angle(rotation.z, sync_rotation_z, 0.2)



func rotate_toward_direction(direction: Vector3):
	direction.z = 0.0
	direction = direction.normalized()
	var angle = atan2(direction.y, direction.x)
	rotation.z = angle + deg_to_rad(-90)
