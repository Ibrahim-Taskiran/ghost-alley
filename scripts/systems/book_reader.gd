extends Node
class_name BookReader

signal reading_started(book_id: String, total_time: float)
signal reading_progress_updated(progress_percent: float, time_remaining: float)
signal reading_completed(book_id: String)
signal reading_cancelled

var current_book_id: String = ""
var is_reading: bool = false
var reading_time_required: float = 0.0
var reading_time_remaining: float = 0.0

var _player: CharacterBody3D = null

func _ready() -> void:
	_player = get_parent() as CharacterBody3D

func start_reading(book_id: String) -> bool:
	if is_reading:
		_player.show_notification("Zaten bir kitap okuyorsunuz!", Color(0.9, 0.3, 0.3))
		return false
		
	var item_data = ItemDatabase.get_item(book_id)
	if item_data.is_empty():
		return false
		
	var effects = item_data.get("effects", {})
	if not effects.has("book"):
		return false
		
	current_book_id = book_id
	is_reading = true
	
	# Reading time required in in-game hours
	var base_time = effects.get("reading_time", 12.0)
	
	var intel = _player.stats.get("intelligence", 1)
	if intel < 1:
		intel = 1
	var req_time = base_time / float(intel)
	if NPCManager.has_npc("teacher"):
		req_time *= 0.5
	reading_time_required = req_time
	reading_time_remaining = reading_time_required
	
	_player.show_notification("📖 %s okunmaya başlandı..." % item_data.get("name", "Kitap"), Color(0.3, 0.8, 0.3))
	reading_started.emit(current_book_id, reading_time_required)
	return true

func cancel_reading() -> void:
	if not is_reading:
		return
		
	var book_id = current_book_id
	var item_data = ItemDatabase.get_item(book_id)
	if _player and _player.inventory:
		_player.inventory.add_item(book_id, 1)
		
	_player.show_notification("Kitap okuma kesildi. %s envantere geri koyuldu." % item_data.get("name", "Kitap"), Color(0.9, 0.5, 0.2))
	_reset()
	reading_cancelled.emit()

func _reset() -> void:
	current_book_id = ""
	is_reading = false
	reading_time_required = 0.0
	reading_time_remaining = 0.0

func _process(delta: float) -> void:
	if not is_reading or not _player or not _player.is_alive:
		return
		
	# How much in-game hours passed
	var time_scale = 30.0
	var day_night = get_tree().get_first_node_in_group("DayNightCycle")
	if day_night:
		time_scale = day_night.time_scale
		
	var hours_passed = (delta / 60.0) * time_scale
	reading_time_remaining -= hours_passed
	
	if reading_time_remaining <= 0.0:
		_complete_reading()
	else:
		var progress = ((reading_time_required - reading_time_remaining) / reading_time_required) * 100.0
		reading_progress_updated.emit(progress, reading_time_remaining)

func _complete_reading() -> void:
	var book_id = current_book_id
	
	_reset()
	
	if book_id == "kitap_tip":
		_player.stats["intelligence"] = _player.stats.get("intelligence", 1) + 1
		_player.stats["military"] = _player.stats.get("military", 1) + 1
		_player.show_notification("📖 Tıp Kitabı tamamen okundu! Zeka +1, Askeri +1 kazanıldı.", Color(0.3, 0.8, 0.3))
		if _player.has_node("XPSystem"):
			_player.get_node("XPSystem").gain_xp(25)
	elif book_id == "kitap_insaat":
		_player.stats["engineering"] = _player.stats.get("engineering", 1) + 2
		_player.show_notification("📖 İnşaat Rehberi tamamen okundu! Mühendislik +2 kazanıldı. Metal Barikat yapabilirsiniz!", Color(0.3, 0.8, 0.3))
		if _player.has_node("XPSystem"):
			_player.get_node("XPSystem").gain_xp(25)
			
	reading_completed.emit(book_id)
