extends RefCounted
class_name Inventory

signal inventory_changed

var slots: Array = []
var max_slots: int = 6

func _init(capacity: int = 6) -> void:
	max_slots = capacity
	slots.resize(max_slots)
	for i in range(max_slots):
		slots[i] = {"item_id": "", "quantity": 0}

func add_item(item_id: String, quantity: int) -> bool:
	var item_data = ItemDatabase.get_item(item_id)
	if item_data.is_empty() or quantity <= 0:
		return false
		
	var remaining = quantity
	
	# 1. Try to stack in existing slots if stackable
	if item_data.get("stackable", false):
		var max_stack = item_data.get("max_stack", 1)
		for i in range(max_slots):
			if slots[i]["item_id"] == item_id:
				var space = max_stack - slots[i]["quantity"]
				if space > 0:
					var add_amt = min(remaining, space)
					slots[i]["quantity"] += add_amt
					remaining -= add_amt
					if remaining <= 0:
						inventory_changed.emit()
						return true
						
	# 2. Add to empty slots
	if remaining > 0:
		for i in range(max_slots):
			if slots[i]["item_id"] == "":
				var max_stack = item_data.get("max_stack", 1)
				var add_amt = min(remaining, max_stack)
				slots[i] = {"item_id": item_id, "quantity": add_amt}
				remaining -= add_amt
				if remaining <= 0:
					inventory_changed.emit()
					return true
					
	inventory_changed.emit()
	return remaining < quantity # Return true if at least some were added

func has_item(item_id: String, quantity: int = 1) -> bool:
	var count = 0
	for slot in slots:
		if slot["item_id"] == item_id:
			count += slot["quantity"]
	return count >= quantity

func remove_item(item_id: String, quantity: int = 1) -> bool:
	if not has_item(item_id, quantity):
		return false
		
	var remaining = quantity
	for i in range(max_slots - 1, -1, -1): # Scan backwards to remove
		if slots[i]["item_id"] == item_id:
			if slots[i]["quantity"] > remaining:
				slots[i]["quantity"] -= remaining
				remaining = 0
				break
			else:
				remaining -= slots[i]["quantity"]
				slots[i] = {"item_id": "", "quantity": 0}
			if remaining <= 0:
				break
				
	inventory_changed.emit()
	return true

func remove_item_at(index: int, quantity: int = 1) -> bool:
	if index < 0 or index >= max_slots:
		return false
	if slots[index]["item_id"] == "" or slots[index]["quantity"] < quantity:
		return false
		
	slots[index]["quantity"] -= quantity
	if slots[index]["quantity"] <= 0:
		slots[index] = {"item_id": "", "quantity": 0}
		
	inventory_changed.emit()
	return true

func can_add_item(item_id: String, quantity: int) -> bool:
	var item_data = ItemDatabase.get_item(item_id)
	if item_data.is_empty():
		return false
		
	var remaining = quantity
	if item_data.get("stackable", false):
		var max_stack = item_data.get("max_stack", 1)
		for slot in slots:
			if slot["item_id"] == item_id:
				remaining -= (max_stack - slot["quantity"])
				if remaining <= 0:
					return true
					
	# Check empty slots
	var empty_slots_needed = 0
	if remaining > 0:
		var max_stack = item_data.get("max_stack", 1)
		empty_slots_needed = ceil(float(remaining) / max_stack)
		
	var empty_slots = 0
	for slot in slots:
		if slot["item_id"] == "":
			empty_slots += 1
			
	return empty_slots >= empty_slots_needed

func swap_slots(idx1: int, idx2: int) -> void:
	if idx1 < 0 or idx1 >= max_slots or idx2 < 0 or idx2 >= max_slots:
		return
	var temp = slots[idx1]
	slots[idx1] = slots[idx2]
	slots[idx2] = temp
	inventory_changed.emit()

func get_total_items() -> int:
	var count = 0
	for slot in slots:
		if slot["item_id"] != "":
			count += 1
	return count

