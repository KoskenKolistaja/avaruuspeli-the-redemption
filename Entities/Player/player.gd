extends CharacterBody3D


@export var id : int

## SHIP SETTINGS
@export_group("Movement Stats")
@export var max_speed: float = 25.0
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

func _ready() -> void:
	# 1. LOCK Z AXIS PHYSICS
	axis_lock_linear_z = true
	axis_lock_angular_x = true
	axis_lock_angular_y = true
	
	# Initialize target zoom to current camera position to prevent jumping
	var camera = get_viewport().get_camera_3d()
	if camera:
		target_zoom = camera.global_position.z

func _unhandled_input(event: InputEvent) -> void:
	# Capture Mouse Wheel Input
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_zoom -= zoom_speed
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_zoom += zoom_speed
		
		# Clamp the zoom so we don't go too far or clip through the ship
		target_zoom = clamp(target_zoom, min_zoom, max_zoom)

func _physics_process(delta: float) -> void:
	handle_rotation(delta)
	handle_thrust(delta)
	handle_camera_zoom(delta) # <--- New Function Call
	
	# Move the ship
	move_and_slide()
	
	# Force Z position to 0 just in case a collision bumps us slightly
	global_position.z = 0.0
	
	if current_planet:
		check_distance_to_planet()

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
	var camera = get_viewport().get_camera_3d()
	if camera:
		# Smoothly interpolate the current Z position to the target Z position
		var new_z = lerp(camera.global_position.z, target_zoom, zoom_smoothing * delta)
		camera.global_position.z = new_z

func _on_planet_catcher_body_entered(body):
	if body.is_in_group("planet_body"):
		current_planet = body.get_planet()
		show_planet_page()
