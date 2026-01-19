extends Node3D




func set_radius(new_radius : float):
	#scale = Vector3(new_radius,new_radius,new_radius)
	#
	#if $CloudManager:
		#$CloudManager.sphere_radius * new_radius
	pass


func gain_focus():
	$HighlightMesh.show()

func lose_focus():
	$HighlightMesh.hide()
