extends Node

# GDD §10.2: 7-Day Resource Respawn System in Dangerous Zones

var _last_respawn_day: int = 1

func _ready() -> void:
	add_to_group("ResourceRespawner")
	
	# Connect to DayNightCycle day_passed signal
	await get_tree().process_frame
	var day_night = get_tree().get_first_node_in_group("DayNightCycle")
	if day_night:
		day_night.connect("day_passed", _on_day_passed)
		_last_respawn_day = day_night.current_day

func _on_day_passed(day_number: int) -> void:
	# Her 7 günde bir tetikle (7, 14, 21...)
	if day_number % 7 != 0:
		return
		
	if day_number == _last_respawn_day:
		return
		
	_last_respawn_day = day_number
	respawn_resources()

func respawn_resources() -> void:
	var zones = get_tree().get_nodes_in_group("Zones")
	var respawned_count = 0
	
	var players = get_tree().get_nodes_in_group("Player")
	var player = players[0] if players.size() > 0 else null
	
	for zone in zones:
		# Sadece güvenli olmayan (tehlikeli) bölgelerde yenileme yap
		if zone.get("is_safe") == true:
			continue
			
		var zone_id = zone.get("zone_id")
		var danger_level = 1
		
		# District info'dan tehlike seviyesini al
		if is_instance_valid(DistrictManager) and DistrictManager.districts.has(zone_id):
			danger_level = DistrictManager.districts[zone_id]["danger_level"]
			
		# Rastgele 2 ila 4 adet eşya spawn et
		var items_to_spawn = randi_range(2, 4)
		var item_scene = load("res://scenes/items/world_item.tscn")
		
		if not item_scene:
			continue
			
		for i in range(items_to_spawn):
			# Alan içindeki mevcut eşyaları say, çok fazla yığılmasın
			var areas = zone.get_overlapping_areas()
			var item_count = 0
			for area in areas:
				if area.is_in_group("WorldItems"):
					item_count += 1
			if item_count >= 8:
				break # Çok fazla eşya varsa bu bölgede spawnı durdur
				
			var item_id = _get_random_item_for_danger(danger_level)
			var qty = _get_default_qty(item_id)
			
			var instance = item_scene.instantiate() as WorldItem
			instance.item_id = item_id
			instance.quantity = qty
			
			# Bölge etrafında rastgele konum (8m yarıçapında)
			var offset = Vector3(randf_range(-8.0, 8.0), 0.0, randf_range(-8.0, 8.0))
			instance.global_position = zone.global_position + offset
			instance.global_position.y = 0.0
			
			zone.get_parent().add_child(instance)
			respawned_count += 1
			
	if respawned_count > 0 and player:
		player.show_notification("🔄 7. GÜN: Şehir sokaklarındaki kaynaklar yenilendi!", Color(0.9, 0.7, 0.3))

func _get_random_item_for_danger(danger: int) -> String:
	# Tehlike seviyesine göre loot tablosu
	var pool = ["tahta", "kumas", "konserve", "su", "plastik"] # Seviye 1 (Low)
	
	if danger >= 2:
		pool.append_array(["metal", "bandaj", "fener", "sopa", "yakit", "barut_kovan"]) # Seviye 2 (Medium)
	if danger >= 3:
		pool.append_array(["metal", "antibiyotik", "bicak", "elektronik", "kimyasal"]) # Seviye 3 (High)
	if danger >= 4:
		pool.append_array(["tabanca", "kitap_tip", "kitap_insaat"]) # Seviye 4 (Critical)
		
	return pool[randi() % pool.size()]

func _get_default_qty(item_id: String) -> int:
	match item_id:
		"tahta": return randi_range(3, 5)
		"kumas": return randi_range(2, 4)
		"metal": return randi_range(1, 3)
		"plastik": return randi_range(2, 4)
		"yakit": return 1
		"barut_kovan": return randi_range(2, 5)
		"elektronik": return randi_range(1, 2)
		"kimyasal": return randi_range(1, 2)
		"konserve": return randi_range(1, 2)
		"su": return randi_range(1, 2)
		"bandaj": return 1
		"antibiyotik": return 1
		"fener": return 1
		"bicak": return 1
		"sopa": return 1
		"tabanca": return 1
		_: return 1
