# Kazanılan Dersler & Kurallar (lessons.md)

Bu dosya, projede karşılaşılan hatalardan öğrenilen dersleri ve kendimize koyduğumuz katı kuralları içerir.

## 📌 Alınan Dersler

### 1. `write_to_file` ve `ArtifactMetadata` Kullanımı
* **Hata:** Projenin kendi dizini altındaki sıradan dosyalara (örneğin `tasks/todo.md`) yazarken `ArtifactMetadata` parametresinin eklenmesi, sistemin bunu geçersiz bir artifact yolu olarak algılamasına ve hata vermesine neden olur.
* **Çözüm/Kural:** Sadece `<appDataDir>\brain\<conversation-id>` altındaki gerçek artifact dosyaları oluşturulurken `ArtifactMetadata` kullanılmalıdır. Proje dizinindeki (`C:\Users\HP\...` gibi) kaynak kod veya görev dosyaları yazılırken bu parametre kesinlikle boş bırakılmalıdır.

### 2. Türkçe Dil Zorunluluğu (TURKISH ONLY)
* **Kural:** Kullanıcı ile olan tüm iletişim, chat mesajları, kod açıklamaları, dokümantasyonlar, planlar ve görev takip dosyaları strictly Türkçe olmalıdır.
* **Uygulama:** Kodlardaki yorum satırları dahil her şey Türkçe yazılacaktır.

### 3. Mobil Öncelikli Tasarım (Mobile-First) & Erişilebilirlik (A11y)
* **Kural:** Mobil cihazlar hiçbir zaman ikinci plana atılamaz. Tüm UI kodları duyarlı (responsive) olmalı ve ARIA standartlarına uygun olarak tasarlanmalıdır.

### 4. Tek Sorumluluk İlkesi (SRP) & Dosya Boyut Sınırı (Max 300 Satır)
* **Kural:** Kod dosyaları (UI bileşenleri, servisler vb.) 300 satırı aşmamalıdır. Yaklaşan veya aşan dosyalar hızlıca alt bileşenlere veya hook'lara bölünmelidir.

### 5. PowerShell ve Terminal Komut Zinciri (Syntax Error)
* **Hata:** PowerShell terminalinde `&&` bağlacı geçerli bir komut ayırıcı değildir ve parser hatası verir.
* **Çözüm/Kural:** PowerShell ortamında ardışık komutları çalıştırmak için `&&` yerine `;` kullanılmalıdır (Örn: `npm install; npm run build`).

### 6. TypeScript `verbatimModuleSyntax` ve Tip İthalatı (TS1484)
* **Hata:** Projede `verbatimModuleSyntax` kuralı devredeyken tipler standart import ile çağrıldığında TS1484 hatası oluşur.
* **Çözüm/Kural:** Yalnızca tip tanımı olan (interface, type) yapılar ithal edilirken mutlaka `import type { ... }` sözdizimi kullanılmalıdır.

### 7. StitchMCP Araç Parametreleri ve Şema Doğrulaması
* **Hata:** StitchMCP gibi lazy-loaded sunucu araçlarını çağırırken varsayılan veya tahmin edilen parametreler (örneğin `create_project` için `deviceType` göndermek) geçersiz argüman hatasına (invalid argument) neden olabilir.
* **Çözüm/Kural:** Araç çağrıları yapmadan önce her zaman ilgili aracın şema dosyasını (`.json`) inceleyerek sadece şemada tanımlanmış olan parametreleri göndermek gerekir.

### 8. Tekrarlayan Derleme Hatalarının Kümülatif Analizi
* **Hata:** Derleyiciden gelen ilk hataya odaklanıp sırayla tek tek çözmek, benzer yapıdaki tekrarlayan hataların (örneğin `MainAxisAlignment.between`, `FontWeight.black`, `.dart` eksikliği) gözden kaçmasına ve sürenin gereksiz uzamasına yol açar.
* **Çözüm/Kural:** Bir derleme hatası alındığında, sadece ilk hataya odaklanmak yerine tüm hata çıktısı analiz edilmeli ve projenin diğer dosyalarında da benzer kalıpların (patterns) bulunup bulunmadığı taranarak toplu (bulk) düzeltme yapılmalıdır.

### 9. Kullanıcı Talimatlarına Sıkı Uyum ve İnisiyatif Sınırları
* **Hata:** Kullanıcının sadece belirli bir ön hazırlık veya dosya taşıma işlemi talep ettiği durumlarda, bir sonraki adımlara dair henüz onay veya "başla" komutu almadan kodlama/geliştirme aşamasına geçilmesi.
* **Çözüm/Kural:** Kullanıcı bir sonraki adım için onay vermedikçe veya doğrudan komut vermedikçe sadece talep edilen dar kapsamlı işlemi yapıp durmalı ve onay beklemeliyiz. Kullanıcının analizleri okuma ve değerlendirme sürelerine saygı duyulmalı, erken inisiyatif alınarak kod tabanı değiştirilmemelidir.
### 10. SQLite Kolon Varlığı Doğrulaması (PRAGMA table_info)
* **Hata:** `appearances` tablosunda `season` ve `competition_id` kolonlarının varlığı varsayılarak sorgu yazıldı. Oysa `season` yalnızca `games` tablosunda bulunuyordu. Bu, `no such column` hatası fırlattı ve oyunlar spinner'da kitlenip kaldı.
* **Çözüm/Kural:** Yeni bir SQL sorgusu yazmadan önce mutlaka `PRAGMA table_info(tablo_adı)` ile hedef tablonun şemasını doğrula. Kolon başka bir tablodaysa uygun `JOIN` kullan.

### 11. SQLite REAL ↔ Dart int Tip Uyumsuzluğu
* **Hata:** Veritabanındaki `transfer_fee`, `highest_market_value_in_eur` gibi kolonlar `REAL` tipinde tanımlıyken, Dart tarafında `as int` ile cast edilmeye çalışıldığında sessiz tip hatası oluşarak oyunlar açılamadı.
* **Çözüm/Kural:** SQLite'dan gelen sayısal değerleri her zaman `(value as num? ?? 0).toInt()` ile güvenli bir şekilde dönüştür. `as int` yerine **asla** doğrudan cast yapma.

### 12. SQLite INTEGER Kolonunun String Olarak Cast Edilmesi
* **Hata:** `games.season` kolonu `INTEGER` (ör: 2019) ama Dart tarafında `as String?` ile cast edildi → tip hatası ve oyun açılmadı.
* **Çözüm/Kural:** Bir kolonun tipi emin olmadığında her zaman `?.toString()` kullan. `as String` sadece kesin TEXT kolonları için geçerlidir.



