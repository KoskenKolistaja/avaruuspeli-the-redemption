extends Node3D

#IncomeHandler stores all the buildings and tells planet how much its resources change


var planet : Node
var last_time : float

# Per-second income rates
var incomes := {
	"Food": 0.0,
	"Technology": 0.0,
	"Iron": 0.0,
	"Uranium": 0.0,
}

# Fractional storage
var accumulators := {
	"Food": 0.0,
	"Technology": 0.0,
	"Iron": 0.0,
	"Uranium": 0.0,
}


# Population change rate (people per second)
var population_rate := 0.0
var population_accumulator := 0.0

func _ready():
	planet = get_parent()
	last_time = Time.get_ticks_msec() / 1000.0

func _process(_delta):
	_update()

func _update():
	var now := Time.get_ticks_msec() / 1000.0
	var delta := now - last_time
	last_time = now

	_recalculate_incomes()
	update_display_increases() # 👈 HUD reads this

	_accumulate(delta)
	_apply_if_whole()

	update_population(delta)


func _recalculate_incomes():
	for key in incomes:
		incomes[key] = 0.0

	var buildings := get_sorted_productive_buildings()
	var remaining_population = planet.population
	const POP_PER_BUILDING := 50.0

	for building in buildings:
		if not _can_afford_cost(building):
			continue

		if remaining_population <= 0:
			break

		var efficiency = min(remaining_population / POP_PER_BUILDING, 1.0)

		# Apply production
		for key in building.product_yield:
			incomes[key] += building.product_yield[key] * efficiency

		# Apply upkeep
		for key in building.product_cost:
			incomes[key] -= building.product_cost[key] * efficiency

		remaining_population -= POP_PER_BUILDING

	# Population food consumption
	incomes["Food"] -= planet.population

	# Base food trickle
	incomes["Food"] += 5.0

func _accumulate(delta : float):
	for key in incomes:
		accumulators[key] += incomes[key] * delta

func _apply_if_whole():
	for key in accumulators:
		var whole := int(accumulators[key])

		if whole != 0:
			planet.add_resource(key, whole)
			accumulators[key] -= whole

func _can_afford_cost(building) -> bool:
	for key in building.product_cost:
		if planet.get(key.to_lower()) < building.product_cost[key]:
			return false
	return true

func get_sorted_productive_buildings() -> Array:
	var sorted := []
	
	for child in get_children():
		if child.is_in_group("productive_building"):
			sorted.append(child)
	
	sorted.sort_custom(func(a, b): return a.index_id < b.index_id)
	return sorted

func update_population(delta : float):
	population_rate = 0.0
	
	# Growth: +1 population per second if there is enough food
	if planet.food > planet.population \
	and planet.population < planet.desired_population:
		population_rate = 1.0
	
	# Starvation: faster decline
	elif planet.food < 1:
		population_rate = -1.0
	elif planet.food_increase < 0 and planet.food < planet.population:
		population_rate = -1.0
	
	# Overpopulation correction
	elif planet.population > planet.desired_population:
		population_rate = -1.0
	
	population_accumulator += population_rate * delta
	
	var whole := int(population_accumulator)
	if whole != 0:
		planet.add_population(whole)
		population_accumulator -= whole



func update_display_increases():
	# Resources — store as float, do NOT cast to int
	for key in incomes:
		var increase_name = key.to_lower() + "_increase"
		planet.set(increase_name, incomes[key])   # <-- keep float

	# Population rate — keep float
	planet.population_increase = population_rate
