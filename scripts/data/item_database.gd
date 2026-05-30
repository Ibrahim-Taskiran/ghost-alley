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
	},
	"plastik": {
		"name": "Plastik",
		"description": "Basit aletler ve elektronik piller için plastik parçası.",
		"type": ItemType.MATERIAL,
		"stackable": true,
		"max_stack": 20,
		"weight": 0.2,
		"effects": {}
	},
	"barut_kovan": {
		"name": "Barut & Kovan",
		"description": "Mermi üretiminde kullanılan barut ve kovan karışımı.",
		"type": ItemType.MATERIAL,
		"stackable": true,
		"max_stack": 30,
		"weight": 0.1,
		"effects": {}
	},
	"elektronik": {
		"name": "Elektronik Parça",
		"description": "Jeneratör, taret ve elektrikli savunma sistemleri için devre kartları.",
		"type": ItemType.MATERIAL,
		"stackable": true,
		"max_stack": 15,
		"weight": 0.3,
		"effects": {}
	},
	"kimyasal": {
		"name": "Kimyasal",
		"description": "Antibiyotik ve ilkyardım ekipmanları için tıbbi kimyasal bileşen.",
		"type": ItemType.MATERIAL,
		"stackable": true,
		"max_stack": 10,
		"weight": 0.4,
		"effects": {}
	},
	"yakit": {
		"name": "Yakıt Şişesi",
		"description": "Jeneratörleri ve projektörleri çalıştırmak için benzin.",
		"type": ItemType.MATERIAL,
		"stackable": true,
		"max_stack": 5,
		"weight": 1.5,
		"effects": {}
	},
	"el_yapimi_tabanca": {
		"name": "El Yapımı Tabanca",
		"description": "Hurda parçalardan yapılmış güvenilmez ama ölümcül tabanca. (Gereksinim: Askeri 1)",
		"type": ItemType.WEAPON,
		"stackable": false,
		"max_stack": 1,
		"weight": 1.2,
		"stat_requirements": { "military": 1 },
		"effects": { "damage": 20.0, "is_firearm": true }
	},
	"civili_sopa": {
		"name": "Çivili Sopa",
		"description": "Ucuna paslı çiviler çakılmış ağır tahta sopa. (Gereksinim: Güç 2)",
		"type": ItemType.WEAPON,
		"stackable": false,
		"max_stack": 1,
		"weight": 1.4,
		"stat_requirements": { "strength": 2 },
		"effects": { "damage": 16.0 }
	},
	"molotof": {
		"name": "Molotof Kokteyli",
		"description": "Düşmanları yakıp yüksek alan hasarı veren patlayıcı şişe. Tek kullanımlıktır.",
		"type": ItemType.WEAPON,
		"stackable": true,
		"max_stack": 3,
		"weight": 0.6,
		"effects": { "damage": 45.0, "is_consumable_weapon": true }
	},
	"arbalet": {
		"name": "Avcı Arbaleti",
		"description": "Sessizce ok atan av arbaleti. Zombileri gürültüsüzce öldürür. (Gereksinim: Askeri 2)",
		"type": ItemType.WEAPON,
		"stackable": false,
		"max_stack": 1,
		"weight": 2.0,
		"stat_requirements": { "military": 2 },
		"effects": { "damage": 30.0, "is_silent_firearm": true }
	},
	"jenerator": {
		"name": "Jeneratör",
		"description": "Üsse elektrik gücü sağlayan taşınabilir benzinli jeneratör.",
		"type": ItemType.TOOL,
		"stackable": false,
		"max_stack": 1,
		"weight": 8.0,
		"effects": { "structure_id": "jenerator" }
	},
	"projektor": {
		"name": "Projektör",
		"description": "Geceleri zombileri göz kamaştırarak yavaşlatan yüksek güçlü projektör.",
		"type": ItemType.TOOL,
		"stackable": false,
		"max_stack": 1,
		"weight": 4.0,
		"effects": { "structure_id": "projektor" }
	},
	"taret": {
		"name": "Otomatik Taret",
		"description": "Görüş alanına giren zombilere otomatik ateş açan savunma tareti.",
		"type": ItemType.TOOL,
		"stackable": false,
		"max_stack": 1,
		"weight": 6.5,
		"effects": { "structure_id": "taret" }
	},
	"matara": {
		"name": "El Yapımı Matara",
		"description": "Yeniden doldurulabilir su matarası. Susuzluğu tamamen giderir.",
		"type": ItemType.WATER,
		"stackable": false,
		"max_stack": 1,
		"weight": 0.4,
		"effects": { "thirst": 80.0 }
	},
	"ilkyardim_cantasi": {
		"name": "Gelişmiş İlkyardım Çantası",
		"description": "Canı tamamen dolduran ve enfeksiyonu anında iyileştiren sıhhi çanta.",
		"type": ItemType.MEDICINE,
		"stackable": true,
		"max_stack": 2,
		"weight": 1.0,
		"effects": { "heal": 100.0, "cure_infection": true }
	},
	"duvar_ahsap": {
		"name": "Ahşap Duvar",
		"description": "Sığınak kapalı alanı oluşturmak için temel ahşap duvar.",
		"type": ItemType.MATERIAL,
		"stackable": true,
		"max_stack": 10,
		"weight": 2.0,
		"effects": { "structure_id": "duvar_ahsap" }
	},
	"duvar_metal": {
		"name": "Metal Duvar",
		"description": "Sığınak kapalı alanı oluşturmak için dayanıklı metal duvar.",
		"type": ItemType.MATERIAL,
		"stackable": true,
		"max_stack": 5,
		"weight": 3.5,
		"effects": { "structure_id": "duvar_metal" }
	},
	"kapi_ahsap": {
		"name": "Ahşap Kapı",
		"description": "Açılıp kapanabilir sığınak kapısı.",
		"type": ItemType.MATERIAL,
		"stackable": true,
		"max_stack": 5,
		"weight": 2.5,
		"effects": { "structure_id": "kapi_ahsap" }
	},
	"kapi_metal": {
		"name": "Metal Kapı",
		"description": "Çok sağlam kilitli metal kapı.",
		"type": ItemType.MATERIAL,
		"stackable": true,
		"max_stack": 3,
		"weight": 4.5,
		"effects": { "structure_id": "kapi_metal" }
	},
	"zemin": {
		"name": "Zemin Döşemesi",
		"description": "Temiz sığınak tabanı yapmak için ahşap zemin.",
		"type": ItemType.MATERIAL,
		"stackable": true,
		"max_stack": 10,
		"weight": 1.0,
		"effects": { "structure_id": "zemin" }
	},
	"cati": {
		"name": "Çatı Kaplaması",
		"description": "Sığınağın üstünü kapatmak için ahşap çatı.",
		"type": ItemType.MATERIAL,
		"stackable": true,
		"max_stack": 10,
		"weight": 1.5,
		"effects": { "structure_id": "cati" }
	},
	"siginak_bayragi": {
		"name": "Sığınak Bayrağı",
		"description": "Base'i sığınak alanı ilan ederek güvenli alan yapan ve zombi spawnını önleyen sığınak bayrağı.",
		"type": ItemType.MATERIAL,
		"stackable": false,
		"max_stack": 1,
		"weight": 2.0,
		"effects": { "structure_id": "siginak_bayragi" }
	}
}

func get_item(id: String) -> Dictionary:
	if database.has(id):
		var item = database[id].duplicate()
		item["id"] = id
		return item
	return {}
