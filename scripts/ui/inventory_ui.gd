extends Control
class_name InventoryUI

@onready var grid_container: GridContainer = $BackgroundPanel/MarginContainer/VBoxContainer/Grid
@onready var title_label: Label = $BackgroundPanel/MarginContainer/VBoxContainer/Header/Title

var _player: CharacterBody3D = null
var _inventory: Inventory = null

func _ready() -> void:
	# Hide by default
	hide()
	
	# Find player and connect
	await get_tree().process_frame
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		_player = players[0]
		_inventory = _player.inventory
		_inventory.inventory_changed.connect(update_ui)
		update_ui()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		if visible:
			close_inventory()
		else:
			open_inventory()

func open_inventory() -> void:
	update_ui()
	show()
	# Play a subtle scale and fade-in animation using tween
	scale = Vector2(0.9, 0.9)
	modulate.a = 0.0
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.15)
	
	# Pause player action if needed (but keep world running)
	if _player:
		_player.is_ui_open = true

func close_inventory() -> void:
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(0.9, 0.9), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.12)
	await tween.finished
	hide()
	if _player:
		_player.is_ui_open = false

func _on_close_button_pressed() -> void:
	close_inventory()

func update_ui() -> void:
	if not _inventory or not grid_container:
		return
		
	# Update title
	title_label.text = "Cepler (%d/%d Slot)" % [_inventory.get_total_items(), _inventory.max_slots]
	
	# Clear existing children
	for child in grid_container.get_children():
		child.queue_free()
		
	# Populate grid slots
	for i in range(_inventory.max_slots):
		var slot_data = _inventory.slots[i]
		var item_id = slot_data["item_id"]
		var quantity = slot_data["quantity"]
		
		# Slot Container panel
		var slot_panel = PanelContainer.new()
		slot_panel.custom_minimum_size = Vector2(80, 80)
		
		# Premium style for slots
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.12, 0.13, 0.16, 0.85)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.24, 0.26, 0.32, 1.0)
		style.corner_radius_top_left = 6
		style.corner_radius_top_right = 6
		style.corner_radius_bottom_left = 6
		style.corner_radius_bottom_right = 6
		slot_panel.add_theme_stylebox_override("panel", style)
		
		grid_container.add_child(slot_panel)
		
		if item_id != "":
			var item = ItemDatabase.get_item(item_id)
			
			# Setup color coding based on type
			var bg_color = Color(0.2, 0.22, 0.26, 0.9)
			match item["type"]:
				ItemDatabase.ItemType.FOOD, ItemDatabase.ItemType.WATER:
					bg_color = Color(0.14, 0.24, 0.2, 0.9) # Emerald Green tint
				ItemDatabase.ItemType.MEDICINE:
					bg_color = Color(0.28, 0.14, 0.14, 0.9) # Crimson Red tint
				ItemDatabase.ItemType.WEAPON:
					bg_color = Color(0.22, 0.14, 0.28, 0.9) # Purple tint
				ItemDatabase.ItemType.MATERIAL:
					bg_color = Color(0.24, 0.22, 0.16, 0.9) # Gold/Bronze tint
				ItemDatabase.ItemType.TOOL:
					bg_color = Color(0.16, 0.22, 0.28, 0.9) # Teal tint
					
			style.bg_color = bg_color
			
			# Inside margin
			var margin = MarginContainer.new()
			margin.add_theme_constant_override("margin_left", 6)
			margin.add_theme_constant_override("margin_top", 6)
			margin.add_theme_constant_override("margin_right", 6)
			margin.add_theme_constant_override("margin_bottom", 6)
			slot_panel.add_child(margin)
			
			# VBox inside margin to layout elements
			var vbox = VBoxContainer.new()
			margin.add_child(vbox)
			
			# Item Initial / Label
			var name_label = Label.new()
			name_label.text = item["name"]
			name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			name_label.add_theme_font_size_override("font_size", 11)
			name_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
			vbox.add_child(name_label)
			
			# Quantity Label (bottom right style)
			if quantity > 1:
				var qty_hbox = HBoxContainer.new()
				qty_hbox.alignment = BoxContainer.ALIGNMENT_END
				vbox.add_child(qty_hbox)
				
				var qty_label = Label.new()
				qty_label.text = "x%d" % quantity
				qty_label.add_theme_font_size_override("font_size", 10)
				qty_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
				qty_hbox.add_child(qty_label)
				
			# Setup tooltip
			var type_str = "Eşya"
			match item["type"]:
				ItemDatabase.ItemType.FOOD: type_str = "Yiyecek 🍖"
				ItemDatabase.ItemType.WATER: type_str = "İçecek 💧"
				ItemDatabase.ItemType.MEDICINE: type_str = "İlaç/Tıbbi 💊"
				ItemDatabase.ItemType.WEAPON: type_str = "Silah ⚔️"
				ItemDatabase.ItemType.MATERIAL: type_str = "Malzeme 🛠️"
				ItemDatabase.ItemType.TOOL: type_str = "Alet 🔦"
				
			slot_panel.tooltip_text = "%s [%s]\n---\n%s\n---\n[Sağ Tık] Kullan/Tüket\n[Shift + Sol Tık] Yere Bırak" % [item["name"], type_str, item["description"]]
			
			# Input interaction
			slot_panel.gui_input.connect(func(event: InputEvent):
				if event is InputEventMouseButton and event.pressed:
					if event.button_index == MOUSE_BUTTON_RIGHT:
						# Consume / Use item
						_use_item_at(i)
					elif event.button_index == MOUSE_BUTTON_LEFT and event.shift_pressed:
						# Drop item
						_drop_item_at(i)
			)
			
			# Add subtle hover/border effect
			slot_panel.mouse_entered.connect(func():
				style.border_color = Color(0.8, 0.6, 0.2, 1.0) # Golden border on hover
			)
			slot_panel.mouse_exited.connect(func():
				style.border_color = Color(0.24, 0.26, 0.32, 1.0)
			)
		else:
			# Empty slot empty tooltip
			slot_panel.tooltip_text = "Boş Slot"
			slot_panel.mouse_entered.connect(func():
				style.border_color = Color(0.4, 0.45, 0.5, 1.0)
			)
			slot_panel.mouse_exited.connect(func():
				style.border_color = Color(0.24, 0.26, 0.32, 1.0)
			)

func _use_item_at(index: int) -> void:
	if not _player or not _inventory:
		return
	
	var slot_data = _inventory.slots[index]
	var item_id = slot_data["item_id"]
	if item_id == "":
		return
		
	var item = ItemDatabase.get_item(item_id)
	var used = false
	
	# Apply effects to player
	var effects = item.get("effects", {})
	
	# Check stat requirements first (e.g. Weapon strength)
	var requirements = item.get("stat_requirements", {})
	if not requirements.is_empty():
		var player_stats = _player.stats if "stats" in _player else {"strength": 1}
		for stat_name in requirements:

			if player_stats.get(stat_name, 1) < requirements[stat_name]:
				# Can't use
				_player.show_notification("Yetersiz stat: %s %d gerekli!" % [stat_name.capitalize(), requirements[stat_name]], Color(0.9, 0.3, 0.3))
				return
				
	# Apply Hunger
	if effects.has("hunger") and _player.has_node("SurvivalNeeds"):
		_player.get_node("SurvivalNeeds").feed(effects["hunger"])
		_player.show_notification("Açlık giderildi: +%d" % effects["hunger"], Color(0.3, 0.8, 0.3))
		used = true
		
	# Apply Thirst
	if effects.has("thirst") and _player.has_node("SurvivalNeeds"):
		_player.get_node("SurvivalNeeds").quench(effects["thirst"])
		_player.show_notification("Susuzluk giderildi: +%d" % effects["thirst"], Color(0.3, 0.6, 0.9))
		used = true
		
	# Apply Healing
	if effects.has("heal"):
		_player.heal(effects["heal"])
		used = true
		
	# Cure infection
	if effects.get("cure_infection", false) and _player.has_node("InfectionSystem"):
		var cured = _player.get_node("InfectionSystem").cure()
		if cured:
			_player.show_notification("Enfeksiyon tedavi edildi!", Color(0.3, 0.8, 0.3))
			used = true
		else:
			_player.show_notification("Enfekte değilsiniz.", Color(0.8, 0.8, 0.8))
			return # Don't consume medicine if not infected
			
	# If weapon, equip it
	if item["type"] == ItemDatabase.ItemType.WEAPON:
		_player.equip_weapon(item_id, effects.get("damage", 10.0))
		_player.show_notification("Silah kuşanıldı: %s" % item["name"], Color(0.7, 0.4, 0.9))
		# Weapons are not consumed on use, they just equip!
		used = false
		
	# If used, consume 1
	if used:
		_inventory.remove_item_at(index, 1)

func _drop_item_at(index: int) -> void:
	if not _player or not _inventory:
		return
		
	var slot_data = _inventory.slots[index]
	var item_id = slot_data["item_id"]
	if item_id == "":
		return
		
	# Drop in world
	_player.drop_item_in_world(item_id, 1)
	_inventory.remove_item_at(index, 1)
	_player.show_notification("Eşya yere bırakıldı.", Color(0.8, 0.8, 0.8))

# Helper to connect inventory to exterior scripts
func get_total_items() -> int:
	if _inventory:
		return _inventory.get_total_items()
	return 0
