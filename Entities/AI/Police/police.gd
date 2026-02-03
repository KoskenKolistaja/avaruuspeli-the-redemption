extends CharacterBody3D




var max_speed = 9.0

@export var synced_velocity : Vector3
@export var sync_position : Vector3
@export var sync_rotation_z : float

var base_velocity = Vector3.ZERO

var target

const  TARGETING_DISTANCE = 30

var BulletPool

var shot_loaded = true

enum STATE {
	STANDBY,
	CHASING,
	SHOOTING,
}


@onready var state = STATE.CHASING

func _physics_process(delta):
	if not multiplayer.is_server():
		_client_interpolate(delta)
		return
	else:
		if is_instance_valid(target):
			
			match state:
				STATE.CHASING:
					chase(delta)
				STATE.SHOOTING:
					aim_and_shoot(delta)
			
			
			
			
		elif multiplayer.is_server():
			target = get_tree().get_first_node_in_group("player")
			if target:
				state = STATE.CHASING
			else:
				state = STATE.STANDBY
				standby(delta)
	
	sync_position = global_position
	sync_rotation_z = rotation.z
	move_and_slide()
	

func _ready():
	if multiplayer.is_server():
		target = get_tree().get_first_node_in_group("player")
		BulletPool = get_tree().get_first_node_in_group("bullet_pool")


func chase(delta):
	var vector = target.global_position - self.global_position
	rotate_toward_direction_smoothly(vector,delta)
	
	var target_velocity = basis.y * max_speed * 60
	base_velocity = base_velocity.move_toward(target_velocity,10)
	synced_velocity = base_velocity
	
	
	velocity = base_velocity * delta
	
	
	
	if vector.length() < TARGETING_DISTANCE:
		state = STATE.SHOOTING
	

func aim_and_shoot(delta):
	var vector = target.global_position - self.global_position
	var bullet_speed = 20
	var predicted_position = get_predicted_position(target,bullet_speed)
	var pre_aimed_direction = predicted_position - self.global_position
	
	rotate_toward_direction_smoothly(pre_aimed_direction,delta)
	if vector.length() > TARGETING_DISTANCE:
		state = STATE.CHASING
	
	var target_velocity = Vector3.ZERO
	base_velocity = base_velocity.move_toward(target_velocity,10)
	synced_velocity = base_velocity
	
	velocity = base_velocity * delta
	
	if shot_loaded:
		shoot()


func get_predicted_position(target_node: Node3D, bullet_speed: float) -> Vector3:
	var distance = global_position.distance_to(target_node.global_position)
	
	# Calculate Time of Flight (t = d / v)
	var time_of_flight = distance / bullet_speed
	
	# Predict future position: Current Position + (Velocity * Time)
	# We use the player's actual velocity property
	var prediction = target_node.global_position + (target_node.velocity * time_of_flight)
	
	return prediction



func shoot():
	var bullet_transform = $Barrel.global_transform
	BulletPool.request_spawn_bullet.rpc_id(1,bullet_transform)
	$ShootTimer.start()
	shot_loaded = false

func standby(delta):
	var target_velocity = Vector3.ZERO
	base_velocity = base_velocity.move_toward(target_velocity,10)
	synced_velocity = base_velocity
	velocity = base_velocity * delta
	print("Standing by")






func _client_interpolate(delta):
	# 1. Update the ghost position based on the last known server velocity
	# This keeps the ship moving even if we haven't received a packet lately
	sync_position += synced_velocity * delta
	
	# 2. Smoothly pull the current position toward the server's sync_position
	# We use lerp to close the gap created by latency
	var interpolation_factor = 0.15 # Adjust (0.1 - 0.2) for smoothness vs accuracy
	global_position = global_position.lerp(sync_position, interpolation_factor)
	
	# 3. Handle Rotation
	# Higher factor here (0.2) keeps it feeling responsive
	rotation.z = lerp_angle(rotation.z, sync_rotation_z, 0.2)
	



func rotate_toward_direction(direction: Vector3,delta):
	direction.z = 0.0
	direction = direction.normalized()
	var angle = atan2(direction.y, direction.x)
	rotation.z = angle + deg_to_rad(-90) * delta * 60

func rotate_toward_direction_smoothly(direction: Vector3, delta: float):
	var police_rotation_speed = 5.0
	direction.z = 0.0
	if direction.length() > 0.001: # Avoid errors when direction is zero
		direction = direction.normalized()
		
		# Calculate the target angle
		var target_angle = atan2(direction.y, direction.x) + deg_to_rad(-90)
		
		# Smoothly interpolate the current Z rotation toward the target
		rotation.z = lerp_angle(rotation.z, target_angle, police_rotation_speed * delta)


func get_hit():
	queue_free()



func _on_shoot_timer_timeout():
	shot_loaded = true
