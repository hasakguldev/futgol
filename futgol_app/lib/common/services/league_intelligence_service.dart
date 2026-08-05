import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Futbolcuların KARİYERLERİ boyunca forma giydiği ligleri sağlar.
///
/// Neden ayrı bir servis?
/// Zorluk seviyesinin doğru çalışması için "bu oyuncu hangi liglerde oynadı?"
/// sorusunun cevabı gerekir. Veritabanında bu bilgi yalnızca 1.88 milyon
/// satırlık `appearances` tablosu taranarak çıkarılabiliyor — soru başına
/// ~700 ms. Ayrıca `players.current_club_domestic_competition_id` ve
/// `player_valuations.player_club_domestic_competition_id` alanlarının ikisi de
/// oyuncunun YALNIZCA GÜNCEL kulübünü tutar; Messi'nin kariyeri bu alanlara
/// göre sadece "MLS1"dir. Kariyer geçmişi için ikisi de kullanılamaz.
///
/// Bu yüzden lig geçmişi derleme zamanında hesaplanıp
/// `assets/data/player_leagues.csv` içine bit maskesi olarak paketlendi
/// (14.081 oyuncu, 157 KB). Çalışma anında maliyeti tek seferlik ~30 ms.
class LeagueIntelligence {
  static final LeagueIntelligence _instance = LeagueIntelligence._internal();
  factory LeagueIntelligence() => _instance;
  LeagueIntelligence._internal();

  static const String _assetPath = 'assets/data/player_leagues.csv';

  /// Bit indeksi → lig kodu (asset başlığından okunur)
  List<String> _leagueOrder = const [];
  final Map<String, int> _leagueBit = {};
  final Map<int, int> _masks = {};

  bool _loaded = false;
  Future<void>? _loading;

  bool get isLoaded => _loaded;
  int get playerCount => _masks.length;

  /// Asset'i bir kez yükler. Eşzamanlı çağrılar aynı Future'ı paylaşır.
  Future<void> ensureLoaded() {
    if (_loaded) return Future.value();
    return _loading ??= _load();
  }

  Future<void> _load() async {
    try {
      final raw = await rootBundle.loadString(_assetPath);
      final lines = raw.split('\n');
      if (lines.isEmpty) throw StateError('Lig verisi boş');

      // 1. satır: "v1;GB1,ES1,IT1,..."
      final header = lines.first.trim();
      final sep = header.indexOf(';');
      if (sep < 0) throw StateError('Lig verisi başlığı geçersiz');
      _leagueOrder = header.substring(sep + 1).split(',');
      for (int i = 0; i < _leagueOrder.length; i++) {
        _leagueBit[_leagueOrder[i]] = i;
      }

      for (int i = 1; i < lines.length; i++) {
        final line = lines[i];
        if (line.isEmpty) continue;
        final comma = line.indexOf(',');
        if (comma <= 0) continue;
        final id = int.tryParse(line.substring(0, comma));
        if (id == null) continue;
        final mask = int.tryParse(line.substring(comma + 1).trim(), radix: 36);
        if (mask == null) continue;
        _masks[id] = mask;
      }
      _loaded = true;
      debugPrint('[Lig] ${_masks.length} oyuncunun kariyer ligi yüklendi');
    } catch (e) {
      // Asset okunamazsa oyun çalışmaya devam eder; lig filtresi devre dışı
      // kalır ve zorluk yalnızca piyasa değeri + döneme göre uygulanır.
      debugPrint('[Lig] Kariyer ligi verisi yüklenemedi: $e');
      _loaded = true;
    }
  }

  /// Bir oyuncunun kariyerinde forma giydiği lig kodları.
  Set<String> leaguesOf(int playerId) {
    final mask = _masks[playerId];
    if (mask == null || mask == 0) return const {};
    final out = <String>{};
    for (int i = 0; i < _leagueOrder.length; i++) {
      if (mask & (1 << i) != 0) out.add(_leagueOrder[i]);
    }
    return out;
  }

  /// Oyuncunun izin verilen liglerden en az birinde oynayıp oynamadığı.
  ///
  /// `allowed` boşsa (kural tanımlanmamışsa) herkes geçer.
  /// Oyuncunun lig verisi yoksa `false` döner — veri yokluğu, tanınırlık
  /// iddiası için yeterli sebep değildir.
  bool matchesExposure(int playerId, Set<String> allowed) {
    if (allowed.isEmpty) return true;
    if (!_loaded || _masks.isEmpty) return true; // veri yoksa filtre uygulama
    final mask = _masks[playerId];
    if (mask == null) return false;
    for (final code in allowed) {
      final bit = _leagueBit[code];
      if (bit != null && mask & (1 << bit) != 0) return true;
    }
    return false;
  }

  /// Tanıdık bir lig etiketi üretir: "İngiltere · İspanya" gibi.
  String exposureLabel(int playerId, {int max = 3}) {
    final ligs = leaguesOf(playerId);
    if (ligs.isEmpty) return '';
    final names = ligs.map((c) => leagueNames[c] ?? c).toList()..sort();
    if (names.length <= max) return names.join(' · ');
    return '${names.take(max).join(' · ')} +${names.length - max}';
  }

  static const Map<String, String> leagueNames = {
    'GB1': 'Premier Lig',
    'ES1': 'LaLiga',
    'IT1': 'Serie A',
    'L1': 'Bundesliga',
    'FR1': 'Ligue 1',
    'TR1': 'Süper Lig',
    'PO1': 'Portekiz',
    'NL1': 'Hollanda',
    'BE1': 'Belçika',
    'RU1': 'Rusya',
    'GR1': 'Yunanistan',
    'SC1': 'İskoçya',
    'DK1': 'Danimarka',
    'A1': 'Avusturya',
    'C1': 'İsviçre',
    'UKR1': 'Ukrayna',
    'RO1': 'Romanya',
    'KR1': 'Hırvatistan',
    'SER1': 'Sırbistan',
    'PL1': 'Polonya',
    'TS1': 'Çekya',
    'SE1': 'İsveç',
    'NO1': 'Norveç',
    'MLS1': 'MLS',
    'BRA1': 'Brezilya',
    'ARG1': 'Arjantin',
    'MEX1': 'Meksika',
    'SA1': 'Suudi Arabistan',
    'JAP1': 'Japonya',
    'RSK1': 'Güney Kore',
    'AUS1': 'Avustralya',
    'COL1': 'Kolombiya',
  };
}
