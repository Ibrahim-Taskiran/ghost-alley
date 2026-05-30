extends Node
class_name BuildManager

var is_building: bool = false
var selected_structure_id: String = ""
var ghost_instance: Node3D = null
var current_rotation_degrees: float = 0.0

# === TİMED CONSTRUCTİON DEĞİŞKENLERİ ===
var is_constructing: bool = false
var construction_timer: float = 0.0
var construction_duration: float = 0.0
var pending_structure_id: String = ""
var pending_position: Vector3 = Vector3.ZERO
var pending_rotation: float = 0.0

var structures_db: Dictionary = {
	"wooden_fence": {
		"name": "Ahşap Çit",
		"cost_material": "tahta",
		"cost_qty": 5,
		"scene_path": "res://scenes/items/wooden_fence.tscn"
	},
	"metal_barricade": {
		"name": "Metal Barikat",
		"cost_material": "metal",
		"cost_qty": 8,
		"scene_path": "res://scenes/items/metal_barricade.tscn",
		"req_engineering": 3
	},
	"bed": {
		"name": "Yatak",
		"cost_material": "tahta",
		"cost_qty": 3,
		"scene_path": "res://scenes/items/bed_item.tscn"
	},
	"duvar_ahsap": {
		"name": "Ahşap Duvar",
		"cost_material": "duvar_ahsap",
		"cost_qty": 1,
		"scene_path": "res://scenes/items/duvar_ahsap.tscn"
	},
	"duvar_metal": {
		"name": "Metal Duvar",
		"cost_material": "duvar_metal",
		"cost_qty": 1,
		"scene_path": "res://scenes/items/duvar_metal.tscn"
	},
	"kapi_ahsap": {
		"name": "Ahşap Kapı",
		"cost_material": "kapi_ahsap",
		"cost_qty": 1,
		"scene_path": "res://scenes/items/kapi_ahsap.tscn"
	},
	"kapi_metal": {
		"name": "Metal Kapı",
		"cost_material": "kapi_metal",
		"cost_qty": 1,
		"scene_path": "res://scenes/items/kapi_metal.tscn"
	},
	"zemin": {
		"name": "Zemin Döşemesi",
		"cost_material": "zemin",
		"cost_qty": 1,
		"scene_path": "res://scenes/items/zemin.tscn"
	},
	"cati": {
		"name": "Çatı Kaplaması",
		"cost_material": "cati",
		"cost_qty": 1,
		"scene_path": "res://scenes/items/cati.tscn"
	},
	"siginak_bayragi": {
		"name": "Sığınak Bayrağı",
		"cost_material": "siginak_bayragi",
		"cost_qty": 1,
		"scene_path": "res://scenes/items/siginak_bayragi.tscn"
	},
	"jenerator": {
		"name": "Jeneratör",
		"cost_material": "jenerator",
		"cost_qty": 1,
		"scene_path": "res://scenes/items/jenerator.tscn"
	},
	"projektor": {
		"name": "Projektör",
		"cost_material": "projektor",
		"cost_qty": 1,
		"scene_path": "res://scenes/items/projektor.tscn"
	},
	"taret": {
		"name": "Otomatik Taret",
		"cost_material": "taret",
		"cost_qty": 1,
		"scene_path": "res://scenes/items/taret.tscn"
	}
}

var _player: CharacterBody3D = null
var _camera: Camera3D = null
var _build_ui: Control = null

func _ready() -> void:
	_player = get_parent() as CharacterBody3D
	
	await get_tree().process_frame
	_camera = _player.get_node("IsometricCamera") as Camera3D
	_build_ui = get_tree().get_first_node_in_group("BuildUI")

func _input(event: InputEvent) -> void:
	if not _player or not _player.is_alive:
		return
		
	if is_constructing and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		cancel_construction()
		return
		
	if event.is_action_pressed("build_mode"):
		if is_building:
			cancel_building()
		elif is_constructing:
			cancel_construction()
		else:
			if _build_ui:
				_build_ui.call("open_build_menu")
				
	if is_building and event is InputEventKey and event.pressed and event.keycode == KEY_R:
		current_rotation_degrees += 90.0
		if current_rotation_degrees >= 360.0:
			current_rotation_degrees = 0.0
		if ghost_instance:
			ghost_instance.rotation_degrees.y = current_rotation_degrees
		_player.show_notification("Yapı Döndürüldü: %d°" % int(current_rotation_degrees), Color(0.3, 0.8, 0.9))

func start_building(structure_id: String) -> void:
	if not structures_db.has(structure_id):
		return
		
	# Cancel any active build first
	cancel_building()
	
	selected_structure_id = structure_id
	var data = structures_db[structure_id]
	current_rotation_degrees = 0.0
	
	# Verify resources
	if not _player.inventory.has_item(data["cost_material"], data["cost_qty"]):
		var mat_name = ItemDatabase.get_item(data["cost_material"]).get("name", "Malzeme")
		_player.show_notification("Yetersiz kaynak: %d adet %s gerekli!" % [data["cost_qty"], mat_name], Color(0.9, 0.3, 0.3))
		return
		
	# Check Engineering requirement if any
	if data.has("req_engineering"):
		var eng = _player.stats.get("engineering", 1)
		if eng < data["req_engineering"]:
			_player.show_notification("Mühendislik seviyesi yetersiz! (Gerekli: %d)" % data["req_engineering"], Color(0.9, 0.3, 0.3))
			return
			
	# Create ghost preview
	var structure_scene = load(data["scene_path"])
	ghost_instance = structure_scene.instantiate() as Node3D
	
	# Add to world root so it renders correctly
	_player.get_parent().add_child(ghost_instance)
	
	# Disable collisions on ghost!
	if ghost_instance is CollisionObject3D:
		ghost_instance.collision_layer = 0
		ghost_instance.collision_mask = 0
	for child in ghost_instance.get_children():
		if child is CollisionObject3D:
			child.collision_layer = 0
			child.collision_mask = 0
			
	# Apply transparent ghost material
	var mesh_inst: MeshInstance3D = ghost_instance.get_node_or_null("MeshInstance3D")
	if mesh_inst:
		var mat = StandardMaterial3D.new()
		mat.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(0.2, 0.6, 0.9, 0.5) # Glowing semi-transparent cyan
		mat.roughness = 0.5
		mesh_inst.material_override = mat
		
	is_building = true
	_player.is_ui_open = true # Block movement clicks while placing!

func cancel_building() -> void:
	if ghost_instance:
		ghost_instance.queue_free()
		ghost_instance = null
		
	is_building = false
	selected_structure_id = ""
	current_rotation_degrees = 0.0
	
	if _player:
		_player.is_ui_open = false

func _process(delta: float) -> void:
	if is_constructing:
		# Lock player movement during construction
		_player.velocity = Vector3.ZERO
		
		construction_timer += delta
		var pct = (construction_timer / construction_duration) * 100.0
		pct = clamp(pct, 0.0, 100.0)
		
		var hud = get_tree().get_first_node_in_group("HUD")
		if hud and hud.has_method("show_action_progress"):
			var struct_name = structures_db[pending_structure_id]["name"]
			hud.call("show_action_progress", "🔨 " + struct_name + " İnşa Ediliyor", pct)
			
		if construction_timer >= construction_duration:
			_complete_construction()
		return

	if not is_building or not ghost_instance or not _camera:
		return
		
	# Raycast from mouse to find Ground location
	var mouse_pos = _player.get_viewport().get_mouse_position()
	var ray_origin = _camera.project_ray_origin(mouse_pos)
	var ray_direction = _camera.project_ray_normal(mouse_pos)
	var ray_end = ray_origin + ray_direction * 1000.0
	
	var space_state = _player.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collision_mask = 1 # Ground
	
	var result = space_state.intersect_ray(query)
	if result:
		var target_pos = result.position
		
		# Snap to 1.0 unit grid for clean snapped placement!
		var snapped_x = round(target_pos.x / 1.0) * 1.0
		var snapped_z = round(target_pos.z / 1.0) * 1.0
		
		ghost_instance.global_position = Vector3(snapped_x, 0.0, snapped_z)
		
		# Rotate structure using mouse scroll or arrow keys if needed, but let's keep it facing the camera direction for ease
		
	# Left click to place
	if Input.is_action_just_pressed("click") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		# Re-verify and place!
		_place_structure()

func _place_structure() -> void:
	if not is_building or selected_structure_id == "":
		return
		
	var data = structures_db[selected_structure_id]
	
	# Verify resources again
	if not _player.inventory.has_item(data["cost_material"], data["cost_qty"]):
		_player.show_notification("Yetersiz kaynak!", Color(0.9, 0.3, 0.3))
		cancel_building()
		return
		
	# Start construction timer
	is_constructing = true
	pending_structure_id = selected_structure_id
	pending_position = ghost_instance.global_position
	pending_rotation = current_rotation_degrees
	
	# Calculate build time: 3.0 / Strength. If engineer is present, * 0.7
	var strength = float(_player.stats.get("strength", 1))
	if strength <= 0:
		strength = 1.0
	construction_duration = 3.0 / strength
	if NPCManager.has_npc("engineer"):
		construction_duration *= 0.7
		
	construction_timer = 0.0
	
	# Lock player movement and stop them
	_player.is_ui_open = true
	_player.velocity = Vector3.ZERO
	if _player.has_method("_stop_moving"):
		_player.call("_stop_moving")
	
	# Clean up ghost preview
	if ghost_instance:
		ghost_instance.queue_free()
		ghost_instance = null
		
	is_building = false
	_player.show_notification("🔨 İnşa edilmeye başlandı...", Color(0.3, 0.8, 0.9))

func _complete_construction() -> void:
	is_constructing = false
	
	var hud = get_tree().get_first_node_in_group("HUD")
	if hud and hud.has_method("hide_action_progress"):
		hud.call("hide_action_progress")
		
	if _player:
		_player.is_ui_open = false
		
	var data = structures_db[pending_structure_id]
	
	# Re-verify and consume resources at the end!
	if not _player.inventory.has_item(data["cost_material"], data["cost_qty"]):
		_player.show_notification("Yetersiz kaynak!", Color(0.9, 0.3, 0.3))
		cancel_construction()
		return
		
	_player.inventory.remove_item(data["cost_material"], data["cost_qty"])
	
	# Spawn real structure
	var scene = load(data["scene_path"])
	var instance = scene.instantiate() as Node3D
	instance.global_position = pending_position
	instance.rotation_degrees.y = pending_rotation
	
	# Set build cost properties for deconstruction/recycling!
	if "build_material_id" in instance:
		instance.build_material_id = data["cost_material"]
		instance.build_cost = data["cost_qty"]
	
	# If player has engineering and it's a destructible structure, apply stat bonuses
	if "max_health" in instance:
		var eng_level = _player.stats.get("engineering", 1)
		instance.max_health += (eng_level - 1) * 50.0 # +50 HP per engineering level
		if "health" in instance:
			instance.health = instance.max_health
	
	_player.get_parent().add_child(instance)
	
	# Gain XP (GDD: 10 XP for building)
	if _player.has_node("XPSystem"):
		_player.get_node("XPSystem").gain_xp(10)
		
	_player.show_notification("✅ %s başarıyla inşa edildi!" % data["name"], Color(0.3, 0.8, 0.3))
	
	# İnşaat gürültüsü yay (8.0 metre)
	if _player.has_method("emit_sound_noise"):
		_player.emit_sound_noise(8.0)
	
	cancel_building()

func cancel_construction() -> void:
	if not is_constructing:
		return
		
	is_constructing = false
	
	var hud = get_tree().get_first_node_in_group("HUD")
	if hud and hud.has_method("hide_action_progress"):
		hud.call("hide_action_progress")
		
	if _player:
		_player.is_ui_open = false
		_player.show_notification("❌ İnşaat iptal edildi!", Color(0.9, 0.3, 0.3))
		
	cancel_building()
