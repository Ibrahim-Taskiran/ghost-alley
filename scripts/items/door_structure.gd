extends StructureBase
class_name DoorStructure

var is_open: bool = false
@onready var _collision_shape: CollisionShape3D = $CollisionShape3D

func _ready() -> void:
	super._ready()
	add_to_group("Doors")

func toggle_door(player: CharacterBody3D) -> void:
	if is_destroyed:
		return
		
	# If player wants to repair damaged door, let them hold Shift or do it when closed?
	# Let's say if the door is open, we close it, and if it's closed and player is holding Shift, we repair it!
	if not is_open and Input.is_key_pressed(KEY_SHIFT):
		repair(player)
		return
		
	is_open = not is_open
	
	if is_open:
		# Rotate door 90 degrees to represent opening
		var tween = create_tween().set_parallel(true)
		if mesh_instance:
			tween.tween_property(mesh_instance, "rotation_degrees:y", 90.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
		# Turn off collision layer so entities can pass through
		collision_layer = 0
		
		player.show_notification("🔓 %s Açıldı! (Kapatmak için [E], Tamir için [Shift + E])" % structure_name, Color(0.3, 0.8, 0.9))
	else:
		# Rotate back
		var tween = create_tween().set_parallel(true)
		if mesh_instance:
			tween.tween_property(mesh_instance, "rotation_degrees:y", 0.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
		# Restore collision
		collision_layer = 8
		
		player.show_notification("🔒 %s Kapatıldı!" % structure_name, Color(0.9, 0.7, 0.3))
