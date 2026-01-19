extends Camera3D

## SETTINGS
@export_group("Target")
@export var target_to_follow: Node3D

@export_group("Movement")
@export var smooth_speed: float = 5.0
@export var z_distance: float = 20.0
@export var look_ahead_factor: float = 0.5 # How far to pan in direction of velocity

func _ready() -> void:
	# If the camera is a child of the player, this detaches its transform 
	# so the player's rotation doesn't spin the camera.
	set_as_top_level(true)

func _physics_process(delta: float) -> void:
	if not target_to_follow:
		return

	# 1. Calculate Base Position (Player X/Y + Fixed Z)
	var target_pos = Vector3(
		target_to_follow.global_position.x, 
		target_to_follow.global_position.y, 
		z_distance
	)

	# 2. Apply "Look Ahead"
	# If the target has a 'velocity' property (like our ship), peek forward
	if "velocity" in target_to_follow:
		var velocity_offset = target_to_follow.velocity * look_ahead_factor
		# Keep the Z offset clean (we don't want to zoom in/out based on speed)
		velocity_offset.z = 0 
		target_pos += velocity_offset

	# 3. Smoothly Move Camera
	# Lerp (Linear Interpolation) eases the camera movement so it's not jittery
	global_position = global_position.lerp(target_pos, smooth_speed * delta)

### OPTIONAL: SCREEN SHAKE
# Call this from your ship script like: camera.shake(0.5)
var shake_strength: float = 0.0

func shake(intensity: float):
	shake_strength = intensity

func _process(delta: float) -> void:
	if shake_strength > 0:
		shake_strength = lerp(shake_strength, 0.0, 5.0 * delta)
		
		# Apply random offset based on strength
		var random_offset = Vector3(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength),
			0
		)
		h_offset = random_offset.x
		v_offset = random_offset.y
	else:
		h_offset = 0
		v_offset = 0
