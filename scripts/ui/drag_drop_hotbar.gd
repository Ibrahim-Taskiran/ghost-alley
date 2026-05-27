extends PanelContainer

## Hotbar Drop Scripti (Drag and Drop — Faz 4)
## Sürüklenen envanter eşyasını hotbar slotunun üzerine bıraktığımızda kısayola atama yapar.

var hotbar_index: int = -1
var hud: Control = null

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	# Sürüklenen verinin geçerli bir eşya içerdiğini doğrula
	return data is Dictionary and data.has("item_id")

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if hotbar_index == -1 or not hud:
		return
		
	var item_id = data["item_id"]
	var player = hud.get("_player")
	if player and "hotbar" in player:
		# Oyuncunun hotbar verisinde ilgili kısayol slotuna eşyayı kaydet
		player.hotbar[hotbar_index] = item_id
		
		# Arayüzü anlık güncelle
		hud.update_hotbar_ui()
		
		var item_name = ItemDatabase.get_item(item_id).get("name", "Eşya")
		player.show_notification("📌 %s Kısayol Slot %d'e atandı!" % [item_name, hotbar_index + 1], Color(0.12, 0.6, 0.9))
