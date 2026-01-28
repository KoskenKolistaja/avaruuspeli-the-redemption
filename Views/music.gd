extends AudioStreamPlayer


var song1 = preload("res://Assets/Audio/Music/Apollo.ogg")
var song2 = preload("res://Assets/Audio/Music/LeavingHome.ogg")
var song3 = preload("res://Assets/Audio/Music/MeansToSurvive.ogg")
var song4 = preload("res://Assets/Audio/Music/Revelation.ogg")
var song5 = preload("res://Assets/Audio/Music/Uncharted.ogg")

var index = 0

var songs = [song1,song2,song3,song4,song5]

func _ready():
	play_random_song()


func _on_finished():
	play_random_song()


func play_random_song():
	var array_size = songs.size()
	var index_range = array_size - 1
	var pool = []
	for n in array_size:
		pool.append(n-1)
	pool.erase(index)
	
	var random_index = pool.pick_random()
	stream = songs[random_index]
	play()
	index = random_index
	
