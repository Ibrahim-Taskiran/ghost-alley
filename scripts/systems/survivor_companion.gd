extends CharacterBody3D
class_name SurvivorCompanion

@export var npc_class: String = "doctor"
@export var follow_distance: float = 2.0
@export var move_speed: float = 4.5

var health: float = 100.0
var max_health: float = 100.0
var is_alive: bool = true
var _hp_bar_label: Label3D = null

var _player: CharacterBody3D = null
var _attack_timer: float = 0.0
var _attack_cooldown: float = 1.2
var _attack_damage: float = 12.0

func _ready() -> void:
	add_to_group("Comcompanions")
	add_to_group("Allies")
	
	# Can Barı Label3D oluştur
	_create_hp_bar_label()
	
	# Mouse dinleme ayarları
	input_ray_pickable = true
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Locate player
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		_player = players[0]
		
	# Dynamic Visual Representation (Mesh + Material)
	var mesh_inst = MeshInstance3D.new()
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.top_radius = 0.3
	cylinder_mesh.bottom_radius = 0.3
	cylinder_mesh.height = 1.6
	mesh_inst.mesh = cylinder_mesh
	mesh_inst.position.y = 0.8
	add_child(mesh_inst)
	
	var mat = StandardMaterial3D.new()
	match npc_class:
		"doctor":
			mat.albedo_color = Color(0.2, 0.8, 0.4) # Green
			_attack_damage = 8.0
		"soldier":
			mat.albedo_color = Color(0.15, 0.3, 0.15) # Olive green / Camo
			_attack_damage = 18.0
			_attack_cooldown = 0.9
		"engineer":
			mat.albedo_color = Color(0.9, 0.5, 0.1) # Orange/Yellow
			_attack_damage = 12.0
		"teacher":
			mat.albedo_color = Color(0.9, 0.85, 0.2) # Yellow
			_attack_damage = 5.0
			_attack_cooldown = 1.5
		"farmer":
			mat.albedo_color = Color(0.6, 0.4, 0.2) # Brown
			_attack_damage = 6.0
			_attack_cooldown = 1.4
		"hunter":
			mat.albedo_color = Color(0.15, 0.35, 0.1) # Dark green
			_attack_damage = 16.0
			_attack_cooldown = 1.0
	mesh_inst.material_override = mat
	
	# Dynamic Collision Shape
	var col_shape = CollisionShape3D.new()
	var cylinder_shape = CylinderShape3D.new()
	cylinder_shape.radius = 0.3
	cylinder_shape.height = 1.6
	col_shape.shape = cylinder_shape
	col_shape.position.y = 0.8
	add_child(col_shape)
	
	# Set layers (Layer 2 = Player/Allies)
	collision_layer = 2
	collision_mask = 1 + 4 + 8 # Ground + Enemy + Structure

func _physics_process(delta: float) -> void:
	if not is_alive or not _player or not _player.is_alive:
		velocity = Vector3.ZERO
		move_and_slide()
		return
		
	if _attack_timer > 0.0:
		_attack_timer -= delta
		
	# Stance and AI logic
	match NPCManager.active_order:
		"PASIF":
			_process_passive(delta)
		"HAYATTA_KAL":
			_process_survival(delta)
		"AGRESIF":
			_process_aggressive(delta)

func _process_passive(delta: float) -> void:
	# PASIF: Attacks only if a zombie is extremely close (< 2.5 units). Otherwise follows player.
	var target_zombie = _get_closest_zombie(2.5)
	if target_zombie:
		_attack_zombie(target_zombie, delta)
	else:
		_follow_player(delta)

func _process_survival(delta: float) -> void:
	# HAYATTA_KAL: Flees from zombies. If cornered (< 1.8 units), turns and fights.
	var closest_zombie = _get_closest_zombie(4.0)
	if closest_zombie:
		var dist = global_position.distance_to(closest_zombie.global_position)
		if dist < 1.8:
			# Cornered! Fight back!
			_attack_zombie(closest_zombie, delta)
		else:
			# Flee! Move away from zombie
			var flee_dir = (global_position - closest_zombie.global_position).normalized()
			flee_dir.y = 0.0
			velocity = flee_dir * move_speed
			move_and_slide()
			_rotate_toward(flee_dir, delta)
	else:
		_follow_player(delta)

func _process_aggressive(delta: float) -> void:
	# AGRESIF: Attacks nearest zombie. Hunter has extended 10.0 range, others 7.0.
	var aggro_range: float = 10.0 if npc_class == "hunter" else 7.0
	var target_zombie = _get_closest_zombie(aggro_range)
	if target_zombie:
		_attack_zombie(target_zombie, delta)
	else:
		_follow_player(delta)

func _follow_player(delta: float) -> void:
	var dist = global_position.distance_to(_player.global_position)
	if dist > follow_distance:
		var dir = (_player.global_position - global_position).normalized()
		dir.y = 0.0
		velocity = dir * move_speed
		move_and_slide()
		_rotate_toward(dir, delta)
	else:
		velocity = Vector3.ZERO
		move_and_slide()

func _attack_zombie(zombie: CharacterBody3D, delta: float) -> void:
	var dist = global_position.distance_to(zombie.global_position)
	var dir = (zombie.global_position - global_position).normalized()
	dir.y = 0.0
	
	if dist > 1.5:
		# Move towards zombie to attack
		velocity = dir * move_speed
		move_and_slide()
		_rotate_toward(dir, delta)
	else:
		# Close range - stop and attack
		velocity = Vector3.ZERO
		move_and_slide()
		_rotate_toward(dir, delta)
		
		if _attack_timer <= 0.0:
			_attack_timer = _attack_cooldown
			if zombie.has_method("take_damage"):
				zombie.call("take_damage", _attack_damage)
				_player.show_notification("⚔️ Takım arkadaşı saldırdı! Canavar hasar aldı.", Color(0.3, 0.8, 0.9))

func _get_closest_zombie(max_dist: float) -> CharacterBody3D:
	var zombies = get_tree().get_nodes_in_group("ZombieAI")
	var closest: CharacterBody3D = null
	var min_dist = max_dist
	
	for zombie in zombies:
		if is_instance_valid(zombie) and zombie.get("is_alive") != false:
			var dist = global_position.distance_to(zombie.global_position)
			if dist < min_dist:
				min_dist = dist
				closest = zombie
	return closest

func _rotate_toward(direction: Vector3, delta: float) -> void:
	if direction.length_squared() > 0.001:
		var target_angle := atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_angle, 10.0 * delta)

func take_damage(amount: float) -> void:
	if not is_alive:
		return
	health = clamp(health - amount, 0.0, max_health)
	_update_hp_bar_visual()
	if health <= 0.0:
		is_alive = false
		_player.show_notification("⚠️ Takım arkadaşınız öldü!", Color(0.9, 0.2, 0.2))
		queue_free()


## Eşlikçi NPC'nin ekran üzerinde 3D diyalog/uyarı balonu çıkartması (Görsel ve Estetik)
func say_alert(message: String) -> void:
	if not is_alive:
		return
		
	# Kafasının üzerinde yüzen 3D Label oluştur
	var label = Label3D.new()
	label.text = message
	label.billboard = StandardMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true # Engellerin arkasında kalsa bile görünsün
	label.pixel_size = 0.005 # Temiz piksel ölçeği
	label.font_size = 28
	label.outline_size = 8
	label.modulate = Color(1.0, 0.35, 0.35) # Parlak kırmızı uyarı rengi
	label.outline_modulate = Color(0.0, 0.0, 0.0, 1.0)
	label.position.y = 1.9 # Eşlikçinin 1.6m kafasının hemen üzeri
	add_child(label)
	
	# 4.5 saniye sonra etiketi yok et
	get_tree().create_timer(4.5).timeout.connect(label.queue_free)

# === CAN BARI SİSTEMİ (MOUSE HOVER HOOKS) ===
func _create_hp_bar_label() -> void:
	_hp_bar_label = Label3D.new()
	_hp_bar_label.billboard = StandardMaterial3D.BILLBOARD_ENABLED
	_hp_bar_label.no_depth_test = true
	_hp_bar_label.pixel_size = 0.006
	_hp_bar_label.font_size = 48 # Büyütüldü! (32 -> 48)
	_hp_bar_label.outline_size = 14 # Belirgin yapıldı! (10 -> 14)
	_hp_bar_label.position.y = 2.2
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
		
	var class_name_tr = "Eşlikçi"
	match npc_class:
		"doctor": class_name_tr = "🏥 Dr. Selim"
		"soldier": class_name_tr = "🎖️ Çvş. Demir"
		"engineer": class_name_tr = "🔧 Kaya Usta"
		"teacher": class_name_tr = "📚 Elif Hoca"
		"farmer": class_name_tr = "🌾 Hasan Ağa"
		"hunter": class_name_tr = "🔫 Yılmaz"
		
	_hp_bar_label.text = "%s\n[%s] %d/%d HP" % [class_name_tr, bar_str, int(health), int(max_health)]
	
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
