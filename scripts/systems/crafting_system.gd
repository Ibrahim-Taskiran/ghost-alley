extends RefCounted
class_name CraftingSystem

var recipes: Dictionary = {
	"sopa": {
		"result_id": "sopa",
		"result_qty": 1,
		"ingredients": { "tahta": 3 },
		"requirements": {},
		"xp_reward": 10
	},
	"bandaj": {
		"result_id": "bandaj",
		"result_qty": 1,
		"ingredients": { "kumas": 2 },
		"requirements": {},
		"xp_reward": 10
	},
	"bicak": {
		"result_id": "bicak",
		"result_qty": 1,
		"ingredients": { "metal": 2, "tahta": 1 },
		"requirements": { "strength": 1 },
		"xp_reward": 20
	}
}

func can_craft(recipe_id: String, inventory: Inventory, player_stats: Dictionary) -> bool:
	if not recipes.has(recipe_id):
		return false
		
	var recipe = recipes[recipe_id]
	
	# 1. Check ingredients
	for ing_id in recipe["ingredients"]:
		var needed = recipe["ingredients"][ing_id]
		if not inventory.has_item(ing_id, needed):
			return false
			
	# 2. Check requirements
	for stat in recipe["requirements"]:
		var req_val = recipe["requirements"][stat]
		if player_stats.get(stat, 0) < req_val:
			return false
			
	# 3. Check if inventory has room for the result
	if not inventory.can_add_item(recipe["result_id"], recipe["result_qty"]):
		return false
		
	return true

func craft(recipe_id: String, inventory: Inventory, player: CharacterBody3D) -> bool:
	var stats = player.stats if "stats" in player else {}
	if not can_craft(recipe_id, inventory, stats):
		return false
		
	var recipe = recipes[recipe_id]
	
	# Consume ingredients
	for ing_id in recipe["ingredients"]:
		var needed = recipe["ingredients"][ing_id]
		inventory.remove_item(ing_id, needed)
		
	# Add result item
	inventory.add_item(recipe["result_id"], recipe["result_qty"])
	
	# Give XP reward
	if player.has_node("XPSystem"):
		player.get_node("XPSystem").gain_xp(recipe["xp_reward"])
		
	return true
