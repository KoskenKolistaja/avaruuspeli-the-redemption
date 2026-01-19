extends Panel

@export var capital_texture : Texture
@export var factory_texture : Texture
@export var farm_texture : Texture
@export var foundry_texture : Texture
@export var geothermal_station_texture : Texture
@export var greenhouse_texture : Texture
@export var iron_mine_texture : Texture
@export var plant_laboratory_texture : Texture
@export var power_plant_texture : Texture
@export var super_farm_texture : Texture
@export var tokamak_texture : Texture
@export var uranium_extractor_texture : Texture
@export var uranium_mine_texture : Texture


func activate():
	show()
	update()
	$Timer.start()


func deactivate():
	hide()
	$Timer.stop()
	$CataloguePanel.hide()


func update():
	update_icons()
	update_buttons()

func update_buttons():
	var planet = get_parent().planet
	const POP_PER_BUILDING := 50

	var unlocked = max((planet.population / POP_PER_BUILDING) + 1, 0)
	var buttons = $GridContainer.get_children()
	
	unlocked = clamp(unlocked,0,floori(planet.size))
	
	# Hide all buttons first
	for i in buttons.size():
		if i < unlocked:
			buttons[i].show()
		else:
			buttons[i].hide()
	
	
	## Show unlocked buttons (clamped to available buttons)
	#for i in range(min(unlocked, buttons.size())):
		#buttons[i].show()


func update_icons():
	var buildings = get_parent().planet.get_buildings()
	
	# Optional: Reset all slots to empty first to prevent ghost icons
	for child in $GridContainer.get_children():
		child.change_icon(null) # Assuming your slot handles null
		child.change_name("")

	for b in buildings:
		var index = b.index_id # e.g., 5
		
		# Ensure the slot exists to prevent crashes if ID > child count
		if index - 1 < $GridContainer.get_child_count():
			var slot = $GridContainer.get_child(index - 1)
			
			# USE 'b' DIRECTLY via the loop variable
			var building_name = b.building_name 
			
			var string = building_name + "_texture"
			var tex = get(string)
			slot.change_icon(tex)
			slot.change_name(building_name)



func button_pressed(button_id):
	$CataloguePanel.slot_to_edit = button_id
	$CataloguePanel.show()

func delete_button_pressed(button_id):
	get_parent().request_delete_building(button_id)

func _on_catalogue_exit_pressed():
	$CataloguePanel.hide()


func _on_timer_timeout():
	update()
