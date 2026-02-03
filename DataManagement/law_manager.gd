extends Node3D


@export var police_scene : PackedScene

var outlaws = []




func _ready():
	if multiplayer.is_server():
		$Timer.start()


func add_outlaw(exported_id):
	if not outlaws.has(exported_id):
		outlaws.append(exported_id)
		print("OUTLAW ADDED: " + str(exported_id))

func remove_outlaw(exported_id):
	outlaws.erase(exported_id)
	print("OUTLAW REMOVED: " + str(exported_id))

func spawn_police(exported_target):
	var police_container = get_tree().get_first_node_in_group("police_container")
	var police_instance = police_scene.instantiate()
	print(exported_target)
	police_instance.target = exported_target
	police_container.add_child(police_instance,true)
	police_instance.global_position = Vector3(randi_range(100,200),randi_range(100,200),0)



func _on_timer_timeout():
	
	if not get_tree().get_nodes_in_group("police").size() > 3:
		for id in outlaws:
			var player = PlayerData.get_player(id)
			spawn_police(player)
	else:
		for id in outlaws:
			var player = PlayerData.get_player(id)
			for p in get_tree().get_nodes_in_group("police"):
				print(p.target)
				if not is_instance_valid(p.target):
					p.target = player
					return
