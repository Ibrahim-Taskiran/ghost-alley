extends ZombieAI
class_name EnemySavage

## Vahşi İnsan / Haydut (Savage Human)
## Akıllı menzilli düşman. Siper almayı taklit ederek belirli mesafede durur ve tabancayla ateş eder.
## Ateş ettikçe gürültü yayar, bu da çevredeki zombileri kendi üzerine ve çatışma alanına çeker!

func _ready() -> void:
	# Vahşi insan statları
	move_speed = 2.4
	patrol_speed = 1.0
	detection_range = 15.0
	attack_range = 10.0 # Menzilli saldırı mesafesi
	attack_damage = 8.0
	attack_cooldown = 1.6
	
	health = 65.0
	max_health = 65.0
	
	super._ready()
	
	# Görsel olarak insan (haydut) olduğu anlaşılsın diye mavi/kahverengi tonlama yapalım
	await get_tree().process_frame
	var mesh_inst = get_node_or_null("MeshInstance3D")
	if mesh_inst:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.15, 0.4, 0.7) # Mavi/lacivert kıyafetli haydut
		mat.roughness = 0.7
		mesh_inst.material_override = mat

## Menzilli saldırı durum makinesi (Siper alma ve uzaktan ateş etme)
func _state_attack(delta: float) -> void:
	if _player == null or not _player.is_alive:
		current_state = State.IDLE
		_patrol_wait_timer = patrol_wait_time
		return

	var direction := _player.global_position - global_position
	direction.y = 0
	var distance := direction.length()

	# Oyuncu çok uzaktaysa tekrar kovalamaya geç
	if distance > attack_range * 1.1:
		current_state = State.CHASE
		return

	# Akıllı Menzilli Davranış:
	# 1. Eğer oyuncu çok yakınındaysa (5 metreden az), geri çekilerek siper/güvenli mesafe almaya çalış
	if distance < 5.0:
		var retreat_dir = -direction.normalized()
		velocity = retreat_dir * move_speed
		move_and_slide()
		_rotate_toward(direction, delta) # Ateş ederken oyuncuya bakmaya devam et
	else:
		# 2. İdeal menzildeyse dur ve ateş et
		velocity = Vector3.ZERO
		move_and_slide()
		_rotate_toward(direction, delta)

	# Ateş etme zamanlaması
	if _attack_timer <= 0:
		_perform_ranged_attack()

## Ateşli silah saldırısı
func _perform_ranged_attack() -> void:
	if not _player or not _player.is_alive:
		return
		
	_attack_timer = attack_cooldown
	
	# Görüş hattını doğrula (engeller arkasından ateş edemez)
	if not _has_line_of_sight_to_player():
		return
		
	# Oyuncuya hasar ver
	_player.take_damage(attack_damage)
	
	# Oyuncunun ekranında bildirim göster
	if _player.has_method("show_notification"):
		_player.show_notification("⚠️ Haydut sana ateş etti! -%d Can" % int(attack_damage), Color(0.9, 0.3, 0.2))
		
	# Emergent Gameplay: Çevredeki zombiler bu silah sesini duyup çatışma alanına koşarlar!
	var zombies = get_tree().get_nodes_in_group("ZombieAI")
	for zombie in zombies:
		if is_instance_valid(zombie) and zombie != self and zombie.has_method("hear_sound"):
			var dist = global_position.distance_to(zombie.global_position)
			if dist <= 15.0:
				zombie.hear_sound(global_position)
