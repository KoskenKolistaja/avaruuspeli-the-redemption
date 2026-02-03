extends Node3D


@export var police_scene : PackedScene

var outlaws = []




func _ready():
	if multiplayer.is_server():
		$Timer.start()


func add_outlaw(exported_id):
	outlaws.append(exported_id)



func spawn_police():
	var police_container = get_tree().get_first_node_in_group("police_container")
	var police_instance = police_scene.instantiate()
	police_container.add_child(police_instance,true)
	police_instance.global_position = Vector3(randi_range(100,200),randi_range(100,200),0)



func _on_timer_timeout():
	
	if not get_tree().get_nodes_in_group("police").size() > 2:
		spawn_police()
