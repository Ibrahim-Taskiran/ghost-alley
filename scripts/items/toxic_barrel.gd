extends StaticBody3D
class_name ToxicBarrel

@export var damage_per_sec: float = 12.0
@onready var detection_area: Area3D = $DetectionArea

var _damage_timer: float = 0.0

func _ready() -> void:
	add_to_group("Hazards")

func _physics_process(delta: float) -> void:
	_damage_timer += delta
	var bodies = detection_area.get_overlapping_bodies()
	
	for body in bodies:
		if body.is_in_group("Player") and body.get("is_alive") == true:
			body.take_damage(damage_per_sec * delta)
			if _damage_timer >= 2.0:
				body.show_notification("⚠️ UYARI: Radyoaktif / Toksik sızıntı! Hasar alıyorsunuz!", Color(0.9, 0.2, 0.2))
				
	if _damage_timer >= 2.0:
		_damage_timer = 0.0
