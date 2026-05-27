extends Node
class_name ZombieSpawner

## Dinamik Zombi Yenilenme Sistemi (Dynamic Zombie Respawn - Faz 4)
## Güvenli olmayan bölgelerdeki zombi nüfusunu her 3 günde bir kontrol eder ve takviye eder.

var _player: CharacterBody3D = null
var _day_night = null

func _ready() -> void:
	# Spawner, player child'ı olarak dinamik yükleneceğinden parent'ı player olacaktır
	_player = get_parent() as CharacterBody3D
	
	# Bir kare bekleyelim ki tüm nodelar hazır olsun
	await get_tree().process_frame
	
	_day_night = get_tree().get_first_node_in_group("DayNightCycle")
	if _day_night:
		_day_night.day_passed.connect(_on_day_passed)

func _on_day_passed(day_number: int) -> void:
	# Her 3 oyun gününde bir zombiler yenilenecek
	if day_number % 3 != 0:
		return
		
	var zones = get_tree().get_nodes_in_group("Zones")
	var spawn_count_total = 0
	
	for zone in zones:
		if zone is ZoneController and not zone.is_safe:
			# Bu zondaki canlı zombi sayısını sayalım
			var overlapping = zone.get_overlapping_bodies()
			var current_zombie_count = 0
			for body in overlapping:
				if body.is_in_group("ZombieAI") or body.is_in_group("Enemies"):
					if body.get("is_alive") != false:
						current_zombie_count += 1
						
			# Eğer zombi sayısı 5'ten az ise, sektöre 1 ila 3 zombi spawn et!
			if current_zombie_count < 5:
				var to_spawn = randi_range(1, 3)
				_spawn_zombies_in_zone(zone, to_spawn)
				spawn_count_total += to_spawn
				
	if spawn_count_total > 0 and _player:
		_player.show_notification("🧟 Şehirde kıpırdanmalar var... Bazı bölgelerde zombiler çoğaldı!", Color(0.9, 0.4, 0.3))

func _spawn_zombies_in_zone(zone: ZoneController, count: int) -> void:
	var zombie_scene = load("res://scenes/enemies/zombie.tscn")
	if not zombie_scene:
		return
		
	for i in range(count):
		# Sektörün merkezi etrafında 2m ila 12m yarıçapında rastgele konum
		var angle = randf_range(0.0, 2.0 * PI)
		var distance = randf_range(2.0, 12.0)
		var offset = Vector3(cos(angle) * distance, 0.0, sin(angle) * distance)
		var spawn_pos = zone.global_position + offset
		spawn_pos.y = 0.0 # Zemin hizası
		
		var zombie = zombie_scene.instantiate() as CharacterBody3D
		zombie.global_position = spawn_pos
		
		# Emergent Dağılım: %60 Standart, %30 Runner, %10 Savage
		var r = randf()
		if r < 0.60:
			# Standart Zombi (Varsayılan script)
			pass
		elif r < 0.90:
			# Runner Zombi (Koşucu)
			zombie.set_script(load("res://scripts/enemies/enemy_runner.gd"))
		else:
			# Savage (Haydut/Vahşi)
			zombie.set_script(load("res://scripts/enemies/enemy_savage.gd"))
			
		zone.get_parent().add_child(zombie)
