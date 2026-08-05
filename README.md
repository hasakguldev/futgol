# Futgol ⚽

Türkçe futbol bilgi ve tahmin oyunları — Flutter ile yazılmış, tek bir yerel SQLite
veritabanı üzerinde çalışan 13 oyunluk bir koleksiyon.

Veri kaynağı Transfermarkt türevi bir veri kümesidir: 47.716 futbolcu, 796 kulüp,
88.808 maç, 1,88 milyon maç kaydı, 3,17 milyon kadro satırı.

## Kurulum

```bash
cd futgol_app
flutter pub get
flutter run
```

Uygulama ilk açılışta veri kümesini (`futgol.db.zip`, 329 MB) `ds` sürümünden
indirir, SHA-256 ile doğrular ve diske açar. İndirme ve arşivden çıkarma disk
üzerinden akışla yapılır, bellekte tutulmaz.

Hazır APK: [Releases](https://github.com/hasakguldev/futgol/releases/latest)

## Oyunlar

**🎮 Karşılıklı oyna** — Kronometre Futbolu (tek telefonda iki kişi)

**🕵️ Futbolcu bul** — Ortak Bağ Bulucu · Kariyer Yolu · 11'deki Gizemli Oyuncu ·
Transfer Köprüsü · Maç Dedektifi · Kart Cezası Canavarı · Zirve İstatistikler ·
Koleksiyoncu Grid

**🧠 Bilgi yarışması** — Yüksek/Düşük Değer · Piyasa Değeri Tahmin ·
Transfer Düellosu · Stadyum Atlası

## Zorluk sistemi

Zorluk üç eksende tanımlıdır: **kariyer zirve değeri**, **kariyerde oynanan ligler**
ve **dönem**.

| Seviye | Değer | Ligler | Dönem |
|---|---|---|---|
| 🟢 Kolay | 40M€+ | 5 Büyük Lig + Süper Lig | — |
| 🟡 Orta | 12–60M€ | + Portekiz, Hollanda, Belçika, Rusya, MLS… | — |
| 🔴 Zor | 4–20M€ | Tüm ligler | — |
| 👑 Efsaneler | 20M€+ | Tüm ligler | 2021 ve öncesi |

Lig kademeleri tahmin değil, ölçümdür. Her lig için şu skor hesaplanır:

```
skor = (50M€+ oyuncu sayısı × 3) + (20M€+ oyuncu sayısı)
     + (5 büyük lige geçiş yüzdesi × 2) + (medyan değer M€ × 4)
```

Bu ölçüm `tools/measure_league_difficulty.py` ile yeniden üretilebilir. Sonuçlar
`config/difficulty_rules.json` içinde saklanır.

**Neden piyasa değeri tek başına yetmiyor?** 40M€ değerinde olup yalnızca Portekiz
liginde oynamış bir futbolcu, sayıya bakınca "kolay" görünür ama Türkiye'deki bir
oyuncu için tanıdık değildir. Bu yüzden zorluk, futbolcunun *kariyeri boyunca*
hangi liglerde forma giydiğine de bakar.

Bu bilgi çalışma anında `appearances` tablosundan çıkarılsaydı soru başına ~700 ms
sürerdi. Bunun yerine derleme zamanında hesaplanıp bit maskesi olarak paketlenir
(`futgol_app/assets/data/player_leagues.csv`, 14.081 futbolcu, 157 KB) ve çalışma
anında 0 ms'e iner.

### Kuralları uygulama güncellemeden değiştirme

Uygulama `config/difficulty_rules.json` dosyasını `main` dalından canlı çeker.
Sürüm numarası artırıldığında istemciler yeni kuralları alır; uygulama içindeki
kopya çevrimdışı yedek olarak kalır.

## Proje yapısı

```
futgol_app/          Flutter uygulaması
  lib/common/        modeller, servisler, tema, ortak widget'lar
  lib/features/      oyun bazlı ekranlar
  assets/data/       önceden hesaplanmış kariyer-lig verisi
config/              zorluk kural kitabı (uygulama canlı çeker)
tools/               veri üretim ve ölçüm betikleri
tasks/               yol haritası ve tasarım notları
futgol_arsiv/        veri kümesi dönüştürücü ve web prototipleri
```

Veri kümesi (`futgol.db`, 875 MB) depoya dahil değildir; Releases üzerinden dağıtılır.

## Araçlar

```bash
# Kariyer-lig asset'ini veritabanından yeniden üret
python tools/gen_player_leagues_asset.py

# Lig tanınırlık skorlarını yeniden ölç
python tools/measure_league_difficulty.py
```

## Geliştirme

```bash
cd futgol_app
flutter analyze     # uyarısız olmalı
flutter test        # 38 test
flutter build apk --release
```

## Lisans

[MIT](LICENSE)
