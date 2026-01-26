extends Node3D

# --- Configuration ---
@export_group("Spawning")
@export var cloud_particle_scene: PackedScene
@export var cloud_count: int = 20
@export var spawn_interval: float = 0.2

@export_group("Sphere Settings")
@export var sphere_radius: float = 20.0
@export var move_speed: float = 0.5
@export var rotation_correction: bool = true

@export_group("Fluctuation")
@export var toggle_interval_min: float = 3.0
@export var toggle_interval_max: float = 10.0

@export_group("Clustering behavior")
@export_range(0.0, 1.0) var grouping_chance: float = 0.7 

# --- Internal Data ---
var clouds: Array = []
var current_spawn_timer: float = 0.0

func _ready():
	if not cloud_particle_scene:
		set_process(false)

func _process(delta):
	# 1. Manage Spawning Queue
	if clouds.size() < cloud_count:
		current_spawn_timer -= delta
		if current_spawn_timer <= 0:
			_spawn_cloud()
			current_spawn_timer = spawn_interval

	# 2. Manage Existing Clouds
	for data in clouds:
		_process_movement(data, delta)
		_process_lifecycle(data, delta)

# --- Logic ---

func _spawn_cloud():
	var instance = cloud_particle_scene.instantiate()
	add_child(instance,true)
	
	if "emitting" in instance:
		instance.emitting = true
	
	# Initial random position (Now strictly Z+)
	instance.position = _get_random_point_on_sphere()
	_orient_cloud(instance)
	
	var data = {
		"node": instance,
		"target": _get_random_point_on_sphere(), # Target is also strictly Z+
		"timer": randf_range(toggle_interval_min, toggle_interval_max)
	}
	
	clouds.append(data)

func _process_movement(data, delta):
	var node = data["node"]
	var target = data["target"]
	
	# Move
	var current_dir = node.position.normalized()
	if current_dir == Vector3.ZERO: current_dir = Vector3.UP
	
	var target_dir = target.normalized()
	# Slerp ensures we follow the sphere curvature
	var new_dir = current_dir.slerp(target_dir, move_speed * delta)
	
	node.position = new_dir * sphere_radius
	
	if rotation_correction:
		_orient_cloud(node)
	
	# Pick new target if reached destination
	if node.position.distance_to(target) < 1.0:
		data["target"] = _get_random_point_on_sphere()

func _process_lifecycle(data, delta):
	data["timer"] -= delta
	
	if data["timer"] <= 0:
		var node = data["node"]
		var is_currently_on = node.emitting
		
		if is_currently_on:
			node.emitting = false
		else:
			if randf() < grouping_chance:
				_teleport_to_active_cloud(data)
			node.emitting = true
			
		data["timer"] = randf_range(toggle_interval_min, toggle_interval_max)

func _teleport_to_active_cloud(my_data):
	var candidates = []
	for other_data in clouds:
		if other_data != my_data and other_data["node"].emitting:
			candidates.append(other_data)
	
	if candidates.size() > 0:
		var parent = candidates.pick_random()
		
		my_data["node"].position = parent["node"].position
		# The new random target will inherently be on the Z+ side
		# because _get_random_point_on_sphere only returns positive Z points now
		my_data["target"] = _get_random_point_on_sphere()
		
		_orient_cloud(my_data["node"])

# --- Math Helpers ---

func _get_random_point_on_sphere() -> Vector3:
	# CHANGE: Theta restricted to 0 -> PI (0 to 180 degrees)
	# This ensures sin(theta) is always positive (0 to 1)
	# Resulting in Z always being >= 0
	var theta = randf_range(0, PI) 
	
	var phi = randf_range(-PI / 2, PI / 2)
	var x = sphere_radius * cos(phi) * cos(theta)
	var y = sphere_radius * sin(phi)
	var z = sphere_radius * cos(phi) * sin(theta)
	
	return Vector3(x, y, z)

func _orient_cloud(node: Node3D):
	if node.position.length_squared() > 0.001:
		node.look_at(-node.global_position.normalized(), Vector3.UP)
