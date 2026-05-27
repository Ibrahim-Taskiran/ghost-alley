extends Node

## Sürü Dalga Yönetim Sistemi (Horde Survival System - Faz 4)
## Her 14 günde bir saat 22:00'de dev zombi sürüleri oyuncunun sığınağına akın eder.
## Gökyüzünü kızıla boyar, sis yoğunluğunu artırır, afetzede eşlikçileri çığlıklarla uyarır.

signal horde_started
signal horde_cleared

var active_horde: bool = false
var total_horde_size: int = 35
var spawned_count: int = 0
var horde_zombies: Array = []

var _spawn_timer: float = 0.0
var _spawn_interval: float = 8.0 # Her 8 saniyede bir 5'li gruplar gelir
var _zombies_per_group: int = 5

# Orijinal Çevre Değerlerini Yedeklemek İçin
var _orig_ambient_color: Color
var _orig_ambient_energy: float
var _orig_sky_top: Color
var _orig_sky_horizon: Color
var _orig_fog_enabled: bool
var _orig_fog_color: Color
var _orig_fog_density: float

var _player: CharacterBody3D = null
var _day_night = null

func _ready() -> void:
	add_to_group("HordeManager")
	
	# DayNightCycle bağlantısını kur
	await get_tree().process_frame
	_day_night = get_tree().get_first_node_in_group("DayNightCycle")
	if _day_night:
		_day_night.time_changed.connect(_on_time_changed)
		
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		_player = players[0]

func _process(delta: float) -> void:
	if not active_horde:
		return
		
	# 1. Hayatta kalan horde zombilerini filtrele ve temizle
	horde_zombies = horde_zombies.filter(func(z): return is_instance_valid(z) and z.get("is_alive") == true)
	
	# 2. Eğer hepsi spawn olduysa ve hiç zombi kalmadıysa zafer!
	if spawned_count >= total_horde_size and horde_zombies.size() == 0:
		complete_horde()
		return
		
	# 3. Zombi spawn zamanlayıcısı
	if spawned_count < total_horde_size:
		_spawn_timer += delta
		if _spawn_timer >= _spawn_interval:
			_spawn_timer = 0.0
			_spawn_horde_group()

func _on_time_changed(hour: int, minute: int) -> void:
	if _day_night == null:
		return
		
	# Her 14. gün saat 22:00'de otomatik tetikleme
	if _day_night.current_day % 14 == 0 and hour == 22 and minute == 0:
		if not active_horde:
			start_horde()

## Sürüyü Manuel Başlatma (Geliştirici / Test Kolaylığı - CHEAT)
func start_horde_manually() -> void:
	start_horde()

## Sürüyü Başlatma
func start_horde() -> void:
	if active_horde:
		return
		
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		_player = players[0]
	else:
		return
		
	active_horde = true
	spawned_count = 0
	horde_zombies.clear()
	_spawn_timer = 0.0
	
	_player.show_notification("🚨 SİRENLER ÇALIYOR! BÜYÜK ZOMBİ SÜRÜSÜ YAKLAŞIYOR!", Color(1.0, 0.1, 0.1))
	horde_started.emit()
	
	# 1. Eşlikçi NPC'leri 3D Konuşma balonlarıyla uyar!
	var companions = get_tree().get_nodes_in_group("Comcompanions")
	for companion in companions:
		if companion.has_method("say_alert"):
			companion.say_alert("SÜRÜ YAKLAŞIYOR! SAVUNMA POZİSYONUNA GEÇİN!")
			
	# 2. Çevreyi kıyamet kırmızısına (Kızıl Sis ve Gökyüzü) çevir
	_apply_crimson_apocalypse_visuals()
	
	# 3. İlk grubu hemen spawn et!
	_spawn_horde_group()

## Kızıl Kıyamet Atmosferi Uygulama (Estetik & WOW Etkisi)
func _apply_crimson_apocalypse_visuals() -> void:
	if _day_night == null:
		return
		
	var env_node = _day_night.world_env
	if env_node and env_node.environment:
		var env = env_node.environment
		
		# Orijinal ayarları yedekle
		_orig_ambient_color = env.ambient_light_color
		_orig_ambient_energy = env.ambient_light_energy
		_orig_fog_enabled = env.fog_enabled
		_orig_fog_color = env.fog_light_color
		_orig_fog_density = env.fog_density
		
		if env.sky and env.sky.sky_material is ProceduralSkyMaterial:
			var sky_mat = env.sky.sky_material as ProceduralSkyMaterial
			_orig_sky_top = sky_mat.sky_top_color
			_orig_sky_horizon = sky_mat.sky_horizon_color
			
			# Gökyüzünü koyu kızıl yap
			var sky_tween = create_tween().set_parallel(true)
			sky_tween.tween_property(sky_mat, "sky_top_color", Color(0.18, 0.01, 0.01), 4.0)
			sky_tween.tween_property(sky_mat, "sky_horizon_color", Color(0.45, 0.03, 0.03), 4.0)
			
		# Kırmızı kasvetli sis ve ortam ışığı
		var env_tween = create_tween().set_parallel(true)
		env_tween.tween_property(env, "ambient_light_color", Color(0.7, 0.08, 0.08), 4.0)
		env_tween.tween_property(env, "ambient_light_energy", 0.5, 4.0)
		
		env.fog_enabled = true
		env_tween.tween_property(env, "fog_light_color", Color(0.35, 0.02, 0.02), 4.0)
		env_tween.tween_property(env, "fog_density", 0.06, 4.0)

## Atmosfer Değerlerini Geri Yükleme
func _restore_visuals() -> void:
	if _day_night == null:
		return
		
	var env_node = _day_night.world_env
	if env_node and env_node.environment:
		var env = env_node.environment
		
		var env_tween = create_tween().set_parallel(true)
		env_tween.tween_property(env, "ambient_light_color", _orig_ambient_color, 4.0)
		env_tween.tween_property(env, "ambient_light_energy", _orig_ambient_energy, 4.0)
		env_tween.tween_property(env, "fog_light_color", _orig_fog_color, 4.0)
		env_tween.tween_property(env, "fog_density", _orig_fog_density, 4.0)
		
		if not _orig_fog_enabled:
			env_tween.chain().tween_callback(func(): env.fog_enabled = false)
			
		if env.sky and env.sky.sky_material is ProceduralSkyMaterial:
			var sky_mat = env.sky.sky_material as ProceduralSkyMaterial
			var sky_tween = create_tween().set_parallel(true)
			sky_tween.tween_property(sky_mat, "sky_top_color", _orig_sky_top, 4.0)
			sky_tween.tween_property(sky_mat, "sky_horizon_color", _orig_sky_horizon, 4.0)

## Zombi Grubunu Sınırların Dışında Spawn Etme ve Hedefe Hücum Ettirme
func _spawn_horde_group() -> void:
	if _player == null or not is_instance_valid(_player):
		return
		
	var count = min(_zombies_per_group, total_horde_size - spawned_count)
	if count <= 0:
		return
		
	var zombie_scene = load("res://scenes/enemies/zombie.tscn")
	if not zombie_scene:
		return
		
	# Oyuncunun çevresinde 25-30 metre mesafede rastgele açı seç
	for i in range(count):
		var angle = randf_range(0.0, 2.0 * PI)
		var distance = randf_range(25.0, 30.0)
		var spawn_offset = Vector3(cos(angle) * distance, 0.0, sin(angle) * distance)
		var spawn_pos = _player.global_position + spawn_offset
		spawn_pos.y = 0.0 # Zemin yüksekliği
		
		var zombie = zombie_scene.instantiate() as CharacterBody3D
		zombie.global_position = spawn_pos
		
		# Emergent: Sürü içinde farklı düşman sınıfları dağılımı yap (%60 Normal Zombi, %30 Koşucu, %10 Savage, Boss)
		var r = randf()
		if r < 0.60:
			# Standart Zombi (Varsayılan script)
			pass
		elif r < 0.85:
			# Koşucu Zombi
			zombie.set_script(load("res://scripts/enemies/enemy_runner.gd"))
		elif r < 0.96:
			# Vahşi İnsan / Haydut
			zombie.set_script(load("res://scripts/enemies/enemy_savage.gd"))
		else:
			# Dev Zombi / Boss (Horde içinde nadir gelir, heyecan yaratır!)
			zombie.set_script(load("res://scripts/enemies/enemy_boss.gd"))
			
		get_parent().add_child(zombie)
		horde_zombies.append(zombie)
		spawned_count += 1
		
		# Spawn olduktan hemen sonra ses halkası yayılımıyla tüm zombileri oyuncuya kilitle!
		await get_tree().process_frame
		if is_instance_valid(zombie) and zombie.has_method("hear_sound"):
			zombie.hear_sound(_player.global_position)

## Sürüyü Tamamlama ve Ödüllendirme
func complete_horde() -> void:
	active_horde = false
	horde_cleared.emit()
	
	_player.show_notification("🏆 TEBRİKLER! Sürü başarıyla temizlendi sığınağınız güvende!", Color(0.3, 0.9, 0.3))
	
	# 1. Büyük XP Bonusu (+100 XP)
	if _player.has_node("XPSystem"):
		_player.get_node("XPSystem").gain_xp(100)
		
	# 2. Gökyüzünü ve atmosferi eski haline döndür
	_restore_visuals()
	
	# 3. Oyuncunun yakınına nadir ganimet loot kutusu (Loot Box) spawn et!
	_spawn_victory_loot_box()

## Başarılı Savunma Sonrası Nadir Ganimet Sandığı Spawnı
func _spawn_victory_loot_box() -> void:
	if _player == null:
		return
		
	# Oyuncunun 2 metre yakınına bırak
	var angle = randf_range(0.0, 2.0 * PI)
	var spawn_pos = _player.global_position + Vector3(cos(angle) * 2.0, 0.0, sin(angle) * 2.0)
	spawn_pos.y = 0.0
	
	var world_item_scene = load("res://scenes/items/world_item.tscn")
	if not world_item_scene:
		return
		
	# Metal, Antibiyotik ve Tabanca barındıran zengin bir kutu!
	# Birden fazla eşya atmak için tek tek spawn edelim ya da bir tane süper loot kutusu atalım.
	# En temiz yol 3 farklı toplanabilir eşyayı yan yana spawn etmektir!
	var items_to_spawn = ["tabanca", "metal", "antibiyotik"]
	var item_qty = [1, 5, 2]
	
	for i in range(items_to_spawn.size()):
		var offset = Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0))
		var item_inst = world_item_scene.instantiate() as WorldItem
		item_inst.item_id = items_to_spawn[i]
		item_inst.quantity = item_qty[i]
		item_inst.global_position = spawn_pos + offset
		item_inst.global_position.y = 0.0
		get_parent().add_child(item_inst)
		
	_player.show_notification("🎁 Ganimetler sığınağın yanına bırakıldı: Tabanca, Metal ve İlaç toplandı!", Color(0.9, 0.8, 0.3))
