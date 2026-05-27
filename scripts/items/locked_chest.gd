extends StaticBody3D
class_name LockedChest

signal unlocked

@export var chest_name: String = "Kilitli Askeri Sandık"
@export var required_intelligence: int = 3
@export var required_military: int = 2
@export var is_locked: bool = true

# Loot table: items inside this chest
@export var loot_items: Array[String] = ["tabanca", "metal", "antibiyotik"]
@export var loot_quantities: Array[int] = [1, 5, 2]

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var interaction_area: Area3D = $InteractionArea

var _player: CharacterBody3D = null

func _ready() -> void:
	add_to_group("Structures")
	add_to_group("LockedChests")
	
	# Solid collision: Layer 4 = Structures (value = 8)
	collision_layer = 8
	collision_mask = 0
	
	if interaction_area:
		interaction_area.body_entered.connect(_on_player_entered)
		interaction_area.body_exited.connect(_on_player_exited)
		
	# Apply visual styling
	_apply_visuals()

func _apply_visuals() -> void:
	if not mesh_instance:
		return
		
	# Dark military green chest with glowing golden lock!
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.25, 0.15) if is_locked else Color(0.3, 0.2, 0.1) # Dark green when locked, brown when open
	mat.roughness = 0.8
	
	if is_locked:
		mat.emission_enabled = true
		mat.emission = Color(0.9, 0.7, 0.2) # Glowing gold lock indicator
		mat.emission_energy_multiplier = 0.6
		
	mesh_instance.material_override = mat

func _on_player_entered(body: Node3D) -> void:
	if not is_locked:
		return
		
	if body.is_in_group("Player") and body.has_method("register_nearby_structure"):
		_player = body as CharacterBody3D
		# Register as a structure so we can interact with E!
		# We can override the text display dynamically:
		var text = "🔒 %s [E - Kilidi Aç (Zeka %d, Askeri %d)]" % [chest_name, required_intelligence, required_military]
		_player.show_notification(text, Color(0.9, 0.8, 0.2))
		_player.nearby_structures.append(self)

func _on_player_exited(body: Node3D) -> void:
	if body.is_in_group("Player") and _player:
		if _player.nearby_structures.has(self):
			_player.nearby_structures.erase(self)
		_player = null

# Override the structure's repair method to act as "open/unlock" when player presses E!
func repair(player: CharacterBody3D) -> void:
	if not is_locked:
		return
		
	var p_intel = player.stats.get("intelligence", 1)
	var p_mil = player.stats.get("military", 1)
	
	if p_intel >= required_intelligence and p_mil >= required_military:
		_unlock_chest(player)
	else:
		player.show_notification("🔒 Kilit Açma Başarısız! Gereksinimler: Zeka %d, Askeri %d (Mevcut: Z %d, A %d)" % [required_intelligence, required_military, p_intel, p_mil], Color(0.9, 0.3, 0.3))

func _unlock_chest(player: CharacterBody3D) -> void:
	is_locked = false
	_apply_visuals()
	
	player.show_notification("🔓 Kilit Açıldı! Ganimetler yere saçıldı.", Color(0.3, 0.8, 0.3))
	
	# Gain XP (GDD: 30 XP for lockpicking)
	if player.has_node("XPSystem"):
		player.get_node("XPSystem").gain_xp(30)
		
	# Spawn all loot items on the ground near the chest
	for i in range(loot_items.size()):
		var item_id = loot_items[i]
		var qty = loot_quantities[i]
		
		# Spawn offset
		var angle = randf_range(0.0, 2.0 * PI)
		var dist = randf_range(1.0, 2.0)
		var offset = Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
		
		player.drop_item_in_world(item_id, qty)
		
	# Emit signal
	unlocked.emit()
	
	# Unregister from player
	if player.nearby_structures.has(self):
		player.nearby_structures.erase(self)
		
	# Smoothly shrink and fade out after 1.5 seconds
	var tween = create_tween()
	tween.tween_interval(1.5)
	tween.tween_property(self, "scale", Vector3.ZERO, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)
