extends Area3D
class_name BedItem

var _player: CharacterBody3D = null
var _my_zone: ZoneController = null

func _ready() -> void:
	add_to_group("Beds")
	
	collision_layer = 16 # Pickups / Interactions
	collision_mask = 2   # Player
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Detect which zone we are placed in
	await get_tree().process_frame
	_detect_zone()

func _detect_zone() -> void:
	var zones = get_tree().get_nodes_in_group("Zones")
	for zone in zones:
		if zone is Area3D and zone.overlaps_area(self):
			_my_zone = zone
			break

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player") and body.has_method("register_nearby_bed"):
		body.register_nearby_bed(self)

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player") and body.has_method("unregister_nearby_bed"):
		body.unregister_nearby_bed(self)

func sleep(player: CharacterBody3D) -> void:
	# Force zone check
	_detect_zone()
	
	if not _my_zone or not _my_zone.is_safe:
		player.show_notification("Burası henüz güvenli değil! (Etraftaki zombileri temizleyin)", Color(0.9, 0.3, 0.3))
		return
		
	# Sleep triggers!
	# 1. Fully heal player to 100 (clamp to max_health)
	player.health = player.max_health
	player.health_changed.emit(player.health, player.max_health)
	
	# 2. Refill survival needs
	if player.has_node("SurvivalNeeds"):
		var needs = player.get_node("SurvivalNeeds")
		needs.feed(100.0)
		needs.quench(100.0)
		needs.rest(100.0)
		
	# 3. Fast forward time by 4 hours
	var day_night = get_tree().get_first_node_in_group("DayNightCycle") as DayNightCycle
	if day_night:
		day_night.current_hour += 4.0
		if day_night.current_hour >= 24.0:
			day_night.current_hour -= 24.0
			day_night.current_day += 1
			day_night.day_passed.emit(day_night.current_day)
			
	player.show_notification("💤 Güvenle uyudunuz. Tüm ihtiyaçlarınız karşılandı ve canınız dolduruldu!", Color(0.3, 0.8, 0.3))
