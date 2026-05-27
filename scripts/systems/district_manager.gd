extends Node

signal district_changed(district_id: String, name: String, danger_level: int)

var districts: Dictionary = {
	"dismalle": {
		"name": "🏘️ Dış Mahalleler",
		"danger_level": 1,
		"danger_text": "⭐ Düşük Tehlike",
		"color": Color(0.3, 0.8, 0.3), # Yeşil
		"bounds_x": [0.0, 50.0],
		"bounds_z": [-20.0, 20.0]
	},
	"ticaret": {
		"name": "🏪 Ticaret Bölgesi",
		"danger_level": 2,
		"danger_text": "⭐⭐ Orta Tehlike",
		"color": Color(0.9, 0.7, 0.2), # Sarı/Turuncu
		"bounds_x": [-50.0, 0.0],
		"bounds_z": [-20.0, 20.0]
	},
	"sanayi": {
		"name": "🏭 Sanayi Bölgesi",
		"danger_level": 3,
		"danger_text": "⭐⭐⭐ Yüksek Tehlike",
		"color": Color(0.9, 0.4, 0.2), # Koyu Turuncu
		"bounds_x": [-50.0, 50.0],
		"bounds_z": [-50.0, -20.0]
	},
	"merkez": {
		"name": "🏢 Şehir Merkezi",
		"danger_level": 4,
		"danger_text": "💀 Kritik Tehlike (Horde Kaynağı)",
		"color": Color(0.9, 0.2, 0.2), # Kırmızı
		"bounds_x": [-50.0, 50.0],
		"bounds_z": [20.0, 50.0]
	}
}

var current_district_id: String = ""
var _player: CharacterBody3D = null
var _update_timer: float = 0.0

func _ready() -> void:
	add_to_group("DistrictManager")

func _process(delta: float) -> void:
	# Her 0.5 saniyede bir oyuncu pozisyonunu kontrol et
	_update_timer += delta
	if _update_timer >= 0.5:
		_update_timer = 0.0
		_check_player_district()

func _check_player_district() -> void:
	if not _player:
		var players = get_tree().get_nodes_in_group("Player")
		if players.size() > 0:
			_player = players[0]
		else:
			return
			
	var pos = _player.global_position
	var detected_district = "dismalle" # Varsayılan/Merkez başlangıç
	
	for dist_id in districts:
		var dist = districts[dist_id]
		var x_in = pos.x >= dist["bounds_x"][0] and pos.x <= dist["bounds_x"][1]
		var z_in = pos.z >= dist["bounds_z"][0] and pos.z <= dist["bounds_z"][1]
		if x_in and z_in:
			detected_district = dist_id
			break
			
	if detected_district != current_district_id:
		var old_district = current_district_id
		current_district_id = detected_district
		
		var dist_info = districts[current_district_id]
		district_changed.emit(current_district_id, dist_info["name"], dist_info["danger_level"])
		
		# HUD üzerinden bildirim göster
		if _player.has_method("show_notification"):
			_player.show_notification(
				"📍 Bölge Değişti: %s (%s)" % [dist_info["name"], dist_info["danger_text"]],
				dist_info["color"]
			)
