extends Control

@onready var stats_label: Label = $Panel/CenterContainer/VBoxContainer/StatsLabel
@onready var respawn_button: Button = $Panel/CenterContainer/VBoxContainer/RespawnButton

func _ready() -> void:
	add_to_group("DeathScreen")
	hide()

func show_death_screen() -> void:
	# Calculate days survived
	var survived_days = 1
	var day_night = get_tree().get_first_node_in_group("DayNightCycle")
	if day_night:
		survived_days = day_night.current_day if "current_day" in day_night else 1
		
	stats_label.text = "Hayatta Kalınan Gün Sayısı: %d" % survived_days
	
	show()
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 1.0) # 1 second fade-in

func _on_respawn_button_pressed() -> void:
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		var player = players[0]
		if player.has_node("DeathSystem"):
			player.get_node("DeathSystem").respawn()
