extends Node

enum ItemType { WEAPON, FOOD, WATER, MEDICINE, MATERIAL, TOOL, BOOK }

var database: Dictionary = {
	"konserve": {
		"name": "Konserve",
		"description": "Doyurucu konserve yiyecek. Açlığı azaltır.",
		"type": ItemType.FOOD,
		"stackable": true,
		"max_stack": 5,
		"weight": 0.5,
		"effects": { "hunger": 40.0 }
	},
	"su": {
		"name": "Su Şişesi",
		"description": "Temiz içme suyu. Susuzluğu giderir.",
		"type": ItemType.WATER,
		"stackable": true,
		"max_stack": 3,
		"weight": 0.5,
		"effects": { "thirst": 50.0 }
	},
	"bandaj": {
		"name": "Bandaj",
		"description": "Temiz bandaj. Sağlığı yeniler.",
		"type": ItemType.MEDICINE,
		"stackable": true,
		"max_stack": 5,
		"weight": 0.1,
		"effects": { "heal": 15.0 }
	},
	"antibiyotik": {
		"name": "Antibiyotik",
		"description": "Enfeksiyon tedavisinde hayati öneme sahip ilaç.",
		"type": ItemType.MEDICINE,
		"stackable": true,
		"max_stack": 3,
		"weight": 0.1,
		"effects": { "cure_infection": true }
	},
	"tahta": {
		"name": "Tahta",
		"description": "İnşaat ve üretimde kullanılan tahta parçası.",
		"type": ItemType.MATERIAL,
		"stackable": true,
		"max_stack": 20,
		"weight": 0.8,
		"effects": {}
	},
	"metal": {
		"name": "Metal Parçası",
		"description": "Dayanıklı metal hurda. İleri düzey crafting için.",
		"type": ItemType.MATERIAL,
		"stackable": true,
		"max_stack": 10,
		"weight": 1.2,
		"effects": {}
	},
	"kumas": {
		"name": "Kumaş",
		"description": "Bandaj yapımında kullanılan kumaş parçası.",
		"type": ItemType.MATERIAL,
		"stackable": true,
		"max_stack": 10,
		"weight": 0.1,
		"effects": {}
	},
	"bicak": {
		"name": "Av Bıçağı",
		"description": "Yakın dövüş silahı. Hızlı ve keskin. (Gereksinim: Güç 1)",
		"type": ItemType.WEAPON,
		"stackable": false,
		"max_stack": 1,
		"weight": 0.4,
		"stat_requirements": { "strength": 1 },
		"effects": { "damage": 15.0 }
	},
	"sopa": {
		"name": "Tahta Sopa",
		"description": "Basit tahta sopa. Savunma için ideal.",
		"type": ItemType.WEAPON,
		"stackable": false,
		"max_stack": 1,
		"weight": 0.7,
		"effects": { "damage": 8.0 }
	},
	"tabanca": {
		"name": "Tabanca",
		"description": "Ateşli silah. Çok yüksek gürültü çıkarır ve yüksek hasar verir. (Gereksinim: Askeri 1)",
		"type": ItemType.WEAPON,
		"stackable": false,
		"max_stack": 1,
		"weight": 1.0,
		"stat_requirements": { "military": 1 },
		"effects": { "damage": 25.0, "is_firearm": true }
	},
	"fener": {
		"name": "El Feneri",
		"description": "Karanlık sokakları aydınlatmak için el feneri.",
		"type": ItemType.TOOL,
		"stackable": false,
		"max_stack": 1,
		"weight": 0.3,
		"effects": {}
	},
	"kitap_tip": {
		"name": "Tıp Kitabı",
		"description": "Zeka ve Askeri statlarına +1 verir. (Durarak okunur)",
		"type": ItemType.BOOK,
		"stackable": false,
		"max_stack": 1,
		"weight": 0.5,
		"effects": { "book": "kitap_tip", "reading_time": 12.0 }
	},
	"kitap_insaat": {
		"name": "İnşaat Rehberi",
		"description": "Mühendislik statına +2 verir ve Metal Barikat yapmayı sağlar.",
		"type": ItemType.BOOK,
		"stackable": false,
		"max_stack": 1,
		"weight": 0.8,
		"effects": { "book": "kitap_insaat", "reading_time": 16.0 }
	}
}

func get_item(id: String) -> Dictionary:
	if database.has(id):
		var item = database[id].duplicate()
		item["id"] = id
		return item
	return {}
