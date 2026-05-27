extends Control
class_name NPCDialogUI

@onready var title_label: Label = $BackgroundPanel/Margin/VBox/Title
@onready var desc_label: Label = $BackgroundPanel/Margin/VBox/Description

@onready var first_stage: HBoxContainer = $BackgroundPanel/Margin/VBox/FirstStageBox
@onready var help_button: Button = $BackgroundPanel/Margin/VBox/FirstStageBox/HelpButton

@onready var second_stage: HBoxContainer = $BackgroundPanel/Margin/VBox/SecondStageBox

var _player: CharacterBody3D = null
var _current_npc: SurvivorNPC = null

func _ready() -> void:
	add_to_group("NPCDialogUI")
	hide()
	
	await get_tree().process_frame
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		_player = players[0]

func open_dialog(npc: SurvivorNPC) -> void:
	if not _player:
		return
		
	_current_npc = npc
	var npc_data = NPCManager.get_npc_details(npc.npc_class)
	if npc_data.is_empty():
		return
		
	# Stage 1 Reset
	first_stage.show()
	second_stage.hide()
	
	# Text formatting
	title_label.text = npc_data["name"]
	
	var req_mat_data = ItemDatabase.get_item(npc.help_item_required)
	var mat_name = req_mat_data.get("name", "Eşya")
	
	desc_label.text = "Yerde ağır yaralı halde yatan bir %s var. Hayatta kalmasını sağlamak için %d adet %s vermeniz gerekiyor.\n\n🎁 Üs Pasif Etkisi: %s" % [
		req_mat_data.get("name", "Hayatta Kalan"),
		npc.help_item_qty,
		mat_name,
		npc_data.get("bonus_text", "Yok")
	]
	
	# Verify item availability
	var has_item = _player.inventory.has_item(npc.help_item_required, npc.help_item_qty)
	if has_item:
		help_button.text = "Yardım Et (%d %s)" % [npc.help_item_qty, mat_name]
		help_button.disabled = false
	else:
		help_button.text = "Eksik Malzeme (%d %s Gerekli)" % [npc.help_item_qty, mat_name]
		help_button.disabled = true
		
	# Visual transitions
	show()
	scale = Vector2(0.95, 0.95)
	modulate.a = 0.0
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.15)
	
	_player.is_ui_open = true

func close_dialog() -> void:
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.1)
	await tween.finished
	hide()
	
	if _player:
		_player.is_ui_open = false
		_player.unregister_nearby_survivor(_current_npc)

func _on_help_pressed() -> void:
	if not _player or not _current_npc:
		return
		
	# Consume help item
	_player.inventory.remove_item(_current_npc.help_item_required, _current_npc.help_item_qty)
	
	# Transition to Stage 2
	first_stage.hide()
	second_stage.show()
	
	desc_label.text = "Yardımınız sayesinde kazazede ayağa kalktı! Minnettar gözlerle size bakıyor. Onu yanınıza alıp peşinizden gelmesini ister misiniz?"

func _on_ignore_pressed() -> void:
	close_dialog()

func _on_recruit_pressed() -> void:
	if _current_npc:
		var spawn_pos = _current_npc.global_position
		NPCManager.recruit_npc(_current_npc.npc_class, spawn_pos)
		# Anında yok et ki geçiş kusursuz ve gecikmesiz olsun
		_current_npc.queue_free()
	close_dialog()

func _on_free_pressed() -> void:
	if _current_npc:
		_current_npc.rescue()
		_player.show_notification("Hayatta kalan serbest bırakıldı.", Color(0.8, 0.8, 0.8))
	close_dialog()
