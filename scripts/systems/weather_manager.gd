extends Node

signal weather_changed(new_weather: String)

var current_weather: String = "SUNNY"

# Weather states
const SUNNY = "SUNNY"
const RAINY = "RAINY"
const STORM = "STORM"
const FOGGY = "FOGGY"
const SNOWY = "SNOWY"

var weather_metadata: Dictionary = {
	SUNNY: { "name": "Güneşli", "icon": "☀️", "speed_mult": 1.0, "zombie_speed_mult": 1.0, "sight_mult": 1.0, "sound_mult": 1.0 },
	RAINY: { "name": "Yağmurlu", "icon": "🌧️", "speed_mult": 1.0, "zombie_speed_mult": 1.0, "sight_mult": 0.7, "sound_mult": 0.5 },
	STORM: { "name": "Fırtınalı", "icon": "⛈️", "speed_mult": 0.8, "zombie_speed_mult": 0.8, "sight_mult": 0.5, "sound_mult": 0.0 },
	FOGGY: { "name": "Sisli", "icon": "🌫️", "speed_mult": 1.0, "zombie_speed_mult": 1.0, "sight_mult": 0.4, "sound_mult": 1.0 },
	SNOWY: { "name": "Karlı", "icon": "❄️", "speed_mult": 0.8, "zombie_speed_mult": 0.8, "sight_mult": 0.8, "sound_mult": 0.9 }
}

var _day_night = null
var _change_timer: float = 0.0

func _ready() -> void:
	add_to_group("WeatherManager")
	
	# Connect to DayNightCycle to align weather changes with in-game days
	await get_tree().process_frame
	_day_night = get_tree().get_first_node_in_group("DayNightCycle")
	if _day_night:
		_day_night.day_passed.connect(_on_day_passed)
		
	# Initial weather
	change_weather(SUNNY)

func _process(delta: float) -> void:
	# Also check for a random weather change every 180 seconds for test convenience
	_change_timer += delta
	if _change_timer >= 180.0:
		_change_timer = 0.0
		if randf() <= 0.35:
			_trigger_random_weather()

func _on_day_passed(_day_num: int) -> void:
	# 50% chance to trigger weather change on a new day
	if randf() <= 0.5:
		_trigger_random_weather()

func _trigger_random_weather() -> void:
	var weathers = [SUNNY, RAINY, STORM, FOGGY, SNOWY]
	var weights = [0.4, 0.2, 0.1, 0.15, 0.15]
	
	var r = randf()
	var selected = SUNNY
	var cumulative = 0.0
	for i in range(weathers.size()):
		cumulative += weights[i]
		if r <= cumulative:
			selected = weathers[i]
			break
			
	change_weather(selected)

func change_weather(new_weather: String) -> void:
	if not weather_metadata.has(new_weather):
		return
		
	current_weather = new_weather
	weather_changed.emit(current_weather)
	
	var details = weather_metadata[current_weather]
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		players[0].show_notification("☁️ Hava Değişti: %s %s" % [details["name"], details["icon"]], Color(0.6, 0.85, 0.9))

func get_multiplier(property: String) -> float:
	if weather_metadata.has(current_weather) and weather_metadata[current_weather].has(property):
		return weather_metadata[current_weather][property]
	return 1.0

func get_icon() -> String:
	if weather_metadata.has(current_weather):
		return weather_metadata[current_weather]["icon"]
	return "☀️"
