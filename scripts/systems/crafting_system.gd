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
	},
	"el_yapimi_tabanca": {
		"result_id": "el_yapimi_tabanca",
		"result_qty": 1,
		"ingredients": { "metal": 5, "plastik": 2, "barut_kovan": 2 },
		"requirements": { "military": 1 },
		"xp_reward": 30
	},
	"civili_sopa": {
		"result_id": "civili_sopa",
		"result_qty": 1,
		"ingredients": { "tahta": 3, "metal": 2 },
		"requirements": { "strength": 2 },
		"xp_reward": 15
	},
	"molotof": {
		"result_id": "molotof",
		"result_qty": 1,
		"ingredients": { "yakit": 1, "kumas": 1 },
		"requirements": {},
		"xp_reward": 15
	},
	"arbalet": {
		"result_id": "arbalet",
		"result_qty": 1,
		"ingredients": { "tahta": 5, "metal": 3, "plastik": 2 },
		"requirements": { "military": 2 },
		"xp_reward": 35
	},
	"jenerator": {
		"result_id": "jenerator",
		"result_qty": 1,
		"ingredients": { "metal": 10, "elektronik": 4, "plastik": 3 },
		"requirements": { "engineering": 2 },
		"xp_reward": 50
	},
	"projektor": {
		"result_id": "projektor",
		"result_qty": 1,
		"ingredients": { "metal": 5, "elektronik": 2, "plastik": 2 },
		"requirements": { "engineering": 1 },
		"xp_reward": 30
	},
	"taret": {
		"result_id": "taret",
		"result_qty": 1,
		"ingredients": { "metal": 10, "elektronik": 5, "plastik": 3, "barut_kovan": 5 },
		"requirements": { "engineering": 3, "military": 2 },
		"xp_reward": 60
	},
	"matara": {
		"result_id": "matara",
		"result_qty": 1,
		"ingredients": { "plastik": 3, "su": 1 },
		"requirements": {},
		"xp_reward": 10
	},
	"ilkyardim_cantasi": {
		"result_id": "ilkyardim_cantasi",
		"result_qty": 1,
		"ingredients": { "bandaj": 2, "kimyasal": 2, "plastik": 1 },
		"requirements": { "intelligence": 2 },
		"xp_reward": 40
	},
	"duvar_ahsap": {
		"result_id": "duvar_ahsap",
		"result_qty": 1,
		"ingredients": { "tahta": 4 },
		"requirements": {},
		"xp_reward": 10
	},
	"duvar_metal": {
		"result_id": "duvar_metal",
		"result_qty": 1,
		"ingredients": { "metal": 4 },
		"requirements": { "engineering": 1 },
		"xp_reward": 15
	},
	"kapi_ahsap": {
		"result_id": "kapi_ahsap",
		"result_qty": 1,
		"ingredients": { "tahta": 6 },
		"requirements": {},
		"xp_reward": 12
	},
	"kapi_metal": {
		"result_id": "kapi_metal",
		"result_qty": 1,
		"ingredients": { "metal": 6, "elektronik": 1 },
		"requirements": { "engineering": 2 },
		"xp_reward": 20
	},
	"zemin": {
		"result_id": "zemin",
		"result_qty": 1,
		"ingredients": { "tahta": 2 },
		"requirements": {},
		"xp_reward": 5
	},
	"cati": {
		"result_id": "cati",
		"result_qty": 1,
		"ingredients": { "tahta": 3 },
		"requirements": {},
		"xp_reward": 8
	},
	"siginak_bayragi": {
		"result_id": "siginak_bayragi",
		"result_qty": 1,
		"ingredients": { "tahta": 5, "kumas": 3, "elektronik": 1 },
		"requirements": { "engineering": 1 },
		"xp_reward": 25
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
