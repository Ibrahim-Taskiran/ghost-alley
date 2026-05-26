extends CharacterBody3D

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
var _attack_timer: float = 0.0
var _patrol_target: Vector3 = Vector3.ZERO
var _spawn_position: Vector3 = Vector3.ZERO
var _patrol_wait_timer: float = 0.0
var _rotation_speed: float = 5.0

# === SAĞLIK ===
var health: float = 50.0
var max_health: float = 50.0
var is_alive: bool = true

# === SİNYALLER ===
signal zombie_died(zombie: CharacterBody3D)


# === BÖLÜM 10.2 GECE BUFFLARI ===
var _orig_move_speed: float
var _orig_patrol_speed: float
var _orig_detection_range: float
var _orig_attack_damage: float

func _ready() -> void:
	_spawn_position = global_position
	_pick_new_patrol_target()
	
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
		velocity = direction.normalized() * patrol_speed
		move_and_slide()
		_rotate_toward(direction, delta)
	else:
		# Hedefe ulaştı — bekle
		_patrol_wait_timer = patrol_wait_time
		current_state = State.IDLE


## CHASE: Oyuncuyu kovalar
func _state_chase(delta: float) -> void:
	if _player == null or not _player.is_alive:
		current_state = State.IDLE
		_patrol_wait_timer = patrol_wait_time
		return

	var direction := _player.global_position - global_position
	direction.y = 0
	var distance := direction.length()

	# Oyuncu menzil dışına çıktı mı?
	if distance > detection_range * 1.5:
		current_state = State.IDLE
		_patrol_wait_timer = patrol_wait_time
		return

	# Saldırı menzilinde mi?
	if distance <= attack_range:
		current_state = State.ATTACK
		return

	# Oyuncuya doğru hareket
	velocity = direction.normalized() * move_speed
	move_and_slide()
	_rotate_toward(direction, delta)


## ATTACK: Oyuncuya saldırır
func _state_attack(delta: float) -> void:
	if _player == null or not _player.is_alive:
		current_state = State.IDLE
		_patrol_wait_timer = patrol_wait_time
		return

	var direction := _player.global_position - global_position
	direction.y = 0
	var distance := direction.length()

	# Oyuncu menzilden çıktıysa kovala
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

## Oyuncuyu algılama — mesafe tabanlı
func _can_see_player() -> bool:
	if _player == null or not _player.is_alive:
		return false
	var distance := global_position.distance_to(_player.global_position)
	return distance <= detection_range


## Saldırı uygulama
func _perform_attack() -> void:
	if _player and _player.is_alive:
		_player.take_damage(attack_damage)
		_attack_timer = attack_cooldown
		
		# %20 enfeksiyon şansı
		if randf() <= 0.20 and _player.has_node("InfectionSystem"):
			_player.get_node("InfectionSystem").infect()



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
	if health <= 0.0:
		_die()


## Ölüm
func _die() -> void:
	is_alive = false
	velocity = Vector3.ZERO
	
	# Oyuncuya 20 XP ver
	if _player and _player.is_alive and _player.has_node("XPSystem"):
		_player.get_node("XPSystem").gain_xp(20)
		
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

