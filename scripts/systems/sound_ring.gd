extends Node3D
class_name SoundRing

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

var target_radius: float = 8.0
var duration: float = 0.6
var color: Color = Color(0.85, 0.15, 0.15, 0.4) # Yarı saydam kırmızı

func _ready() -> void:
	var mat = StandardMaterial3D.new()
	mat.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat.roughness = 1.0
	mesh_instance.material_override = mat

	# İlk ölçeklendirme
	scale = Vector3(0.01, 1.0, 0.01)

	# Tween ile genişleme ve sönme animasyonu
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale:x", target_radius, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale:z", target_radius, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	var fade_color = color
	fade_color.a = 0.0
	tween.tween_property(mat, "albedo_color", fade_color, duration).set_trans(Tween.TRANS_LINEAR)
	
	tween.chain().tween_callback(queue_free)
