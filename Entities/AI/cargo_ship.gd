extends Node3D


var population : int = 0
var food : int = 0
var technology : int = 0
var iron : int = 0
var uranium : int = 0

@export var population_icon : Texture
@export var food_icon : Texture
@export var technology_icon : Texture
@export var iron_icon : Texture
@export var uranium_icon : Texture


var is_trade_ship = false


@export var initial_receiver : Node3D

var receiver
var receiver_position

var speed = 0.05

func _ready():
	
	if is_trade_ship:
		$CargoShipMesh.hide()
		$TradeShipMesh.show()
	
	receiver_position = receiver.global_position
	if initial_receiver:
		receiver = initial_receiver
	set_icon()
	var vector = receiver.global_position - self.global_position
	var direction = Vector3(vector.x,vector.y,0).normalized()
	direction = direction.rotated(Vector3(0,0,1),deg_to_rad(-90))
	print(direction)
	await get_tree().physics_frame
	global_position += direction * 2
	receiver_position += direction * 2



func set_icon():
	var icon_name = get_biggest_resource() + "_icon"
	$ResourceIcon.get_surface_override_material(0).albedo_texture = get(icon_name)



func get_biggest_resource() -> String:
	var dic = {"population" : population , "food" : food , "technology" : technology , "iron" : iron , "uranium" : uranium} 
	var biggest = "population"
	for key in dic:
		var biggest_number = dic[biggest]
		var current_number = dic[key]
		
		if current_number > biggest_number:
			biggest = key
	return biggest



func _physics_process(delta):
	var vector = receiver_position - self.global_position
	var direction = Vector3(vector.x,vector.y,0).normalized()
	
	rotate_toward_direction(direction)
	
	
	global_position += direction * speed
	
	if vector.length() < 5:
		send_resources()
		queue_free()

func rotate_toward_direction(direction: Vector3):
	direction.z = 0.0
	direction = direction.normalized()
	var angle = atan2(direction.y, direction.x)
	rotation.z = angle + deg_to_rad(-90)

var cargo_dic_example = {
	"population" : 0,
	"food" : 100,
	"technology" : 0,
	"iron" : 0,
	"uranium" : 0,
	}

func set_cargo(c : Dictionary):
	population = c["population"]
	food = c["food"]
	technology = c["technology"]
	iron = c["iron"]
	uranium = c["uranium"]


func send_resources():
	var dic = {
		"population" : population,
		"food" : food,
		"technology" : technology,
		"iron" : iron,
		"uranium" : uranium,
	}
	
	receiver.unload_cargo(dic)
