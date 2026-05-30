# 🎮 GHOST ALLEY
## Game Design Document / Oyun Tasarım Belgesi
### Versiyon 1.0 • 2025

---

| Bilgi / Info | Detay / Detail |
|---|---|
| Oyun Adı / Title | Ghost Alley |
| Tür / Genre | Top-Down 3D Survival RPG |
| Motor / Engine | Godot 4 (3D Engine) |
| Platform | Windows (PC) |
| Grafik Stili | Top-Down 3D / Orthographic 3D (2.5D derinlik hissi - Last Day on Earth / Project Zomboid stili) |
| Hedef Kitle | Tek oyunculu, 16+ yaş |
| Durum / Status | Pre-Production |
| Geliştirici | Solo Developer + AI Assisted |

---

## 1. Oyun Vizyonu / Game Vision

### 1.1 Özet / Summary

Ghost Alley, kıyamet sonrası bir şehirde hayatta kalmaya çalışan isimsiz bir evsizin hikayesini anlatan tek oyunculu, top-down 3D bir survival RPG oyunudur. Oyuncu; keşfederek, inşa ederek, okuyarak öğrenir ve büyür. Ortografik 3D kamera ile oyun 2.5D derinlik hissi verir.

*Ghost Alley is a single-player top-down 3D survival RPG where the player controls a nameless homeless man trying to survive in a post-apocalyptic city. The player learns and grows by exploring, building, and reading. Using orthographic 3D camera, the game provides a 2.5D depth perception experience.*

### 1.2 Temel Tasarım Direkleri / Core Design Pillars

- **Keşif Önce Gelir:** Harita fog of war ile kaplıdır, her adım yeni tehlikeler ve fırsatlar sunar.
- **Bilgi Güçtür:** Karakter başlangıçta hiçbir şey bilmez; kitaplar ve parşömenlerle öğrenir.
- **Her Bölgenin Değeri Var:** Temizlenen sokak oyuncuya gerçek avantaj sağlar.
- **Gerilim ve Gizem:** Karanlık atmosfer, düşmanların sırrı ve şehrin gizemi oyunu ilerletir.

---

## 2. Karakter Sistemi / Character System

### 2.1 Ana Karakter / Main Character

**Adı:** "Adam" (İsimsiz)

Kıyametten önce şehrin sokaklarında yaşayan, geçmişi belirsiz bir evsiz. Başlangıçta temel hayatta kalma bilgisinden bile yoksun. Oyunun en güçlü anlatı aracı: sıradan biri olmasına rağmen olağanüstü bir hikayenin merkezinde.

### 2.2 Stat Sistemi / Stat System

| Stat | Türkçe | Etkisi / Effect |
|---|---|---|
| 💪 Strength | Güç | Ağır silah kullanımı, barikat kurma hızı |
| 🎖️ Military | Askeri | Ateşli silah kullanımı, savaş taktikleri, hasar bonusu |
| 🔧 Engineering | Mühendislik | Bina tamiri, gelişmiş crafting, yapı HP bonusu |
| 🧠 Intelligence | Zeka | Kitap okuma hızı, kilit açma, yüksek seviye sandıklar |

### 2.3 XP & Level Sistemi / XP & Level System

**XP Kaynakları:**
- Zombi / Düşman öldürme
- Kitap okuma
- Eşya crafting yapma
- Bölge temizleme ve güvenli ilan etme
- NPC kurtarma

**Level Sandık Ödülleri:**

| Level | Sandık İçeriği / Chest Contents |
|---|---|
| 1–3 | Yiyecek, su, basit alet (bıçak, el feneri) |
| 4–6 | Parşömen, basit silah, ilaç malzemesi |
| 7–10 | Gelişmiş silah, crafting planı, NPC slotu açılımı |
| 11–15 | Nadir silahlar, özel zırh planı, horde erken uyarı cihazı |
| 16+ | Efsanevi eşyalar, şehir merkezi harita parçaları |

### 2.4 Stat Gereksinimleri / Stat Requirements

> Sokakta bulunan bazı eşyalar, sandıklar ve silahlar minimum stat gereksinimi ister. Düşük stat ile eşyayı görebilirsin ama kullanamazsın veya açamazsın.

| Eşya / Item | Gereksinim / Requirement |
|---|---|
| Tabanca | Askeri 2 |
| Tüfek | Askeri 4 |
| Metal Barikat Planı | Mühendislik 3 |
| Kilitli Askeri Sandık | Zeka 3 + Askeri 2 |
| Bina Tamiri (Harap) | Mühendislik 2 |
| Gelişmiş Tıp Kitabı | Zeka 3 |

---

## 3. Dünya & Harita Sistemi / World & Map System

### 3.1 Harita Yapısı / Map Structure

Top-down 3D perspektif (Orthographic kamera, 45° çapraz açılı). Harita, mahalleler halinde organize edilmiş, pre-production aşamasında **500x500 birimlik devasa bir alana (5x Ölçek)** genişletilmiş geniş bir kıyamet sonrası şehirden oluşur. Zemin collidarları ve sınır meshleri bu ölçekle tamamen uyumludur. Başlangıçta tamamı fog of war ile kaplıdır; oyuncu keşfettikçe açılır. Harita üzerinde canlı HUD miniharita (Sağ Alt) ve `M` tuşu ile açılan tam ekran Taktik Harita mevcuttur.

### 3.2 Mahalle Tehlike Seviyeleri / District Danger Levels

| Bölge / Zone | Tehlike Seviyesi | Koordinat Sınırları | Özellik / Feature |
|---|---|---|---|
| Dış Mahalleler | ⭐ Düşük (Low) | X/Z: -250 ila -120 | Başlangıç bölgesi, temel kaynaklar |
| Ticaret Bölgesi | ⭐⭐ Orta (Medium) | X/Z: -120 ila 10 | Dükkanlar, daha iyi loot, vahşi insan grupları |
| Sanayi Bölgesi | ⭐⭐⭐ Yüksek (High) | X/Z: 10 ila 130 | Zehirli variller, askeri sandıklar, taret parçaları |
| Şehir Merkezi | ⭐⭐⭐⭐ Kritik (Deadly) | X/Z: 130 ila 250 | Son boss, kıyametin sırrı, hikaye sonu |

### 3.3 Bölge Ele Geçirme & Sığınak Bayrağı / Zone Capture & Shelter Flag

| Adım | Aksiyon | Sonuç |
|---|---|---|
| 1 | Sokağı veya binayı düşmanlardan temizle | Düşman spawni durdurulmaya hazır hale gelir |
| 2 | Bir sektöre **Sığınak Bayrağı** (`siginak_bayragi.tscn`) yerleştir | Sistem bölgeyi anında **Güvenli Bölge (Safezone)** ilan eder |
| 3 | Bölgeye Çit / Duvar / Kapı kur *(1.0 Grid Snapping)* | Zombi spawn'ları bu alanda kalıcı olarak son bulur |
| 4 | Kaynak Yenilenmesi tetiklenir | Güvenli bölgede her 2 saatte bir hammadde üretimi başlar |

**Güvenli Bölge Avantajları:**
- NPC'lerin bölgeye yerleşmesi
- Horde dalgalarına karşı savunma hattı

---

## 4. Bina & Yapı Sistemi / Building & Defensive Systems

### 4.1 Yapı Sağlık Sistemi / Structure HP System

Tüm yapı elemanları, elektrikli cihazlar ve savunma taretleri **3D Nesneler (3D TSCN Prefabları)** olarak dünyaya yerleştirilir. İnşa modunda (`B` tuşu) veya envanterden doğrudan `1.0 birimlik` grid snapping ile yerleşirler. HP değeri sıfırlanırsa yapı yıkılır.

| Yapı / Structure | HP | İnşa Bedeli / Cost | Özellik / Feature |
|---|---|---|---|
| **Ahşap Duvar** *(duvar_ahsap.tscn)* | 150 | Tahta × 6 | Temel savunma hattı |
| **Metal Duvar** *(duvar_metal.tscn)* | 400 | Metal Parçası × 8 | Güçlü barikat hattı |
| **Ahşap Kapı** *(kapi_ahsap.tscn)* | 150 | Tahta × 10 | Açılıp kapanabilir geçit |
| **Metal Kapı** *(kapi_metal.tscn)* | 400 | Metal Parçası × 10 | Güvenli, zırhlı kapı |
| **Zemin** *(zemin.tscn)* | 200 | Tahta × 4 | Sığınak temeli |
| **Çatı** *(cati.tscn)* | 200 | Tahta × 4 | Y-ekseni `2.5m` yüksekliğe otomatik oturan çatı |
| **Sığınak Bayrağı** *(siginak_bayragi.tscn)* | 100 | Tahta × 15 + Plastik × 5 | Güvenli bölge tetikleyicisi |
| **Jeneratör** *(jenerator.tscn)* | 250 | Demir × 15 + Yakıt × 5 | Üs elektrik santrali |
| **Projektör** *(projektor.tscn)* | 150 | Elektronik × 4 + Metal × 5 | Gece görüş/aydınlatma |
| **Otomatik Taret** *(taret.tscn)* | 350 | Silah + Metal × 10 + Elektronik | 3D döner başlıklı otomatik savunma hattı |

### 4.2 🚪 Gelişmiş Kapı Etkileşimi (Interactive Doors)
Kapıların yanına gelindiğinde **`E`** tuşu ile kapı açılabilir veya kapatılabilir.
- **Açık Kapı:** Çarpışma kutuları devre dışı kalır, oyuncular ve düşmanlar geçebilir.
- **Kapalı Kapı:** Tam bir barikat görevi üstlenir.
- **Tamir Etme:** Hasar gören kapıları tamir etmek için yanına gelip **`Shift + E`** tuşlarına basılır.

### 4.3 🤖 Otomatik Savunma Tareti AI (Automatic Defensive Turret)
Oyuncu üssüne bir otomatik taret yerleştirdiğinde:
- `12 metre` yarıçapındaki en yakın canlı zombiyi otomatik olarak hedefler.
- 3D kafasını zombiye doğru çevirerek her `0.8 saniyede` bir **`18 HP`** hasar veren mermiler ateşler.
- Ateş ettikçe silah sesi yayar ve çevredeki zombileri üstüne çeker.

### 4.4 ⚠️ Zehirli Atık Varilleri & Engeller (Environmental Hazards)
- **Zehirli Variller (Toxic Barrels):** Sanayi bölgesindeki parıldayan yeşil variller `3.5m` yarıçaptaki oyunculara saniyede **`12 HP`** radyasyon hasarı verir (enfeksiyonu tetikler).
- **Yol Blokajları:** Paslı araba barikatları (`RustyCar`) ve tilted beton köprüler (`Bridge`) keşif ve taktik rotaları belirler.

---

## 5. Düşman Sistemi / Enemy System

### 5.1 Düşman Tipleri / Enemy Types

| Tip / Type | Hız | Hasar | Özellik |
|---|---|---|---|
| 🧟 Zombi (Standart) | Yavaş | Düşük | Kalabalık gelir, gürültüye tepki verir |
| 🧟 Zombi (Koşucu) | Hızlı | Orta | Direkt saldırır, ses çıkarmaz |
| 👤 Vahşi İnsan | Normal | Yüksek | Akıllı, grupla organize olur, silah kullanabilir |
| 👤 Vahşi Lider | Normal | Çok Yüksek | Grubu yönetir, önce onu öldür |
| 🧟 Boss Zombi | Orta | Çok Yüksek | Her 5. gece, bölgeye özel boss |

### 5.2 Gece/Gündüz Farkları / Day-Night Differences

| Özellik | Gündüz | Gece |
|---|---|---|
| Hareket Hızı | Normal | +50% |
| Verilen Hasar | Normal | +30% |
| Görüş Menzili | Kısa | Geniş (oyuncu için tehlikeli) |
| Hedef Önceliği | Oyuncu | Oyuncu + Çitler + Duvarlar |
| Ses Tepkisi | Zayıf | Güçlü — her gürültü düşman çeker |

### 5.3 Ses Mekaniği / Sound Mechanic

Oyuncunun çıkardığı her gürültü düşmanların dikkatini çeker:

| Aksiyon | Gürültü Seviyesi |
|---|---|
| Silah ateşleme | 🔴 Çok Yüksek |
| Koşma | 🟠 Orta |
| İnşaat (çit/duvar 3D placement) | 🟠 Orta |
| Yürüme | 🟡 Düşük |
| Stealth hareketi | 🟢 Sıfır |

### 5.4 Horde Dalgası / Horde Wave

**Her 14 günde bir** dev horde dalgası gelir. Normal gecelerden çok daha büyük ve güçlüdür.

- 50–300 arası zombi aynı anda saldırır
- Zombiler **3D piramit yaparak** yüksek duvarları tırmanabilir
- Bölge savunması kritik önem taşır
- Horde öncesi oyuncu uyarılır (sis, ses efekti, NPC diyalogu)
- Horde'u başarıyla atlatmak büyük XP ve nadir loot verir

---

## 6. Hayatta Kalma Mekanikleri / Survival Mechanics

### 6.1 Temel İhtiyaçlar / Basic Needs

| İhtiyaç | Sonuç (Karşılanmazsa) |
|---|---|
| 🍖 Açlık | HP yavaş azalır, hareket hızı düşer |
| 💧 Susuzluk | HP hızlı azalır, bulanık görüş |
| 😴 Uyku | Stat penalty, yavaş refleks |
| 🏥 Sağlık | Sıfırlanırsa: Game Over |

### 6.2 Enfeksiyon Sistemi / Infection System

Zombi ısırığı veya vahşi insan yaralanması enfeksiyona yol açabilir.

- Isırık sonrası enfeksiyon sayacı başlar
- Belirli süre içinde antibiyotik veya özel ilaç kullanılmazsa HP düşmeye başlar
- Tedavi edilmezse **3 gün içinde ölüm**
- Doktor NPC base'de ise tedavi süreci hızlanır

### 6.3 Hava Durumu / Weather System

| Hava | Etki / Effect |
|---|---|
| ☀️ Güneşli | Normal — bonus yok |
| 🌧️ Yağmurlu | Görüş azalır, ateş söner, ayak sesi duyulmaz (stealth kolay) |
| ⛈️ Fırtına | Hareket yavaşlar, ses mekanik devre dışı |
| 🌫️ Sis | Görüş çok kısalır, düşman görmek zorlaşır |
| ❄️ Kar | Hareket yavaşlar, iz bırakılır (düşman takip edebilir) |

---

## 7. Bilgi & Crafting Sistemi / Knowledge & Crafting

### 7.1 Bilgi Edinme / Knowledge Acquisition

Adam başlangıçta hiçbir şey bilmez. Bilgi iki yolla edinilir:

| Kaynak | İçerik | Etki |
|---|---|---|
| 📚 Kitaplar | Tıp, inşaat, silah, hayatta kalma | Yeni crafting tarifleri açılır, stat bonusu |
| 📜 Parşömenler | Kısa ipuçları, hap bilgiler | Küçük bonus, dünya lore'u |
| 🧑 NPC Diyalogu | Bölge bilgisi, tehlike uyarısı | Haritada yeni nokta açılır |
| 📦 Level Sandığı | Otomatik bilgi kazanımı | Her level başı pasif öğrenme |

> *Zeka stat'ı okuma hızını belirler. Zeka 1'de bir kitap 3 gün sürer; Zeka 5'te aynı gece biter.*

### 7.2 Crafting Sistemi / Crafting System

- Crafting, bilgi gerektiren tariflerle yapılır
- Temel tarifler başlangıçta açık; gelişmişler kitaplarla öğrenilir
- Bazı tarifler hem stat hem de bilgi gerektirir
- Crafting XP verir

---

## 8. NPC Sistemi / NPC System

### 8.1 NPC Keşfi / NPC Discovery

Haritada rastgele konumlarda kurtarılmayı bekleyen NPC'ler bulunur:

- Bir binada mahsur kalmış
- Hasta veya yaralı
- Vahşi insanlara esir düşmüş
- Korku içinde saklanıyor

Her NPC ile karşılaşmada iki seçenek sunulur: **Yardım Et / Geç Git**. Yardım edilirse **Base'e Al / Serbest Bırak** seçeneği çıkar.

### 8.2 NPC Meslekleri & Bonusları / NPC Classes & Bonuses

| Meslek | Savaş Gücü | Base Bonusu |
|---|---|---|
| 🏥 Doktor | Düşük | Pasif HP yenilenmesi, enfeksiyon tedavisi hızlanır |
| 🎖️ Asker | Çok Yüksek | Bölge savunması güçlenir, ateşli silah hasarı artar |
| 🔧 Mühendis | Orta | Tamir hızı +%30, yeni crafting tarifleri açılır |
| 📚 Öğretmen | Düşük | XP kazanımı +%20, kitap okuma hızı artar |
| 🌾 Çiftçi | Düşük | Base'de yiyecek üretimi başlar |
| 🔫 Avcı | Yüksek | Devriye görevi yapabilir, loot kalitesi artar |

### 8.3 NPC Kuralları / NPC Rules

- NPC'ler base'de **sadık kalır** — sen atmadıkça ayrılmazlar
- Her NPC'nin kendi 4 stat'ı var; savaşta kendi statına göre davranır
- NPC ölümü **kalıcıdır** — dikkatli kullan
- Base'de kapasite sınırı vardır; yeni NPC slotu level atlamakla açılır

---

## 9. Hikaye & Anlatı / Story & Narrative

### 9.1 Başlangıç / Opening

Adam, kıyametten önce zaten sokaktaydı. Herkes kaçarken o yerindeydi — belki de bu yüzden hayatta kalan tek kişi o. Hiçbir şey hatırlamıyor, kim olduğunu bilmiyor. Tek amacı: hayatta kalmak.

### 9.2 Ana Hikaye Soruları / Core Mystery

- Şehre ne oldu?
- Neden kimse geri dönmedi?
- Vahşi insanlar neden bu kadar organize?
- Adam gerçekten kim?

### 9.3 Hikaye Sonları / Story Endings

Yeterli bölge temizlenip şehir merkezine ulaşıldığında kıyametin sırrı ortaya çıkar. Birden fazla son mevcuttur:

- 🟢 **İyi Son:** Şehri kurtarır, hayatta kalanlarla topluluk kurar
- 🟡 **Nötr Son:** Sırrı öğrenir ama şehri terk eder
- 🔴 **Karanlık Son:** Adam sırrın bir parçasıydı

> Hikaye bittikten sonra **Hayatta Kalma Modu (sonsuz)** aktif olur.

---

## 10. Teknik Plan / Technical Plan

### 10.1 Motor & Araçlar / Engine & Tools

| İhtiyaç | Araç / Tool | Maliyet |
|---|---|---|
| Oyun Motoru | Godot 4 | Ücretsiz |
| Grafikler | OpenGameArt.org / Itch.io | Ücretsiz |
| Ses Efektleri | Freesound.org / Mixkit | Ücretsiz |
| Müzik | Incompetech.com | Ücretsiz |
| Kod Desteği | AI (Claude vb.) | Ücretsiz |
| Versiyon Kontrolü | GitHub | Ücretsiz |

### 10.2 Mekanik Kararları / Final Mechanics Decisions

#### 🎮 Kontrol & Kamera
- **Hareket:** 3D Raycast tabanlı Mouse tıkla-git sistemi (Vector3 fizik tabanlı, CharacterBody3D)
- **Kamera:** Orthographic 3D Kamera (çapraz açılı takip - 45° isometrik görüş, 2.5D derinlik hissi)
- **Grid Sistemi:** 3D Fizik tabanlı (Grid-snapped 3D Placement, VoxelGrid sistem)

#### 🎒 Envanter Sistemi (Backpack & Pockets)
- **Tür:** İki katmanlı entegre konteynır sistemi (Sırt Çantası ve Cepler).
- **Kapasite:** 21 Slot (16 Sırt Çantası slotu + 5 Hızlı Erişim Cebi slotu).
- **Sürükle-Bırak:** Çanta ile cepler arasında iki yönlü fiziksel transfer (swap/takas) desteği. Mükerrer kısayol atamaları tamamen engellenmiştir, eşya fiziksel olarak çantadan cebe veya cepten çantaya taşınır.
- **Tüketim:** Eşyalar doğrudan ceplerden (slots 16-20) tüketilebilir (1-5 tuşları). Üretim ve inşaat sistemleri öncelikli olarak ceplerdeki hammaddeleri tüketir.

#### 🌍 Kaynak Yönetimi
- **Yenilenme:** Güvenli bölgeler hariç, tehlikeli bölgelerdeki loot ve sandıklar 7 günde bir yenilenir.
- **Bina/Üs Boyutu:** 500x500 harita sınırlarında modüler ve serbest inşaat alanı (1.0 Grid Snapping).

#### 🌙 Gün-Gece Döngüsü
- **Gündüz:** 17 dakika
- **Gece:** 7 dakika
- **Düşman Sistemi:** Gündüz sabit, gece rastgele kombinasyon ve horde saldırıları.

#### 💀 Ölüm Sistemi
- Ölünce güvenli bölgedeki en son dikilen Sığınak Bayrağı'nda respawn ol (veya başlangıç noktasında).
- Eşyalar: Öldüğün yerde physical loot kutusu olarak kalır.

#### 🗺️ Harita Arayüzü (Minimap & Fullmap)
- **Canlı Miniharita:** HUD ekranının Sağ Alt köşesine konumlandırılmıştır. Oyuncuyu ortalayan ortografik bir 3D kameradan oluşur. Oyuncunun baktığı yönü kırmızı bir ok ile gösterir. Window yeniden boyutlandırıldığında sağ alta kilitlenir.
- **Taktik Harita (Tam Ekran - M Tuşu):** Oyuncu M tuşuna bastığında açılan 550x550 piksellik yarı şeffaf cyberpunk panel. Oyuncunun etrafındaki 200 metrelik alanı kuşbakışı render eder. Açıldığında karakter hareketini dondurur, envanter veya crafting açıkken çakışma koruması ile açılması engellenir.

#### 🏗️ Yapı Sistemi
- **Detay:** 3D modüler inşaat elemanları (duvar_ahsap, duvar_metal, kapi_ahsap, kapi_metal, zemin, cati, siginak_bayragi).
- **Elektrik & Güç:** jenerator yerleştirildiğinde üs elektrik sistemi başlar, projektor ve taret çalıştırılabilir.
- **Taret:** 12 metre range'deki en yakın zombiyi hedefleyen ve 0.8 saniyede bir 18 HP hasar veren otomatik taret yapısı.

#### 🗺️ Harita
- **Tür:** Genişletilmiş sabit 500x500 birimlik şehir haritası.
- **Prosedürel:** Hayır.

#### 🎵 Multiplayer
- **v1.0:** Tek oyunculu (Modüler üs ve cepler altyapısı hazır)
- **v2.0+:** Çok oyunculu (planlı)

### 10.3 Geliştirme Fazları / Development Phases

| Faz | İçerik | Hedef Süre |
|---|---|---|
| Faz 1 — Prototip | 3D Harita ve Raycast Hareket Altyapısı, Orthographic Kamera, ilk düşman | 2–3 hafta |
| Faz 2 — Core Loop | Gece/gündüz, crafting, inventory, ölüm | 4–6 hafta |
| Faz 3 — Sistemler | NPC, bilgi, bölge ele geçirme, 3D yapı HP sistemi | 6–8 hafta |
| Faz 4 — İçerik | Tüm düşmanlar, horde, hava durumu, hikaye | 8–10 hafta |
| Faz 5 — Cila | Ses, müzik, UI, denge, test | 4–6 hafta |

---

## 11. Referans Oyunlar / Reference Games

| Oyun / Dizi | Alınan İlham / Inspiration |
|---|---|
| Last Day on Earth | Top-down 3D/2.5D survival, crafting, base building, gece dalgaları |
| Days Gone | Horde mekaniği, dinamik düşman davranışı, hava durumu |
| Project Zomboid | Orthographic isometrik perspektif, detailed construction system |
| World War Z (Oyun) | Zombi piramidi, sınıf sistemi |
| The Walking Dead (Dizi) | NPC ilişki derinliği, grup dinamiği, kaynak çatışması |
| World War Z (Film) | Ses mekaniği, kalabalık zombi paniği |

---

*Bu belge yaşayan bir dokümandır. Geliştirme sürecinde güncellenecektir.*
*This is a living document and will be updated throughout development.*

**GHOST ALLEY — GDD v1.0 © 2025**
