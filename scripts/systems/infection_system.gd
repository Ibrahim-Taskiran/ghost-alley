extends Node
class_name InfectionSystem

signal infection_changed(is_infected: bool, time_left_hours: float)

var is_infected: bool = false
var infection_time_left: float = 0.0 # in game-hours (72 hours = 3 days)

var _player: CharacterBody3D = null
var _day_night: DayNightCycle = null
var _notif_timer: float = 0.0

func _ready() -> void:
	_player = get_parent() as CharacterBody3D
	
	await get_tree().process_frame
	_day_night = get_tree().get_first_node_in_group("DayNightCycle") as DayNightCycle

func _process(delta: float) -> void:
	if not _player or not _player.is_alive or not is_infected:
		return
		
	var time_scale = 30.0
	if _day_night:
		time_scale = _day_night.time_scale
		
	# Reduce time left (in game-hours)
	var game_hours = (delta / 60.0) * time_scale
	infection_time_left = max(infection_time_left - game_hours, 0.0)
	
	infection_changed.emit(is_infected, infection_time_left)
	
	# If time runs out, start killing the player
	if infection_time_left <= 0.0:
		_player.take_damage(2.0 * delta) # 2 HP/sec
		
		# Show warning every 5 seconds
		_notif_timer += delta
		if _notif_timer >= 5.0:
			_notif_timer = 0.0
			_player.show_notification("⚠️ Enfeksiyon kalbinize ulaştı! Ölüyorsunuz!", Color(1.0, 0.1, 0.1))

func infect() -> void:
	if is_infected:
		return
		
	is_infected = true
	infection_time_left = 3.0 * 24.0 # 3 game-days = 72 hours
	_player.show_notification("⚠️ Isırıldınız! Vücudunuzda bir enfeksiyon yayılıyor!", Color(0.9, 0.2, 0.2))
	infection_changed.emit(is_infected, infection_time_left)

func cure() -> bool:
	if not is_infected:
		return false
		
	is_infected = false
	infection_time_left = 0.0
	infection_changed.emit(is_infected, infection_time_left)
	return true
