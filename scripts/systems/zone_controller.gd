extends Area3D
class_name ZoneController

@export var zone_id: String = "dismalle"
@export var zone_name: String = "Dış Mahalleler"

var is_cleared: bool = false
var is_safe: bool = false

var _check_timer: float = 0.0

func _ready() -> void:
	add_to_group("Zones")
	
	# Collision mask: 4 (Layer 3 = Enemy)
	collision_layer = 0
	collision_mask = 4

func _process(delta: float) -> void:
	# Periodic check every 1.5 seconds to save performance
	_check_timer += delta
	if _check_timer < 1.5:
		return
	_check_timer = 0.0
	
	_check_zone_status()

func _check_zone_status() -> void:
	var enemies = get_overlapping_bodies()
	var enemy_count = 0
	
	# Double check bodies belong to zombie_ai and are alive
	for body in enemies:
		if body.is_in_group("ZombieAI") or body.is_in_group("Enemies"):
			if body.get("is_alive") != false:
				enemy_count += 1
				
	if enemy_count > 0:
		is_cleared = false
		if is_safe:
			is_safe = false
			var players = get_tree().get_nodes_in_group("Player")
			if players.size() > 0:
				players[0].show_notification("⚠️ UYARI: %s Sektörüne düşman sızdı! Güvenlik kayboldu." % zone_name, Color(0.9, 0.2, 0.2))
	else:
		if not is_cleared:
			is_cleared = true
			var players = get_tree().get_nodes_in_group("Player")
			if players.size() > 0:
				players[0].show_notification("🎉 Sektör Temizlendi: %s! Yatak kurarak burayı Güvenli Bölge yapın." % zone_name, Color(0.3, 0.8, 0.9))
				
		# Check if a bed or shelter flag exists inside this zone to declare it Safe!
		var beds = get_overlapping_areas()
		var has_safe_object = false
		for area in beds:
			if area.is_in_group("Beds") or area.get_parent().is_in_group("ShelterFlags"):
				has_safe_object = true
				break
				
		if has_safe_object and not is_safe:
			is_safe = true
			var players = get_tree().get_nodes_in_group("Player")
			if players.size() > 0:
				players[0].show_notification("🏡 SIĞINAK AKTİF: %s Güvenli Bölge yapıldı! Düşman spawni durduruldu." % zone_name, Color(0.3, 0.8, 0.3))
				if zone_id == "merkez":
					_trigger_story_ending(players[0])
				
	# GDD §3.3: Güvenli bölgede pasif kaynak üretimi (Her 2 oyun saatinde bir)
	if is_safe:
		var day_night = get_tree().get_first_node_in_group("DayNightCycle")
		if day_night:
			var cur_hour = int(floor(day_night.current_hour))
			if cur_hour % 2 == 0 and cur_hour != _last_gen_hour:
				_last_gen_hour = cur_hour
				_generate_passive_resource()

var _last_gen_hour: int = -1

func _generate_passive_resource() -> void:
	# Alan içindeki mevcut eşyaları kontrol et (Maks 5 eşya limiti)
	var areas = get_overlapping_areas()
	var item_count = 0
	for area in areas:
		if area.is_in_group("WorldItems"):
			item_count += 1
			
	if item_count >= 5:
		return # Eşya spamını önlemek için sınır
		
	var loot_pool = [
		{"id": "tahta", "qty": 3},
		{"id": "kumas", "qty": 2},
		{"id": "metal", "qty": 1}
	]
	
	# GDD §8.2: Çiftçi varsa ek yiyecek kaynağı şansı
	if NPCManager.has_npc("farmer"):
		loot_pool.append({"id": "konserve", "qty": 1})
		
	var chosen = loot_pool[randi() % loot_pool.size()]
	var item_scene = load("res://scenes/items/world_item.tscn")
	if item_scene:
		var instance = item_scene.instantiate() as WorldItem
		instance.item_id = chosen["id"]
		instance.quantity = chosen["qty"]
		
		# Merkez etrafında rastgele konum (5m yarıçapında)
		var offset = Vector3(randf_range(-5.0, 5.0), 0.0, randf_range(-5.0, 5.0))
		instance.global_position = global_position + offset
		instance.global_position.y = 0.0
		
		get_parent().add_child(instance)
		
		var players = get_tree().get_nodes_in_group("Player")
		if players.size() > 0:
			players[0].show_notification("📦 Güvenli Bölgede yeni kaynak bulundu: %s" % ItemDatabase.get_item(chosen["id"]).get("name", "Kaynak"), Color(0.3, 0.8, 0.5))

func _trigger_story_ending(player: CharacterBody3D) -> void:
	var hud = get_tree().get_first_node_in_group("HUD")
	if not hud:
		return
		
	# Pause player action
	player.is_ui_open = true
	player.call("_stop_moving")
	
	# Create Main Panel Container
	var ending_panel = PanelContainer.new()
	ending_panel.name = "EndingPanel"
	ending_panel.set_anchors_and_offsets_preset(15) # PRESET_FULL_RECT
	
	# Premium dark semi-transparent style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.05, 0.07, 0.96)
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	style.border_color = Color(0.9, 0.7, 0.2, 0.8) # Golden border
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	ending_panel.add_theme_stylebox_override("panel", style)
	
	# Margin Container inside
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 60)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_right", 60)
	margin.add_theme_constant_override("margin_bottom", 40)
	ending_panel.add_child(margin)
	
	# VBox inside margin
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "🏢 ŞEHİR MERKEZİ GÜVENLİ BÖLGE İLAN EDİLDİ!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	vbox.add_child(title)
	
	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "Kıyametin Sırrı ve Şehrin Kaderi..."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(subtitle)
	
	# Separator line
	var sep = HSeparator.new()
	vbox.add_child(sep)
	
	# ScrollContainer for Lore Text
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 150)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	
	var lore_label = Label.new()
	lore_label.text = "Şehir merkezindeki askeri sığınağı ve radyo kulesini zombilerden temizleyerek güvenli hale getirdiniz. Masadaki gizli araştırma belgelerini ve kişisel günlükleri okuduktan sonra hafızanızdaki tüm boşluklar doldu ve acı gerçekle yüzleştiniz.\n\nŞehri yok eden salgın, devlet destekli askeri bir laboratuvar deneyiydi. Ve siz 'Adam', bu deneyleri yöneten baş bilim insanıydınız! Kıyamet koptuğunda suçluluk duygunuz yüzünden kendinizi sokaklara attınız ve travma nedeniyle her şeyi unuttunuz.\n\nŞimdi sığınağın kumanda panelindesiniz. Şehrin ve kendinizin kaderini belirleme vakti geldi. Hangi yolu seçeceksiniz?"
	lore_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lore_label.add_theme_font_size_override("font_size", 12)
	lore_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	lore_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(lore_label)
	
	# Buttons HBox
	var buttons_hbox = HBoxContainer.new()
	buttons_hbox.add_theme_constant_override("separation", 20)
	buttons_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(buttons_hbox)
	
	# Style for buttons
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.12, 0.13, 0.16, 0.9)
	btn_style.border_width_left = 1
	btn_style.border_width_top = 1
	btn_style.border_width_right = 1
	btn_style.border_width_bottom = 1
	btn_style.border_color = Color(0.3, 0.35, 0.4, 0.8)
	btn_style.corner_radius_top_left = 6
	btn_style.corner_radius_top_right = 6
	btn_style.corner_radius_bottom_left = 6
	btn_style.corner_radius_bottom_right = 6
	
	# Helper function to create ending buttons
	var create_btn = func(btn_title: String, color: Color, desc: String, action_id: int):
		var btn_box = VBoxContainer.new()
		btn_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var btn = Button.new()
		btn.text = btn_title
		btn.custom_minimum_size = Vector2(0, 45)
		btn.add_theme_color_override("font_color", color)
		btn.add_theme_font_size_override("font_size", 12)
		btn.add_theme_stylebox_override("normal", btn_style)
		btn_box.add_child(btn)
		
		var desc_lbl = Label.new()
		desc_lbl.text = desc
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_lbl.add_theme_font_size_override("font_size", 10)
		desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		btn_box.add_child(desc_lbl)
		
		buttons_hbox.add_child(btn_box)
		
		btn.pressed.connect(func():
			# Show specific ending screen
			_show_specific_ending(ending_panel, action_id, player)
		)
		
	create_btn.call(
		"🟢 İYİ SON\n(Yeni Topluluk)",
		Color(0.3, 0.9, 0.3),
		"Radyo kulesini kullanarak diğer afetzedeleri çağırın ve arkadaşlarınızla sığınakta barışçıl bir topluluk kurun.",
		1
	)
	
	create_btn.call(
		"🟡 NÖTR SON\n(Belgeleri Al ve Git)",
		Color(0.9, 0.8, 0.2),
		"Formülü yanınıza alarak sığınaktakileri geride bırakın ve dış dünyada yeni bir başlangıç için yola çıkın.",
		2
	)
	
	create_btn.call(
		"🔴 KARANLIK SON\n(Sürünün Başına Geç)",
		Color(0.9, 0.2, 0.2),
		"Geçmişinizdeki karanlığı kabullenin, kuleyi kullanarak virüsü tüm dünyaya yayın ve sürünün başına geçin...",
		3
	)
	
	hud.add_child(ending_panel)
	
	# Fade in panel
	ending_panel.modulate.a = 0.0
	var tween = ending_panel.create_tween()
	tween.tween_property(ending_panel, "modulate:a", 1.0, 1.2)

func _show_specific_ending(main_panel: PanelContainer, ending_id: int, player: CharacterBody3D) -> void:
	# Clear children of main_panel's margin vbox
	var margin = main_panel.get_child(0) as MarginContainer
	var vbox = margin.get_child(0) as VBoxContainer
	for child in vbox.get_children():
		child.queue_free()
		
	var title_text = ""
	var color = Color.WHITE
	var lore_text = ""
	
	match ending_id:
		1:
			title_text = "🟢 İYİ SON: Şehrin Küllerinden Doğuşu"
			color = Color(0.3, 0.9, 0.3)
			lore_text = "Radyo vericisine yaklaştınız, frekansı ayarladınız ve dış dünyaya ilk umut mesajınızı gönderdiniz: 'Biz hayatta kaldık. Şehir merkezindeki sığınak güvenli.'\n\nGünler geçtikçe çağrınıza kulak veren onlarca afetzede sığınağınıza ulaştı. Dr. Selim gelenlerin tedavisiyle ilgilendi, Çavuş Demir savunma hattını güçlendirdi ve Kaya Usta yeni sığınak binaları inşa etti. Salgını yayan formülü imha ettiniz ve insanlığa olan borcunuzu ödediniz. Şehir tamamen kurtulmadı ama artık hayatta kalanların yeşerebileceği güvenli bir vaha, Ghost Alley'nin küllerinden doğan yeni bir umut var...\n\nTEBRİKLER! İYİ SONA ULAŞTINIZ."
		2:
			title_text = "🟡 NÖTR SON: Sessiz Ayrılık"
			color = Color(0.9, 0.8, 0.2)
			lore_text = "Araştırma belgelerini ve virüsün antivirüs formülünü sırt çantanıza yerleştirdiniz. Radyo kulesine veya sığınaktaki arkadaşlarınıza dönüp bakmadınız bile. Şehrin bu lanetli sokaklarında yaşanacak bir gelecek yoktu.\n\nGece çökerken, sığınağın arka kapısından sessizce çıktınız ve batı sınırından şehri terk ettiniz. Dış dünyada, virüsün ulaşamadığı uzak dağlarda formülle ne yapacağınız tamamen size kalmış. Arkadaşlarınız sizin gittiğinizi sabah fark edecekler, belki size kızacaklar belki de anlayacaklar. Artık bir evsiz değil, insanlığın kaderini çantasında taşıyan isimsiz bir yolcusunuz...\n\nTEBRİKLER! NÖTR SONA ULAŞTINIZ."
		3:
			title_text = "🔴 KARANLIK SON: Sürünün Yeni Efendisi"
			color = Color(0.9, 0.2, 0.2)
			lore_text = "Radyo kumanda paneline yürüdünüz ve kilitli kodları girdiniz. Gözlerinizdeki suçluluk yerini karanlık bir kararlılığa bıraktı. 'Eğer bu virüsü ben yarattıysam, onun getireceği yeni dünyayı da ben yönetmeliyim' diye fısıldadınız.\n\nSirenleri açarak virüsü radyo dalgalarıyla dış dünyaya yayma emrini verdiniz ve sığınağın kapılarını tamamen açarak sürüyü içeri davet ettiniz. Zombiler size saldırmak yerine etrafınızda diz çöktüler. Siz artık bir hayatta kalan değilsiniz; salgını kontrol eden, sürüyü yönlendiren ve Ghost Alley'nin karanlık kıyametine hükmeden yeni efendisiniz...\n\nTEBRİKLER! KARANLIK SONA ULAŞTINIZ."
			
	# Update Main Panel borders color to match ending
	var style = main_panel.get_theme_stylebox("panel") as StyleBoxFlat
	if style:
		style = style.duplicate() as StyleBoxFlat
		style.border_color = color
		main_panel.add_theme_stylebox_override("panel", style)
		
	# Add Title
	var title = Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", color)
	vbox.add_child(title)
	
	var sep = HSeparator.new()
	vbox.add_child(sep)
	
	# ScrollContainer for Lore Text
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 180)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	
	var lore_label = Label.new()
	lore_label.text = lore_text
	lore_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lore_label.add_theme_font_size_override("font_size", 12)
	lore_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	lore_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(lore_label)
	
	# Continue in Infinite Mode Button
	var cont_btn = Button.new()
	cont_btn.text = "♾️ Sonsuz Hayatta Kalma Moduna Geç"
	cont_btn.custom_minimum_size = Vector2(250, 45)
	cont_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	var btn_style_cont = StyleBoxFlat.new()
	btn_style_cont.bg_color = Color(0.15, 0.2, 0.25, 0.9)
	btn_style_cont.border_width_left = 1
	btn_style_cont.border_width_top = 1
	btn_style_cont.border_width_right = 1
	btn_style_cont.border_width_bottom = 1
	btn_style_cont.border_color = color
	btn_style_cont.corner_radius_top_left = 6
	btn_style_cont.corner_radius_top_right = 6
	btn_style_cont.corner_radius_bottom_left = 6
	btn_style_cont.corner_radius_bottom_right = 6
	cont_btn.add_theme_stylebox_override("normal", btn_style_cont)
	cont_btn.add_theme_color_override("font_color", color)
	vbox.add_child(cont_btn)
	
	cont_btn.pressed.connect(func():
		var tween = main_panel.create_tween()
		tween.tween_property(main_panel, "modulate:a", 0.0, 0.8)
		tween.tween_callback(main_panel.queue_free)
		player.is_ui_open = false
		player.show_notification("Hikaye tamamlandı! Sonsuz Hayatta Kalma Modu aktif.", Color(0.3, 0.8, 0.9))
	)
