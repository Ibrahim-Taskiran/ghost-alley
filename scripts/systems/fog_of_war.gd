extends MeshInstance3D
class_name FogOfWar

# GDD §3.1: Fog of War System
# Tracks exploration, fades out out-of-sight areas, and updates a shader material dynamically.

@export var map_size: Vector2 = Vector2(100.0, 100.0) # World dimensions

var _grid_width: int = 100
var _grid_height: int = 100
var _fog_image: Image = null
var _fog_texture: ImageTexture = null
var _player: CharacterBody3D = null
var _update_timer: float = 0.0

func _ready() -> void:
	add_to_group("FogOfWar")
	
	# Create PlaneMesh for rendering above the ground but below camera (Y = 3.5)
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = map_size
	self.mesh = plane_mesh
	
	# Create the shader material
	var shader = load("res://resources/materials/fog_of_war.gdshader")
	if shader:
		var mat = ShaderMaterial.new()
		mat.shader = shader
		self.material_override = mat
		
	# Y=3.5 positions the fog above standard walls/zombies but keeps ground/obstacles under wraps
	global_position = Vector3(0.0, 3.5, 0.0)
	
	# Initialize the fog image (R = Visible, G = Explored, B/A = unused/1.0)
	_fog_image = Image.create(_grid_width, _grid_height, false, Image.FORMAT_RGBA8)
	_fog_image.fill(Color(0.0, 0.0, 0.0, 1.0)) # Unexplored
	_fog_texture = ImageTexture.create_from_image(_fog_image)
	
	# Pass texture to shader
	if material_override:
		material_override.set_shader_parameter("fog_texture", _fog_texture)
		
	# Find player
	await get_tree().process_frame
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		_player = players[0]

func _process(delta: float) -> void:
	# Update 10 times a second to save CPU
	_update_timer += delta
	if _update_timer >= 0.1:
		_update_timer = 0.0
		_update_fog()

func _update_fog() -> void:
	if not _player or not is_instance_valid(_player) or not _player.is_alive:
		return
		
	var player_pos = _player.global_position
	
	# Map world position to grid coords (-50 to 50 maps to 0 to 100)
	var grid_x = int(clamp((player_pos.x + map_size.x * 0.5) * (_grid_width / map_size.x), 0, _grid_width - 1))
	var grid_z = int(clamp((player_pos.z + map_size.y * 0.5) * (_grid_height / map_size.y), 0, _grid_height - 1))
	
	# Calculate reveal radius based on Day/Night + Weather
	var base_radius = 12.0 # Gündüz görüşü
	
	var day_night = get_tree().get_first_node_in_group("DayNightCycle")
	if day_night and day_night.get("is_night") == true:
		base_radius = 6.0 # Gece görüşü daralır
		
	# Hava durumu görüş kısıtlaması
	if is_instance_valid(WeatherManager):
		var sight_mult = WeatherManager.get_multiplier("sight_mult")
		base_radius *= sight_mult
		
	# Grid birimine dönüştür
	var grid_radius = int(base_radius * (_grid_width / map_size.x))
	
	# R kanalı (Currently Visible) temizlenmeli çünkü her frame oyuncu hareket ettikçe değişir
	for x in range(_grid_width):
		for z in range(_grid_height):
			var current_pixel = _fog_image.get_pixel(x, z)
			# Sadece Red kanalını sıfırla (görünürlüğü sıfırla, yeşil kanalını yani keşfedilmişliği KORU)
			current_pixel.r = 0.0
			_fog_image.set_pixel(x, z, current_pixel)
			
	# 1. RADYAL FİZİKSEL RAYCAST (Line of Sight)
	# 120 adet ışın ile etrafı tara (360 derece / 120 = her 3 derecede bir ışın)
	var num_rays = 120
	var ray_distances: Array[float] = []
	ray_distances.resize(num_rays)
	
	var space_state = get_world_3d().direct_space_state
	var start_y = player_pos.y + 0.5 # Göz hizası
	
	for i in range(num_rays):
		var angle = i * (2.0 * PI / num_rays)
		var dir = Vector3(cos(angle), 0.0, sin(angle))
		var start_pos = Vector3(player_pos.x, start_y, player_pos.z)
		var end_pos = start_pos + dir * base_radius
		
		# Raycast parameters: Layer 4 = Structures/Walls (collision value = 8)
		var query = PhysicsRayQueryParameters3D.create(start_pos, end_pos)
		query.collision_mask = 8 # Sadece duvarlar ve engeller
		query.collide_with_areas = false
		
		var result = space_state.intersect_ray(query)
		if result:
			ray_distances[i] = start_pos.distance_to(result.position)
		else:
			ray_distances[i] = base_radius
			
	# 2. IZGARA ÜZERİNDE GÖRÜŞ ALANINI ÇİZME
	# Oyuncu etrafındaki alanı dairesel olarak tara, ancak Line of Sight engellerine takılsın
	for dx in range(-grid_radius, grid_radius + 1):
		for dz in range(-grid_radius, grid_radius + 1):
			if dx * dx + dz * dz <= grid_radius * grid_radius:
				var target_x = grid_x + dx
				var target_z = grid_z + dz
				
				if target_x >= 0 and target_x < _grid_width and target_z >= 0 and target_z < _grid_height:
					# Grid hücresinin dünya koordinatını hesapla
					var cell_world_x = (target_x * map_size.x / _grid_width) - map_size.x * 0.5
					var cell_world_z = (target_z * map_size.y / _grid_height) - map_size.y * 0.5
					var cell_world_pos = Vector3(cell_world_x, player_pos.y, cell_world_z)
					
					var dist = player_pos.distance_to(cell_world_pos)
					var to_cell = cell_world_pos - player_pos
					var angle_rad = atan2(to_cell.z, to_cell.x)
					if angle_rad < 0.0:
						angle_rad += 2.0 * PI
						
					var ray_idx = int(round(angle_rad * num_rays / (2.0 * PI))) % num_rays
					
					# Duvarın kalınlığını ve sınırını güzelce görmek için tolerans payı ekleyelim (örneğin +0.6 metre)
					if dist <= ray_distances[ray_idx] + 0.6:
						# R=1.0 (Görünür), G=1.0 (Keşfedilmiş)
						var col = Color(1.0, 1.0, 0.0, 1.0)
						_fog_image.set_pixel(target_x, target_z, col)
						
	# Dokuyu güncelle
	_fog_texture.update(_fog_image)
