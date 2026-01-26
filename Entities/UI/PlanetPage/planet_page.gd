extends Control



@export var planet : Node3D

var active = false



func set_planet(exported_planet):
	planet = exported_planet
	$TradePanel.planet = planet
	exported_planet.planet_page = self


func activate(exported_planet):
	set_planet(exported_planet)
	show()
	update_base()
	active = true
	$SettingsPanel.hide()
	$BuildingsPanel.deactivate()
	$TradePanel.hide()

func deactivate():
	hide()
	active = false



func _physics_process(delta):
	if active:
		update_resources()
		update_increases()


func assign_new_shipment(exported_dictionary):
	planet.request_assign_new_shipment.rpc_id(1,exported_dictionary)


func request_buy_building(slot_id : int , building_name : String):
	planet.request_buy_building.rpc_id(1,slot_id,building_name)

func request_delete_building(slot_id):
	planet.request_delete_building.rpc_id(1,slot_id)

func building_bought():
	$BuildingsPanel.update()
	$BuildingsPanel/CataloguePanel.hide()

func building_deleted():
	$BuildingsPanel.update()


func update_base():
	$%SizeLabel.text = str(floori(planet.size))
	update_name()
	update_traits()
	update_resources()
	update_owner()



func update_owner():
	var owner_id = planet.owner_id
	
	if not owner_id:
		$PlanetPanel/OwnerName.hide()
		%ColonizeButton.show()
		hide_buttons()
	elif owner_id == PlayerData.my_id:
		$PlanetPanel/OwnerName.hide()
		show_buttons()
		%ColonizeButton.hide()
	else:
		var owner_name = PlayerData.player_names[owner_id]
		$PlanetPanel/OwnerName.text = "Governor: " + owner_name
		$PlanetPanel/OwnerName.show()
		hide_buttons()
		%ColonizeButton.hide()

func hide_buttons():
	for b in $%ButtonContainer.get_children():
		b.hide()

func show_buttons():
	for b in $%ButtonContainer.get_children():
		b.show()


func update_name():
	$PlanetPanel/PlanetNameLabel.text = str(planet.planet_name)

func update_traits():
	if planet.atmosphere:
		$PlanetPanel/PlanetContents/TraitContainer/Atmosphere.show()
	else:
		$PlanetPanel/PlanetContents/TraitContainer/Atmosphere.hide()
	if planet.warm:
		$PlanetPanel/PlanetContents/TraitContainer/Warm.show()
	else:
		$PlanetPanel/PlanetContents/TraitContainer/Warm.hide()
	if planet.hot:
		$PlanetPanel/PlanetContents/TraitContainer/Hot.show()
	else:
		$PlanetPanel/PlanetContents/TraitContainer/Hot.hide()
	if planet.has_iron:
		$PlanetPanel/PlanetContents/TraitContainer/Iron.show()
	else:
		$PlanetPanel/PlanetContents/TraitContainer/Iron.hide()
	if planet.has_uranium:
		$PlanetPanel/PlanetContents/TraitContainer/Uranium.show()
	else:
		$PlanetPanel/PlanetContents/TraitContainer/Uranium.hide()

func update_resources():
	%PopulationAmount.text = str(format_number(planet.population))
	%PopulationIncrease.text = str(format_number(planet.population_increase))
	%FoodAmount.text = str(format_number(planet.food))
	%FoodIncrease.text = str(format_number(planet.food_increase))
	%TechnologyAmount.text = str(format_number(planet.technology))
	%TechnologyIncrease.text = str(format_number(planet.technology_increase))
	%IronAmount.text = str(format_number(planet.iron))
	%IronIncrease.text = str(format_number(planet.iron_increase))
	%UraniumAmount.text = str(format_number(planet.uranium))
	%UraniumIncrease.text = str(format_number(planet.uranium_increase))

func format_number(value: int) -> String:
	var result: String = ""
	
	if value < 1000:
		return str(value)
	
	if value < 10000:
		# Format as "1,234" or "5,000"
		return str(value).insert(str(value).length() - 3, ",")
	
	if value < 1000000:
		# Format as "10,5k"
		var simplified = float(value) / 1000.0
		# snapped(0.1) keeps one decimal place
		result = str(snapped(simplified, 0.1)).replace(".", ",") + "k"
		return result
	
	# Millions (1,5m)
	var simplified = float(value) / 1000000.0
	result = str(snapped(simplified, 0.1)).replace(".", ",") + "m"
	return result




func update_increases():
	_update_label(%PopulationIncrease, planet.population_increase)
	_update_label(%FoodIncrease, planet.food_increase)
	_update_label(%TechnologyIncrease, planet.technology_increase)
	_update_label(%IronIncrease, planet.iron_increase)
	_update_label(%UraniumIncrease, planet.uranium_increase)

func _update_label(label: Label, value: float):
	label.text = _format_signed_rate(value)
	label.modulate = _color_for_value(value)



func _format_signed_rate(value : float) -> String:
	if abs(value) < 0.05:
		return "0.0/s"
	
	var sign := "+" if value > 0 else "-"
	return "%s%.1f/s" % [sign, abs(value)]

func _color_for_value(value : float) -> Color:
	if value > 0:
		return Color(0.2, 1.0, 0.2) # green
	elif value < 0:
		return Color(1.0, 0.3, 0.3) # red
	else:
		return Color(0.7, 0.7, 0.7) # gray












func _on_settings_button_pressed():
	$BuildingsPanel.deactivate()
	$SettingsPanel/SettingsContainer/DesiredPopulationContainer/SpinBox.value = planet.desired_population
	$SettingsPanel.show()
	$TradePanel.hide()
	$ShipPanel.hide()

func _on_buildings_button_pressed():
	$SettingsPanel.hide()
	$BuildingsPanel.activate()
	$TradePanel.hide()
	$ShipPanel.hide()

func _on_trade_button_pressed():
	$SettingsPanel.hide()
	$BuildingsPanel.deactivate()
	$TradePanel.update()
	$TradePanel.show()
	$ShipPanel.hide()

func _on_science_button_pressed():
	pass # Replace with function body.


func _on_ship_button_pressed():
	$SettingsPanel.hide()
	$BuildingsPanel.deactivate()
	$TradePanel.hide()
	$ShipPanel.show()

func _on_military_button_pressed():
	pass # Replace with function body.


func _on_spin_box_value_changed(value):
	var int_value = roundi(value)
	if planet:
		planet.request_set_desired_population.rpc_id(1,int_value)
	else:
		push_error("Planet page didn't find planet!")





func _on_settings_exit_pressed():
	$SettingsPanel.hide()





func _on_buildings_exit_pressed():
	$BuildingsPanel.deactivate()


func _on_colonize_button_pressed():
	planet.request_change_owner(PlayerData.my_id)
	update_base()
