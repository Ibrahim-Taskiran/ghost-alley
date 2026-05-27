extends Area3D
class_name SurvivorNPC

@export var npc_class: String = "doctor" # doctor, soldier, engineer
@export var help_item_required: String = "bandaj"
@export var help_item_qty: int = 1

var is_rescued: bool = false

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	add_to_group("Survivors")
	
	collision_layer = 16 # Pickups/Interactions
	collision_mask = 2   # Player
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	_apply_visuals()

func _apply_visuals() -> void:
	if not mesh_instance:
		return
		
	var color = Color(0.8, 0.8, 0.8) # Default gray
	match npc_class:
		"doctor":
			color = Color(0.9, 0.9, 0.9) # Pure white for Doctors
		"soldier":
			color = Color(0.2, 0.35, 0.15) # Army green for Soldiers
		"engineer":
			color = Color(0.9, 0.55, 0.1) # Construction orange/gold for Engineers
			
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.6
	material.emission_enabled = true
	material.emission = color * 0.1 # Subtle glowing aura
	
	mesh_instance.material_override = material

func _on_body_entered(body: Node3D) -> void:
	if is_rescued:
		return
	if body.is_in_group("Player") and body.has_method("register_nearby_survivor"):
		body.register_nearby_survivor(self)

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player") and body.has_method("unregister_nearby_survivor"):
		body.unregister_nearby_survivor(self)

func rescue() -> void:
	is_rescued = true
	
	# Play a visual fade out before deleting
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3.ZERO, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await tween.finished
	
	queue_free()
