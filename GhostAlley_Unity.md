# 🎮 GHOST ALLEY
## Game Design Document / Oyun Tasarım Belgesi
### Versiyon 1.0 • 2025

---

| Bilgi / Info | Detay / Detail |
|---|---|
| Oyun Adı / Title | Ghost Alley |
| Tür / Genre | Top-Down 3D Survival RPG |
| Motor / Engine | Unity 6 (3D Engine) |
| Platform | Windows (PC) |
| Grafik Stili | Top-Down 3D / Orthographic 3D (2.5D derinlik hissi - Last Day on Earth / Project Zomboid stili) |
| Hedef Kitle | Tek oyunculu, 16+ yaş |
| Durum / Status | Pre-Production |
| Geliştirici | Solo Developer |

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

Top-down 3D perspektif (Orthographic kamera, 45° çapraz açılı). Harita, mahalleler halinde organize edilmiş geniş bir kıyamet sonrası şehirden oluşur. Tüm duvar, çit ve barikatlar **3D Nesneler (3D Boxes / Meshes)** olarak kurgulenmişlerdir. Başlangıçta tamamı fog of war ile kaplıdır; oyuncu keşfettikçe açılır.

### 3.2 Mahalle Tehlike Seviyeleri / District Danger Levels

| Bölge / Zone | Tehlike | Özellik / Feature |
|---|---|---|
| Dış Mahalleler | ⭐ Düşük | Başlangıç bölgesi, temel kaynaklar |
| Ticaret Bölgesi | ⭐⭐ Orta | Dükkanlar, daha iyi loot, vahşi insan grupları |
| Sanayi Bölgesi | ⭐⭐⭐ Yüksek | Askeri sandıklar, fabrika binaları, güçlü düşmanlar |
| Şehir Merkezi | ⭐⭐⭐⭐ Kritik | Son boss, kıyametin sırrı, hikaye sonu |

### 3.3 Bölge Ele Geçirme / Zone Capture

| Adım | Aksiyon | Sonuç |
|---|---|---|
| 1 | Sokağı düşmanlardan temizle | Düşman spawni durur |
| 2 | Harap binaları tamir et *(3D Meshes)* | Bina kullanılabilir hale gelir |
| 3 | Çit / barikat / kapı kur *(3D Nesneler)* | Bölge savunmaya hazır |
| 4 | Bölge "Güvenli" ilan edilir | Tüm bonuslar aktif olur |

**Güvenli Bölge Avantajları:**
- Güvenli uyku → tam HP ile güne başlama
- Pasif kaynak yenilenmesi
- NPC'lerin bölgeye yerleşmesi
- Horde dalgalarına karşı savunma hattı

---

## 4. Bina & Yapı Sistemi / Building System

### 4.1 Yapı Sağlık Sistemi / Structure HP System

Her duvar, çit, barikat ve binanın kendine ait HP değeri vardır. Tüm yapılar **3D Nesneler (3D Boxes / Meshes)** olarak dünyaya yerleştirilir. Hasar aldıkça görsel olarak çatlar ve kırılır. HP sıfırlanırsa yapı yıkılır ve bölge artık güvenli sayılmaz.

| Yapı / Structure | HP | Tamir Malzemesi | 3D Tipi |
|---|---|---|---|
| Ahşap Çit *(3D Box)* | 100 | Tahta × 5 | BoxMesh |
| Metal Barikat *(3D Box)* | 300 | Metal × 8 + Alet | BoxMesh |
| Kapı (Ahşap) *(3D Mesh)* | 150 | Tahta × 10 + Menteşe | CustomMesh |
| Kapı (Metal) *(3D Mesh)* | 400 | Metal × 15 + Kilit | CustomMesh |
| Harap Bina Duvarı *(3D Box)* | 200 | Tahta × 20 veya Metal × 10 | BoxMesh |
| Tamir Edilmiş Bina *(3D Box)* | 500 | Tahta × 50 + Metal × 20 | BoxMesh |

> **Not:** Mühendislik stat'ı her seviyede tamir hızını %15 artırır ve yapı max HP'sine +50 bonus ekler.

### 4.2 Gece Yapı Saldırıları / Night Structure Attacks

Geceleri düşmanlar öncelikle 3D çitlere ve duvarlara saldırır. Oyuncunun gece rutininin bir parçası zayıf noktaları tespit edip güçlendirmek olmalıdır. 3D yapılar hasar aldıkça mesh deformasyonu ile görsel olarak kırılır.

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
| Oyun Motoru | Unity 6 (Personal License) | Ücretsiz |
| IDE / Kod Editörü | Visual Studio / Cursor | Ücretsiz |
| Kod Desteği | Claude / ChatGPT | Ücretsiz |
| Grafikler | OpenGameArt.org / Itch.io / AI Üretimi | Ücretsiz |
| Ses Efektleri | Freesound.org / Mixkit | Ücretsiz |
| Müzik | Incompetech.com | Ücretsiz |
| Versiyon Kontrolü | GitHub | Ücretsiz |

> **Not:** Unity 6 Personal License yıllık 100.000$ gelirin altındaki projeler için tamamen ücretsizdir. Gelir bu eşiği geçerse lisans gerekir.

### 10.2 Unity 6 Teknik Altyapı / Unity 6 Technical Stack

| Sistem | Unity Karşılığı |
|---|---|
| Karakter Fizik | `CharacterController` veya `Rigidbody` (3D) |
| Mouse Hareket | `Raycast` → `NavMesh Agent` |
| Kamera | `Camera` — Orthographic, 45° açı |
| Düşman AI | `NavMesh` + `NavMesh Agent` |
| Yapı Sistemi | `GameObject` (BoxCollider + MeshRenderer) |
| Ses Sistemi | `AudioSource` + `AudioListener` |
| UI | `Unity UI (uGUI)` veya `UI Toolkit` |
| Kaydetme | `PlayerPrefs` veya `JSON Serialization` |
| Işıklandırma | `URP (Universal Render Pipeline)` |

### 10.2 Mekanik Kararları / Final Mechanics Decisions

#### 🎮 Kontrol & Kamera
- **Hareket:** Unity `Raycast` + `NavMesh Agent` tabanlı Mouse tıkla-git sistemi (Vector3 fizik tabanlı)
- **Kamera:** Unity `Camera` — Orthographic mod, 45° çapraz açılı takip (2.5D derinlik hissi)
- **Grid Sistemi:** 3D Fizik tabanlı (Grid-snapped 3D Placement, Unity `GridLayout` ile)

#### 🎒 Envanter Sistemi
- **Tür:** Konteynır sistemi (çanta, sırt çantası vb.)
- **Kapasite:** Sınırlı (her konteynırın max kapasitesi var)

#### 🌍 Kaynak Yönetimi
- **Güvenli Bölge:** Kaynaklar yenilenmiyor
- **Tehlikeli Bölge:** Her 7 günde bir loot/sandık yenilenir
- **Bina/Üs Boyutu:** Orta (2x2 ila 4x4 grid)

#### 🌙 Gün-Gece Döngüsü
- **Gündüz:** 17 dakika
- **Gece:** 7 dakika
- **Düşman Sistemi:** Gündüz sabit, gece rastgele kombinasyon

#### 💀 Ölüm Sistemi
- Ölünce güvenli bölgedeki yatağında doğ (veya oyunun başladığı noktada)
- Eşyalar: Öldüğün yerde kalır
- Miniharita: Eşya konumu işaretli kalır
- Ayarlar: İleride bu sistem kişiselleştirilebilir

#### 🧟 Horde Sistemi
- **Frekans:** Her 14 günde bir
- **Max Düşman:** Dinamik (bilgisayar gücüne göre)
- **Horde Öncesi:** Oyuncu uyarılır

#### 🏗️ Yapı Sistemi
- **Detay:** Orta seviye (HP, mühendislik bonusu, tamir timi)
- **Savaş:** Anlık (tıkla ve savaş)
- **3D Yapılar:** BoxMesh ve CustomMesh kullanarak 3D Nesneler olarak implement edilir

#### 🗺️ Harita
- **Tür:** Sabit (el ile tasarlanmış şehir)
- **Prosedürel:** Hayır

#### 🎵 Multiplayer
- **v1.0:** Tek oyunculu
- **v2.0+:** Çok oyunculu (planlı)

### 10.3 Geliştirme Fazları / Development Phases

| Faz | İçerik | Hedef Süre |
|---|---|---|
| Faz 1 — Prototip | Unity 6 kurulum, 3D Harita, NavMesh+Raycast hareket altyapısı, Orthographic Kamera, ilk düşman | 2–3 hafta |
| Faz 2 — Core Loop | Gece/gündüz, crafting, inventory, ölüm sistemi | 4–6 hafta |
| Faz 3 — Sistemler | NPC, bilgi, bölge ele geçirme, 3D yapı HP sistemi | 6–8 hafta |
| Faz 4 — İçerik | Tüm düşmanlar, horde, hava durumu, hikaye | 8–10 hafta |
| Faz 5 — Cila | Ses, müzik, UI (uGUI), denge, test, build | 4–6 hafta |

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

**GHOST ALLEY — GDD v1.1 © 2025**
> v1.1 — Motor Unity 6'ya geçirildi. Teknik altyapı C# / NavMesh / URP olarak güncellendi.
