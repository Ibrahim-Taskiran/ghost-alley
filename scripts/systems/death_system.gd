extends Node
class_name DeathSystem

signal player_respawned

var _player: CharacterBody3D = null
var _death_screen: Control = null
var _spawn_point: Vector3 = Vector3.ZERO

func _ready() -> void:
	_player = get_parent() as CharacterBody3D
	_spawn_point = _player.global_position
	
	_player.player_died.connect(_on_player_died)
	
	await get_tree().process_frame
	_death_screen = get_tree().get_first_node_in_group("DeathScreen")

func _on_player_died() -> void:
	# 1. Drop all inventory items at the death spot
	if _player.inventory:
		for i in range(_player.inventory.max_slots):
			var slot = _player.inventory.slots[i]
			if slot["item_id"] != "":
				_player.drop_item_in_world(slot["item_id"], slot["quantity"])
				_player.inventory.slots[i] = {"item_id": "", "quantity": 0}
		_player.inventory.inventory_changed.emit()
		
	# 2. Show DeathScreen UI
	if _death_screen:
		if _death_screen.has_method("show_death_screen"):
			_death_screen.show_death_screen()
			
	_player.show_notification("Öldünüz! Eşyalarınız öldüğünüz yerde kaldı.", Color(0.9, 0.2, 0.2))

func respawn() -> void:
	if not _player:
		return
		
	# Reset player status
	_player.global_position = _spawn_point
	_player.health = _player.max_health
	_player.is_alive = true
	_player.health_changed.emit(_player.health, _player.max_health)
	
	# Reset survival needs if survival exists
	if _player.has_node("SurvivalNeeds"):
		var needs = _player.get_node("SurvivalNeeds")
		needs.hunger = 50.0
		needs.thirst = 50.0
		needs.sleep = 50.0
		needs.needs_changed.emit(50.0, 50.0, 50.0)
		
	# Cure infection if infected
	if _player.has_node("InfectionSystem"):
		_player.get_node("InfectionSystem").cure()
		
	# Reset path target
	_player.call("_stop_moving")
	
	# Hide DeathScreen
	if _death_screen:
		_death_screen.hide()
		
	player_respawned.emit()
	_player.show_notification("Yeniden doğdunuz. Hayatta kalmaya devam edin!", Color(0.3, 0.8, 0.3))
