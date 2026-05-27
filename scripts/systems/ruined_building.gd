extends StructureBase
class_name RuinedBuilding

# GDD §4.1 & GDD §3.3: Ruined Building Repair System
# Stage 1: Harap (200 HP, Tamir: 20 Tahta veya 10 Metal)
# Stage 2: Tamir Edilmiş (500 HP, Yükseltme: 50 Tahta + 20 Metal)

var stage: int = 1 # 1 = Harap, 2 = Tamir Edilmiş

func _ready() -> void:
	structure_name = "Harap Bina Duvarı"
	max_health = 200.0
	health = 50.0 # Harap halde başlar, yarım can
	
	build_material_id = "tahta"
	build_cost = 20 # Yıkıldığında 10 tahta verir
	
	super._ready()
	
	# Harap bina için özel görsel (koyu kahverengi/çatlak teması)
	await get_tree().process_frame
	_update_stage_visuals()

func _update_stage_visuals() -> void:
	if not mesh_instance:
		return
	var mat = mesh_instance.material_override as StandardMaterial3D
	if mat:
		if stage == 1:
			_orig_color = Color(0.4, 0.25, 0.15) # Harap kahverengisi
		else:
			_orig_color = Color(0.7, 0.7, 0.7) # Sağlam beton grisi
		_update_visuals()

func repair(player: CharacterBody3D) -> void:
	if is_destroyed:
		return
		
	var eng_level = player.stats.get("engineering", 1)
	var final_heal = repair_heal_amount * (1.0 + (eng_level - 1) * 0.15)
	if NPCManager.has_npc("engineer"):
		final_heal *= 1.3
		
	if stage == 1:
		# Aşama 1: Harap tamiri (20 Tahta veya 10 Metal ister)
		if health >= max_health:
			# Aşama 2'ye yükseltme tetiklenebilir
			_upgrade_to_stage_2(player)
			return
			
		# Envanterde tahta veya metal var mı kontrol et
		var has_tahta = player.inventory.has_item("tahta", 20)
		var has_metal = player.inventory.has_item("metal", 10)
		
		if has_tahta or has_metal:
			var mat_used = "tahta" if has_tahta else "metal"
			var cost = 20 if has_tahta else 10
			player.inventory.remove_item(mat_used, cost)
			
			health = clamp(health + final_heal * 2.0, 0.0, max_health) # Yıkık bina tamiri daha büyük can verir
			health_changed.emit(health, max_health)
			_update_visuals()
			
			player.show_notification("🏚️ Bina Duvarı onarılıyor! (%d/%d HP)" % [int(health), int(max_health)], Color(0.3, 0.8, 0.3))
		else:
			player.show_notification("🏚️ Tamir için 20 Tahta veya 10 Metal gerekir!", Color(0.9, 0.3, 0.3))
			
	elif stage == 2:
		# Aşama 2: Sağlam bina tamiri (Zaten max cana ulaşmışsa işlem yapma)
		if health >= max_health:
			player.show_notification("Bina tamamen onarıldı ve sapasağlam!", Color(0.3, 0.9, 0.3))
			return
			
		# Normal tamir malzemesi olarak metal×5 kullan
		if player.inventory.has_item("metal", 5):
			player.inventory.remove_item("metal", 5)
			health = clamp(health + final_heal, 0.0, max_health)
			health_changed.emit(health, max_health)
			_update_visuals()
			player.show_notification("🔧 Onarılmış Bina güçlendirildi! (+%d HP)" % int(final_heal), Color(0.3, 0.8, 0.3))
		else:
			player.show_notification("Onarım için 5 Metal gerekir!", Color(0.9, 0.3, 0.3))

func _upgrade_to_stage_2(player: CharacterBody3D) -> void:
	# Aşama 2 yükseltme maliyeti: 50 tahta ve 20 metal
	var has_wood = player.inventory.has_item("tahta", 50)
	var has_metal = player.inventory.has_item("metal", 20)
	
	if has_wood and has_metal:
		player.inventory.remove_item("tahta", 50)
		player.inventory.remove_item("metal", 20)
		
		stage = 2
		structure_name = "Tamir Edilmiş Bina"
		max_health = 500.0
		health = 200.0 # Yükseltme sonrası başlangıç canı
		
		_update_stage_visuals()
		health_changed.emit(health, max_health)
		
		player.show_notification("🏗️ BİNA AŞAMA 2'YE YÜKSELTİLDİ! Artık sapasağlam (500 HP max)", Color(0.3, 0.9, 0.3))
		if player.has_node("XPSystem"):
			player.get_node("XPSystem").gain_xp(50) # Büyük XP ödülü!
	else:
		player.show_notification("🏗️ Yükseltme için 50 Tahta ve 20 Metal gerekir!", Color(0.9, 0.4, 0.2))

# Hasar aldığında yok olma davranışı
func _destroy() -> void:
	is_destroyed = true
	destroyed.emit()
	
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		players[0].show_notification("⚠️ UYARI: Bir bina duvarı çöktü!", Color(0.9, 0.2, 0.2))
		
	queue_free()
