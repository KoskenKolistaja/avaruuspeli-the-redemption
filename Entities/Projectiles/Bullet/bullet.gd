extends Area3D


var direction = Vector3.ZERO





func _ready():
	pass


func _physics_process(delta):
	global_position += direction * delta




func activate():
	await get_tree().create_timer(2).timeout
	var BulletPool = get_tree().get_first_node_in_group("bullet_pool")
	BulletPool.despawn_bullet(self)






func _on_body_entered(body):
	var BulletPool = get_tree().get_first_node_in_group("bullet_pool")
	BulletPool.despawn_bullet(self)
	if multiplayer.is_server():
		if body.has_method("get_hit"):
			body.get_hit()
