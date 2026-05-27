extends Control
class_name BuildUI

var _player: CharacterBody3D = null

func _ready() -> void:
	add_to_group("BuildUI")
	hide()
	
	await get_tree().process_frame
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		_player = players[0]

func open_build_menu() -> void:
	show()
	scale = Vector2(0.9, 0.9)
	modulate.a = 0.0
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.12)
	
	if _player:
		_player.is_ui_open = true

func close_build_menu() -> void:
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(0.9, 0.9), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.1)
	await tween.finished
	hide()
	
	# Only release player block if they are not active in placing structure!
	if _player:
		var build_mgr = _player.get_node_or_null("BuildManager")
		if build_mgr and build_mgr.get("is_building") != true:
			_player.is_ui_open = false

func _on_build_fence_pressed() -> void:
	if _player and _player.has_node("BuildManager"):
		_player.get_node("BuildManager").start_building("wooden_fence")
	close_build_menu()

func _on_build_barricade_pressed() -> void:
	if _player and _player.has_node("BuildManager"):
		_player.get_node("BuildManager").start_building("metal_barricade")
	close_build_menu()

func _on_build_bed_pressed() -> void:
	if _player and _player.has_node("BuildManager"):
		_player.get_node("BuildManager").start_building("bed")
	close_build_menu()

