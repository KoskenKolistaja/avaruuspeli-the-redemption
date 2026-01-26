extends Panel

var slot_to_edit : int = 0

@export var parent : Control



func _ready():
	if slot_to_edit < 1:
		hide()



func request_buy_building(slot_id : int , building_name : String):
	#parent = PlanetPage
	parent.request_buy_building(slot_id,building_name)
	hide()


func _on_capital_panel_pressed():
	request_buy_building(slot_to_edit,"capital")

func _on_farm_panel_pressed():
	request_buy_building(slot_to_edit,"farm")


func _on_greenhouse_panel_pressed():
	request_buy_building(slot_to_edit,"greenhouse")


func _on_plant_laboratory_panel_pressed():
	request_buy_building(slot_to_edit,"plant_laboratory")


func _on_factory_panel_pressed():
	request_buy_building(slot_to_edit,"factory")


func _on_foundry_panel_pressed():
	request_buy_building(slot_to_edit,"foundry")


func _on_power_plant_panel_pressed():
	request_buy_building(slot_to_edit,"power_plant")


func _on_iron_mine_panel_pressed():
	request_buy_building(slot_to_edit,"iron_mine")

func _on_super_farm_panel_pressed():
	request_buy_building(slot_to_edit,"super_farm")

func _on_uranium_extractor_panel_pressed():
	request_buy_building(slot_to_edit,"uranium_extractor")

func _on_uranium_mine_panel_pressed():
	request_buy_building(slot_to_edit,"uranium_mine")

func _on_tokamak_panel_pressed():
	request_buy_building(slot_to_edit,"tokamak")

func _on_geothermal_station_panel_pressed():
	request_buy_building(slot_to_edit,"geothermal_station")

func _on_none_pressed():
	request_buy_building(slot_to_edit,"none")
