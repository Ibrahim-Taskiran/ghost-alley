extends CharacterBody3D
class_name ZombieAI

static var are_zombies_frozen: bool = false


## Zombie AI Controller — Ghost Alley (Faz 1)
## Standart Zombi: Yavaş, düşük hasar, kalabalık gelir, gürültüye tepki verir
## GDD Referans: Bölüm 5.1 — Düşman Tipleri

# === ZOMBİ STATLARI ===
@export var move_speed: float = 2.0
@export var patrol_speed: float = 1.0
@export var detection_range: float = 10.0
@export var attack_range: float = 1.5
@export var attack_damage: float = 10.0
@export var attack_cooldown: float = 1.5
@export var patrol_radius: float = 8.0
@export var patrol_wait_time: float = 3.0

# === DURUM MAKİNESİ ===
enum State { IDLE, PATROL, CHASE, ATTACK }
var current_state: State = State.IDLE

# === İÇ DEĞİŞKENLER ===
var _player: CharacterBody3D = null
var _rotation_speed: float = 5.0
var _patrol_target: Vector3 = Vector3.ZERO
var _spawn_position: Vector3 = Vector3.ZERO
var _patrol_wait_timer: float = 0.0
var _attack_timer: float = 0.0

# Stealth variables (LKP search)
var _last_seen_position: Vector3 = Vector3.ZERO
var _lost_sight_timer: float = 0.0
var _is_searching_last_seen: bool = false

# === SAĞLIK ===
var health: float = 50.0
var max_health: float = 50.0
var is_alive: bool = true
var _hp_bar_label: Label3D = null

# === SİNYALLER ===
signal zombie_died(zombie: CharacterBody3D)


# === BÖLÜM 10.2 GECE BUFFLARI ===
var _orig_move_speed: float
var _orig_patrol_speed: float
var _orig_detection_range: float
var _orig_attack_damage: float

func _ready() -> void:
	add_to_group("ZombieAI")
	_spawn_position = global_position
	_pick_new_patrol_target()
	
	# Can Barı Label3D oluştur
	_create_hp_bar_label()
	
	# Mouse dinleme ayarları (Hover ile can barını göstermek için)
	input_ray_pickable = true
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Orijinal statları sakla
	_orig_move_speed = move_speed
	_orig_patrol_speed = patrol_speed
	_orig_detection_range = detection_range
	_orig_attack_damage = attack_damage

	# Oyuncuyu bul — "Player" grubundan
	await get_tree().process_frame
	var players := get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		_player = players[0]
		
	# Gece/Gündüz döngüsünü dinle
	var day_night = get_tree().get_first_node_in_group("DayNightCycle")
	if day_night:
		day_night.night_started.connect(apply_night_buff)
		day_night.day_started.connect(remove_night_buff)
		if day_night.is_night:
			apply_night_buff()


func _physics_process(delta: float) -> void:
	if not is_alive:
		return
		
	if are_zombies_frozen:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	# Saldırı cooldown
	if _attack_timer > 0:
		_attack_timer -= delta

	# Durum geçişleri
	match current_state:
		State.IDLE:
			_state_idle(delta)
		State.PATROL:
			_state_patrol(delta)
		State.CHASE:
			_state_chase(delta)
		State.ATTACK:
			_state_attack(delta)
			
	# Yapı/Barikat engellerini kontrol et ve saldır
	_check_structure_collisions(delta)


# ===== DURUM FONKSİYONLARI =====

## IDLE: Yerinde durur, oyuncuyu arar, bekleme süresi dolduktan sonra devriyeye çıkar
func _state_idle(delta: float) -> void:
	velocity = Vector3.ZERO
	move_and_slide()

	# Oyuncu algılama — öncelikli
	if _can_see_player():
		current_state = State.CHASE
		return

	# Bekleme sonrası devriye
	_patrol_wait_timer -= delta
	if _patrol_wait_timer <= 0:
		_pick_new_patrol_target()
		current_state = State.PATROL


## PATROL: Rastgele noktalar arasında yavaşça dolanır
func _state_patrol(delta: float) -> void:
	# Oyuncu algılama — öncelikli
	if _can_see_player():
		current_state = State.CHASE
		return

	# Devriye noktasına git
	var direction := _patrol_target - global_position
	direction.y = 0
	var distance := direction.length()

	if distance > 0.5:
		var speed_mult = WeatherManager.get_multiplier("zombie_speed_mult")
		velocity = direction.normalized() * patrol_speed * speed_mult
		move_and_slide()
		_rotate_toward(direction, delta)
	else:
		# Hedefe ulaştı — bekle
		_patrol_wait_timer = patrol_wait_time
		current_state = State.IDLE


## CHASE: Hedefi kovalar (Görüş kaybolursa son görülen yere gidip arar)
func _state_chase(delta: float) -> void:
	if _target_character == null or not _target_character.get("is_alive") == true:
		current_state = State.IDLE
		_patrol_wait_timer = patrol_wait_time
		_is_searching_last_seen = false
		return

	# Görüş kontrolü
	var can_see = _can_see_player()
	
	if can_see and _target_character:
		# Görünürse son görülen konumu güncelle ve arama modunu sıfırla
		_last_seen_position = _target_character.global_position
		_is_searching_last_seen = false
		_lost_sight_timer = 0.0
	else:
		# Görüş kaybolduysa arama moduna geç
		if not _is_searching_last_seen:
			_is_searching_last_seen = true
			_lost_sight_timer = 3.0 # En fazla 3 saniye ara

	# Hedef koordinatı belirle (Görüyorsak hedef, görmüyorsak son görülen nokta)
	var target_pos: Vector3 = _target_character.global_position if (not _is_searching_last_seen and _target_character) else _last_seen_position
	var direction: Vector3 = target_pos - global_position
	direction.y = 0
	var distance := direction.length()

	# Eğer son görülen yeri arıyorsak:
	if _is_searching_last_seen:
		_lost_sight_timer -= delta
		# Noktaya ulaştıysa veya süre bittiyse aramayı bırak, devriyeye dön
		if distance <= 0.8 or _lost_sight_timer <= 0.0:
			current_state = State.IDLE
			_patrol_wait_timer = patrol_wait_time
			_is_searching_last_seen = false
			return
	else:
		# Normal kovalama mesafe kontrolleri
		if distance > detection_range * 1.5:
			current_state = State.IDLE
			_patrol_wait_timer = patrol_wait_time
			return

		# Saldırı menziline girdi mi?
		if distance <= attack_range:
			current_state = State.ATTACK
			return

	# Belirlenen hedefe doğru hareket et
	var speed_mult = WeatherManager.get_multiplier("zombie_speed_mult")
	velocity = direction.normalized() * move_speed * speed_mult
	move_and_slide()
	_rotate_toward(direction, delta)


## ATTACK: Hedefe saldırır
func _state_attack(delta: float) -> void:
	if _target_character == null or not _target_character.get("is_alive") == true:
		current_state = State.IDLE
		_patrol_wait_timer = patrol_wait_time
		return

	var direction := _target_character.global_position - global_position
	direction.y = 0
	var distance := direction.length()

	# Hedef menzilden çıktıysa kovala
	if distance > attack_range * 1.2:
		current_state = State.CHASE
		return

	# Dur ve saldır
	velocity = Vector3.ZERO
	move_and_slide()
	_rotate_toward(direction, delta)

	# Saldırı cooldown kontrolü
	if _attack_timer <= 0:
		_perform_attack()


# ===== YARDIMCI FONKSİYONLAR =====

# Aktif hedef karakter (Oyuncu veya Müttefik)
var _target_character: CharacterBody3D = null

func _update_best_target() -> void:
	var candidates: Array = []
	
	# Oyuncuyu ekle
	var players = get_tree().get_nodes_in_group("Player")
	for p in players:
		if is_instance_valid(p) and p.get("is_alive") == true:
			candidates.append(p)
			
	# Müttefikleri ekle
	var allies = get_tree().get_nodes_in_group("Comcompanions")
	for a in allies:
		if is_instance_valid(a) and a.get("is_alive") == true:
			candidates.append(a)
			
	var best_candidate: CharacterBody3D = null
	var min_distance = 9999.0
	
	# Hava durumu görüş kısıtlamasını uygula
	var sight_mult = WeatherManager.get_multiplier("sight_mult")
	var active_range = detection_range * sight_mult
	
	for c in candidates:
		var dist = global_position.distance_to(c.global_position)
		if dist <= active_range:
			if _has_line_of_sight_to(c):
				# En yakın olan hedefe veya eğer gürültü yapıyorsa öncelik ver
				var noise_factor = 0.0
				# Eğer oyuncu hızlı hareket ediyorsa (gürültü çıkıyorsa) mesafesini yapay olarak daha yakın say
				if c.is_in_group("Player") and Input.is_key_pressed(KEY_SHIFT) and c.get("velocity", Vector3.ZERO).length() > 0.1:
					noise_factor = 3.0 # Zombinin gürültülü hedefe daha duyarlı olması
					
				var adjusted_dist = dist - noise_factor
				if adjusted_dist < min_distance:
					min_distance = adjusted_dist
					best_candidate = c
					
	if best_candidate:
		_target_character = best_candidate
	else:
		if _target_character and not _has_line_of_sight_to(_target_character):
			if current_state != State.CHASE:
				_target_character = null

func _has_line_of_sight_to(target: CharacterBody3D) -> bool:
	if not target:
		return false
		
	var space_state = get_world_3d().direct_space_state
	var start_pos = global_position + Vector3(0, 1.0, 0)
	var end_pos = target.global_position + Vector3(0, 1.0, 0)
	
	var query = PhysicsRayQueryParameters3D.create(start_pos, end_pos)
	query.collision_mask = 1 + 8 # Ground + Structure
	query.collide_with_areas = false
	
	var result = space_state.intersect_ray(query)
	if result:
		var hit_pos = result.position
		var dist_to_hit = start_pos.distance_to(hit_pos)
		var dist_to_target = start_pos.distance_to(end_pos)
		if dist_to_hit < dist_to_target - 0.2:
			return false
	return true

func _can_see_player() -> bool:
	_update_best_target()
	return _target_character != null

func _perform_attack() -> void:
	if _target_character and _target_character.get("is_alive") == true and _has_line_of_sight_to(_target_character):
		if _target_character.has_method("take_damage"):
			_target_character.call("take_damage", attack_damage)
		_attack_timer = attack_cooldown
		
		# Sadece oyuncuya saldırırken enfeksiyon riski
		if _target_character.is_in_group("Player") and randf() <= 0.20 and _target_character.has_node("InfectionSystem"):
			_target_character.get_node("InfectionSystem").infect()
	else:
		_attack_timer = attack_cooldown



## Rastgele devriye noktası seçme
func _pick_new_patrol_target() -> void:
	var random_offset := Vector3(
		randf_range(-patrol_radius, patrol_radius),
		0,
		randf_range(-patrol_radius, patrol_radius)
	)
	_patrol_target = _spawn_position + random_offset


## Belirli bir yöne yumuşak dönüş
func _rotate_toward(direction: Vector3, delta: float) -> void:
	if direction.length_squared() > 0.001:
		var target_angle := atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_angle, _rotation_speed * delta)


## Hasar alma
func take_damage(amount: float) -> void:
	if not is_alive:
		return
	health = clamp(health - amount, 0.0, max_health)
	_update_hp_bar_visual()
	if health <= 0.0:
		_die()


## Sesi Duyma Mekanizması (Akustik Ses Dalgası)
func hear_sound(source_pos: Vector3) -> void:
	if not is_alive:
		return
		
	# Eğer zaten aktif kovalamadaysa ve oyuncuyu görüyorsa, sese gitmesin (oyuncuya odaklansın)
	if current_state == State.CHASE and not _is_searching_last_seen:
		return
		
	# Sesi duyduğunda hedefe (LKP - Son Bilinen Konum) yönel
	_last_seen_position = source_pos
	_is_searching_last_seen = true
	_lost_sight_timer = 4.0 # Sesin kaynağını aramak için 4 saniye süre verelim
	current_state = State.CHASE



## Ölüm
func _die() -> void:
	is_alive = false
	velocity = Vector3.ZERO
	
	# Oyuncuya 20 XP ver
	if _player and _player.is_alive and _player.has_node("XPSystem"):
		_player.get_node("XPSystem").gain_xp(20, true)
		
	zombie_died.emit(self)
	queue_free()



# ===== GECE BUFF MEKANİKLERİ =====

func apply_night_buff() -> void:
	move_speed = _orig_move_speed * 1.5
	patrol_speed = _orig_patrol_speed * 1.5
	detection_range = _orig_detection_range * 1.5
	attack_damage = _orig_attack_damage * 1.3

func remove_night_buff() -> void:
	move_speed = _orig_move_speed
	patrol_speed = _orig_patrol_speed
	detection_range = _orig_detection_range
	attack_damage = _orig_attack_damage


# ===== FAZ 3 BARİKAT SALDIRI YAPAY ZEKASI =====

func _check_structure_collisions(delta: float) -> void:
	if not is_alive or current_state == State.IDLE:
		return
		
	var hit_structure: Node3D = null
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and collider.is_in_group("Structures"):
			hit_structure = collider
			break
			
	if hit_structure and hit_structure.has_method("take_damage"):
		# Dur ve barikata saldır
		velocity = Vector3.ZERO
		
		if _attack_timer <= 0:
			hit_structure.call("take_damage", attack_damage)
			_attack_timer = attack_cooldown
			
			# Barikata doğru dön
			var dir = hit_structure.global_position - global_position
			_rotate_toward(dir, delta)

# === CAN BARI SİSTEMİ (MOUSE HOVER HOOKS) ===
func _create_hp_bar_label() -> void:
	_hp_bar_label = Label3D.new()
	_hp_bar_label.billboard = StandardMaterial3D.BILLBOARD_ENABLED
	_hp_bar_label.no_depth_test = true
	_hp_bar_label.pixel_size = 0.006
	_hp_bar_label.font_size = 48 # Büyütüldü! (32 -> 48)
	_hp_bar_label.outline_size = 14 # Belirgin yapıldı! (10 -> 14)
	_hp_bar_label.position.y = 2.1
	_hp_bar_label.visible = false
	add_child(_hp_bar_label)
	_update_hp_bar_visual()

func _update_hp_bar_visual() -> void:
	if not _hp_bar_label:
		return
		
	var pct = clamp(health / max_health, 0.0, 1.0)
	var filled_blocks = int(round(pct * 10.0))
	var empty_blocks = 10 - filled_blocks
	
	var bar_str = ""
	for i in range(filled_blocks):
		bar_str += "█"
	for i in range(empty_blocks):
		bar_str += "░"
		
	_hp_bar_label.text = "[%s] %d/%d HP" % [bar_str, int(health), int(max_health)]
	
	# Premium Cyberpunk renk tayfı
	if pct > 0.6:
		_hp_bar_label.modulate = Color(0.2, 0.9, 0.4) # Neon Yeşil
	elif pct > 0.25:
		_hp_bar_label.modulate = Color(0.9, 0.7, 0.1) # Neon Sarı
	else:
		_hp_bar_label.modulate = Color(1.0, 0.25, 0.25) # Neon Kırmızı

func _on_mouse_entered() -> void:
	if _hp_bar_label:
		_hp_bar_label.visible = true
		_update_hp_bar_visual()

func _on_mouse_exited() -> void:
	if _hp_bar_label:
		_hp_bar_label.visible = false


