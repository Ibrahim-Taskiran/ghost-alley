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
@onready var freeze_button: Button = $RightMargin/VBoxContainer/FreezeButton

# --- Notifications ---
@onready var notif_panel: PanelContainer = $NotificationPanel
@onready var notif_label: Label = $NotificationPanel/Margin/Label

# --- New Phase 3 UI Elements ---
@onready var base_survivors_label: Label = $LeftMargin/VBoxContainer/BaseSurvivorsLabel
@onready var zones_label: Label = $LeftMargin/VBoxContainer/ZonesLabel
@onready var reading_container: VBoxContainer = $LeftMargin/VBoxContainer/ReadingContainer
@onready var reading_label: Label = $LeftMargin/VBoxContainer/ReadingContainer/ReadingLabel
@onready var reading_bar: ProgressBar = $LeftMargin/VBoxContainer/ReadingContainer/ReadingBar

var _player: CharacterBody3D = null
var _day_night: DayNightCycle = null
var _notif_tween: Tween = null
var _zone_update_timer: float = 0.0
var _minimap_container: PanelContainer = null
var _minimap_camera: Camera3D = null
var _fullmap_container: PanelContainer = null
var _fullmap_camera: Camera3D = null
var is_fullmap_open: bool = false

func _ready() -> void:
	# Hide notification panel initially
	notif_panel.hide()
	
	# Connect freeze button
	if freeze_button:
		freeze_button.pressed.connect(_on_freeze_button_pressed)
		# Synchronize text
		freeze_button.text = "Zombileri Çöz" if ZombieAI.are_zombies_frozen else "Zombileri Durdur"
	
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
		
		# Connect to BookReader if player has it
		if _player.has_node("BookReader"):
			var book_reader = _player.get_node("BookReader")
			book_reader.reading_started.connect(_on_reading_started)
			book_reader.reading_progress_updated.connect(_on_reading_progress_updated)
			book_reader.reading_completed.connect(_on_reading_completed)
			book_reader.reading_cancelled.connect(_on_reading_cancelled)
			
	# Connect to DayNightCycle
	_day_night = get_tree().get_first_node_in_group("DayNightCycle") as DayNightCycle
	if _day_night:
		_day_night.time_changed.connect(_on_time_changed)
		_on_time_changed(int(floor(_day_night.current_hour)), int(floor((_day_night.current_hour - floor(_day_night.current_hour)) * 60.0)))
		
	# NPC & Zone Updates
	NPCManager.npc_list_changed.connect(_update_npc_list)
	_update_npc_list()
	_update_safe_zones()
	
	# Squad Stance Connections
	$LeftMargin/VBoxContainer/StanceContainer/StancePasif.pressed.connect(func(): _on_stance_changed("PASIF"))
	$LeftMargin/VBoxContainer/StanceContainer/StanceSurvival.pressed.connect(func(): _on_stance_changed("HAYATTA_KAL"))
	$LeftMargin/VBoxContainer/StanceContainer/StanceAgresif.pressed.connect(func(): _on_stance_changed("AGRESIF"))
	_update_stance_ui()
	
	# Weather Updates Connection
	if is_instance_valid(WeatherManager):
		WeatherManager.weather_changed.connect(func(_new_weather):
			if _day_night:
				var hr = floor(_day_night.current_hour)
				var mn = floor((_day_night.current_hour - hr) * 60.0)
				_on_time_changed(int(hr), int(mn))
		)
		
	# Programmatic District Label (Phase 3)
	var dist_label = Label.new()
	dist_label.name = "DistrictLabel"
	dist_label.text = "📍 Bölge: Dış Mahalleler (⭐ Düşük)"
	dist_label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3))
	dist_label.add_theme_font_size_override("font_size", 14)
	if has_node("RightMargin/VBoxContainer"):
		$RightMargin/VBoxContainer.add_child(dist_label)
		$RightMargin/VBoxContainer.move_child(dist_label, 1)
		
	if is_instance_valid(DistrictManager):
		DistrictManager.district_changed.connect(func(dist_id, name, danger):
			var dist_info = DistrictManager.districts[dist_id]
			dist_label.text = "📍 Bölge: %s (%s)" % [name.split(" ")[1], dist_info["danger_text"].split(" ")[0]]
			dist_label.add_theme_color_override("font_color", dist_info["color"])
		)
		
	# Hotbar Kısayol Arayüzünü oluştur ve bağla
	_create_hotbar_ui()
	if _player and _player.inventory:
		_player.inventory.inventory_changed.connect(update_hotbar_ui)
		update_hotbar_ui()
		
	# Minimap Arayüzünü oluştur
	_create_minimap_ui()

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
		var weather_icon = "☀️"
		if is_instance_valid(WeatherManager):
			weather_icon = WeatherManager.get_icon()
		time_label.text = "Gün %d | %02d:%02d %s" % [_day_night.current_day, hour, minute, weather_icon]

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

func _on_freeze_button_pressed() -> void:
	ZombieAI.are_zombies_frozen = not ZombieAI.are_zombies_frozen
	if freeze_button:
		freeze_button.text = "Zombileri Çöz" if ZombieAI.are_zombies_frozen else "Zombileri Durdur"
		
	var msg = "Zombiler durduruldu!" if ZombieAI.are_zombies_frozen else "Zombiler serbest bırakıldı!"
	var col = Color(0.9, 0.8, 0.3) if ZombieAI.are_zombies_frozen else Color(0.3, 0.8, 0.3)
	show_message(msg, col)

func _process(delta: float) -> void:
	# Update minimap camera position
	if is_instance_valid(_minimap_camera) and is_instance_valid(_player):
		_minimap_camera.global_position = _player.global_position + Vector3(0.0, 40.0, 0.0)
		_minimap_camera.global_rotation_degrees = Vector3(-90.0, 0.0, 0.0)
		
	# Update fullmap camera position
	if is_fullmap_open and is_instance_valid(_fullmap_camera) and is_instance_valid(_player):
		_fullmap_camera.global_position = _player.global_position + Vector3(0.0, 100.0, 0.0)
		
	# Periodically update safe zones count every 1.5 seconds
	_zone_update_timer += delta
	if _zone_update_timer >= 1.5:
		_zone_update_timer = 0.0
		_update_safe_zones()

func _update_npc_list() -> void:
	if not base_survivors_label:
		return
		
	var has_allies = NPCManager.get_npc_count() > 0
	var stance_container = $LeftMargin/VBoxContainer/StanceContainer
	if stance_container:
		stance_container.visible = has_allies
		
	if NPCManager.recruited_npcs.is_empty():
		base_survivors_label.text = "🏡 Üs: Hayatta Kalan Yok"
	else:
		var names = []
		for npc_class in NPCManager.recruited_npcs:
			var details = NPCManager.get_npc_details(npc_class)
			if not details.is_empty():
				var short_name = details["name"].split(" (")[0] # e.g. "🏥 Dr. Selim"
				names.append(short_name)
		base_survivors_label.text = "🏡 Üs: " + ", ".join(names)

func _update_safe_zones() -> void:
	if not zones_label:
		return
	var zones = get_tree().get_nodes_in_group("Zones")
	var safe_count = 0
	for zone in zones:
		if zone.get("is_safe") == true:
			safe_count += 1
	zones_label.text = "🗺️ Güvenli Bölgeler: %d" % safe_count

func _on_reading_started(book_id: String, _total_time: float) -> void:
	if reading_container and reading_label and reading_bar:
		var item_data = ItemDatabase.get_item(book_id)
		var book_name = item_data.get("name", "Kitap")
		reading_label.text = "📖 %s (%d%%)..." % [book_name, 0]
		reading_bar.value = 0.0
		reading_container.show()

func _on_reading_progress_updated(progress_percent: float, _time_remaining: float) -> void:
	if reading_container and reading_label and reading_bar and _player.has_node("BookReader"):
		var book_reader = _player.get_node("BookReader")
		var book_id = book_reader.current_book_id
		var item_data = ItemDatabase.get_item(book_id)
		var book_name = item_data.get("name", "Kitap")
		reading_label.text = "📖 %s (%d%%)..." % [book_name, int(progress_percent)]
		reading_bar.value = progress_percent
		reading_container.show()

func _on_reading_completed(_book_id: String) -> void:
	if reading_container:
		reading_container.hide()

func _on_reading_cancelled() -> void:
	if reading_container:
		reading_container.hide()

func show_action_progress(action_name: String, progress_percent: float) -> void:
	if reading_container and reading_label and reading_bar:
		reading_label.text = "%s (%d%%)..." % [action_name, int(progress_percent)]
		reading_bar.value = progress_percent
		reading_container.show()

func hide_action_progress() -> void:
	if reading_container:
		reading_container.hide()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F1:
			_on_stance_changed("PASIF")
		elif event.keycode == KEY_F2:
			_on_stance_changed("HAYATTA_KAL")
		elif event.keycode == KEY_F3:
			_on_stance_changed("AGRESIF")
		elif event.keycode == KEY_M:
			if is_fullmap_open:
				close_fullmap()
			elif _player and not _player.is_ui_open:
				open_fullmap()

func _on_stance_changed(stance: String) -> void:
	NPCManager.active_order = stance
	_update_stance_ui()
	
	var stance_tr = "Pasif"
	if stance == "HAYATTA_KAL": stance_tr = "Hayatta Kal"
	elif stance == "AGRESIF": stance_tr = "Agresif"
	
	var msg = "🔊 Takım Emri: %s!" % stance_tr
	var col = Color(0.3, 0.8, 0.9)
	show_message(msg, col)

func _update_stance_ui() -> void:
	var active = NPCManager.active_order
	
	var btn_pasif = $LeftMargin/VBoxContainer/StanceContainer/StancePasif
	var btn_surv = $LeftMargin/VBoxContainer/StanceContainer/StanceSurvival
	var btn_aggr = $LeftMargin/VBoxContainer/StanceContainer/StanceAgresif
	
	if not btn_pasif or not btn_surv or not btn_aggr:
		return
		
	# Dim inactive, highlight active
	if active == "PASIF":
		btn_pasif.modulate = Color(0.3, 0.9, 0.3)
		btn_surv.modulate = Color(0.6, 0.6, 0.6)
		btn_aggr.modulate = Color(0.6, 0.6, 0.6)
	elif active == "HAYATTA_KAL":
		btn_pasif.modulate = Color(0.6, 0.6, 0.6)
		btn_surv.modulate = Color(0.3, 0.8, 0.9)
		btn_aggr.modulate = Color(0.6, 0.6, 0.6)
	elif active == "AGRESIF":
		btn_pasif.modulate = Color(0.6, 0.6, 0.6)
		btn_surv.modulate = Color(0.6, 0.6, 0.6)
		btn_aggr.modulate = Color(0.9, 0.3, 0.3)

# === HOTBAR (HIZLI ERİŞİM BARISSLOTLARI) UI YÖNETİMİ ===
var hotbar_slots_ui: Array[PanelContainer] = []

func _create_hotbar_ui() -> void:
	# Ana Hotbar Panel Container
	var hotbar_panel = PanelContainer.new()
	hotbar_panel.name = "HotbarPanel"
	hotbar_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Premium Cyberpunk tarzı yarı şeffaf arka plan
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.05, 0.07, 0.8) # Koyu slate
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.12, 0.6, 0.9, 0.5) # Neon Mavi kenarlık
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	hotbar_panel.add_theme_stylebox_override("panel", style)
	
	# Ekranda alt kısımda, ortada hizala
	hotbar_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	hotbar_panel.size_flags_vertical = Control.SIZE_SHRINK_END
	
	# Margin Container
	var margin = MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 8)
	hotbar_panel.add_child(margin)
	
	# HBoxContainer for 5 slots
	var hbox = HBoxContainer.new()
	hbox.mouse_filter = Control.MOUSE_FILTER_PASS
	hbox.add_theme_constant_override("separation", 10)
	margin.add_child(hbox)
	
	# Create 5 slots
	for i in range(5):
		var slot = preload("res://scripts/ui/drag_drop_hotbar.gd").new()
		slot.set("hotbar_index", i)
		slot.set("hud", self)
		slot.custom_minimum_size = Vector2(40, 40) # Mükemmel küçük kareler (40x40)
		slot.mouse_filter = Control.MOUSE_FILTER_STOP
		
		var slot_style = StyleBoxFlat.new()
		slot_style.bg_color = Color(0.08, 0.09, 0.11, 0.9)
		slot_style.border_width_left = 1
		slot_style.border_width_top = 1
		slot_style.border_width_right = 1
		slot_style.border_width_bottom = 1
		slot_style.border_color = Color(0.24, 0.26, 0.32, 1.0)
		slot_style.corner_radius_top_left = 4
		slot_style.corner_radius_top_right = 4
		slot_style.corner_radius_bottom_left = 4
		slot_style.corner_radius_bottom_right = 4
		slot.add_theme_stylebox_override("panel", slot_style)
		
		# Control inside slot for absolute layout (prevents stretching)
		var content = Control.new()
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(content)
		
		# Kısayol Tuş Etiketi (sol üst)
		var num_lbl = Label.new()
		num_lbl.text = str(i + 1)
		num_lbl.add_theme_font_size_override("font_size", 8)
		num_lbl.add_theme_color_override("font_color", Color(0.12, 0.6, 0.9, 0.8))
		num_lbl.position = Vector2(3, 1)
		num_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(num_lbl)
		
		# Eşya adı
		var item_lbl = Label.new()
		item_lbl.text = "Boş"
		item_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		item_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		item_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		item_lbl.add_theme_font_size_override("font_size", 7)
		item_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		item_lbl.position = Vector2(2, 10)
		item_lbl.size = Vector2(36, 20)
		item_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(item_lbl)
		
		# Eşya miktarı
		var qty_lbl = Label.new()
		qty_lbl.text = ""
		qty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		qty_lbl.add_theme_font_size_override("font_size", 7)
		qty_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		qty_lbl.position = Vector2(2, 28)
		qty_lbl.size = Vector2(36, 10)
		qty_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(qty_lbl)
		
		hbox.add_child(slot)
		hotbar_slots_ui.append(slot)
		
	# HUD sahnesinin en altına yerleştir
	add_child(hotbar_panel)
	
	# Ekranın sol alt köşesinde konumlandır (Görselle tam uyumlu)
	hotbar_panel.set_anchors_preset(10) # PRESET_BOTTOM_LEFT
	hotbar_panel.position.x = 20 # Sol kenardan 20 piksel boşluk
	hotbar_panel.position.y = get_viewport().get_visible_rect().size.y - 75 # Sol alta konumlandır
	
	# Pencere boyutu değiştiğinde pozisyonu korumak için viewport sinyali bağla
	get_viewport().size_changed.connect(func():
		hotbar_panel.position.y = get_viewport().get_visible_rect().size.y - 75
	)

func update_hotbar_ui() -> void:
	if not _player or not _player.inventory or not hotbar_slots_ui or hotbar_slots_ui.size() < 5:
		return
		
	for i in range(5):
		var pocket_slot = _player.inventory.slots[16 + i]
		var item_id = pocket_slot["item_id"]
		var quantity = pocket_slot["quantity"]
		
		var slot_panel = hotbar_slots_ui[i]
		var content = slot_panel.get_child(0)
		var item_lbl = content.get_child(1) as Label
		var qty_lbl = content.get_child(2) as Label
		var slot_style = slot_panel.get_theme_stylebox("panel") as StyleBoxFlat
		
		if item_id != "":
			var item = ItemDatabase.get_item(item_id)
			item_lbl.text = item["name"]
			item_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
			
			qty_lbl.text = "x%d" % quantity
			
			# Kısayol aktif/aktif değil rengi
			slot_style.border_color = Color(0.12, 0.6, 0.9, 0.8) # Parlak neon mavi
		else:
			item_lbl.text = "Boş"
			item_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			qty_lbl.text = ""
			slot_style.border_color = Color(0.24, 0.26, 0.32, 1.0)

func _create_minimap_ui() -> void:
	# Ana Minimap Panel Container
	_minimap_container = PanelContainer.new()
	_minimap_container.name = "MinimapContainer"
	
	# Premium slate style with neon cyan borders
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.05, 0.07, 0.85)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.12, 0.6, 0.9, 0.7) # Glowing neon cyan
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	style.shadow_size = 5
	_minimap_container.add_theme_stylebox_override("panel", style)
	
	# Position at top right
	add_child(_minimap_container)
	_minimap_container.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_minimap_container.position.x = get_viewport().get_visible_rect().size.x - 170
	_minimap_container.position.y = get_viewport().get_visible_rect().size.y - 180
	
	# Viewport container
	var vp_container = SubViewportContainer.new()
	vp_container.custom_minimum_size = Vector2(150, 150)
	vp_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vp_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_minimap_container.add_child(vp_container)
	
	# SubViewport
	var vp = SubViewport.new()
	vp.size = Vector2(150, 150)
	vp.msaa_3d = SubViewport.MSAA_2X # Premium AA for clean graphics
	vp_container.add_child(vp)
	
	# Minimap top-down Camera3D
	_minimap_camera = Camera3D.new()
	_minimap_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_minimap_camera.size = 35.0 # View radius
	_minimap_camera.far = 100.0
	_minimap_camera.near = 0.1
	# Position above player
	if is_instance_valid(_player):
		_minimap_camera.global_position = _player.global_position + Vector3(0.0, 40.0, 0.0)
	else:
		_minimap_camera.global_position = Vector3(0.0, 40.0, 0.0)
	_minimap_camera.global_rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	vp.add_child(_minimap_camera)
	
	# Add a premium central player pointer (overlaying 2D label or crosshair)
	var crosshair = Label.new()
	crosshair.text = "▲" # Upward arrow representing player position/forward
	crosshair.add_theme_font_size_override("font_size", 14)
	crosshair.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3)) # Glowing Crimson Red pointer
	crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crosshair.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	crosshair.set_anchors_preset(Control.PRESET_CENTER)
	crosshair.position = Vector2(67, 65) # Perfect center of the 150x150 panel
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_minimap_container.add_child(crosshair)
	
	# Connect size changed to adjust bottom-right offset dynamically
	get_viewport().size_changed.connect(func():
		_minimap_container.position.x = get_viewport().get_visible_rect().size.x - 170
		_minimap_container.position.y = get_viewport().get_visible_rect().size.y - 180
	)

func _create_fullmap_ui() -> void:
	_fullmap_container = PanelContainer.new()
	_fullmap_container.name = "FullmapContainer"
	
	# Premium dark styling with neon gold borders
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.04, 0.05, 0.95)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.9, 0.7, 0.2, 0.8) # Gold border
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.shadow_color = Color(0, 0, 0, 0.6)
	style.shadow_size = 15
	_fullmap_container.add_theme_stylebox_override("panel", style)
	
	# Centered on screen, size 550x550
	_fullmap_container.custom_minimum_size = Vector2(550, 550)
	_fullmap_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_fullmap_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	add_child(_fullmap_container)
	
	# Center it on ready
	_fullmap_container.set_anchors_preset(Control.PRESET_CENTER)
	_fullmap_container.position = (get_viewport().get_visible_rect().size - Vector2(550, 550)) / 2.0
	
	# VBox inside
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	_fullmap_container.add_child(vbox)
	
	# Title HBox (Title + Close Button)
	var title_hbox = HBoxContainer.new()
	title_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(title_hbox)
	
	var title = Label.new()
	title.text = "🗺️ ŞEHİR TAKTİK HARİTASI"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2))
	title_hbox.add_child(title)
	
	# Subview Container
	var vp_container = SubViewportContainer.new()
	vp_container.custom_minimum_size = Vector2(480, 460)
	vp_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vp_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	vbox.add_child(vp_container)
	
	var vp = SubViewport.new()
	vp.size = Vector2(480, 460)
	vp.msaa_3d = SubViewport.MSAA_2X
	vp_container.add_child(vp)
	
	_fullmap_camera = Camera3D.new()
	_fullmap_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_fullmap_camera.size = 200.0 # Huge view size to see the whole surrounding
	_fullmap_camera.far = 200.0
	_fullmap_camera.near = 0.1
	_fullmap_camera.global_position = _player.global_position + Vector3(0.0, 100.0, 0.0) if is_instance_valid(_player) else Vector3(0, 100, 0)
	_fullmap_camera.global_rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	vp.add_child(_fullmap_camera)
	
	# Close info footer
	var footer = Label.new()
	footer.text = "[M] Kapat veya Haritadan Çık"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 10)
	footer.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	vbox.add_child(footer)
	
	# Add a premium central player pointer
	var pointer = Label.new()
	pointer.text = "▲"
	pointer.add_theme_font_size_override("font_size", 18)
	pointer.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	pointer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pointer.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pointer.set_anchors_preset(Control.PRESET_CENTER)
	pointer.position = Vector2(232, 230) # Center of the 480x460 viewport within the panel
	pointer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fullmap_container.add_child(pointer)
	
	_fullmap_container.hide()
	
	# Connect window resize
	get_viewport().size_changed.connect(func():
		_fullmap_container.position = (get_viewport().get_visible_rect().size - Vector2(550, 550)) / 2.0
	)

func open_fullmap() -> void:
	if not _player:
		return
		
	# Create if not created
	if not is_instance_valid(_fullmap_container):
		_create_fullmap_ui()
		
	is_fullmap_open = true
	_player.is_ui_open = true
	_player.call("_stop_moving")
	
	# Center map camera on player
	if is_instance_valid(_fullmap_camera) and is_instance_valid(_player):
		_fullmap_camera.global_position = _player.global_position + Vector3(0.0, 100.0, 0.0)
		
	_fullmap_container.show()
	_fullmap_container.scale = Vector2(0.9, 0.9)
	_fullmap_container.modulate.a = 0.0
	var tween = create_tween().set_parallel(true)
	tween.tween_property(_fullmap_container, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_fullmap_container, "modulate:a", 1.0, 0.15)
	
	_player.show_notification("🗺️ Taktik Harita Açıldı", Color(0.9, 0.7, 0.2))

func close_fullmap() -> void:
	if not is_instance_valid(_fullmap_container):
		return
		
	is_fullmap_open = false
	if _player:
		_player.is_ui_open = false
		
	var tween = create_tween().set_parallel(true)
	tween.tween_property(_fullmap_container, "scale", Vector2(0.9, 0.9), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(_fullmap_container, "modulate:a", 0.0, 0.12)
	await tween.finished
	_fullmap_container.hide()
