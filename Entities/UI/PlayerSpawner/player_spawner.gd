extends Node3D


var planets_array = []
var index = 0
var planet

var target_pos


@export_group("Camera Zoom")
@export var min_zoom: float = 5.0   # Closest the camera can get
@export var max_zoom: float = 200.0   # Farthest the camera can get
@export var zoom_speed: float = 4.0  # How much to zoom per scroll tick
@export var zoom_smoothing: float = 5.0 # Higher = Snappier, Lower = Smoother
@export var camera : Camera3D
var target_zoom: float = 10.0 # Internal variable to track where we want to be

func _ready():
	planets_array = PlanetData.get_sorted_planets()
	switch_planet(0)
	


func _physics_process(delta):
	if Input.is_action_just_pressed("ui_left"):
		var exported_planet = select_planet("left")
		set_planet(exported_planet)
	if Input.is_action_just_pressed("ui_right"):
		var exported_planet = select_planet("right")
		set_planet(exported_planet)
	if Input.is_action_just_pressed("ui_down"):
		var exported_planet = select_planet("down")
		set_planet(exported_planet)
	if Input.is_action_just_pressed("ui_up"):
		var exported_planet = select_planet("up")
		set_planet(exported_planet)
	
	var smooth_speed = 5.0
	
	global_position = global_position.lerp(target_pos, smooth_speed * delta)
	handle_camera_zoom(delta)

func _unhandled_input(event: InputEvent) -> void:
	# Capture Mouse Wheel Input
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_zoom -= zoom_speed
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_zoom += zoom_speed
		
		# Clamp the zoom so we don't go too far or clip through the ship
		target_zoom = clamp(target_zoom, min_zoom, max_zoom)


func handle_camera_zoom(delta: float) -> void:
	if camera:
		# Smoothly interpolate the current Z position to the target Z position
		var new_z = lerp(camera.global_position.z, target_zoom, zoom_smoothing * delta)
		camera.global_position.z = new_z



func select_planet(input_dir_string: String) -> Node3D:
	var planets = get_tree().get_nodes_in_group("planet")
	var best_planet: Node3D = null
	var lowest_cost: float = INF # Start with infinite cost
	
	# 1. Define the direction vector
	var favoured_dir: Vector3
	match input_dir_string:
		"up":
			favoured_dir = Vector3.UP
		"down":
			favoured_dir = Vector3.DOWN
		"left":
			favoured_dir = Vector3.LEFT
		"right":
			favoured_dir = Vector3.RIGHT
		_:
			push_warning("Invalid direction string")
			return null

	# 2. Iterate over all planets
	for p in planets:
		# Skip if the planet is the one currently running this script
		if p == planet:
			continue
			
		# Get the vector from current position to the target planet
		var relative_vector = p.global_position - planet.global_position
		
		# Enforce 2.5D: Flatten the Z axis so depth doesn't affect calculations
		relative_vector.z = 0 
		
		# 3. Check if in the right direction
		# The dot product projects the relative vector onto the direction.
		# If positive, the target is generally in that direction.
		var dist_parallel = relative_vector.dot(favoured_dir)
		
		if dist_parallel <= 0.1: # Use a small epsilon to ignore strictly perpendicular/behind items
			continue

		# 4. Calculate Cost
		# We already have dist_parallel (Component towards correct direction)
		
		# Now we need the component towards the "wrong" direction (perpendicular deviation).
		# We subtract the parallel part from the total vector to get the remainder.
		var parallel_vector_part = favoured_dir * dist_parallel
		var perpendicular_vector_part = relative_vector - parallel_vector_part
		var dist_perpendicular = perpendicular_vector_part.length()
		
		# Apply scoring: Correct direction * 1, Wrong direction * 2
		var cost = (dist_parallel * 1.0) + (dist_perpendicular * 2.0)
		
		# 5. Choose the cheapest
		if cost < lowest_cost:
			lowest_cost = cost
			best_planet = p
	
	return best_planet



func switch_planet(value : int):
	if not planets_array:
		return
	var array_size = planets_array.size()
	index += value
	if index < 0:
		index = array_size - 1
	elif index > array_size - 1:
		index = 0
	set_planet(planets_array[index])


func set_planet(exported_planet):
	
	if not exported_planet:
		return
	
	planet = exported_planet
	target_pos = planet.global_position
	%PlanetNameLabel.text = planet.planet_name
	
	var current_index = 0
	
	for p in planets_array:
		if planet == p:
			index = current_index
		current_index += 1


func _on_spawn_button_pressed():
	var space = get_tree().get_first_node_in_group("space")
	assert(space,"NO SPACE FOUND!")
	
	var position_to_export = target_pos + Vector3(0,10,0)
	
	space.request_spawn_player.rpc_id(1,multiplayer.get_unique_id(),position_to_export)


func _on_arrow_left_button_pressed():
	switch_planet(-1)


func _on_arrow_right_button_pressed():
	switch_planet(1)
