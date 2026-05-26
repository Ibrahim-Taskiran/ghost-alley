extends Camera3D

## Isometric Camera Controller — Ghost Alley (Faz 1)
## Orthographic 3D Kamera — çapraz açılı takip, 45° isometrik görüş, 2.5D derinlik hissi
## GDD Referans: Bölüm 10.2 — Kontrol & Kamera

# === KAMERA AYARLARI ===
@export var follow_speed: float = 5.0
@export var camera_size: float = 15.0
@export var camera_offset: Vector3 = Vector3(10, 12, 10)

# === İÇ DEĞİŞKENLER ===
var _target: Node3D = null


func _ready() -> void:
	# Parent transform'u yoksay — bağımsız takip
	top_level = true

	# Orthographic projeksiyon ayarları
	projection = Camera3D.PROJECTION_ORTHOGONAL
	size = camera_size
	near = 0.1
	far = 100.0

	# Hedef: parent node (Player)
	_target = get_parent()

	# İlk konumlandırma
	if _target:
		global_position = _target.global_position + camera_offset
		look_at(_target.global_position, Vector3.UP)


func _process(delta: float) -> void:
	if _target == null:
		return

	# Hedef pozisyon hesapla
	var target_pos := _target.global_position + camera_offset

	# Smooth takip (lerp)
	global_position = global_position.lerp(target_pos, follow_speed * delta)

	# Kamerayı her zaman oyuncuya baktır
	look_at(_target.global_position, Vector3.UP)
