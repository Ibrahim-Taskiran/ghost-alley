extends StaticBody3D
class_name StructureBase

signal health_changed(new_hp: float, max_hp: float)
signal destroyed

@export_category("Structure Stats")
@export var structure_name: String = "Ahşap Çit"
@export var max_health: float = 100.0
@export var repair_material_id: String = "tahta"
@export var repair_cost: int = 3
@export var repair_heal_amount: float = 40.0
@export var build_material_id: String = "tahta"
@export var build_cost: int = 4

var health: float = 100.0
var is_destroyed: bool = false

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var interaction_area: Area3D = $InteractionArea

# Original color for damage lerping
var _orig_color: Color = Color.WHITE
var _visual_initialized: bool = false

func _ready() -> void:
	# Add to group
	add_to_group("Structures")
	
	# Configure static body collision: Layer 4 = Structure
	collision_layer = 8
	collision_mask = 0
	
	health = max_health
	
	# Connect interaction signals
	if interaction_area:
		interaction_area.body_entered.connect(_on_player_entered)
		interaction_area.body_exited.connect(_on_player_exited)
		
	# Store original material color
	await get_tree().process_frame
	_init_visuals()

func _init_visuals() -> void:
	if not mesh_instance:
		return
		
	var mat = mesh_instance.material_override as StandardMaterial3D
	if not mat:
		mat = mesh_instance.get_active_material(0) as StandardMaterial3D
		
	if mat:
		# Separate material instance
		mat = mat.duplicate() as StandardMaterial3D
		mesh_instance.material_override = mat
		_orig_color = mat.albedo_color
		_visual_initialized = true
		_update_visuals()

func _update_visuals() -> void:
	if not _visual_initialized or not mesh_instance:
		return
		
	var mat = mesh_instance.material_override as StandardMaterial3D
	if mat:
		var pct = clamp(health / max_health, 0.0, 1.0)
		# Deform structure color to a charred dark red/black tone as it breaks
		mat.albedo_color = _orig_color.lerp(Color(0.15, 0.05, 0.05), 1.0 - pct)

func take_damage(amount: float) -> void:
	if is_destroyed:
		return
		
	health = clamp(health - amount, 0.0, max_health)
	health_changed.emit(health, max_health)
	_update_visuals()
	
	if health <= 0.0:
		_destroy()

func repair(player: CharacterBody3D) -> void:
	if is_destroyed:
		return
		
	if health >= max_health:
		player.show_notification("Yapı sağlığı zaten tam!", Color(0.8, 0.8, 0.8))
		return
		
	# Apply Engineering bonus to repair efficiency
	var eng_level = player.stats.get("engineering", 1)
	var final_heal = repair_heal_amount * (1.0 + (eng_level - 1) * 0.15) # +15% heal per engineering level
	
	# Mühendis NPC'si varsa tamir verimi %30 artar
	if NPCManager.has_npc("engineer"):
		final_heal *= 1.3
	
	if player.inventory.has_item(repair_material_id, repair_cost):
		player.inventory.remove_item(repair_material_id, repair_cost)
		health = clamp(health + final_heal, 0.0, max_health)
		health_changed.emit(health, max_health)
		_update_visuals()
		
		var mat_name = ItemDatabase.get_item(repair_material_id).get("name", "Malzeme")
		player.show_notification("%s tamir edildi! (+%d HP)" % [structure_name, int(final_heal)], Color(0.3, 0.8, 0.3))
	else:
		var mat_name = ItemDatabase.get_item(repair_material_id).get("name", "Malzeme")
		player.show_notification("Yetersiz malzeme: %d adet %s gerekli!" % [repair_cost, mat_name], Color(0.9, 0.3, 0.3))

func _on_player_entered(body: Node3D) -> void:
	if body.is_in_group("Player") and body.has_method("register_nearby_structure"):
		body.register_nearby_structure(self)

func _on_player_exited(body: Node3D) -> void:
	if body.is_in_group("Player") and body.has_method("unregister_nearby_structure"):
		body.unregister_nearby_structure(self)

func _destroy() -> void:
	is_destroyed = true
	destroyed.emit()
	
	# Play dynamic break notification
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		players[0].show_notification("⚠️ UYARI: Bir %s yıkıldı!" % structure_name, Color(0.9, 0.2, 0.2))
		
	# Clean up
	queue_free()

func deconstruct(player: CharacterBody3D) -> void:
	if is_destroyed:
		return
		
	is_destroyed = true
	destroyed.emit()
	
	# Calculate return quantity: half of build cost
	var refund_qty = int(floor(build_cost / 2.0))
	if refund_qty > 0:
		var added = player.inventory.add_item(build_material_id, refund_qty)
		if added:
			var mat_name = ItemDatabase.get_item(build_material_id).get("name", "Malzeme")
			player.show_notification("♻️ %s yıkıldı! %d adet %s geri kazanıldı." % [structure_name, refund_qty, mat_name], Color(0.3, 0.8, 0.3))
		else:
			player.drop_item_in_world(build_material_id, refund_qty)
			var mat_name = ItemDatabase.get_item(build_material_id).get("name", "Malzeme")
			player.show_notification("♻️ Envanter dolu! %d adet %s yere bırakıldı." % [refund_qty, mat_name], Color(0.9, 0.8, 0.3))
	else:
		player.show_notification("♻️ %s yıkıldı!" % structure_name, Color(0.3, 0.8, 0.3))
		
	# Clean up structure
	queue_free()
