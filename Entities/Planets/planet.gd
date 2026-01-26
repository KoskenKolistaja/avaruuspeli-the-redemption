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
	add_child(visual_instance,true)
	visual_instance.set_radius(size)
	
	
	await get_tree().create_timer(0.1).timeout
	PlanetData.assign_planet(planet_id,planet_name,self)
	
	if owner_id == 999:
		setup_npc()
	
	await get_tree().create_timer(randf_range(0,1)).timeout
	if multiplayer.is_server():
		$Timer.start()

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

@rpc("any_peer","reliable","call_local")
func request_assing_new_shipment(exported_shipment_dictionary):
	assign_new_shipment(exported_shipment_dictionary)
	assign_new_shipment.rpc(exported_shipment_dictionary)

#Passing function
@rpc("authority","reliable")
func assign_new_shipment(exported_shipment_dictionary):
	%AutoSender.assing_new_shipment(exported_shipment_dictionary)

@rpc("any_peer","reliable","call_local")
func request_assign_new_trade(exported_trade_dictionary):
	assign_new_trade(exported_trade_dictionary)
	assign_new_trade.rpc(exported_trade_dictionary)

#Passing function
@rpc("authority","reliable")
func assign_new_trade(exported_trade_dictionary):
	%AutoSender.assing_new_trade(exported_trade_dictionary)


#Passing function
@rpc("any_peer","reliable","call_local")
func request_delete_shipment(exported_index):
	if not multiplayer.is_server():
		return
	%AutoSender.delete_shipment(exported_index)
	sync_delete_shipment.rpc(exported_index)

@rpc("authority","reliable")
func sync_delete_shipment(exported_index):
	%AutoSender.delete_shipment(exported_index)

@rpc("any_peer","reliable","call_local")
func request_delete_trade(exported_index):
	if not multiplayer.is_server():
		return
	%AutoSender.delete_trade(exported_index)
	sync_delete_trade.rpc(exported_index)


@rpc("authority","reliable")
func sync_delete_trade(exported_index):
	%AutoSender.delete_trade(exported_index)


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
@rpc("any_peer","reliable","call_local")
func request_buy_building(slot_id : int , building_name : String):
	if not multiplayer.is_server():
		return
	if building_name == "none":
		delete_existing_building(slot_id)
		return
	var purchase_valid = _is_building_purchasable(building_name)
	if purchase_valid:
		add_building_locally(slot_id,building_name)
		if planet_page:
			planet_page.building_bought()
		print("Purchase was valid")
		sync_buy_building.rpc(slot_id,building_name)
	else:
		print("Purchase was not valid")



@rpc("authority","reliable")
func sync_buy_building(slot_id,building_name):
	add_building_locally(slot_id,building_name)


func add_building_locally(slot_id,building_name):
	delete_existing_building(slot_id)
	print("Building name is: " + building_name)
	var building_instance = BuildingData.buildings[building_name].instantiate()
	print("Building dictionary returns: " + str(BuildingData.buildings[building_name]))
	$IncomeHandler.add_child(building_instance,true)
	building_instance.index_id = slot_id
	technology -= BuildingData.building_prices[building_name]
	print($IncomeHandler.get_sorted_productive_buildings())


@rpc("any_peer","reliable","call_local")
func request_delete_building(slot_id):
	if not multiplayer.is_server():
		return
	delete_existing_building(slot_id)
	sync_delete_building.rpc(slot_id)

@rpc("any_peer","reliable")
func sync_delete_building(slot_id):
	delete_existing_building(slot_id)
	if planet_page:
		planet_page.building_deleted()

#Action function
func delete_existing_building(slot_id : int):
	var buildings = $IncomeHandler.get_sorted_productive_buildings()
	#print("Buildings in 'delete existing': "  + str(buildings))
	for b in buildings:
		#print(b.index_id)
		#print(slot_id)
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
@rpc("any_peer","reliable","call_local")
func request_set_desired_population(value : int):
	if not multiplayer.is_server():
		return
	desired_population = value

@rpc("authority","reliable")
func sync_desired_population(value):
	desired_population = value



func get_population() -> int:
	return population

func get_food() -> int:
	return food


#func _on_timer_timeout():
	## We pack everything into a single flat array. 
	## No keys, no nested structures, just raw data values.
	## Order: [Pop, Food, Tech, Iron, Ur, Food+, Tech+, Iron+, Ur+]
	#sync_planet_data.rpc([
		#population, 
		#food, 
		#technology, 
		#iron, 
		#uranium,
		#food_increase, 
		#technology_increase, 
		#iron_increase, 
		#uranium_increase
	#])
#
#@rpc("authority", "call_remote", "reliable")
#func sync_planet_data(data: Array):
	## We unpack by index. This is extremely fast and low bandwidth.
	#population = data[0]
	#food = data[1]
	#technology = data[2]
	#iron = data[3]
	#uranium = data[4]
	#
	#food_increase = data[5]
	#technology_increase = data[6]
	#iron_increase = data[7]
	#uranium_increase = data[8]

func _on_timer_timeout():
	# 1. Pack Resources into Int array (Order: Pop, Food, Tech, Iron, Ur)
	# Use PackedInt64Array if your resources will exceed 2 Billion.
	# Use PackedInt32Array to save bandwidth (4 bytes per number vs 8).
	var res_data = PackedInt32Array([
		population, 
		food, 
		technology, 
		iron, 
		uranium,
		desired_population,
	])
	
	
	sync_planet_data.rpc(res_data)


@rpc("authority", "call_remote", "reliable")
func sync_planet_data(res_data: PackedInt32Array):
	# Unpack Integers
	population = res_data[0]
	food       = res_data[1]
	technology = res_data[2]
	iron       = res_data[3]
	uranium    = res_data[4]
	desired_population = res_data[5]

func request_change_owner(exported_id):
	set_planet_owner.rpc_id(1,exported_id)

@rpc("any_peer","call_local","reliable")
func set_planet_owner(exported_id):
	if not owner_id:
		owner_id = exported_id
		sync_owner.rpc(exported_id)

@rpc("authority","reliable")
func sync_owner(exported_id):
	owner_id = exported_id
	if planet_page:
		planet_page.update_base()
