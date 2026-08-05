import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

/// Zorluk seviyelerinin kural kitabı.
///
/// v2.0.0 ile model tamamen değişti. Eskiden zorluk iki eksende tanımlıydı:
/// piyasa değeri tabanı + oyuncunun GÜNCEL kulübünün ligi. Bu model üç ciddi
/// hata üretiyordu:
///
///  1. `current_club_domestic_competition_id` oyuncunun BUGÜN nerede oynadığını
///     söyler, kariyerini değil. Messi (Inter Miami/MLS), Cristiano Ronaldo
///     (Al-Nassr/Suudi), Neymar (Santos/Brezilya), Suárez, Müller, Busquets ve
///     Marcelo bu yüzden KOLAY moddan dışlanıyordu. 30M+ oyuncuların %20'si
///     eleniyordu ve elenenler tam da en tanınan isimlerdi.
///  2. "Veteran" modu `max 2M` ile en DÜŞÜK değerli oyuncuları seçiyordu:
///     38.494 kişilik havuz, tamamı hiç duyulmamış isimler. Tahmin edilmesi
///     imkânsız olduğu için oynanabilir bir mod değildi.
///  3. Lig kademeleri ölçülmemişti. Süper Lig, Premier Lig ile aynı kutudaydı;
///     buna karşılık Rusya ve Ukrayna ligleri "Orta" seviyedeydi — oysa bu iki
///     ligin oyuncularının 5 büyük lige geçiş oranı %12 ve %5,8 ile en düşük
///     iki değerdir. Ayrıca `KR1` kodu Hırvatistan ligine aittir, Kore'ye değil
///     (Kore `RSK1`); eski kural kitabı bunu yanlış sınıflandırmıştı.
///
/// Yeni model üç eksen kullanır:
///  • **değer**  : `highest_market_value_in_eur` (kariyer zirvesi) alt/üst bant
///  • **tanınırlık**: oyuncunun KARİYERİNDE oynadığı ligler
///    (`LeagueIntelligence` üzerinden, önceden hesaplanmış veriyle)
///  • **dönem**  : `last_season` — "Efsaneler" modunu mümkün kılar
///
/// Lig kademeleri tahmin değil; veritabanı üzerinde ölçülen bir skora dayanır:
///   skor = (50M+ oyuncu sayısı × 3) + (20M+ oyuncu sayısı)
///          + (5 büyük lige geçiş yüzdesi × 2) + (medyan değer(M€) × 4)
class DifficultyRulesService {
  static final DifficultyRulesService _instance = DifficultyRulesService._internal();
  factory DifficultyRulesService() => _instance;
  DifficultyRulesService._internal();

  static const String currentVersion = '2.0.0';

  /// Kural kitabının uzak kopyası.
  ///
  /// DÜZELTME: Eski adres `futgol-project/config` deposunu gösteriyordu; böyle
  /// bir depo yok, bu yüzden senkronizasyon her seferinde sessizce başarısız
  /// oluyordu ve kurallar uygulama güncellenmeden hiç değişemiyordu.
  static const String remoteRulesUrl =
      'https://raw.githubusercontent.com/hasakguldev/futgol/main/config/difficulty_rules.json';

  /// Varsayılan kural kitabı (uygulamayla birlikte gelir, çevrimdışı çalışır).
  static const Map<String, dynamic> _defaultRules = {
    "version": currentVersion,
    "updated_at": "2026-08-05T00:00:00Z",

    // Veritabanı üzerinde ölçülen tanınırlık skorları (şeffaflık için saklanır)
    "league_scores": {
      "GB1": 1670, "ES1": 1072, "IT1": 1017, "FR1": 877, "L1": 856,
      "PO1": 328, "NL1": 298, "TR1": 295, "BE1": 209,
      "C1": 127, "ARG1": 123, "GR1": 116, "A1": 103, "SA1": 100,
      "RU1": 94, "MLS1": 92, "KR1": 90, "BRA1": 90, "DK1": 87, "SC1": 85,
      "SE1": 78, "UKR1": 61, "PL1": 60, "SER1": 56, "NO1": 53, "MEX1": 51,
      "JAP1": 44, "TS1": 44, "RO1": 33, "RSK1": 0, "AUS1": 0, "COL1": 0
    },

    // Ölçülen skora göre kademeler
    "league_tiers": {
      "elit": ["GB1", "ES1", "IT1", "L1", "FR1"],
      "ust": ["PO1", "NL1", "TR1", "BE1"],
      "orta": ["C1", "ARG1", "GR1", "A1", "SA1", "RU1", "MLS1", "KR1", "BRA1", "DK1", "SC1"],
      "uzak": ["SE1", "UKR1", "PL1", "SER1", "NO1", "MEX1", "JAP1", "TS1", "RO1", "RSK1", "AUS1", "COL1"]
    },

    // Türkiye'deki oyuncu için yerel tanıdıklık: Süper Lig, ölçülen skoru
    // "üst" kademe olsa da bizim kullanıcımız için elit kadar tanıdıktır.
    "local_leagues": ["TR1"],

    "difficulties": {
      "easy": {
        "display_name": "Kolay",
        "title": "Er",
        "icon": "🟢",
        "min_highest_market_value": 40000000,
        "max_highest_market_value": null,
        // "local" anahtar kelimesi local_leagues listesini açar
        "exposure_tiers": ["elit", "local"],
        "description":
            "5 büyük lig ve Süper Lig'de forma giymiş, kariyer zirve değeri 40M€ "
            "üzerindeki yıldızlar. Messi, Ronaldo, Neymar gibi bugün MLS veya "
            "Suudi Arabistan'da oynayan efsaneler de dahil."
      },
      "medium": {
        "display_name": "Orta",
        "title": "Teğmen",
        "icon": "🟡",
        "min_highest_market_value": 12000000,
        "max_highest_market_value": 60000000,
        "exposure_tiers": ["elit", "ust", "orta"],
        "description":
            "Zirve değeri 12M€–60M€ arasında, Avrupa'nın tanınan liglerinde "
            "oynamış futbolcular. Bilirsiniz ama bir an düşünmeniz gerekir."
      },
      "hard": {
        "display_name": "Zor",
        "title": "Binbaşı",
        "icon": "🔴",
        "min_highest_market_value": 4000000,
        "max_highest_market_value": 20000000,
        "exposure_tiers": ["elit", "ust", "orta", "uzak"],
        "description":
            "Zirve değeri 4M€–20M€ arasında, dünyanın her liginden geniş havuz. "
            "Sıkı futbol takipçileri için."
      },
      "veteran": {
        "display_name": "Efsaneler",
        "title": "General",
        "icon": "👑",
        "min_highest_market_value": 20000000,
        "max_highest_market_value": null,
        "exposure_tiers": ["elit", "ust", "orta", "uzak"],
        // Dönem filtresi: kariyeri 2021 ve öncesinde biten oyuncular
        "max_last_season": 2021,
        "description":
            "Nostalji modu: kariyeri 2021 ve öncesinde tamamlanmış büyük isimler. "
            "Xavi, Totti, Drogba, Kaká, Pirlo, Casillas, Agüero…"
      }
    }
  };

  Map<String, dynamic> _rules = _defaultRules;
  bool _initialized = false;

  Map<String, dynamic> get rules => _rules;
  String get version => _rules['version']?.toString() ?? '0.0.0';

  /// Başlangıç yüklemesi (yerel önbellekten oku).
  ///
  /// DÜZELTME: Eski sürüm önbellekteki kural kitabını koşulsuz olarak
  /// yüklüyordu. Uygulama güncellenip varsayılan kurallar yenilendiğinde bile
  /// cihazda duran ESKİ sürüm kazanıyordu; kullanıcı düzeltilmiş kurallara asla
  /// geçemiyordu. Artık sürümler karşılaştırılıyor ve yeni olan kazanıyor.
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedRulesStr = prefs.getString('difficulty_rules_json');
      if (cachedRulesStr != null && cachedRulesStr.isNotEmpty) {
        final cached = jsonDecode(cachedRulesStr) as Map<String, dynamic>;
        final cachedVer = cached['version']?.toString() ?? '0.0.0';
        if (_isNewer(cachedVer, currentVersion)) {
          _rules = cached;
        } else {
          // Önbellek eski kaldı: uygulamanın kurallarına dön ve önbelleği tazele.
          _rules = _defaultRules;
          await prefs.setString('difficulty_rules_json', jsonEncode(_defaultRules));
          debugPrint('[Zorluk] Önbellek ($cachedVer) eski; $currentVersion yüklendi');
        }
      }
    } catch (e) {
      debugPrint('[Zorluk] Yerel önbellek okunamadı: $e');
      _rules = _defaultRules;
    }
    _initialized = true;
  }

  /// "2.0.0" > "1.11.3" karşılaştırması (sayısal, sözlük sırası değil).
  static bool _isNewer(String a, String b) {
    List<int> parse(String v) => v
        .split('.')
        .map((p) => int.tryParse(p.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();
    final pa = parse(a), pb = parse(b);
    for (int i = 0; i < 3; i++) {
      final x = i < pa.length ? pa[i] : 0;
      final y = i < pb.length ? pb[i] : 0;
      if (x != y) return x > y;
    }
    return false;
  }

  /// GitHub üzerinden kuralları senkronize et (yalnız daha yeni sürümü kabul eder).
  Future<bool> syncRules(String url) async {
    await initialize();
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final Map<String, dynamic> remoteRules =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final String remoteVer = remoteRules['version']?.toString() ?? '0.0.0';

        if (_isNewer(remoteVer, version)) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('difficulty_rules_json', jsonEncode(remoteRules));
          _rules = remoteRules;
          debugPrint('[Zorluk] Kurallar güncellendi → $remoteVer');
          return true;
        }
      }
    } catch (e) {
      debugPrint('[Zorluk] Senkronizasyon başarısız (çevrimdışı): $e');
    }
    return false;
  }

  /// Belirli bir zorluk seviyesinin kurallarını alma.
  Map<String, dynamic> getDifficultyConfig(String difficulty) {
    final diffs = _rules['difficulties'] as Map<String, dynamic>? ??
        _defaultRules['difficulties'] as Map<String, dynamic>;
    return diffs[difficulty] as Map<String, dynamic>? ??
        diffs['medium'] as Map<String, dynamic>;
  }

  /// Zorluğun izin verdiği lig kodlarının tamamı.
  /// `exposure_tiers` içindeki "local" anahtarı `local_leagues` listesini açar.
  Set<String> allowedLeaguesFor(String difficulty) {
    final config = getDifficultyConfig(difficulty);
    final tiers = (config['exposure_tiers'] as List<dynamic>?) ??
        (config['allowed_league_tiers'] as List<dynamic>?) ??
        const [];
    return leaguesForTiers(tiers).toSet();
  }

  /// Kademe adlarını lig kodlarına çevirir.
  List<String> leaguesForTiers(List<dynamic> tiers) {
    final tierMap = _rules['league_tiers'] as Map<String, dynamic>? ??
        _rules['leagues'] as Map<String, dynamic>? ??
        _defaultRules['league_tiers'] as Map<String, dynamic>;
    final locals = (_rules['local_leagues'] as List<dynamic>? ??
            _defaultRules['local_leagues'] as List<dynamic>)
        .map((e) => e.toString());

    final result = <String>{};
    for (final tier in tiers) {
      final key = tier.toString();
      if (key == 'all') {
        for (final v in tierMap.values) {
          result.addAll((v as List<dynamic>).map((e) => e.toString()));
        }
        result.addAll(locals);
        continue;
      }
      if (key == 'local') {
        result.addAll(locals);
        continue;
      }
      final list = tierMap[key] as List<dynamic>?;
      if (list != null) result.addAll(list.map((e) => e.toString()));
    }
    return result.toList();
  }

  /// Eski API ile uyumluluk (v1 kural kitabı yüklenmişse çalışmayı sürdürür).
  List<String> getLeaguesForTiers(List<dynamic> tiers) => leaguesForTiers(tiers);

  /// Zorluk açıklaması — arayüzde gösterilir, kurallarla birlikte güncellenir.
  String describe(String difficulty) {
    final config = getDifficultyConfig(difficulty);
    return config['description']?.toString() ?? '';
  }

  /// Arayüzde gösterilecek özet rozetler: "40M€+", "5 Büyük Lig + Süper Lig".
  List<String> summaryChips(String difficulty) {
    final config = getDifficultyConfig(difficulty);
    final chips = <String>[];

    final minV = (config['min_highest_market_value'] as num?)?.toInt();
    final maxV = (config['max_highest_market_value'] as num?)?.toInt();
    String fmt(int v) => v >= 1000000
        ? '${(v / 1000000).toStringAsFixed(0)}M€'
        : '${(v / 1000).toStringAsFixed(0)}K€';
    if (minV != null && maxV != null) {
      chips.add('${fmt(minV)} – ${fmt(maxV)}');
    } else if (minV != null && minV > 0) {
      chips.add('${fmt(minV)}+');
    }

    final tiers = (config['exposure_tiers'] as List<dynamic>?) ?? const [];
    final names = tiers
        .map((t) {
          switch (t.toString()) {
            case 'elit':
              return '5 Büyük Lig';
            case 'ust':
              return 'Üst Ligler';
            case 'orta':
              return 'Orta Ligler';
            case 'uzak':
              return 'Tüm Ligler';
            case 'local':
              return 'Süper Lig';
            default:
              return t.toString();
          }
        })
        .toList();
    if (names.contains('Tüm Ligler')) {
      chips.add('Tüm Ligler');
    } else if (names.isNotEmpty) {
      chips.add(names.join(' + '));
    }

    final maxSeason = (config['max_last_season'] as num?)?.toInt();
    if (maxSeason != null) chips.add('$maxSeason ve öncesi');

    return chips;
  }
}
