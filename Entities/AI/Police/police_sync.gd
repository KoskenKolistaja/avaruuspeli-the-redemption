extends Area3D





@export var synchronizer : MultiplayerSynchronizer







func disable_sync_for(exported_id):
	synchronizer.set_visibility_for(exported_id,false)


func enable_sync_for(exported_id):
	synchronizer.set_visibility_for(exported_id,true)
