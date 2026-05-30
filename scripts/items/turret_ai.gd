extends StructureBase
class_name TurretAI

@export var turret_range: float = 12.0
@export var turret_damage: float = 18.0
@export var fire_cooldown: float = 0.8

var _fire_timer: float = 0.0

func _ready() -> void:
	super._ready()
	add_to_group("Turrets")

func _physics_process(delta: float) -> void:
	if is_destroyed:
		return
		
	if _fire_timer > 0.0:
		_fire_timer -= delta
		
	# Find closest alive zombie
	var closest_zombie = _get_closest_zombie(turret_range)
	if closest_zombie and _fire_timer <= 0.0:
		_fire_at(closest_zombie)

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

func _fire_at(zombie: CharacterBody3D) -> void:
	_fire_timer = fire_cooldown
	
	# Look at zombie
	var dir = zombie.global_position - global_position
	dir.y = 0.0
	if dir.length_squared() > 0.001:
		var target_angle = atan2(dir.x, dir.z)
		if mesh_instance:
			mesh_instance.rotation.y = target_angle
			
	# Damage zombie
	if zombie.has_method("take_damage"):
		zombie.call("take_damage", turret_damage)
		
	# Show muzzle flash glow or notify player
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		players[0].show_notification("💥 Savunma Tareti ateş açtı! Canavar hasar aldı.", Color(1.0, 0.4, 0.3))
		
	# Emit shoot noise so other zombies hear!
	var noise_range = 10.0
	var sound_ring = get_node_or_null("SoundRing")
	if sound_ring:
		# If we have a sound ring, we can use it, or just let players handle notification
		pass
