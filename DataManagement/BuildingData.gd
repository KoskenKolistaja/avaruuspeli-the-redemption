extends Node



@onready var capital = preload("res://Entities/Buildings/capital.tscn")
@onready var factory = preload("res://Entities/Buildings/factory.tscn")
@onready var farm = preload("res://Entities/Buildings/farm.tscn")
@onready var foundry = preload("res://Entities/Buildings/foundry.tscn")
@onready var geothermal_station = preload("res://Entities/Buildings/geothermal_station.tscn")
@onready var greenhouse = preload("res://Entities/Buildings/greenhouse.tscn")
@onready var iron_mine = preload("res://Entities/Buildings/iron_mine.tscn")
@onready var plant_laboratory = preload("res://Entities/Buildings/plant_laboratory.tscn")
@onready var power_plant = preload("res://Entities/Buildings/power_plant.tscn")
@onready var super_farm = preload("res://Entities/Buildings/super_farm.tscn")
@onready var tokamak = preload("res://Entities/Buildings/tokamak.tscn")
@onready var uranium_extractor = preload("res://Entities/Buildings/uranium_extractor.tscn")
@onready var uranium_mine = preload("res://Entities/Buildings/uranium_mine.tscn")

@onready var buildings = {
	"capital" : capital,
	"factory" : factory,
	"farm" : farm,
	"foundry" : foundry,
	"geothermal_station" : geothermal_station,
	"greenhouse" : greenhouse,
	"iron_mine" : iron_mine,
	"plant_laboratory" : plant_laboratory,
	"power_plant" : power_plant,
	"super_farm" : super_farm,
	"tokamak" : tokamak,
	"uranium_extractor" : uranium_extractor,
	"uranium_mine" : uranium_mine,
}


var building_prices = {
	"capital" : 0,
	"factory" : 150,
	"farm" : 50,
	"foundry" : 500,
	"geothermal_station" : 50,
	"greenhouse" : 100,
	"iron_mine" : 250,
	"plant_laboratory" : 250,
	"power_plant" : 1000,
	"super_farm" : 300,
	"tokamak" : 10000,
	"uranium_extractor" : 5000,
	"uranium_mine" : 400,
}

var building_requirements = {
	"capital" : [],
	"factory" : [],
	"farm" : ["atmosphere","warm"],
	"foundry" : [],
	"geothermal_station" : ["hot"],
	"greenhouse" : ["atmosphere"],
	"iron_mine" : ["has_iron"],
	"plant_laboratory" : [],
	"power_plant" : [],
	"super_farm" : ["atmosphere","warm"],
	"tokamak" : [],
	"uranium_extractor" : ["has_uranium"],
	"uranium_mine" : ["has_uranium"],
}
