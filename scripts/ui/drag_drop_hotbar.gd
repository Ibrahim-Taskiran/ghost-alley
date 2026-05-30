extends PanelContainer

## Hotbar Drop Scripti (Drag and Drop — Faz 4)
## Sürüklenen envanter eşyasını hotbar slotunun üzerine bıraktığımızda kısayola atama yapar.

var hotbar_index: int = -1
var hud: CanvasLayer = null

func _get_drag_data(_at_position: Vector2) -> Variant:
	print("[DragDropHotbar] _get_drag_data tetiklendi, hotbar_index: ", hotbar_index)
	if hotbar_index == -1 or not hud:
		print("[DragDropHotbar] Hata: hotbar_index veya hud tanımlı değil!")
		return null
		
	var player = hud.get("_player")
	if not player or not player.inventory:
		print("[DragDropHotbar] Hata: player veya inventory nesnesi bulunamadı!")
		return null
		
	var pocket_idx = 16 + hotbar_index
	var slot_data = player.inventory.slots[pocket_idx]
	var item_id = slot_data["item_id"]
	if item_id == "":
		print("[DragDropHotbar] Hata: Boş cep sürüklenmeye çalışıldı.")
		return null
		
	# Sürükleme sırasında farenin altında görünecek önizleme etiketi
	var preview_panel = PanelContainer.new()
	preview_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.6, 0.9, 0.45) # Yarı saydam neon mavi
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.12, 0.6, 0.9, 0.8)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	preview_panel.add_theme_stylebox_override("panel", style)
	
	var label = Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var item_data = ItemDatabase.get_item(item_id)
	label.text = " 📌 %s " % item_data.get("name", "Eşya")
	label.add_theme_font_size_override("font_size", 10)
	preview_panel.add_child(label)
	
	set_drag_preview(preview_panel)
	
	# Sürüklenen veriyi aktar
	return {"item_id": item_id, "source_slot_index": pocket_idx}

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	print("[DragDropHotbar] _can_drop_data tetiklendi, hotbar_index: ", hotbar_index, " veri: ", data)
	return data is Dictionary and data.has("item_id") and data.has("source_slot_index")

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	print("[DragDropHotbar] _drop_data tetiklendi, hotbar_index: ", hotbar_index, " veri: ", data)
	if hotbar_index == -1 or not hud:
		print("[DragDropHotbar] Hata: hotbar_index veya hud tanımlı değil!")
		return
		
	var player = hud.get("_player")
	if player and player.inventory:
		var source_idx = data.get("source_slot_index", -1)
		var dest_idx = 16 + hotbar_index
		
		if source_idx != -1 and source_idx != dest_idx:
			# Swapping items natively between backpack and pockets!
			player.inventory.swap_slots(source_idx, dest_idx)
			
			# Force update inventory UI too if visible
			var inv_ui = get_tree().get_first_node_in_group("InventoryUI") as InventoryUI
			if inv_ui:
				inv_ui.call("update_ui")
				
			var item_name = ItemDatabase.get_item(data["item_id"]).get("name", "Eşya")
			player.show_notification("📌 %s Cebe Yerleştirildi (Slot %d)" % [item_name, hotbar_index + 1], Color(0.12, 0.6, 0.9))
