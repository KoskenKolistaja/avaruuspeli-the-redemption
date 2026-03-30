extends CharacterBody3D


@export var player_id : int

## SHIP SETTINGS
@export_group("Movement Stats")
@export var max_speed: float = 10.0
@export var acceleration: float = 5.0
@export var rotation_speed: float = 3.0
@export var drag: float = 0.5 # Low drag = lots of drift

## INPUT SETTINGS
const INPUT_THRUST = "move_up"    # Usually 'W'
const INPUT_BACK = "move_down"    # Usually 'S'
const INPUT_LEFT = "move_left"    # Usually 'A'
const INPUT_RIGHT = "move_right"  # Usually 'D'

@export var rotation_smoothing: float = 10.0 

## ZOOM SETTINGS (NEW)
@export_group("Camera Zoom")
@export var min_zoom: float = 5.0   # Closest the camera can get
@export var max_zoom: float = 200.0   # Farthest the camera can get
@export var zoom_speed: float = 4.0  # How much to zoom per scroll tick
@export var zoom_smoothing: float = 5.0 # Higher = Snappier, Lower = Smoother

var current_planet = null
var target_zoom: float = 10.0 # Internal variable to track where we want to be

@export var synced_velocity : Vector3

var BulletPool

@export var camera : Camera3D

var shot_loaded = true


func _enter_tree():
	# Set the authority based on the node name (which is the peer ID)
	if not multiplayer.is_server():
		request_sync_position.rpc_id(1)
	set_multiplayer_authority(name.to_int())
	player_id = name.to_int()
	PlayerData.players

@rpc("any_peer","reliable")
func request_sync_position():
	sync_client_position.rpc(global_position)

@rpc("any_peer","reliable")
func sync_client_position(exported_position):
	print("WAS CALLED")
	self.global_position = exported_position


func _ready() -> void:
	# 1. LOCK Z AXIS PHYSICS
	axis_lock_linear_z = true
	axis_lock_angular_x = true
	axis_lock_angular_y = true
	
	# Initialize target zoom to current camera position to prevent jumping
	var camera = get_viewport().get_camera_3d()
	if camera:
		target_zoom = camera.global_position.z
	
	await get_tree().create_timer(0.1).timeout
	
	if is_multiplayer_authority():
		$Camera3D.current = true
		for item in get_tree().get_nodes_in_group("player_spawner"):
			item.queue_free()
		
	else:
		pass
	
	BulletPool = get_tree().get_first_node_in_group("bullet_pool")





func _unhandled_input(event: InputEvent) -> void:
	# Capture Mouse Wheel Input
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_zoom -= zoom_speed
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_zoom += zoom_speed
		
		# Clamp the zoom so we don't go too far or clip through the ship
		target_zoom = clamp(target_zoom, min_zoom, max_zoom)


#If not BulletPool return
func shoot():
	var bullet_transform = $Barrel.global_transform
	shot_loaded = false
	BulletPool.request_spawn_bullet.rpc_id(1,bullet_transform)


func _physics_process(delta: float) -> void:
	
	if not is_multiplayer_authority():
		move_to_phantom_position(delta)
		add_phantom_position_velocity(delta)
		return
	else:
		synced_velocity = velocity
	
	$Phantom.global_position = global_position
	$Phantom.global_rotation = global_rotation
	
	handle_rotation(delta)
	handle_thrust(delta)
	handle_input()
	handle_camera_zoom(delta) # <--- New Function Call
	
	
	# Move the ship
	move_and_slide()
	
	# Force Z position to 0 just in case a collision bumps us slightly
	global_position.z = 0.0
	
	if current_planet:
		check_distance_to_planet()

func handle_input():
	if Input.is_action_pressed("mouse1"):
		if shot_loaded:
			shoot()
			$ShootTimer.start()


func add_phantom_position_velocity(delta):
	$Phantom.global_position += synced_velocity * delta

func move_to_phantom_position(delta):
	var target_pos = $Phantom.global_position
	var target_rot = $Phantom.global_rotation

	# --- POSITION CORRECTION ---
	var distance_vector = target_pos - global_position
	var max_correction = max_speed * 2
	
	var correction_strength = 10.0
	velocity = distance_vector * correction_strength
	velocity = velocity.limit_length(max_speed * 2.0)
	
	move_and_slide()

	# --- ROTATION ---
	global_rotation.y = lerp_angle(global_rotation.y, target_rot.y, 10.0 * delta)
	global_rotation.x = lerp_angle(global_rotation.x, target_rot.x, 10.0 * delta)
	global_rotation.z = lerp_angle(global_rotation.z, target_rot.z, 10.0 * delta)


func check_distance_to_planet():
	if (self.global_position - current_planet.global_position).length() > 10:
		hide_planet_page()

func show_planet_page():
	var planet_page = get_tree().get_first_node_in_group("planet_page")
	if planet_page:
		planet_page.activate(current_planet)

func hide_planet_page():
	var planet_page = get_tree().get_first_node_in_group("planet_page")
	if planet_page:
		planet_page.deactivate()










func handle_thrust(delta: float) -> void:
	# 1. Get Thrust Input
	var thrust_input = Input.get_axis(INPUT_BACK, INPUT_THRUST)
	
	# 2. Calculate Direction (Assuming Y is Up/Forward locally)
	var facing_direction = transform.basis.y 
	
	# 3. Apply Acceleration
	if thrust_input:
		velocity += facing_direction * thrust_input * acceleration * delta
	
	# 4. Limit Speed
	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed
		
	# 5. Apply Drag
	if velocity.length() > 0:
		velocity = velocity.move_toward(Vector3.ZERO, drag * delta)

	# 6. Strict Z-Lock
	velocity.z = 0.0

func handle_rotation(delta: float) -> void:
	# 1. RAYCAST
	var camera = get_viewport().get_camera_3d()
	if !camera: return # Safety check
	
	var mouse_pos = get_viewport().get_mouse_position()
	
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_dir = camera.project_ray_normal(mouse_pos)
	
	# Ensure ray_dir.z isn't zero to avoid division by zero
	if is_zero_approx(ray_dir.z): return 
	
	var t = (0 - ray_origin.z) / ray_dir.z
	var world_mouse_pos = ray_origin + ray_dir * t
	
	# 2. CALCULATE TARGET ANGLE
	var target_dir = world_mouse_pos - global_position
	
	if target_dir.length_squared() > 1.0:
		var target_angle = atan2(target_dir.y, target_dir.x) - PI / 2
		rotation.z = lerp_angle(rotation.z, target_angle, rotation_smoothing * delta)
		rotation.x = 0
		rotation.y = 0

func handle_camera_zoom(delta: float) -> void:
	if camera:
		# Smoothly interpolate the current Z position to the target Z position
		var new_z = lerp(camera.global_position.z, target_zoom, zoom_smoothing * delta)
		camera.global_position.z = new_z

func _on_planet_catcher_body_entered(body):
	if not is_multiplayer_authority():
		return
	if body.is_in_group("planet_body"):
		current_planet = body.get_planet()
		show_planet_page()




func get_hit():
	var id = name.to_int()
	var space = get_tree().get_first_node_in_group("space")
	
	space.spawn_player_spawner.rpc_id(id)
	var law = get_tree().get_first_node_in_group("law_manager")
	law.remove_outlaw(player_id)
	queue_free()







func _on_tree_exiting():
	hide_planet_page()


func _on_shoot_timer_timeout():
	shot_loaded = true
