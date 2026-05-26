extends Node
class_name DayNightCycle

signal time_changed(hour: int, minute: int)
signal day_started
signal night_started
signal day_passed(day_number: int)

@export_category("Time Settings")
@export var time_scale: float = 30.0 # High value for prototyping (default is 1 in-game hour = 2 real seconds at 30.0)
@export var day_start_hour: float = 6.0
@export var night_start_hour: float = 23.0

@export_category("Node References")
@export var sun_light: DirectionalLight3D
@export var world_env: WorldEnvironment

var current_hour: float = 6.0
var current_day: int = 1
var is_night: bool = false

# Visual lerp targets
var day_sky_top = Color(0.35, 0.38, 0.48)
var night_sky_top = Color(0.02, 0.03, 0.08)
var day_sky_horizon = Color(0.55, 0.52, 0.48)
var night_sky_horizon = Color(0.04, 0.05, 0.1)

var day_ambient_color = Color(0.5, 0.5, 0.55)
var night_ambient_color = Color(0.08, 0.1, 0.18)

func _ready() -> void:
	add_to_group("DayNightCycle")
	# Autodetect references if not explicitly set
	if not sun_light:
		sun_light = get_parent().get_node_or_null("DirectionalLight3D")
	if not world_env:
		world_env = get_parent().get_node_or_null("WorldEnvironment")
		
	# Setup initial state
	_update_time_visuals(0.0)

func _process(delta: float) -> void:
	# Advance time (delta is in seconds. 1 game hour = 60 real seconds at scale 1.0)
	current_hour += (delta / 60.0) * time_scale
	
	# Handle day transition
	if current_hour >= 24.0:
		current_hour -= 24.0
		current_day += 1
		day_passed.emit(current_day)
		
	# Check day/night transition
	var now_night = (current_hour >= night_start_hour or current_hour < day_start_hour)
	if now_night != is_night:
		is_night = now_night
		if is_night:
			night_started.emit()
		else:
			day_started.emit()
			
	# Emit hourly/minute signal
	var hr = floor(current_hour)
	var mn = floor((current_hour - hr) * 60.0)
	time_changed.emit(int(hr), int(mn))
	
	# Update lighting and sky
	_update_time_visuals(delta)

func _update_time_visuals(_delta: float) -> void:
	if not sun_light:
		return
		
	# 1. Rotate sun on X-axis (0 to 360 degrees)
	# Map current hour to 360 degrees rotation.
	# Day is from 6.0 to 23.0 (17 hours). We map this to 0 to 180 degrees.
	# Night is from 23.0 to 6.0 (7 hours). We map this to 180 to 360 degrees.
	var angle: float = 0.0
	var factor: float = 0.0
	
	if not is_night:
		factor = (current_hour - day_start_hour) / (night_start_hour - day_start_hour)
		angle = factor * 180.0
	else:
		if current_hour >= night_start_hour:
			factor = (current_hour - night_start_hour) / (24.0 - night_start_hour + day_start_hour)
		else:
			factor = (current_hour + (24.0 - night_start_hour)) / (24.0 - night_start_hour + day_start_hour)
		angle = 180.0 + factor * 180.0
		
	# Apply rotation (skewed a bit on Y for a nice isometric angle look)
	sun_light.rotation_degrees = Vector3(angle - 90.0, -45.0, 0.0)
	
	# 2. Adjust lighting intensity & colors based on daylight factor (smooth sine curve)
	var light_factor = 0.0
	if not is_night:
		# Bell curve: 0 at sunrise, 1 at midday, 0 at sunset
		light_factor = sin(factor * PI)
		sun_light.light_energy = lerp(0.1, 1.2, light_factor)
		sun_light.light_color = Color(1.0, 0.9, 0.8).lerp(Color(1.0, 0.5, 0.25), 1.0 - light_factor)
	else:
		# Night curve (moonlight peaking at midnight)
		light_factor = sin(factor * PI)
		sun_light.light_energy = lerp(0.01, 0.15, light_factor)
		sun_light.light_color = Color(0.2, 0.25, 0.4)
		
	# 3. Environment sky and ambient settings
	if world_env and world_env.environment:
		var env = world_env.environment
		
		# Set ambient lighting
		if not is_night:
			env.ambient_light_color = day_ambient_color.lerp(Color(0.6, 0.35, 0.2), 1.0 - light_factor)
			env.ambient_light_energy = lerp(0.15, 0.7, light_factor)
		else:
			env.ambient_light_color = night_ambient_color
			env.ambient_light_energy = lerp(0.05, 0.18, light_factor)
			
		# Lerp ProceduralSkyMaterial colors if it exists
		if env.sky and env.sky.sky_material is ProceduralSkyMaterial:
			var sky_mat = env.sky.sky_material as ProceduralSkyMaterial
			
			if not is_night:
				sky_mat.sky_top_color = night_sky_top.lerp(day_sky_top, light_factor)
				sky_mat.sky_horizon_color = night_sky_horizon.lerp(day_sky_horizon, light_factor)
			else:
				sky_mat.sky_top_color = night_sky_top
				sky_mat.sky_horizon_color = night_sky_horizon
