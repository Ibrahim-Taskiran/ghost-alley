extends ZombieAI
class_name EnemyRunner

## Koşucu Zombi (Runner Zombie)
## Normal zombiden %150 daha hızlı koşar, canı daha düşüktür (30 HP), çok agresiftir.

func _ready() -> void:
	# Temel statları koşucuya göre ayarla
	move_speed = 3.3
	patrol_speed = 1.5
	detection_range = 12.0
	attack_range = 1.3
	attack_damage = 7.0
	attack_cooldown = 0.9 # Çok hızlı saldırır
	
	health = 30.0
	max_health = 30.0
	
	super._ready()
	
	# Görsel olarak kırmızımsı veya farklı olması için MeshInstance bulup rengini ayarla (Premium hissettirir!)
	await get_tree().process_frame
	var mesh_inst = get_node_or_null("MeshInstance3D")
	if mesh_inst:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.8, 0.2, 0.2) # Agresif kırmızı renk tonu
		mat.roughness = 0.8
		mesh_inst.material_override = mat
