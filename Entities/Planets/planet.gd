extends Node3D

class_name Planet


@export var planet_visual : PackedScene

@export var size : float

@export var planet_id : int

@export var owner_id : int


#Planet data

@export var planet_name : String = "Xebion 12"
@export var planet_icon : Texture




#Planet traits

@export var atmosphere : bool
@export var warm : bool
@export var hot : bool
@export var has_iron : bool
@export var has_uranium : bool



#Planet resources

var population : int = 10
var food : int = 5000
var technology : int = 0
var iron : int = 0
var uranium : int = 0

#Planet income

var population_increase : float = 0
var food_increase : float = 0
var technology_increase : float = 0
var iron_increase : float = 0
var uranium_increase : float = 0



#Setting variables

var desired_population : int = 100


#Buildings

var buildings : Array = []


#References

@export var planet_page : Control


func _ready():
	
	var visual_instance = planet_visual.instantiate()
	add_child(visual_instance)
	visual_instance.set_radius(size)
	
	
	await get_tree().create_timer(0.1).timeout
	PlanetData.assign_planet(planet_id,planet_name,self)
	
	if owner_id == 999:
		setup_npc()


func set_owner_id(exported_id):
	owner_id = exported_id

func get_owner_id() -> int:
	return owner_id


func get_buildings():
	return $IncomeHandler.get_sorted_productive_buildings()

func get_shipment_dictionaries():
	return %AutoSender.get_shipment_dictionaries()

func get_trade_dictionaries():
	return %AutoSender.get_trade_dictionaries()

func get_auto_sender():
	return %AutoSender


#Passing function
func assign_new_shipment(exported_shipment_dictionary):
	%AutoSender.assing_new_shipment(exported_shipment_dictionary)


#Passing function
func assign_new_trade(exported_trade_dictionary):
	%AutoSender.assing_new_trade(exported_trade_dictionary)


#Passing function
func request_delete_shipment(exported_index):
	%AutoSender.delete_shipment(exported_index)


func setup_npc():
	technology = 30000
	desired_population = 550
	population = 550
	buy_npc_buildings()

func buy_npc_buildings():
	var buildings = {
		1 : "super_farm",
		2 : "super_farm",
		3 : "super_farm",
		4 : "iron_mine",
		5 : "iron_mine",
		6 : "iron_mine",
		7 : "iron_mine",
		8 : "iron_mine",
		9: "uranium_extractor",
		10: "power_plant",
		11: "foundry"
		}
	
	for key in buildings:
		request_buy_building(key,buildings[key])


#Action function
func request_buy_building(slot_id : int , building_name : String):
	if building_name == "none":
		delete_existing_building(slot_id)
		return
	var purchase_valid = _is_building_purchasable(building_name)
	if purchase_valid:
		delete_existing_building(slot_id)
		print("Building name is: " + building_name)
		var building_instance = BuildingData.buildings[building_name].instantiate()
		print("Building dictionary returns: " + str(BuildingData.buildings[building_name]))
		$IncomeHandler.add_child(building_instance)
		building_instance.index_id = slot_id
		technology -= BuildingData.building_prices[building_name]
		
		print($IncomeHandler.get_sorted_productive_buildings())
		
		if planet_page:
			planet_page.building_bought()
		print("Purchase was valid")
	else:
		print("Purchase was not valid")


#Action function
func delete_existing_building(slot_id : int):
	var buildings = $IncomeHandler.get_sorted_productive_buildings()
	#print("Buildings in 'delete existing': "  + str(buildings))
	for b in buildings:
		print(b.index_id)
		print(slot_id)
		if b.index_id == slot_id:
			#print("To be deleted: " + str(b))
			# Immediately remove from parent so get_children() doesn't see it
			$IncomeHandler.remove_child(b) 
			b.queue_free()
			return


#Check function
func _is_building_purchasable(building_name) -> bool:
	if technology < BuildingData.building_prices[building_name]:
		print("Not enough resources")
		return false
	
	var reqs = BuildingData.building_requirements[building_name]
	
	# Check if the requirement string exists, THEN check the planet's bool
	if reqs.has("atmosphere") and not atmosphere:
		print("No atmosphere")
		return false
	if reqs.has("warm") and not warm:
		print("Not warm")
		return false
	if reqs.has("hot") and not hot:
		print("Not hot")
		return false
	if reqs.has("has_iron") and not has_iron:
		print("No iron")
		return false
	if reqs.has("has_uranium") and not has_uranium:
		print("No uranium")
		return false
	return true

#Action function
func unload_cargo(dic : Dictionary):
	for resource_name in dic:
		set(resource_name,get(resource_name) + dic[resource_name])

#Local function
func add_resource(type : String, amount : float):
	var var_name = type.to_lower()
	var new_value = max(0.0, get(var_name) + amount)
	set(var_name, new_value)

#Host only
func add_population(amount):
	population += amount
	population = clamp(population,0,INF)

#Action function
func set_desired_population(value : int):
	desired_population = value

func get_population() -> int:
	return population

func get_food() -> int:
	return food
