extends Node
class_name SurvivalNeeds

signal needs_changed(hunger: float, thirst: float, sleep: float)

@export var max_hunger: float = 100.0
@export var max_thirst: float = 100.0
@export var max_sleep: float = 100.0

# Drain rates per in-game hour
@export var hunger_drain_rate: float = 1.5
@export var thirst_drain_rate: float = 2.0
@export var sleep_drain_rate: float = 0.8

var hunger: float = 100.0
var thirst: float = 100.0
var sleep: float = 100.0

var _player: CharacterBody3D = null
var _day_night: DayNightCycle = null

func _ready() -> void:
	_player = get_parent() as CharacterBody3D
	
	# Find DayNightCycle to align drain with time scale
	await get_tree().process_frame
	_day_night = get_tree().get_first_node_in_group("DayNightCycle") as DayNightCycle
	
	needs_changed.emit(hunger, thirst, sleep)

func _process(delta: float) -> void:
	if not _player or not _player.is_alive:
		return
		
	var time_scale = 30.0 # Fallback
	if _day_night:
		time_scale = _day_night.time_scale
		
	# Game hours passed in this frame
	var game_hours = (delta / 60.0) * time_scale
	
	# 1. Drain needs
	hunger = clamp(hunger - hunger_drain_rate * game_hours, 0.0, max_hunger)
	thirst = clamp(thirst - thirst_drain_rate * game_hours, 0.0, max_thirst)
	sleep = clamp(sleep - sleep_drain_rate * game_hours, 0.0, max_sleep)
	
	needs_changed.emit(hunger, thirst, sleep)
	
	# 2. Apply penalties
	_apply_penalties(delta)

func _apply_penalties(delta: float) -> void:
	# Hunger penalty: HP -0.5/sec when hunger is 0, speed -30%
	if hunger <= 0.0:
		_player.take_damage(0.5 * delta)
		_player.move_speed = 3.5 # (Normal speed 5.0 * 0.7 = 3.5)
	else:
		_player.move_speed = 5.0 # Reset
		
	# Thirst penalty: HP -1.0/sec when thirst is 0
	if thirst <= 0.0:
		_player.take_damage(1.0 * delta)
		
	# Sleep penalty: all stats -1
	# For simplicity, if sleep is 0, we can just print a alert or apply a slow effect
	if sleep <= 0.0:
		# Slow down slightly
		_player.move_speed = clamp(_player.move_speed - 1.0, 1.0, 5.0)

func feed(amount: float) -> void:
	hunger = clamp(hunger + amount, 0.0, max_hunger)
	needs_changed.emit(hunger, thirst, sleep)

func quench(amount: float) -> void:
	thirst = clamp(thirst + amount, 0.0, max_thirst)
	needs_changed.emit(hunger, thirst, sleep)

func rest(amount: float) -> void:
	sleep = clamp(sleep + amount, 0.0, max_sleep)
	needs_changed.emit(hunger, thirst, sleep)
