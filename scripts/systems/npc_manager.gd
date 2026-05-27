extends Node

signal npc_list_changed

# Holds list of recruited NPC classes: e.g. ["doctor", "soldier"]
var recruited_npcs: Array = []
var active_order: String = "HAYATTA_KAL"

var npc_metadata: Dictionary = {
	"doctor": {
		"name": "🏥 Dr. Selim (Doktor)",
		"class_id": "doctor",
		"description": "Base'de pasif sağlık yenilenmesi (+0.5 HP/sn) sağlar ve enfeksiyon süresini yarıya indirir.",
		"bonus_text": "Pasif HP: +0.5/sn, Enfeksiyon Süresi: -50%"
	},
	"soldier": {
		"name": "🎖️ Çvş. Demir (Asker)",
		"class_id": "soldier",
		"description": "Oyuncunun yakın dövüş saldırı gücünü %30 artırır.",
		"bonus_text": "Saldırı Hasarı: +30%"
	},
	"engineer": {
		"name": "🔧 Kaya Usta (Mühendis)",
		"class_id": "engineer",
		"description": "Barikat ve yapı tamir hızını %30 artırır, maksimum HP kapasitelerini yükseltir.",
		"bonus_text": "Yapı Tamiri: +30% Hızlı"
	},
	"teacher": {
		"name": "📚 Elif Hoca (Öğretmen)",
		"class_id": "teacher",
		"description": "XP kazanımını %20 artırır ve kitap okuma süresini yarıya indirir.",
		"bonus_text": "XP Kazanımı: +20%, Kitap Okuma: -50% Süre"
	},
	"farmer": {
		"name": "🌾 Hasan Ağa (Çiftçi)",
		"class_id": "farmer",
		"description": "Güvenli bölgede her 2 oyun saatinde 1 konserve üretir.",
		"bonus_text": "Pasif Yiyecek: 1 Konserve / 2 Saat"
	},
	"hunter": {
		"name": "🔫 Yılmaz (Avcı)",
		"class_id": "hunter",
		"description": "Eşya toplama menzilini %50 artırır ve düşman öldürme XP'sini %30 artırır.",
		"bonus_text": "Eşya Menzili: +50%, Öldürme XP: +30%"
	}
}

# Çiftçi pasif yiyecek üretimi için zaman takibi
var _last_farmer_hour: int = -1

func _ready() -> void:
	add_to_group("NPCManager")

func _process(_delta: float) -> void:
	# Çiftçi pasif yiyecek üretimi: güvenli bölgede her 2 oyun saatinde 1 konserve
	if not has_npc("farmer"):
		return
	
	# DayNightCycle'dan güncel saati al
	var day_night_nodes = get_tree().get_nodes_in_group("DayNightCycle")
	if day_night_nodes.size() == 0:
		return
	var day_night = day_night_nodes[0]
	
	var current_hour: int = int(day_night.current_time) if day_night.get("current_time") != null else -1
	if current_hour < 0:
		return
	
	# Her 2 saatte bir tetikle (0, 2, 4, 6 ...)
	if current_hour % 2 != 0:
		return
	if current_hour == _last_farmer_hour:
		return
	
	# Oyuncunun güvenli bölgede olup olmadığını kontrol et
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() == 0:
		return
	var player = players[0]
	
	var in_safe_zone: bool = false
	var zones = get_tree().get_nodes_in_group("Zones")
	for zone in zones:
		if zone.get("is_safe_zone") and zone.has_method("has_point"):
			if zone.has_point(player.global_position):
				in_safe_zone = true
				break
		elif zone.get("is_safe_zone") and zone.get("monitoring") != null:
			# Area3D tabanlı güvenli bölge - overlapping bodies kontrolü
			if zone.has_method("get_overlapping_bodies"):
				var bodies = zone.get_overlapping_bodies()
				if player in bodies:
					in_safe_zone = true
					break
	
	if not in_safe_zone:
		return
	
	_last_farmer_hour = current_hour
	
	# Envantere 1 konserve ekle
	if player.has_method("add_item"):
		player.add_item("konserve", 1)
	elif player.get("inventory") != null:
		if player.inventory.has_method("add_item"):
			player.inventory.add_item("konserve", 1)
	
	player.show_notification("🌾 Çiftçi 1 konserve üretti!", Color(0.6, 0.4, 0.2))

func recruit_npc(npc_class: String, spawn_position: Vector3 = Vector3.ZERO) -> void:
	if not recruited_npcs.has(npc_class) and npc_metadata.has(npc_class):
		recruited_npcs.append(npc_class)
		npc_list_changed.emit()
		
		# GDD §8.2: Avcı işe alındığında dünyadaki mevcut tüm eşyaların algılama menzilini artır
		if npc_class == "hunter":
			var items = get_tree().get_nodes_in_group("WorldItems")
			for item in items:
				if item.has_node("CollisionShape3D"):
					item.get_node("CollisionShape3D").scale = Vector3(1.5, 1.5, 1.5)
		
		# Show global HUD notifications
		var players = get_tree().get_nodes_in_group("Player")
		if players.size() > 0:
			var npc_name = npc_metadata[npc_class]["name"]
			var player = players[0]
			player.show_notification("🎉 %s ekibinize katıldı!" % npc_name, Color(0.3, 0.8, 0.3))
			
			# Spawn companion physically
			var companion_script = load("res://scripts/systems/survivor_companion.gd")
			if companion_script:
				var companion = CharacterBody3D.new()
				companion.set_script(companion_script)
				companion.npc_class = npc_class
				
				# Eğer konum belirtildiyse tam oraya, yoksa oyuncu yakınına koy
				if spawn_position != Vector3.ZERO:
					companion.global_position = spawn_position
				else:
					var offset = Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(1.0, 2.0))
					companion.global_position = player.global_position + offset
				
				player.get_parent().add_child(companion)

func has_npc(npc_class: String) -> bool:
	return recruited_npcs.has(npc_class)

func get_npc_count() -> int:
	return recruited_npcs.size()

func get_npc_details(npc_class: String) -> Dictionary:
	return npc_metadata.get(npc_class, {})
