# Yapılacaklar Listesi (TODO) - Futgol İleri Düzey Güncellemeler

Bu plan, kullanıcının istekleri doğrultusunda Futgol uygulamasının arayüz işleyişinin, oyun mekaniklerinin ve bütüncül kullanıcı deneyiminin güncellenmesini içerir.

---

## 📋 Proje Geliştirme Yol Haritası

### Faz 1: Onboarding ve Tam Ekran Yönetimi
- [x] **1.1.** Uygulama ilk açılışı için neobrutalist tasarımlı slayt geçişli başlangıç rehberi (Onboarding) ekranını tasarla.
- [x] **1.2.** Kronometre Futbolu ve Futbolcu Tahmin Oyunu için ilk girişe özel oyun içi rehber (Onboarding) katmanlarını kodla.
- [x] **1.3.** `shared_preferences` entegrasyonu ile onboarding ekranlarının sadece bir kez gösterilmesini sağla.
- [x] **1.4.** Uygulamanın en başında bildirim çubuğunu gizleyerek tam ekran (immersive) modunu aktif hale getir.
- [x] **1.5.** Ana ekranda ve oyun içinde sistem geri tuşunu (`PopScope`) özelleştir; ana ekranda 3 kez geri basıldığında uygulamadan güvenli çıkış mantığını kur.

### Faz 2: Ana Ekran (Lobi) & İstatistik Yeniden Tasarımı
- [x] **2.1.** Lobi ekranındaki 2x2 grid yapısını değiştirerek sadece 2 oyun kartını ("Kronometre Futbolu", "Futbolcu Tahmin Oyunu") ön plana çıkar.
- [x] **2.2.** İstatistikler ve Ayarlar bölümlerini Header'a (sağ üst köşe ikon butonları olarak) taşı.
- [x] **2.3.** İstatistik ekranını güncelleyerek "Doğru Sayısı" yerine "Doğru Yüzdesi" (`Doğru / (Doğru + Yanlış)`) bazlı sıralama göster.
- [x] **2.4.** İstatistik listesini sıfırlama (temizleme) butonunu ekle.

### Faz 3: Kronometre Futbolu Mekanik ve SQLite Kadro Seçimi
- [x] **3.1.** Maç öncesi kurulum ekranını tasarla: Yıl bazlı takımları ve takımlara özel oyuncuları SQLite veritabanından çek.
- [x] **3.2.** Autocomplete önerileriyle oyuncu arama ve 3. seçenek olarak el yazısıyla serbest isim ekleme imkanı sağla.
- [x] **3.3.** Oyuncu seçimi ve aksiyonlarında kronometre mekanizmasını düzelt: Sırası gelen oyuncu "BAŞLAT" ile sayacı döndürür, "DURDUR" ile saliseyi yakalar.
- [x] **3.4.** Ekranda pas, şut, gol, faul gibi eylemler için büyük görsel neobrutalist aksiyon kartları ve animasyonlu geri bildirimler sun.

### Faz 4: Futbolcu Tahmin Oyunu (Eski Ortak Bağ Bulucu)
- [x] **4.1.** Oyun adını "Futbolcu Tahmin Oyunu" olarak değiştir.
- [x] **4.2.** Arayüzdeki "Arkadaş" -> "Takım Arkadaşı", "Kulüp" -> "Aynı Kulüp" terimlerini güncelle.
- [x] **4.3.** Arama kutusundaki otomatik tamamlama listesinden oyuncu seçilememe bug'ını düzelt.
- [x] **4.4.** Oyuna başlamadan önce oyuncu adı girişi al ve skorları isme özel olarak kaydet; oyunu sonsuz döngüde kesintisiz sürdür.

### Faz 5: Dinamik Zorluk Derecesi ve GitHub Kural Kitabı Entegrasyonu
- [x] **5.1.** GitHub üzerinden sürüm kontrollü kural kitabı (`difficulty_rules.json`) çekme, yerel cache'leme ve fallback yapısını yöneten `DifficultyRulesService` sınıfını yaz.
- [x] **5.2.** `DatabaseService` içerisine zorluk kurallarına göre dinamik olarak oyuncu ve takım soruları üreten (`generateDynamicPlayerQuestion` / `generateDynamicTeamQuestion`) algoritmik metodları ekle.
- [x] **5.3.** Tahmin Oyunu (Ortak Bağ Bulucu) için başlangıca neobrutalist tasarımlı Zorluk ve Mod Seçim kurulum ekranını yerleştir.
- [x] **5.4.** Dinamik soru yüklenirken neobrutalist loading spinner gösterimini entegre et.
- [x] **5.5.** React Web uygulamasına ait tüm dosyaları yedek klasörüne (`C:\Users\HP\proje\yedek\futgol`) taşı.
- [x] **5.6.** Açılmamış Antep Fıstığı (Veteran) modu için `max_highest_market_value <= 2M` kısıtlaması getirilerek popüler süperstarların (Ronaldinho vb.) bu modda gelmesi engellendi.
- [x] **5.7.** Ses çalma sistemi yerel assets (`assets/sounds/`) yapısına geçirildi; `AssetSource` entegrasyonu sağlandı ve çevrimdışı/dosyasız durumlarda kilitlenmeyi önleyici asenkron try-catch/timeout hata koruma yapısı kuruldu.
- [x] **5.8.** Arayüz donmalarını önlemek amacıyla veritabanı sorguları esnasında (`_isProcessing`) butonlar ve yazı alanı pasifleştirilerek mükerrer tıklama kilitlenmesi engellendi; yüklenme esnasında dinamik futbol durum metinleri (`VAR incelemesi yapılıyor...` vb.) eklendi.
- [x] **5.9.** Ortak otomatik tamamlama widget'ı (`NeobrutalistAutocompleteField`) geliştirildi. Hem Kadro Seçim ekranında hem de Tahmin ekranında kod tekrarını önleyecek şekilde entegre edildi.
- [x] **5.10.** Flutter Stack/Clip hit-test hatası giderilerek tüm listedeki elemanların scroll edilmesi ve seçilmesi sağlandı; sanal klavyenin listeyi kapatmaması için liste giriş kutusunun yukarısına taşındı.
- [x] **5.11.** Soru yüklenirken spinner'ın görünmemesi hatası `build` metodu içindeki durum öncelikleri düzenlenerek çözüldü (`_isLoadingQuestion` kontrolü `!_gameStarted` kontrolünün önüne alındı).
- [x] **5.12.** Dinamik soru üretiminin boş dönmesi durumunda (null pointer) uygulamanın beyaz ekrana düşüp çökmesi engellendi; hata toleranslı `_gameStarted = false` geri dönüş mekanizması kuruldu.

### Faz 6: Kod Modülerliği, Klasör Yapısı ve SRP Refaktörü
- [x] **6.1.** Klasör yapısını `lib/common/` ve `lib/features/` mimarisine uygun olarak fiziksel olarak oluştur.
- [x] **6.2.** Mevcut tüm dosyaları (screens, widgets, services, utils, theme, models) yeni klasörlerine taşı.
- [x] **6.3.** Taşınan tüm dosyalardaki `import` yollarını güncelle ve derleme/analiz doğruluğunu onayla.
- [x] **6.4.** `NeobrutalistGameSetup` adında, tüm oyunlarda ortak kullanılabilecek, parametrik ve jenerik bir zorluk/mod seçimi kurulum widget'ı yaz.
- [x] **6.5.** Mevcut `CommonLinkFinderScreen` and `StopwatchFootballScreen` sınıflarını alt widget'larına (header, question_card, state_overlays vb.) bölerek 300 satır sınırına indir.

### Faz 7: 10 Yeni Veritabanı Tabanlı Oyunun Geliştirilmesi
- [x] **7.1.** **Kariyer Yolu (Career Path Trivia):** Kronolojik takım geçişlerinden oyuncu tahmin etme oyunu.
- [x] **7.2.** **Yüksek / Düşük (Higher / Lower Market Value):** Oyuncuların peak piyasa değerlerini karşılaştırma oyunu.
- [x] **7.3.** **Pahalı Transfer Düellosu (Transfer Fee Duel):** Hangi transferin daha pahalı olduğunu tahmin etme oyunu.
- [x] **7.4.** **11'deki Gizemli Futbolcu (Missing Lineup Player):** Tarihi maç kadrosundaki eksik oyuncuyu bulma oyunu.
- [x] **7.5.** **Transfer Zinciri (Transfer Chain Linker):** İki takım arasındaki ortak transfer/oyuncu köprüsünü kurma oyunu.
- [x] **7.6.** **Tarihi Maç: Kim Attı? (Match Goalscorer Trivia):** Maç skoru ve gol dakikalarına göre golcüleri bulma oyunu.
- [x] **7.7.** **Koleksiyoncu Grid (Immaculate Grid):** 3x3'lük kulüp/lig kesişim tablosunu ortak oyuncularla doldurma oyunu.
- [x] **7.8.** **Stadyum ve Kulüp Eşleştirme (Stadium Capacity Quiz):** Kulüp ve stadyum detaylarını eşleştirme oyunu.
- [x] **7.9.** **Kart Cezası Canavarı (The Card King):** En çok kart gören oyuncuları tahmin etme oyunu.
- [x] **7.10.** **Asist ve Gol Krallığı (Top Stats Quiz):** Sezon bazlı gol/asist krallarını bulma oyunu.

### Faz 8: Oyun Seçim Merkezi (Game Selection Hub) Arayüzü
- [x] **8.1.** Ana menüden geçiş yapılabilen, 12 oyunu kategorize eden, neobrutalist kartlar, emojiler ve canlı renklerle tasarlanmış görsel olarak mükemmel bir "Oyun Seçim Lobi Ekranı" geliştir (MainMenuScreen ile birleştirildi).

### Faz 9: Çoklu Oyuncu Sistemi & İstatistik Altyapısı
- [x] **9.1.** **Profil & İstatistik Modeli:** `UserProfile` ve `GameSession` modellerini oluştur. Profil için emoji listesi ve yerel veritabanı/SharedPreferences kayıt mekanizmasını kur.
- [x] **9.2.** **İlk Açılış Profil Ekranı:** Kullanıcı ilk kez girdiğinde isim ve emoji seçebileceği profil oluşturma akışını ekle.
- [x] **9.3.** **Multiplayer ve İstatistik Servisleri:** `StatisticsService` ve `MultiplayerService` sınıflarını implemente et.
- [x] **9.4.** **Ortak Arayüz Bileşenleri:** Oyuncu sayısı seçici, maraton geçiş ekranı (`MarathonHandoff`), H2H split-screen düzeni ve oyun sonu skor tablosu widget'larını kodla.
- [x] **9.5.** **Oyunlara Çoklu Oyuncu Desteği Ekleme:** Belirlenen matrise göre oyunların (Kariyer Yolu, Stadyum Atlası vb.) çoklu oyuncu (Maraton ve H2H) entegrasyonunu tamamla.

---

## 📌 Değerlendirme ve İnceleme Bölümü (Review)

### 💻 Teknik Mimari ve Kod Kalitesi
* **Platform:** Flutter Native (Dart)
* **İndirme & RAM Optimizasyonu:** Disk Stream ve File-based Zip Extraction geçişi başarıyla uygulandı (OOM çözüldü).
* **Onboarding & Terimler:** Tamamlandı, SharedPreferences entegrasyonu sağlandı.
* **Mekanik Düzeltmeleri:** Kronometre Futbolu ve Tahmin Oyunu tamamen yenilendi, otomatik tamamlama ve veri tipi uyumsuzlukları giderildi.
* **SRP Uyumluluğu:** Devasa ekran dosyaları alt widget sınıflarına bölünerek satır sayısı 300 sınırına yaklaştırıldı.
* **Zorluk & Senkronizasyon:** GitHub raw üzerinden kuralları çekip yerel önbellek ve veri tabanıyla eşleyen yapı kuruldu; dinamik olarak sonsuz soru üretimi eklendi.
* **Veritabanı Hataları:** appearances tablosundaki eksik season kolonu JOIN ile çözüldü, tüm casting hataları (REAL->int) giderildi.

---

### Faz 10: UX/UI Yenilemesi ve Veritabanı Doğruluk Denetimi

#### 10.1 Veritabanı katmanı — gerçek hataların tespiti ve giderilmesi
Tüm sorgular 875 MB'lık gerçek `futgol.db` üzerinde ölçüldü ve doğrulandı (43 sorgu, 0 sözdizimi/şema hatası).

- [x] **`getTeamsByYear` — şema hatası:** `appearances` tablosunda `season` kolonu YOK; sorgu her çağrıda `no such column: a.season` fırlatıp sessizce sabit yedek listeye düşüyordu. Sezon bilgisi `games` tablosundan JOIN ile alınacak şekilde düzeltildi.
- [x] **`getCommonClubs` / `checkPlayerClubsCommon` — kartezyen patlaması:** `appearances` (1.88 M satır) kendisiyle `player_club_id` üzerinden JOIN'leniyordu. Ölçüm: **>100 saniye** (uygulama donuyordu). Alt sorgu (IN) yaklaşımına çevrildi → **~30 ms**.
- [x] **`generateDynamicPlayerQuestion` — cevap listesi daima boş:** JOIN kurgusu nedeniyle `p` her zaman P1'in kendisiydi, sonra P1 dışlandığı için sonuç hep boş dönüyordu. Oyuncu modunda hiç gerçek cevap/ipucu üretilemiyordu. Sorgu yeniden yazıldı.
- [x] **`getRandomCardKingQuiz` — tam tablo taraması:** `GROUP BY` + `ORDER BY RANDOM()` tüm `appearances` üzerinde çalışıyordu (**~12 sn**). Önce oyuncu seçip yalnız onun satırlarını toplayan algoritmaya geçildi → **~20 ms**.
- [x] **`getRandomTopStatsQuiz` — tam tablo taraması:** appearances × games × competitions birleşimi (**~15 sn**) → oyuncu bazlı sorguya çevrildi → **~30 ms**.
- [x] **`getRandomImmaculateGridConfig` — oyun hiç açılmıyordu:** 12 rastgele kulüpten 4'ünün dört kesişiminin de dolu çıkmasını umuyordu; ölçümde **0/3 başarı**. Ayrıca kulüpleri isimle eşleştirip Türkçe harfleri `%` jokerine çevirdiği için yanlış kulüpleri de kesiştirebiliyordu. Kesişimi garanti eden algoritmaya geçildi (sütunlar iki kulüpte de oynamış bir futbolcudan, satırlar tek sorguyla) → **8/8 başarı, ~185 ms**.
- [x] **`getRandomClubPairForLinker` — %40 boş dönüyordu:** `transfers` tablosu `appearances`'tan geniş dönem kapsadığı için seçilen kulüp çiftinin ortak oyuncusu çoğu kez yoktu. Kulüp çifti artık iki kulüpte de forma giydiği veriyle sabit bir futbolcudan türetiliyor → **8/8**.
- [x] **`getRandomGameWithMissingLineup` — eksik kadro:** "toplam 8+ satır" iki takımın toplamıydı; ev sahibinin kadrosu yetersiz kalabiliyordu. Ev sahibi yetmezse deplasmana, o da yetmezse başka maça geçiliyor → **8/8**.
- [x] **`getRandomGameWithGoalscorer` — eşleşmeyen golcü:** `game_events.player_id` her zaman `players`'ta karşılık bulmuyor. En az 2 geçerli golcüsü olan maç aranıyor → **8/8**.
- [x] **`getRandomPlayerWithCareer`:** `rulesService.initialize()` hiç çağrılmıyordu; ayrıca kariyer listesi her sezon için ayrı satır döndürüp aynı kulübü tekrarlıyordu (Barcelona, Barcelona, Barcelona…). Kulüp bazında gruplanıp sezon aralığıyla gösteriliyor ("Barcelona (2012–2020)").
- [x] **Hata görünürlüğü:** Tüm sorgular merkezî `_query()` üzerinden çalışıyor; `DatabaseService.lastError` ekranlara aktarılıyor. Kullanıcı artık sessiz "soru yüklenemedi" yerine gerçek nedeni görüyor. Soru üretimi başarısız olursa ekranlar otomatik 3 kez yeniden deniyor.
- [x] **Bağlantı ayarı:** Salt-okunur açılışta `cache_size`, `temp_store`, `mmap_size` PRAGMA'ları uygulanıyor.
- [x] **Doğrulama:** 16 oyunun veri yolu gerçek veritabanında uçtan uca simüle edildi — **tamamı geçti**.

#### 10.2 Kronometre Futbolu — arayüz ve oynanış yenilemesi
- [x] **Aksiyon yanlış ekranda görünüyordu:** Hamle bitince sıra rakibe geçtiği için sonuç kartı daima karşı tarafın ekranında beliriyordu. `MatchAction.ownerPlayerNum` ile hamle sahibi takip ediliyor; kart artık hamleyi yapanın yarısında kalıyor.
- [x] **Kadro ekranda yoktu:** `RosterStrip` eklendi. 10 futbolcu, kronometre hanesiyle (0-9) eşleşen numaraları, portreleri ve canlı durumlarıyla görünüyor: ⚽ gol sayısı, 🟨 sarı, 🟥 kırmızı, 🏥 sakatlık geri sayımı, ⚠️ kart sınırı. Oyuncu artık "3 gelirse kim çıkacak?" sorusunu görerek yanıtlıyor.
- [x] **Cümle içinde kaybolan isim:** `ActionStageCard` ile cümle kurulmuyor; futbolcu adı (17 pt) ve hareket tipi (22 pt) ayrı ayrı, portre ve forma numarasıyla birlikte basılıyor. Eski sürümde her şey 8 pt tek cümleydi.
- [x] **Kadro kurulumu veritabanına bağlandı:** Fotoğraflı/mevkili/piyasa değerli arama, "HAZIR KADRO" ile popüler kulübün en çok forma giymiş 10 futbolcusunu tek dokunuşla yükleme, düzenlenebilir takım adı, adım göstergesi.
- [x] Oyuncu bazlı gol takibi, canlı maç olay şeridi, rezerv/atak süresi çubukları, aşama etiketi ("ADIM 1 · FUTBOLCU SEÇ"), çıkışta onay diyaloğu, maç sonu "YENİDEN" butonu.
- [x] Onboarding kartına salise hanesi → hareket eşleme tablosu eklendi (0=GOL, 1=Direk, … 9=Sakatlık).

#### 10.3 Genel arayüz ve arama deneyimi
- [x] **Aksan duyarsız arama:** SQLite `GLOB` karakter sınıflarıyla "guler → Arda Güler", "ozil → Mesut Özil", "muller → Thomas Müller", "sukur → Şükür" (~30 ms). Türkçe klavye zorunluluğu kalktı.
- [x] **Arama sonuçları zenginleştirildi:** Tüm oyunlarda portre + mevki + kulüp + piyasa değeri; sonuçlar ünlü oyuncu önce gelecek şekilde piyasa değerine göre sıralı (eski sürümde "messi" araması önce "Fabian Messina"yı getiriyordu).
- [x] **Tahmin doğrulama esnetildi:** `DbText.namesMatch` ile aksansız yazım, yalnız soyadı ve ters sıra kabul ediliyor (eski sürüm birebir string karşılaştırması yapıyordu).
- [x] **Cevap açılışı:** Doğru bilindiğinde ve canlar bittiğinde `AnswerRevealCard` futbolcunun gerçek fotoğrafını ve künyesini gösteriyor.
- [x] **Ana menü:** 13 oyun düz liste yerine 3 kategoriye ayrıldı (Karşılıklı Oyna / Futbolcu Bul / Bilgi Yarışması); profil selamı ve genel doğruluk şeridi eklendi; kartlara renkli ayraç rayı kondu.
- [x] **Ortak Bağ:** "AYNY KULÜP" yazım hatası düzeltildi; soru kartında iki futbolcunun portresi/mevkisi/uyruğu gösteriliyor; yarışan arama isteklerinin birbirini ezmesi engellendi.

#### 10.4 Kod sağlığı
- [x] `flutter analyze`: **36 uyarıdan 0'a** (`withOpacity` → `withValues`, `print` → `debugPrint`, eksik `path` bağımlılığı, async-gap `BuildContext` kullanımı vb.).
- [x] Şablondan kalma ve zaten kırık olan sayaç testi kaldırıldı; yerine **21 anlamlı test** yazıldı (aksan eşleşmesi, kadro durumu, aksiyon kartı tipografisi, sıra göstergesi).
- [x] `flutter build apk --debug` başarılı.
