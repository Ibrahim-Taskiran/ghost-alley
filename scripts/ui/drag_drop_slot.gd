extends PanelContainer

## Envanter Sürükleme Scripti (Drag and Drop — Faz 4)
## Eşyanın envanter slotundan sürüklenip bırakılmasını sağlar.

var slot_index: int = -1
var inventory_ui: Control = null

func _get_drag_data(_at_position: Vector2) -> Variant:
	print("[DragDropSlot] _get_drag_data tetiklendi, slot_index: ", slot_index)
	if slot_index == -1 or not inventory_ui:
		print("[DragDropSlot] Hata: slot_index veya inventory_ui tanımlı değil!")
		return null
		
	var inventory = inventory_ui.get("_inventory")
	if not inventory:
		print("[DragDropSlot] Hata: inventory nesnesi bulunamadı!")
		return null
		
	var slot_data = inventory.slots[slot_index]
	var item_id = slot_data["item_id"]
	if item_id == "":
		print("[DragDropSlot] Hata: Boş slot sürüklenmeye çalışıldı.")
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
	return {"item_id": item_id, "source_slot_index": slot_index}

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("source_slot_index")

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if slot_index == -1 or not inventory_ui:
		return
		
	var inventory = inventory_ui.get("_inventory")
	if not inventory:
		return
		
	var source_idx = data["source_slot_index"]
	if source_idx != -1 and source_idx != slot_index:
		# Swapping items natively inside the inventory (which includes backpack and pockets!)
		inventory.swap_slots(source_idx, slot_index)
		
		# Force redraw of both backpack and hotbar
		inventory_ui.call("update_ui")
		var hud = get_tree().get_first_node_in_group("HUD")
		if hud and hud.has_method("update_hotbar_ui"):
			hud.call("update_hotbar_ui")
