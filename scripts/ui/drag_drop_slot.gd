extends PanelContainer

## Envanter Sürükleme Scripti (Drag and Drop — Faz 4)
## Eşyanın envanter slotundan sürüklenip bırakılmasını sağlar.

var slot_index: int = -1
var inventory_ui: Control = null

func _get_drag_data(_at_position: Vector2) -> Variant:
	if slot_index == -1 or not inventory_ui:
		return null
		
	var inventory = inventory_ui.get("_inventory")
	if not inventory:
		return null
		
	var slot_data = inventory.slots[slot_index]
	var item_id = slot_data["item_id"]
	if item_id == "":
		return null
		
	# Sürükleme sırasında farenin altında görünecek önizleme etiketi
	var preview_panel = PanelContainer.new()
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
	var item_data = ItemDatabase.get_item(item_id)
	label.text = " 📌 %s " % item_data.get("name", "Eşya")
	label.add_theme_font_size_override("font_size", 10)
	preview_panel.add_child(label)
	
	set_drag_preview(preview_panel)
	
	# Sürüklenen veriyi aktar
	return {"item_id": item_id, "source_slot_index": slot_index}
