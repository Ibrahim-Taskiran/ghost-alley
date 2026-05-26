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

# Silah Statları
var equipped_weapon_id: String = ""
var weapon_damage: float = 0.0

# === HAREKET DEĞİŞKENLERİ ===
var _target_position: Vector3 = Vector3.ZERO
var _is_moving: bool = false
var _has_target: bool = false

# === REFERANSLAR ===
@onready var _camera: Camera3D = $IsometricCamera

# === SİNYALLER ===
signal health_changed(new_health: float, max_hp: float)
signal player_died


func _ready() -> void:
	_target_position = global_position
	health_changed.emit(health, max_health)
	
	# Envanteri başlat
	inventory = Inventory.new(6)
	
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
	
	# Grupları ayarla
	add_to_group("Player")


func _input(event: InputEvent) -> void:
	if not is_alive or is_ui_open:
		return
		
	if event.is_action_pressed("interact"):
		_interact_with_nearby()

func _unhandled_input(event: InputEvent) -> void:
	if not is_alive or is_ui_open:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_handle_click(event.position)


## Fare tıklamasını 3D dünya koordinatına çevirir (Raycast)
func _handle_click(screen_position: Vector2) -> void:
	# Kameradan 3D ray oluştur
	var ray_origin := _camera.project_ray_origin(screen_position)
	var ray_direction := _camera.project_ray_normal(screen_position)
	var ray_end := ray_origin + ray_direction * 1000.0

	# PhysicsDirectSpaceState3D ile zemine raycast
	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collision_mask = 1  # Layer 1 = Ground
	query.collide_with_areas = false

	var result := space_state.intersect_ray(query)

	if result:
		_target_position = result.position
		_target_position.y = global_position.y  # Y eksenini sabitle (top-down)
		_is_moving = true
		_has_target = true


func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	if _is_moving and _has_target:
		var direction := _target_position - global_position
		direction.y = 0  # Y eksenini yoksay
		var distance := direction.length()

		if distance > arrival_distance:
			# Hedefe doğru hareket
			velocity = direction.normalized() * move_speed
			move_and_slide()

			# Karakteri hareket yönüne çevir
			_rotate_toward_target(delta)
		else:
			# Hedefe ulaşıldı — dur
			_stop_moving()
	else:
		# Duruyorken velocity sıfırla
		velocity = Vector3.ZERO
		move_and_slide()


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
	if nearby_items.size() == 0:
		return
		
	var closest: Node3D = null
	var min_dist = 9999.0
	for item in nearby_items:
		if is_instance_valid(item):
			var dist = global_position.distance_to(item.global_position)
			if dist < min_dist:
				min_dist = dist
				closest = item
				
	if closest:
		if inventory.add_item(closest.item_id, closest.quantity):
			var item_data = ItemDatabase.get_item(closest.item_id)
			show_notification("%s toplandı!" % item_data.get("name", "Eşya"), Color(0.3, 0.8, 0.3))
			nearby_items.erase(closest)
			closest.collect()
			
			if has_node("XPSystem"):
				get_node("XPSystem").gain_xp(5)
		else:
			show_notification("Envanter dolu!", Color(0.9, 0.3, 0.3))

func drop_item_in_world(item_id: String, qty: int) -> void:
	var world_item_scene = load("res://scenes/items/world_item.tscn")
	var instance = world_item_scene.instantiate() as WorldItem
	instance.item_id = item_id
	instance.quantity = qty
	
	# Oyuncunun ön kısmına bırak
	var offset = -transform.basis.z * 1.2
	instance.global_position = global_position + offset
	instance.global_position.y = 0.0
	
	get_parent().add_child(instance)

func equip_weapon(item_id: String, damage: float) -> void:
	equipped_weapon_id = item_id
	weapon_damage = damage
	
	# If equipped, check if we had other weapons and adjust damage
	# For simple gameplay, let's say our attack damage matches equipped weapon

func show_notification(message: String, color: Color = Color.WHITE) -> void:
	var hud = get_tree().get_first_node_in_group("HUD")
	if hud and hud.has_method("show_message"):
		hud.show_message(message, color)

