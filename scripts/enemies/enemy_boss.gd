extends ZombieAI
class_name EnemyBoss

## Dev Zombi / Tank (Boss Zombie)
## Çok yüksek can (350 HP), yavaş hareket eder, çitleri ve duvarları anında/çok hızlı yıkar, devasa boyutlardadır.

func _ready() -> void:
	# Dev zombi statları
	move_speed = 1.0
	patrol_speed = 0.5
	detection_range = 14.0
	attack_range = 2.2 # Daha uzun kolları var!
	attack_damage = 30.0
	attack_cooldown = 2.0
	
	health = 350.0
	max_health = 350.0
	
	super._ready()
	
	# Boyutunu devasa yap (X1.8 ölçeklendirme)
	scale = Vector3(1.8, 1.8, 1.8)
	
	# Devasa koyu gri zırhlı görünüm
	await get_tree().process_frame
	var mesh_inst = get_node_or_null("MeshInstance3D")
	if mesh_inst:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.25, 0.25, 0.3) # Koyu zırhlı gri rengi
		mat.roughness = 0.9
		mesh_inst.material_override = mat

## Dev zombi çitleri ve barikatları ezerek geçer
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
		# Dur ve barikata ezici saldırı yap
		velocity = Vector3.ZERO
		
		if _attack_timer <= 0:
			# Dev zombi barikatlara tek seferde 100 hasar verir! (Ahşap çiti anında kırabilir)
			var boss_structure_damage = 100.0
			hit_structure.call("take_damage", boss_structure_damage)
			_attack_timer = attack_cooldown
			
			# Oyuncuya bildirim gönder
			if _player and _player.has_method("show_notification"):
				_player.show_notification("⚠️ Dev Zombi barikata darbe indirdi!", Color(0.9, 0.2, 0.2))
			
			# Barikata doğru dön
			var dir = hit_structure.global_position - global_position
			_rotate_toward(dir, delta)
