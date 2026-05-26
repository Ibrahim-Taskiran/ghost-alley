extends CanvasLayer

# --- Bars Left ---
@onready var health_bar: ProgressBar = $LeftMargin/VBoxContainer/HealthBarContainer/HealthBar
@onready var health_label: Label = $LeftMargin/VBoxContainer/HealthBarContainer/HealthLabel
@onready var hunger_bar: ProgressBar = $LeftMargin/VBoxContainer/HungerContainer/HungerBar
@onready var thirst_bar: ProgressBar = $LeftMargin/VBoxContainer/ThirstContainer/ThirstBar
@onready var sleep_bar: ProgressBar = $LeftMargin/VBoxContainer/SleepContainer/SleepBar

# --- Stats/Clock Right ---
@onready var time_label: Label = $RightMargin/VBoxContainer/TimeLabel
@onready var level_label: Label = $RightMargin/VBoxContainer/XPContainer/LevelLabel
@onready var xp_bar: ProgressBar = $RightMargin/VBoxContainer/XPContainer/XPBar
@onready var infection_alert: Label = $RightMargin/VBoxContainer/InfectionAlert

# --- Notifications ---
@onready var notif_panel: PanelContainer = $NotificationPanel
@onready var notif_label: Label = $NotificationPanel/Margin/Label

var _player: CharacterBody3D = null
var _day_night: DayNightCycle = null
var _notif_tween: Tween = null

func _ready() -> void:
	# Hide notification panel initially
	notif_panel.hide()
	
	# Locate player and connect to survival modules
	await get_tree().process_frame
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		_player = players[0]
		_player.health_changed.connect(_on_health_changed)
		_player.player_died.connect(_on_player_died)
		
		# Connect to survival needs
		if _player.has_node("SurvivalNeeds"):
			_player.get_node("SurvivalNeeds").needs_changed.connect(_on_needs_changed)
			var needs = _player.get_node("SurvivalNeeds")
			_on_needs_changed(needs.hunger, needs.thirst, needs.sleep)
			
		# Connect to XP system
		if _player.has_node("XPSystem"):
			_player.get_node("XPSystem").xp_changed.connect(_on_xp_changed)
			var xp_sys = _player.get_node("XPSystem")
			_on_xp_changed(xp_sys.xp, xp_sys.xp_required)
			
		# Connect to Infection system
		if _player.has_node("InfectionSystem"):
			_player.get_node("InfectionSystem").infection_changed.connect(_on_infection_changed)
			
		# Set initial HP
		_on_health_changed(_player.health, _player.max_health)
		
	# Connect to DayNightCycle
	_day_night = get_tree().get_first_node_in_group("DayNightCycle") as DayNightCycle
	if _day_night:
		_day_night.time_changed.connect(_on_time_changed)
		_on_time_changed(int(floor(_day_night.current_hour)), int(floor((_day_night.current_hour - floor(_day_night.current_hour)) * 60.0)))

func _on_health_changed(new_health: float, max_hp: float) -> void:
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = new_health
	if health_label:
		health_label.text = "%d / %d" % [int(new_health), int(max_hp)]

func _on_player_died() -> void:
	if health_label:
		health_label.text = "ÖLDÜN"

func _on_needs_changed(hunger: float, thirst: float, sleep: float) -> void:
	if hunger_bar:
		hunger_bar.value = hunger
	if thirst_bar:
		thirst_bar.value = thirst
	if sleep_bar:
		sleep_bar.value = sleep

func _on_xp_changed(xp: int, req_xp: int) -> void:
	if xp_bar:
		xp_bar.max_value = req_xp
		xp_bar.value = xp
	if level_label and _player and _player.has_node("XPSystem"):
		var lvl = _player.get_node("XPSystem").level
		level_label.text = "Seviye %d (%d/%d XP)" % [lvl, xp, req_xp]

func _on_infection_changed(is_infected: bool, _time_left: float) -> void:
	if infection_alert:
		infection_alert.visible = is_infected

func _on_time_changed(hour: int, minute: int) -> void:
	if time_label and _day_night:
		time_label.text = "Gün %d | %02d:%02d" % [_day_night.current_day, hour, minute]

func show_message(text: String, color: Color = Color.WHITE) -> void:
	if not notif_label or not notif_panel:
		return
		
	notif_label.text = text
	notif_label.add_theme_color_override("font_color", color)
	
	notif_panel.show()
	notif_panel.modulate.a = 1.0
	
	if _notif_tween:
		_notif_tween.kill()
		
	_notif_tween = create_tween()
	_notif_tween.tween_interval(2.5)
	_notif_tween.tween_property(notif_panel, "modulate:a", 0.0, 0.5)
	_notif_tween.tween_callback(notif_panel.hide)
