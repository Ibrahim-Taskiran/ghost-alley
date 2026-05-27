extends Control
class_name CraftingUI

@onready var recipe_list: VBoxContainer = $BackgroundPanel/MarginContainer/VBoxContainer/Content/LeftPanel/ScrollContainer/RecipeList

# Details Panel
@onready var recipe_title: Label = $BackgroundPanel/MarginContainer/VBoxContainer/Content/RightPanel/DetailsBox/Margin/DetailsVBox/RecipeTitle
@onready var recipe_desc: Label = $BackgroundPanel/MarginContainer/VBoxContainer/Content/RightPanel/DetailsBox/Margin/DetailsVBox/RecipeDesc
@onready var ingredients_list: VBoxContainer = $BackgroundPanel/MarginContainer/VBoxContainer/Content/RightPanel/DetailsBox/Margin/DetailsVBox/IngredientsList
@onready var requirements_list: VBoxContainer = $BackgroundPanel/MarginContainer/VBoxContainer/Content/RightPanel/DetailsBox/Margin/DetailsVBox/RequirementsList
@onready var craft_button: Button = $BackgroundPanel/MarginContainer/VBoxContainer/Content/RightPanel/CraftButton

var _player: CharacterBody3D = null
var _inventory: Inventory = null
var _crafting_system: CraftingSystem = null
var _selected_recipe_id: String = ""

func _ready() -> void:
	add_to_group("CraftingUI")
	hide()
	_crafting_system = CraftingSystem.new()
	
	await get_tree().process_frame
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		_player = players[0]
		_inventory = _player.inventory
		_inventory.inventory_changed.connect(_on_inventory_changed)
		
	_clear_details()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("crafting"):
		if visible:
			close_crafting()
		else:
			open_crafting()

func open_crafting() -> void:
	_populate_recipes()
	show()
	scale = Vector2(0.9, 0.9)
	modulate.a = 0.0
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.15)
	
	if _player:
		_player.is_ui_open = true

func open_crafting_filtered(material_id: String) -> void:
	_populate_recipes_filtered(material_id)
	show()
	scale = Vector2(0.9, 0.9)
	modulate.a = 0.0
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.15)
	
	if _player:
		_player.is_ui_open = true

func _populate_recipes_filtered(material_id: String) -> void:
	if not recipe_list or not _inventory:
		return
		
	# Clear
	for child in recipe_list.get_children():
		child.queue_free()
		
	# Populate
	var first_recipe = ""
	for recipe_id in _crafting_system.recipes:
		var recipe = _crafting_system.recipes[recipe_id]
		if not recipe["ingredients"].has(material_id):
			continue
			
		var item_data = ItemDatabase.get_item(recipe["result_id"])
		if item_data.is_empty():
			continue
			
		if first_recipe == "":
			first_recipe = recipe_id
			
		var button = Button.new()
		button.text = item_data["name"]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(0, 40)
		
		# Stylize button based on selection and feasibility
		var can_craft_this = _crafting_system.can_craft(recipe_id, _inventory, _player.stats)
		if can_craft_this:
			button.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))
		else:
			button.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
			
		if recipe_id == _selected_recipe_id:
			button.button_pressed = true
			
		button.pressed.connect(func():
			_selected_recipe_id = recipe_id
			_show_recipe_details(recipe_id)
		)
		
		recipe_list.add_child(button)
		
	# Select the first recipe in the filtered list if found
	if first_recipe != "":
		_selected_recipe_id = first_recipe
		_show_recipe_details(first_recipe)
	else:
		_clear_details()
		recipe_title.text = "Üretilebilecek Eşya Yok"
		recipe_desc.text = "Envanterinizdeki bu malzeme ile doğrudan üretilebilecek bir tarif bulunmuyor."

func close_crafting() -> void:
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(0.9, 0.9), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.12)
	await tween.finished
	hide()
	if _player:
		_player.is_ui_open = false

func _on_close_button_pressed() -> void:
	close_crafting()

func _on_inventory_changed() -> void:
	if visible:
		_populate_recipes()
		if _selected_recipe_id != "":
			_show_recipe_details(_selected_recipe_id)

func _populate_recipes() -> void:
	if not recipe_list or not _inventory:
		return
		
	# Clear
	for child in recipe_list.get_children():
		child.queue_free()
		
	# Populate
	for recipe_id in _crafting_system.recipes:
		var recipe = _crafting_system.recipes[recipe_id]
		var item_data = ItemDatabase.get_item(recipe["result_id"])
		if item_data.is_empty():
			continue
			
		var button = Button.new()
		button.text = item_data["name"]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(0, 40)
		
		# Stylize button based on selection and feasibility
		var can_craft_this = _crafting_system.can_craft(recipe_id, _inventory, _player.stats)
		if can_craft_this:
			button.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5)) # Green text if craftable!
		else:
			button.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
			
		if recipe_id == _selected_recipe_id:
			button.button_pressed = true
			
		button.pressed.connect(func():
			_selected_recipe_id = recipe_id
			_show_recipe_details(recipe_id)
		)
		
		recipe_list.add_child(button)

func _clear_details() -> void:
	recipe_title.text = "Tarif Seçin"
	recipe_desc.text = "Sol taraftan bir tarif seçerek malzemelerini görebilirsiniz."
	
	for child in ingredients_list.get_children():
		child.queue_free()
	for child in requirements_list.get_children():
		child.queue_free()
		
	craft_button.disabled = true

func _show_recipe_details(recipe_id: String) -> void:
	# Clear lists first
	for child in ingredients_list.get_children():
		child.queue_free()
	for child in requirements_list.get_children():
		child.queue_free()
		
	if not _crafting_system.recipes.has(recipe_id):
		_clear_details()
		return
		
	var recipe = _crafting_system.recipes[recipe_id]
	var item_data = ItemDatabase.get_item(recipe["result_id"])
	
	recipe_title.text = item_data["name"] + " (x%d)" % recipe["result_qty"]
	recipe_desc.text = item_data["description"]
	
	# Populate Ingredients
	var all_ingredients_available = true
	for ing_id in recipe["ingredients"]:
		var needed = recipe["ingredients"][ing_id]
		var ing_data = ItemDatabase.get_item(ing_id)
		
		# Count player inventory count
		var player_has = 0
		for slot in _inventory.slots:
			if slot["item_id"] == ing_id:
				player_has += slot["quantity"]
				
		var label = Label.new()
		label.add_theme_font_size_override("font_size", 12)
		
		if player_has >= needed:
			label.text = "✓ %s (%d/%d)" % [ing_data["name"], player_has, needed]
			label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3))
		else:
			label.text = "✗ %s (%d/%d)" % [ing_data["name"], player_has, needed]
			label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
			all_ingredients_available = false
			
		ingredients_list.add_child(label)
		
	# Populate Requirements
	var requirements_met = true
	for stat_name in recipe["requirements"]:
		var needed_val = recipe["requirements"][stat_name]
		var player_val = _player.stats.get(stat_name, 0)
		
		var label = Label.new()
		label.add_theme_font_size_override("font_size", 12)
		
		var stat_tr = "Güç"
		if stat_name == "military": stat_tr = "Askeri"
		elif stat_name == "engineering": stat_tr = "Mühendislik"
		elif stat_name == "intelligence": stat_tr = "Zeka"
		
		if player_val >= needed_val:
			label.text = "✓ Gereksinim: %s %d (Mevcut: %d)" % [stat_tr, needed_val, player_val]
			label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3))
		else:
			label.text = "✗ Gereksinim: %s %d (Mevcut: %d)" % [stat_tr, needed_val, player_val]
			label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
			requirements_met = false
			
		requirements_list.add_child(label)
		
	# Enable/Disable button
	var can_add = _inventory.can_add_item(recipe["result_id"], recipe["result_qty"])
	if not can_add:
		craft_button.text = "ENVANTER DOLU!"
		craft_button.disabled = true
	elif all_ingredients_available and requirements_met:
		craft_button.text = "ÜRET"
		craft_button.disabled = false
	else:
		craft_button.text = "EKSİK MALZEME / STAT"
		craft_button.disabled = true

func _on_craft_button_pressed() -> void:
	if _selected_recipe_id == "":
		return
		
	if _crafting_system.craft(_selected_recipe_id, _inventory, _player):
		var item_data = ItemDatabase.get_item(_crafting_system.recipes[_selected_recipe_id]["result_id"])
		_player.show_notification("%s üretildi!" % item_data["name"], Color(0.3, 0.8, 0.3))
		_populate_recipes()
		_show_recipe_details(_selected_recipe_id)
