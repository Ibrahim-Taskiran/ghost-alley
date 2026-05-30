extends CharacterBody3D

## Player Controller — Ghost Alley (Faz 1)
## 3D Raycast tabanlı Mouse tıkla-git sistemi (Vector3 fizik tabanlı, CharacterBody3D)
## GDD Referans: Bölüm 10.2 — Kontrol & Kamera

# === HAREKET AYARLARI ===
@export var move_speed: float = 5.0
@export var arrival_distance: float = 0.3
@export var rotation_speed: float = 10.0

# === TEMEL STATLAR (Faz 2 Hazırlık) ===
## GDD Referans: Bölüm 2.2 — Stat Sistemi
var stats: Dictionary = {
	"strength": 1,      # 💪 Güç — Ağır silah, barikat kurma hızı
	"military": 1,      # 🎖️ Askeri — Ateşli silah, savaş taktikleri
	"engineering": 1,   # 🔧 Mühendislik — Bina tamiri, gelişmiş crafting
	"intelligence": 1   # 🧠 Zeka — Kitap okuma hızı, kilit açma
}

# === SAĞLIK SİSTEMİ ===
## GDD Referans: Bölüm 6.1 — Temel İhtiyaçlar
var health: float = 100.0
var max_health: float = 100.0
var is_alive: bool = true

# === FAZ 2 ENVANTER & ETKİLEŞİM ===
var inventory: Inventory = null
var is_ui_open: bool = false
var nearby_items: Array = []
var nearby_structures: Array = []
var nearby_survivors: Array = []
var nearby_beds: Array = []

# Silah Statları
var equipped_weapon_id: String = ""
var weapon_damage: float = 0.0

# === HAREKET DEĞİŞKENLERİ ===
var _target_position: Vector3 = Vector3.ZERO
var _is_moving: bool = false
var _has_target: bool = false
var _noise_timer: float = 0.0
var _combat_target: CharacterBody3D = null
var _player_attack_timer: float = 0.0

# === REFERANSLAR ===
@onready var _camera: Camera3D = $IsometricCamera

# === SİNYALLER ===
signal health_changed(new_health: float, max_hp: float)
signal player_died


func _ready() -> void:
	_target_position = global_position
	health_changed.emit(health, max_health)
	
	# Envanteri başlat (Yeni üs yapma malzemelerinin sığması için 16 slot yapıldı)
	inventory = Inventory.new(21)
	inventory.add_item("kitap_tip", 1)
	inventory.add_item("kitap_insaat", 1)
	inventory.add_item("tabanca", 1)
	inventory.add_item("tahta", 15)
	inventory.add_item("metal", 15)
	inventory.add_item("siginak_bayragi", 1)
	inventory.add_item("duvar_ahsap", 6)
	inventory.add_item("kapi_ahsap", 1)
	inventory.add_item("jenerator", 1)
	inventory.add_item("taret", 1)
	inventory.add_item("konserve", 2)
	inventory.add_item("su", 2)
	
	# Dinamik hayatta kalma ve gelişim sistemlerini yükle
	var survival = SurvivalNeeds.new()
	survival.name = "SurvivalNeeds"
	add_child(survival)
	
	var infection = InfectionSystem.new()
	infection.name = "InfectionSystem"
	add_child(infection)
	
	var death_sys = DeathSystem.new()
	death_sys.name = "DeathSystem"
	add_child(death_sys)
	
	var xp_sys = XPSystem.new()
	xp_sys.name = "XPSystem"
	add_child(xp_sys)
	
	# İnşa yöneticisini yükle
	var build_mgr = BuildManager.new()
	build_mgr.name = "BuildManager"
	add_child(build_mgr)
	
	# Kitap okuma sistemini yükle
	var book_read = BookReader.new()
	book_read.name = "BookReader"
	add_child(book_read)
	
	# Dinamik Zombi Yenileyiciyi yükle
	var zombie_spawn = ZombieSpawner.new()
	zombie_spawn.name = "ZombieSpawner"
	add_child(zombie_spawn)
	
	# Grupları ayarla
	add_to_group("Player")


func _input(event: InputEvent) -> void:
	if not is_alive or is_ui_open:
		return
		
	# Hotbar Tuş Kısayolları (1-5 tuşları)
	if event is InputEventKey and event.pressed:
		if event.keycode >= KEY_1 and event.keycode <= KEY_5:
			var slot_idx = event.keycode - KEY_1
			_use_hotbar_slot(slot_idx)
			return
		
	if event.is_action_pressed("interact"):
		_interact_with_nearby()
		
	if event is InputEventKey and event.pressed and event.keycode == KEY_X:
		_deconstruct_nearby_structure()
		
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		_perform_player_attack()
		
	# Geliştirici & Test Kısayolları (Estetik & Kolaylık)
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F4:
			# F4: Horde Saldırısını Anında Başlatır
			if is_instance_valid(HordeManager):
				HordeManager.start_horde_manually()
		elif event.keycode == KEY_F5:
			# F5: Hava Durumunu Sırayla Değiştirir
			if is_instance_valid(WeatherManager):
				var weathers = ["SUNNY", "RAINY", "STORM", "FOGGY", "SNOWY"]
				var current_idx = weathers.find(WeatherManager.current_weather)
				var next_idx = (current_idx + 1) % weathers.size()
				WeatherManager.change_weather(weathers[next_idx])

func _unhandled_input(event: InputEvent) -> void:
	if not is_alive or is_ui_open:
		return

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_handle_right_click(event.position)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			_handle_left_click(event.position)


## Sol tıkla tıklanan zombiye odaklanır, ona doğru hareket edip saldırır
func _handle_left_click(screen_position: Vector2) -> void:
	# Kameradan 3D ray oluştur
	var ray_origin := _camera.project_ray_origin(screen_position)
	var ray_direction := _camera.project_ray_normal(screen_position)
	var ray_end := ray_origin + ray_direction * 1000.0

	var space_state := get_world_3d().direct_space_state
	
	# Öncelikli olarak zombiye mi tıklandı? (Zombi Layer 3 = value 4)
	var query_zombie := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query_zombie.collision_mask = 4  # Layer 3 = Enemies
	query_zombie.collide_with_areas = false
	
	var result_zombie := space_state.intersect_ray(query_zombie)
	if result_zombie and is_instance_valid(result_zombie.collider) and result_zombie.collider.is_in_group("ZombieAI"):
		var z = result_zombie.collider as CharacterBody3D
		if z.get("is_alive") == true:
			_combat_target = z
			_target_position = z.global_position
			_is_moving = true
			_has_target = true
			show_notification("🎯 Zombiye Odaklanıldı (Saldırı)", Color(0.9, 0.4, 0.3))


## Sağ tıkla tıklanan yeri algılar (Zombi ise hedefler, zeminse hareket eder)
func _handle_right_click(screen_position: Vector2) -> void:
	# Kameradan 3D ray oluştur
	var ray_origin := _camera.project_ray_origin(screen_position)
	var ray_direction := _camera.project_ray_normal(screen_position)
	var ray_end := ray_origin + ray_direction * 1000.0

	var space_state := get_world_3d().direct_space_state
	
	# 1. Öncelikli olarak zombiye mi tıklandı? (Zombi Layer 3 = value 4)
	var query_zombie := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query_zombie.collision_mask = 4  # Layer 3 = Enemies
	query_zombie.collide_with_areas = false
	
	var result_zombie := space_state.intersect_ray(query_zombie)
	if result_zombie and is_instance_valid(result_zombie.collider) and result_zombie.collider.is_in_group("ZombieAI"):
		var z = result_zombie.collider as CharacterBody3D
		if z.get("is_alive") == true:
			_combat_target = z
			_target_position = z.global_position
			_is_moving = true
			_has_target = true
			return
			
	# 2. Eğer zombiye tıklanmadıysa, zemin tıklandı mı? (Zemin Layer 1 = value 1)
	var query_ground := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query_ground.collision_mask = 1  # Layer 1 = Ground
	query_ground.collide_with_areas = false
	
	var result_ground := space_state.intersect_ray(query_ground)
	if result_ground:
		_combat_target = null  # Savaş hedefini sıfırla, normal yürüyoruz
		_target_position = result_ground.position
		_target_position.y = global_position.y  # Y eksenini sabitle
		_is_moving = true
		_has_target = true


func _physics_process(delta: float) -> void:
	if not is_alive:
		return
		
	if _player_attack_timer > 0.0:
		_player_attack_timer -= delta
		
	# Doktor pasif iyileştirme bonusu (+0.5 HP/sn)
	if NPCManager.has_npc("doctor"):
		heal(0.5 * delta)

	# --- SAVAŞ HEDEFİ TAKİBİ VE SALDIRI ---
	if is_instance_valid(_combat_target) and _combat_target.get("is_alive") == true:
		_target_position = _combat_target.global_position
		_target_position.y = global_position.y
		_is_moving = true
		_has_target = true
		
		# Saldırı menzili hesabı
		var attack_range = 2.0
		if equipped_weapon_id != "":
			var item = ItemDatabase.get_item(equipped_weapon_id)
			var effects = item.get("effects", {})
			var is_firearm = effects.get("is_firearm", false)
			attack_range = 15.0 if is_firearm else 2.5
			
		var distance = global_position.distance_to(_target_position)
		if distance <= attack_range:
			_stop_moving()
			_rotate_toward_target(delta)
			_perform_player_attack()
	elif is_instance_valid(_combat_target) and _combat_target.get("is_alive") == false:
		_combat_target = null
		_stop_moving()

	if _is_moving and _has_target:
		var direction := _target_position - global_position
		direction.y = 0  # Y eksenini yoksay
		var distance := direction.length()

		if distance > arrival_distance:
			# Dinamik hız hesaplaması
			var target_speed = move_speed
			var book_reader = get_node_or_null("BookReader")
			if book_reader and book_reader.get("is_reading") == true:
				# Okurken koşulamaz, hız %80 olur
				target_speed = move_speed * 0.8
			elif Input.is_key_pressed(KEY_SHIFT):
				# Normal koşu: %130 hız
				target_speed = move_speed * 1.3
				
			# Hava durumu hız çarpanını uygula
			var weather_mult = WeatherManager.get_multiplier("speed_mult")
			target_speed = target_speed * weather_mult
				
			# Hedefe doğru hareket
			velocity = direction.normalized() * target_speed
			move_and_slide()

			# Karakteri hareket yönüne çevir
			_rotate_toward_target(delta)
			
			# Akustik ses/gürültü üretimi
			_noise_timer += delta
			var is_sprinting = Input.is_key_pressed(KEY_SHIFT) and not (book_reader and book_reader.get("is_reading") == true)
			var interval = 0.5 if is_sprinting else 0.8
			var noise_range = 8.0 if is_sprinting else 3.0
			if _noise_timer >= interval:
				_noise_timer = 0.0
				emit_sound_noise(noise_range)
		else:
			# Hedefe ulaşıldı — dur
			_stop_moving()
			_noise_timer = 0.0
	else:
		# Duruyorken velocity sıfırla
		velocity = Vector3.ZERO
		move_and_slide()
		_noise_timer = 0.0


## Karakteri hedef yönüne yumuşak döndürür
func _rotate_toward_target(delta: float) -> void:
	var direction := _target_position - global_position
	direction.y = 0
	if direction.length_squared() > 0.001:
		var target_rotation := atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)


## Karakteri güvenli bir şekilde durdurur
func _stop_moving() -> void:
	velocity = Vector3.ZERO
	_is_moving = false
	_has_target = false


## Hasar alma — düşman saldırısında çağrılır
func take_damage(amount: float) -> void:
	if not is_alive:
		return

	# Eğer inşaat yapılıyorsa hasar alınca iptal et!
	var build_mgr = get_node_or_null("BuildManager")
	if build_mgr and build_mgr.get("is_constructing") == true:
		build_mgr.call("cancel_construction")

	health = clamp(health - amount, 0.0, max_health)
	health_changed.emit(health, max_health)

	if health <= 0.0:
		_die()


## Ölüm fonksiyonu
func _die() -> void:
	is_alive = false
	_stop_moving()
	player_died.emit()


## İyileşme
func heal(amount: float) -> void:
	if not is_alive:
		return
	health = clamp(health + amount, 0.0, max_health)
	health_changed.emit(health, max_health)


# ===== FAZ 2 YARDIMCI FONKSİYONLAR =====

func register_nearby_item(item: Node3D) -> void:
	if not nearby_items.has(item):
		nearby_items.append(item)
		var item_data = ItemDatabase.get_item(item.item_id)
		show_notification("Yerdeki eşya: %s [E]" % item_data.get("name", "Eşya"), Color(0.9, 0.8, 0.6))

func unregister_nearby_item(item: Node3D) -> void:
	if nearby_items.has(item):
		nearby_items.erase(item)

func _interact_with_nearby() -> void:
	# En yakın toplanabilir eşyayı bul
	var closest_item: Node3D = null
	var min_item_dist = 9999.0
	for item in nearby_items:
		if is_instance_valid(item):
			var dist = global_position.distance_to(item.global_position)
			if dist < min_item_dist:
				min_item_dist = dist
				closest_item = item
				
	# En yakın barikat/yapıyı bul
	var closest_struct: StaticBody3D = null
	var min_struct_dist = 9999.0
	for struct in nearby_structures:
		if is_instance_valid(struct):
			var dist = global_position.distance_to(struct.global_position)
			if dist < min_struct_dist:
				min_struct_dist = dist
				closest_struct = struct
				
	# En yakın kurtarılacak NPC'yi bul
	var closest_survivor: Node3D = null
	var min_survivor_dist = 9999.0
	for survivor in nearby_survivors:
		if is_instance_valid(survivor):
			var dist = global_position.distance_to(survivor.global_position)
			if dist < min_survivor_dist:
				min_survivor_dist = dist
				closest_survivor = survivor

	# En yakın yatağı bul
	var closest_bed: Area3D = null
	var min_bed_dist = 9999.0
	for bed in nearby_beds:
		if is_instance_valid(bed):
			var dist = global_position.distance_to(bed.global_position)
			if dist < min_bed_dist:
				min_bed_dist = dist
				closest_bed = bed

	# Etkileşim öncelikleri:
	# 1. Eğer bir hayatta kalan NPC en yakınsa onunla konuş (Diyalog aç)
	if closest_survivor and min_survivor_dist <= min_item_dist and min_survivor_dist <= min_struct_dist and min_survivor_dist <= min_bed_dist:
		var dialog = get_tree().get_first_node_in_group("NPCDialogUI")
		if dialog:
			dialog.open_dialog(closest_survivor)
	# 2. Eğer yatak en yakınsa uyu
	elif closest_bed and min_bed_dist <= min_item_dist and min_bed_dist <= min_struct_dist:
		closest_bed.sleep(self)
	# 3. Eğer toplanabilir eşya en yakınsa onu al
	elif closest_item and min_item_dist <= min_struct_dist:
		if inventory.add_item(closest_item.item_id, closest_item.quantity):
			var item_data = ItemDatabase.get_item(closest_item.item_id)
			show_notification("%s toplandı!" % item_data.get("name", "Eşya"), Color(0.3, 0.8, 0.3))
			nearby_items.erase(closest_item)
			closest_item.collect()
			if has_node("XPSystem"):
				get_node("XPSystem").gain_xp(5)
		else:
			show_notification("Envanter dolu!", Color(0.9, 0.3, 0.3))
	# 4. Eğer yapı en yakınsa ve kapıysa aç/kapat, yoksa tamir et
	elif closest_struct:
		if closest_struct.has_method("toggle_door"):
			closest_struct.call("toggle_door", self)
		else:
			closest_struct.repair(self)


func drop_item_in_world(item_id: String, qty: int) -> void:
	var world_item_scene = load("res://scenes/items/world_item.tscn")
	var instance = world_item_scene.instantiate() as WorldItem
	instance.item_id = item_id
	instance.quantity = qty
	
	# Oyuncunun ön kısmına rastgele küçük bir yayılımla bırak (üst üste binmeyi önler!)
	var angle = randf_range(0.0, 2.0 * PI)
	var dist = randf_range(0.1, 0.7)
	var random_offset = Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
	
	var base_offset = -transform.basis.z * 1.2
	instance.global_position = global_position + base_offset + random_offset
	instance.global_position.y = 0.0
	
	get_parent().add_child(instance)

func equip_weapon(item_id: String, damage: float) -> void:
	equipped_weapon_id = item_id
	weapon_damage = damage
	
	# Eğer 1. slot boş ise otomatik oraya yerleşsin
	if inventory.slots[16]["item_id"] == "":
		inventory.slots[16] = {"item_id": item_id, "quantity": 1}
		var hud = get_tree().get_first_node_in_group("HUD")
		if hud and hud.has_method("update_hotbar_ui"):
			hud.call("update_hotbar_ui")
	
	# If equipped, check if we had other weapons and adjust damage
	# For simple gameplay, let's say our attack damage matches equipped weapon

# ===== FAZ 3 YARDIMCI FONKSİYONLAR =====

func register_nearby_structure(struct: StaticBody3D) -> void:
	if not nearby_structures.has(struct):
		nearby_structures.append(struct)
		show_notification("Yapı yakında: %s (%d/%d HP) [E - Tamir Et] [X - Yık]" % [struct.structure_name, int(struct.health), int(struct.max_health)], Color(0.9, 0.8, 0.6))

func unregister_nearby_structure(struct: StaticBody3D) -> void:
	if nearby_structures.has(struct):
		nearby_structures.erase(struct)

func register_nearby_survivor(npc: Node3D) -> void:
	if not nearby_survivors.has(npc):
		nearby_survivors.append(npc)
		var npc_data = NPCManager.get_npc_details(npc.npc_class)
		show_notification("Yaralı kazazede: %s [E - Konuş]" % npc_data.get("name", "Hayatta Kalan"), Color(0.9, 0.8, 0.6))

func unregister_nearby_survivor(npc: Node3D) -> void:
	if nearby_survivors.has(npc):
		nearby_survivors.erase(npc)

func register_nearby_bed(bed: Area3D) -> void:
	if not nearby_beds.has(bed):
		nearby_beds.append(bed)
		show_notification("Yatak yakında: [E - Uyu/Dinlen]", Color(0.9, 0.8, 0.6))

func unregister_nearby_bed(bed: Area3D) -> void:
	if nearby_beds.has(bed):
		nearby_beds.erase(bed)


func show_notification(message: String, color: Color = Color.WHITE) -> void:
	var hud = get_tree().get_first_node_in_group("HUD")
	if hud and hud.has_method("show_message"):
		hud.show_message(message, color)


## Akustik Ses Yayma Mekanizması
func emit_sound_noise(sound_range: float) -> void:
	if not is_alive:
		return
		
	# Hava durumu ses çarpanını uygula (yağmur/fırtına ses yayılımını düşürür)
	var sound_mult = WeatherManager.get_multiplier("sound_mult")
	var active_range = sound_range * sound_mult
	
	if active_range <= 0.0:
		return # Fırtınada ses yayılımı tamamen engellenir
		
	# Menzildeki tüm zombileri uyar (Line of Sight gerekmez!)
	var zombies = get_tree().get_nodes_in_group("ZombieAI")
	for zombie in zombies:
		if is_instance_valid(zombie) and zombie.has_method("hear_sound"):
			var dist = global_position.distance_to(zombie.global_position)
			if dist <= active_range:
				zombie.hear_sound(global_position)


## Oyuncunun yakın/menzilli saldırı yapması
func _perform_player_attack() -> void:
	if not is_alive or _player_attack_timer > 0.0:
		return
		
	var is_firearm = false
	var damage = 10.0 # Varsayılan yumruk hasarı
	var attack_range = 2.0 # Yakın dövüş menzili
	var noise_range = 3.0 # Yumruk sesi
	
	if equipped_weapon_id != "":
		var item = ItemDatabase.get_item(equipped_weapon_id)
		damage = weapon_damage
		var effects = item.get("effects", {})
		is_firearm = effects.get("is_firearm", false)
		
		if is_firearm:
			attack_range = 15.0 # Ateşli silah menzili
			noise_range = 20.0 # Silah sesi (Gürültülü!)
		else:
			attack_range = 2.5 # Yakın dövüş silahı menzili (Bıçak/Sopa)
			noise_range = 5.0 # Melee savurma sesi
			
	# Çvş. Demir (soldier) bonusu: ateşli silah olmayan (melee/yumruk) saldırılara %30 ek güç!
	if NPCManager.has_npc("soldier") and not is_firearm:
		damage = damage * 1.3
			
	# Saldırı hedefini belirle (Önce kilitli hedef, yoksa en yakın zombi)
	var closest_zombie: CharacterBody3D = null
	if is_instance_valid(_combat_target) and _combat_target.get("is_alive") == true:
		closest_zombie = _combat_target
	else:
		var min_dist = attack_range
		var zombies = get_tree().get_nodes_in_group("ZombieAI")
		for zombie in zombies:
			if is_instance_valid(zombie) and zombie.get("is_alive") == true:
				var dist = global_position.distance_to(zombie.global_position)
				if dist <= min_dist:
					min_dist = dist
					closest_zombie = zombie
					
	# Sesi her durumda yay (boşa ateş etse bile ses çıkar!)
	emit_sound_noise(noise_range)
	
	# Saldırı cooldown'ını uygula (Ateşli silahlarda 0.5s, yakın dövüşte 0.7s)
	_player_attack_timer = 0.5 if is_firearm else 0.7
	
	if closest_zombie:
		# Zombiye hasar ver!
		if is_firearm:
			show_notification("💥 Ateş edildi! %d hasar verildi." % int(damage), Color(1.0, 0.4, 0.3))
		else:
			show_notification("⚔️ Saldırıldı! %d hasar verildi." % int(damage), Color(0.9, 0.7, 0.3))
			
		closest_zombie.call("take_damage", damage)
		
		# Zombi öldüyse hedefi temizle
		if closest_zombie.get("is_alive") == false or closest_zombie.is_queued_for_deletion():
			_combat_target = null
			_stop_moving()
	else:
		if equipped_weapon_id != "":
			if is_firearm:
				show_notification("💥 Boşa ateş ettin!", Color(0.7, 0.7, 0.7))
			else:
				show_notification("⚔️ Havayı kestin!", Color(0.7, 0.7, 0.7))
		else:
			show_notification("👊 Yumruk savurdun!", Color(0.7, 0.7, 0.7))

func _deconstruct_nearby_structure() -> void:
	if not is_alive or is_ui_open:
		return
		
	var closest_struct: StaticBody3D = null
	var min_struct_dist = 9999.0
	for struct in nearby_structures:
		if is_instance_valid(struct):
			var dist = global_position.distance_to(struct.global_position)
			if dist < min_struct_dist:
				min_struct_dist = dist
				closest_struct = struct
				
	if closest_struct:
		if closest_struct.has_method("deconstruct"):
			# Unregister first to avoid index errors
			nearby_structures.erase(closest_struct)
			closest_struct.call("deconstruct", self)

# === HOTBAR (HIZLI ERİŞİM BARISSLOTLARI) YÖNETİMİ ===
var hotbar: Array[String]:
	get:
		var arr: Array[String] = ["", "", "", "", ""]
		for i in range(5):
			arr[i] = inventory.slots[16 + i]["item_id"]
		return arr
	set(value):
		pass

func _use_hotbar_slot(index: int) -> void:
	if index < 0 or index >= 5:
		return
		
	var pocket_slot = inventory.slots[16 + index]
	var item_id = pocket_slot["item_id"]
	var quantity = pocket_slot["quantity"]
	if item_id == "":
		show_notification("Cep boş! Sırt çantasından sürükleyip buraya yerleştirin.", Color(0.8, 0.8, 0.8))
		return
		
	var item = ItemDatabase.get_item(item_id)
	
	# İnşaat tetiklemeleri (Eğer Tahta ise Ahşap Çit, Metal ise Metal Barikat moduna gir!)
	if item_id == "tahta" and has_node("BuildManager"):
		var build_mgr = get_node("BuildManager")
		build_mgr.call("start_building", "wooden_fence")
		return
	elif item_id == "metal" and has_node("BuildManager"):
		var build_mgr = get_node("BuildManager")
		build_mgr.call("start_building", "metal_barricade")
		return
	elif item.get("effects", {}).has("structure_id") and has_node("BuildManager"):
		var build_mgr = get_node("BuildManager")
		build_mgr.call("start_building", item["effects"]["structure_id"])
		return
		
	# Silah kuşanma kontrolü
	if item["type"] == ItemDatabase.ItemType.WEAPON:
		var effects = item.get("effects", {})
		equip_weapon(item_id, effects.get("damage", 10.0))
		show_notification("Silah kuşanıldı: %s" % item["name"], Color(0.7, 0.4, 0.9))
		
		# HUD Hotbar UI güncelle
		var hud = get_tree().get_first_node_in_group("HUD")
		if hud and hud.has_method("update_hotbar_ui"):
			hud.call("update_hotbar_ui")
		return
		
	# Diğer tüketilebilirler (Yemek, Su, İlaç, Kitap) - Envanterdeki ilgili cep slotunda "Kullan" tetikleme
	var inv_ui = get_tree().get_first_node_in_group("InventoryUI") as InventoryUI
	if inv_ui:
		inv_ui.call("_use_item_at", 16 + index)
		
		# HUD Hotbar UI güncelle
		var hud = get_tree().get_first_node_in_group("HUD")
		if hud and hud.has_method("update_hotbar_ui"):
			hud.call("update_hotbar_ui")
