extends Area3D
class_name WorldItem

@export var item_id: String = "konserve"
@export var quantity: int = 1

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

func _ready() -> void:
	# Add to group for easier queries
	add_to_group("WorldItems")
	
	# Configure collision mask to look only for Player (Layer 2)
	collision_layer = 16 # Layer 5 = Pickups
	collision_mask = 2   # Mask 2 = Player
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Color code the box mesh placeholder based on item type
	_apply_visuals()
	
	# GDD §8.2: Avcı bonusu (Eşya toplama menzilini %50 artırır)
	if NPCManager.has_npc("hunter") and has_node("CollisionShape3D"):
		get_node("CollisionShape3D").scale = Vector3(1.5, 1.5, 1.5)

func _apply_visuals() -> void:
	if not mesh_instance:
		return
		
	var item_data = ItemDatabase.get_item(item_id)
	if item_data.is_empty():
		return
		
	var color = Color(0.6, 0.6, 0.6) # Default gray
	
	# Unique item-specific color codes for premium visuals!
	match item_id:
		"yakit":
			color = Color(0.9, 0.55, 0.1) # Glowing Orange
		"elektronik":
			color = Color(0.1, 0.85, 0.8) # Glowing Neon Cyan
		"kimyasal":
			color = Color(0.3, 0.9, 0.1) # Glowing Toxic Green
		"barut_kovan":
			color = Color(0.65, 0.65, 0.5) # Glowing Brass
		"plastik":
			color = Color(0.85, 0.85, 0.85) # Glowing White
		_:
			# Fallback to type-based colors
			match item_data["type"]:
				ItemDatabase.ItemType.FOOD, ItemDatabase.ItemType.WATER:
					color = Color(0.2, 0.7, 0.3) # Emerald Green for food/water
				ItemDatabase.ItemType.MEDICINE:
					color = Color(0.9, 0.2, 0.2) # Crimson Red for medicine
				ItemDatabase.ItemType.WEAPON:
					color = Color(0.7, 0.2, 0.9) # Purple for weapons
				ItemDatabase.ItemType.MATERIAL:
					color = Color(0.8, 0.5, 0.2) # Wooden brown/bronze for materials
				ItemDatabase.ItemType.TOOL:
					color = Color(0.2, 0.6, 0.9) # Electric blue for tools
			
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.5
	material.emission_enabled = true
	material.emission = color * 0.15 # Subtle glowing emission so they stand out!
	
	mesh_instance.material_override = material

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player") and body.has_method("register_nearby_item"):
		body.register_nearby_item(self)

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player") and body.has_method("unregister_nearby_item"):
		body.unregister_nearby_item(self)

func collect() -> void:
	# Here we can add particles/sound in the future
	queue_free()
