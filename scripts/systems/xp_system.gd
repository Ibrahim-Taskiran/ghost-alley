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

func gain_xp(amount: int, is_kill: bool = false) -> void:
	if not _player or not _player.is_alive:
		return
		
	# GDD §8.2: Öğretmen bonusu (%20 XP kazanım artışı)
	if NPCManager.has_npc("teacher"):
		amount = int(amount * 1.2)
		
	# GDD §8.2: Avcı bonusu (%30 öldürme XP artışı)
	if is_kill and NPCManager.has_npc("hunter"):
		amount = int(amount * 1.3)
		
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
		
		# GDD §2.3: Seviye Atlama Ganimet Ödülleri
		_spawn_level_up_rewards(level)
		
	level_up.emit(level)

func _spawn_level_up_rewards(lvl: int) -> void:
	var items: Array[String] = []
	var qtys: Array[int] = []
	var info_text = ""
	
	if lvl <= 3:
		items = ["konserve", "su", "fener"]
		qtys = [1, 1, 1]
		info_text = "Yiyecek, Su ve El Feneri"
	elif lvl <= 6:
		items = ["bandaj", "sopa"]
		qtys = [2, 1]
		info_text = "Bandaj ve Tahta Sopa"
	elif lvl <= 10:
		items = ["bicak", "metal"]
		qtys = [1, 5]
		info_text = "Av Bıçağı ve Metal"
	elif lvl <= 15:
		items = ["tabanca", "metal", "antibiyotik"]
		qtys = [1, 5, 2]
		info_text = "Tabanca, Metal ve Antibiyotik"
	else:
		items = ["tabanca", "antibiyotik", "metal"]
		qtys = [1, 3, 10]
		info_text = "Efsanevi Mühimmat Paketi"
		
	# Spawn items physically near the player
	for i in range(items.size()):
		var item_id = items[i]
		var qty = qtys[i]
		
		var angle = randf_range(0.0, 2.0 * PI)
		var dist = randf_range(1.0, 2.0)
		var offset = Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
		
		_player.drop_item_in_world(item_id, qty)
		
	_player.show_notification("🎁 Seviye %d Ödülü: %s yere bırakıldı!" % [lvl, info_text], Color(0.3, 0.9, 0.3))
