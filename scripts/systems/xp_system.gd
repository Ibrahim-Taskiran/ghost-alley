extends Node
class_name XPSystem

signal level_up(new_level: int)
signal xp_changed(current_xp: int, required_xp: int)

var level: int = 1
var xp: int = 0
var xp_required: int = 100

var _player: CharacterBody3D = null

func _ready() -> void:
	_player = get_parent() as CharacterBody3D
	xp_required = level * 100
	
	await get_tree().process_frame
	xp_changed.emit(xp, xp_required)

func gain_xp(amount: int) -> void:
	if not _player or not _player.is_alive:
		return
		
	xp += amount
	_player.show_notification("+%d XP" % amount, Color(0.7, 0.7, 0.9))
	
	# Handle leveling up (can level up multiple times if huge XP gained)
	var leveled_up = false
	while xp >= xp_required:
		xp -= xp_required
		level += 1
		xp_required = level * 100
		leveled_up = true
		_on_level_up()
		
	xp_changed.emit(xp, xp_required)

func _on_level_up() -> void:
	# Randomly increment one of player's core survival stats
	var stat_keys = _player.stats.keys()
	if stat_keys.size() > 0:
		var random_stat = stat_keys[randi() % stat_keys.size()]
		_player.stats[random_stat] += 1
		
		var stat_name_tr = "Güç"
		if random_stat == "military": stat_name_tr = "Askeri"
		elif random_stat == "engineering": stat_name_tr = "Mühendislik"
		elif random_stat == "intelligence": stat_name_tr = "Zeka"
		
		_player.show_notification("⭐ SEVİYE ATLADINIZ! Seviye %d (%s +1)" % [level, stat_name_tr], Color(1.0, 0.85, 0.2))
		
	level_up.emit(level)
