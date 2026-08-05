import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../models/question_models.dart';
import '../models/football_player.dart';
import 'difficulty_rules_service.dart';
import 'league_intelligence_service.dart';
import 'db_text_utils.dart';

class DatabaseService {
  // Singleton Yapısı
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;
  bool _isLoaded = false;

  /// Son veritabanı hatası. Ekranlar sessiz "soru üretilemedi" yerine
  /// gerçek nedeni gösterebilsin diye tutuluyor.
  String? _lastError;
  String? get lastError => _lastError;

  bool get isLoaded => _isLoaded;

  void _fail(String context, Object error) {
    _lastError = '$context: $error';
    debugPrint('[DB] $_lastError');
  }

  /// Sorguları merkezî hata yakalama ile çalıştırır.
  Future<List<Map<String, Object?>>> _query(
    String context,
    String sql, [
    List<Object?> params = const [],
  ]) async {
    final db = _db;
    if (db == null) {
      _lastError = '$context: Veritabanı yüklenmemiş.';
      return const [];
    }
    try {
      return await db.rawQuery(sql, params);
    } catch (e) {
      _fail(context, e);
      return const [];
    }
  }

  // Veritabanı durumunu kontrol etme
  Future<bool> checkDatabaseStatus() async {
    if (_db != null && _isLoaded) return true;

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, "futgol.db");
    final exists = await File(path).exists();

    if (exists && _db == null) {
      try {
        _db = await openDatabase(path, readOnly: true);
        await _tuneConnection();
        _isLoaded = true;
        // Zorluk motorunun ihtiyaç duyduğu kariyer-lig verisini arka planda
        // hazırla; ilk soru gelmeden hazır olur.
        unawaited(LeagueIntelligence().ensureLoaded());
        unawaited(DifficultyRulesService().initialize());
        return true;
      } catch (e) {
        _fail('Mevcut veritabanı açılamadı', e);
        return false;
      }
    }
    return _isLoaded;
  }

  /// Salt-okunur açılan 875 MB'lık veritabanında sorgu hızını artıran ayarlar.
  Future<void> _tuneConnection() async {
    final db = _db;
    if (db == null) return;
    try {
      await db.rawQuery('PRAGMA cache_size = -20000'); // ~20 MB sayfa önbelleği
      await db.rawQuery('PRAGMA temp_store = MEMORY');
      await db.rawQuery('PRAGMA mmap_size = 268435456'); // 256 MB
    } catch (e) {
      // Bazı platformlarda PRAGMA salt-okunur bağlantıda reddedilebilir; kritik değil.
      debugPrint('[DB] PRAGMA ayarlanamadı: $e');
    }
  }

  // Veritabanı indirme, doğrulama, çıkarma ve yükleme adımları (OOM/RAM Sızıntısını Önleme - Disk Stream Destekli)
  Future<void> setupDatabase({
    required String url,
    required String? expectedHash,
    required Function(String stage, double percent) onProgress,
  }) async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final tempZipPath = join(documentsDirectory.path, "futgol.db.zip.temp");
    final targetDbPath = join(documentsDirectory.path, "futgol.db");

    // Önceki geçici ve hedef dosyaları temizle
    final tempZipFile = File(tempZipPath);
    if (await tempZipFile.exists()) {
      await tempZipFile.delete();
    }
    final targetDbFile = File(targetDbPath);
    if (await targetDbFile.exists()) {
      await targetDbFile.delete();
    }

    try {
      // 1. ADIM: İndirme (Download) - Doğrudan Diske Stream ederek (0 MB RAM)
      onProgress('download', 0.0);
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception(
          "Veritabanı zip dosyası indirilemedi (Status: ${response.statusCode})",
        );
      }

      final contentLength = response.contentLength ?? 0;
      int receivedBytes = 0;

      // Dosyaya yazmak için sink açıyoruz
      final IOSink fileSink = tempZipFile.openWrite();

      await for (var chunk in response.stream) {
        fileSink.add(chunk);
        receivedBytes += chunk.length;
        if (contentLength > 0) {
          double percent = (receivedBytes / contentLength) * 100;
          onProgress('download', percent);
        }
      }
      await fileSink.close();
      client.close();
      onProgress('download', 100.0);

      // 1.5. ADIM: Hash Doğrulama (Verify) - Dosyayı RAM'e yüklemeden Stream olarak doğrulama
      if (expectedHash != null && expectedHash.isNotEmpty) {
        onProgress('verify', 0.0);
        final hashStream = tempZipFile.openRead();
        final computedHashDigest = await sha256.bind(hashStream).first;
        final computedHash = computedHashDigest.toString().toLowerCase();

        if (computedHash != expectedHash.toLowerCase().trim()) {
          throw Exception(
            "Bütünlük doğrulaması (SHA-256) başarısız oldu.\nBeklenen: $expectedHash\nHesaplanan: $computedHash",
          );
        }
        onProgress('verify', 100.0);
      }

      // 2. ADIM: Arşivden Çıkarma (Unzip) - InputFileStream ve OutputFileStream kullanarak disk üzerinden çıkarma
      onProgress('unzip', 20.0);
      final inputStream = InputFileStream(tempZipPath);
      final archive = ZipDecoder().decodeBuffer(inputStream);
      onProgress('unzip', 60.0);

      final dbFileInZip = archive.findFile('futgol.db');
      if (dbFileInZip == null) {
        throw Exception("Zip arşivi içerisinde futgol.db dosyası bulunamadı.");
      }

      onProgress('unzip', 80.0);
      final outputStream = OutputFileStream(targetDbPath);
      dbFileInZip.writeContent(outputStream);
      outputStream.close();
      inputStream.close();
      onProgress('unzip', 100.0);

      // Geçici zip dosyasını temizle
      if (await tempZipFile.exists()) {
        await tempZipFile.delete();
      }

      // 3. ADIM: Yükleme (Load)
      onProgress('load', 50.0);
      _db = await openDatabase(targetDbPath, readOnly: true);
      await _tuneConnection();
      _isLoaded = true;
      onProgress('load', 100.0);
    } catch (e) {
      _fail('Kurulum', e);
      _isLoaded = false;
      _db = null;
      // Hata durumunda kalan dosyaları temizle
      if (await tempZipFile.exists()) {
        await tempZipFile.delete();
      }
      if (await targetDbFile.exists()) {
        await targetDbFile.delete();
      }
      rethrow;
    }
  }

  // ==========================================
  // ARAMA / AUTOCOMPLETE
  // ==========================================

  /// Zengin oyuncu araması: aksan duyarsız (guler -> Güler), piyasa değerine
  /// göre sıralı, fotoğraf ve mevki bilgisiyle birlikte döner.
  Future<List<FootballPlayer>> searchPlayers(
    String query, {
    int limit = 8,
  }) async {
    final q = query.trim();
    if (q.length < 2) return const [];

    const columns =
        'player_id, name, image_url, position, sub_position, country_of_citizenship, '
        'current_club_name, highest_market_value_in_eur, date_of_birth, foot';

    // 1) Hızlı yol: ASCII LIKE (indeksten faydalanır, çoğu arama burada biter)
    var rows = await _query(
      'Oyuncu araması',
      '''
        SELECT $columns FROM players
        WHERE name LIKE ?
        ORDER BY COALESCE(highest_market_value_in_eur, 0) DESC
        LIMIT ?
      ''',
      ['%$q%', limit],
    );

    // 2) Sonuç yoksa aksan duyarsız GLOB ile tekrar dene ("ozil" -> "Özil")
    if (rows.isEmpty) {
      rows = await _query(
        'Oyuncu araması (aksansız)',
        '''
          SELECT $columns FROM players
          WHERE name GLOB ?
          ORDER BY COALESCE(highest_market_value_in_eur, 0) DESC
          LIMIT ?
        ''',
        [DbText.globPattern(q), limit],
      );
    }

    return rows.map(FootballPlayer.fromRow).toList();
  }

  /// Geriye dönük uyumluluk: sadece isim listesi döner.
  Future<List<String>> autocomplete(String query) async {
    final players = await searchPlayers(query, limit: 8);
    return players.map((p) => p.name).toList();
  }

  /// Kulüp araması (kadro kurulumu ve grid oyunları için).
  Future<List<FootballClub>> searchClubs(String query, {int limit = 8}) async {
    final q = query.trim();
    if (q.length < 2) return const [];

    var rows = await _query(
      'Kulüp araması',
      '''
        SELECT club_id, COALESCE(short_name, name) as name, domestic_competition_id,
               squad_size, stadium_seats, stadium_name
        FROM clubs
        WHERE name LIKE ? OR short_name LIKE ?
        ORDER BY national_team_players DESC, squad_size DESC
        LIMIT ?
      ''',
      ['%$q%', '%$q%', limit],
    );

    if (rows.isEmpty) {
      final pattern = DbText.globPattern(q);
      rows = await _query(
        'Kulüp araması (aksansız)',
        '''
          SELECT club_id, COALESCE(short_name, name) as name, domestic_competition_id,
                 squad_size, stadium_seats, stadium_name
          FROM clubs
          WHERE name GLOB ? OR short_name GLOB ?
          ORDER BY national_team_players DESC, squad_size DESC
          LIMIT ?
        ''',
        [pattern, pattern, limit],
      );
    }

    return rows.map(FootballClub.fromRow).toList();
  }

  /// Kadro kurulumunda "hızlı doldur" için popüler kulüpler.
  Future<List<FootballClub>> getPopularClubs({int limit = 24}) async {
    final rows = await _query(
      'Popüler kulüpler',
      '''
        SELECT club_id, COALESCE(short_name, name) as name, domestic_competition_id,
               squad_size, stadium_seats, stadium_name
        FROM clubs
        WHERE squad_size >= 18 AND national_team_players >= 1
        ORDER BY national_team_players DESC, stadium_seats DESC
        LIMIT ?
      ''',
      [limit],
    );
    return rows.map(FootballClub.fromRow).toList();
  }

  /// Bir kulübün en çok forma giymiş oyuncularını döner.
  /// Kronometre Futbolu'nda 10 kişilik kadroyu tek dokunuşla doldurmak için.
  Future<List<FootballPlayer>> getSquadForClub(
    int clubId, {
    int limit = 10,
  }) async {
    final rows = await _query(
      'Kulüp kadrosu',
      '''
        SELECT p.player_id, p.name, p.image_url, p.position, p.sub_position,
               p.country_of_citizenship, p.current_club_name,
               p.highest_market_value_in_eur, p.date_of_birth, p.foot,
               COUNT(DISTINCT a.game_id) as apps
        FROM appearances a
        JOIN players p ON p.player_id = a.player_id
        WHERE a.player_club_id = ?
        GROUP BY p.player_id
        ORDER BY apps DESC
        LIMIT ?
      ''',
      [clubId, limit],
    );
    return rows.map(FootballPlayer.fromRow).toList();
  }

  /// Tek bir oyuncunun kart bilgisi (fotoğraf, mevki, değer, kariyer özeti).
  Future<FootballPlayer?> getPlayerById(int playerId) async {
    final rows = await _query(
      'Oyuncu kartı',
      '''
        SELECT player_id, name, image_url, position, sub_position,
               country_of_citizenship, current_club_name,
               highest_market_value_in_eur, date_of_birth, foot
        FROM players WHERE player_id = ? LIMIT 1
      ''',
      [playerId],
    );
    if (rows.isEmpty) return null;
    return FootballPlayer.fromRow(rows.first);
  }

  /// İsimden oyuncu kartı çözer (eski ekranlar isimle çalışıyor).
  Future<FootballPlayer?> getPlayerByName(String name) async {
    final results = await searchPlayers(name, limit: 1);
    return results.isEmpty ? null : results.first;
  }

  /// Oyuncunun kariyer istatistiği: toplam maç, gol, asist, kart.
  Future<Map<String, int>> getPlayerCareerStats(int playerId) async {
    final rows = await _query(
      'Oyuncu istatistiği',
      '''
        SELECT COUNT(DISTINCT game_id) as apps, COALESCE(SUM(goals),0) as goals,
               COALESCE(SUM(assists),0) as assists,
               COALESCE(SUM(yellow_cards),0) as yellow, COALESCE(SUM(red_cards),0) as red
        FROM appearances WHERE player_id = ?
      ''',
      [playerId],
    );
    if (rows.isEmpty) return const {};
    final r = rows.first;
    return {
      'apps': (r['apps'] as num?)?.toInt() ?? 0,
      'goals': (r['goals'] as num?)?.toInt() ?? 0,
      'assists': (r['assists'] as num?)?.toInt() ?? 0,
      'yellow': (r['yellow'] as num?)?.toInt() ?? 0,
      'red': (r['red'] as num?)?.toInt() ?? 0,
    };
  }

  // ==========================================
  // ORTAK BAĞ OYUNU SORGULARI
  // ==========================================

  /// İki oyuncunun birlikte forma giydiği kulüpler.
  ///
  /// ÖNEMLİ: Eski sürüm `appearances` tablosunu kendisiyle `player_club_id`
  /// üzerinden JOIN'liyordu. 1.88 milyon satırlık tabloda bu, kulüp başına
  /// kartezyen çarpım üretip sorguyu 100 saniyenin üzerine çıkarıyordu
  /// (pratikte uygulama donuyordu). Alt sorgu (IN) yaklaşımı aynı sonucu
  /// ~30 ms'de veriyor.
  Future<List<String>> getCommonClubs(String player1, String player2) async {
    final rows = await _query(
      'Ortak kulüpler',
      '''
        SELECT DISTINCT COALESCE(c.short_name, c.name) as club_name
        FROM clubs c
        WHERE c.club_id IN (
                SELECT player_club_id FROM appearances
                WHERE player_id IN (SELECT player_id FROM players WHERE name LIKE ?)
              )
          AND c.club_id IN (
                SELECT player_club_id FROM appearances
                WHERE player_id IN (SELECT player_id FROM players WHERE name LIKE ?)
              )
        ORDER BY club_name
      ''',
      ['%$player1%', '%$player2%'],
    );
    return rows.map((r) => r['club_name'] as String).toList();
  }

  /// Tahmin edilen oyuncunun, hem P1 hem P2 ile aynı kulüpte oynayıp
  /// oynamadığını doğrular.
  Future<bool> checkPlayerClubsCommon(
    String guess,
    String player1,
    String player2,
  ) async {
    final guessClubs = await _clubIdsOfPlayerName(guess);
    if (guessClubs.isEmpty) return false;

    final p1Clubs = await _clubIdsOfPlayerName(player1);
    if (p1Clubs.intersection(guessClubs).isEmpty) return false;

    final p2Clubs = await _clubIdsOfPlayerName(player2);
    return p2Clubs.intersection(guessClubs).isNotEmpty;
  }

  Future<Set<int>> _clubIdsOfPlayerName(String name) async {
    final rows = await _query(
      'Oyuncu kulüpleri',
      '''
        SELECT DISTINCT player_club_id FROM appearances
        WHERE player_id IN (SELECT player_id FROM players WHERE name LIKE ?)
      ''',
      ['%$name%'],
    );
    return rows.map((r) => (r['player_club_id'] as num).toInt()).toSet();
  }

  /// Tahmin edilen oyuncunun iki kulüpte de oynayıp oynamadığını doğrular.
  Future<bool> checkClubPlayerCommon(
    String guess,
    String team1,
    String team2,
  ) async {
    final rows = await _query(
      'Ortak kulüp oyuncusu',
      '''
        SELECT
          MAX(CASE WHEN a.player_club_id IN
                (SELECT club_id FROM clubs WHERE name LIKE ? OR short_name LIKE ?)
              THEN 1 ELSE 0 END) as in_first,
          MAX(CASE WHEN a.player_club_id IN
                (SELECT club_id FROM clubs WHERE name LIKE ? OR short_name LIKE ?)
              THEN 1 ELSE 0 END) as in_second
        FROM appearances a
        WHERE a.player_id IN (SELECT player_id FROM players WHERE name LIKE ?)
      ''',
      ['%$team1%', '%$team1%', '%$team2%', '%$team2%', '%$guess%'],
    );
    if (rows.isEmpty) return false;
    final r = rows.first;
    return ((r['in_first'] as num?)?.toInt() ?? 0) == 1 &&
        ((r['in_second'] as num?)?.toInt() ?? 0) == 1;
  }

  /// Yıl bazlı takımları getirme.
  ///
  /// DÜZELTME: `appearances` tablosunda `season` kolonu YOKTUR; eski sorgu
  /// "no such column: a.season" hatasıyla her seferinde sabit yedek listeye
  /// düşüyordu. Sezon bilgisi `games` tablosunda bulunur.
  Future<List<String>> getTeamsByYear(String year) async {
    final int? seasonInt = int.tryParse(
      year.trim().length >= 4 ? year.trim().substring(0, 4) : year.trim(),
    );
    if (seasonInt == null) return _fallbackTeams;

    final results = await _query(
      'Yıla göre takımlar',
      '''
        SELECT DISTINCT COALESCE(c.short_name, c.name) as name
        FROM clubs c
        JOIN games g ON g.home_club_id = c.club_id OR g.away_club_id = c.club_id
        WHERE g.season = ?
        ORDER BY name ASC
      ''',
      [seasonInt],
    );

    if (results.isEmpty) return _fallbackTeams;
    return results.map((r) => r['name'] as String).toList();
  }

  static const List<String> _fallbackTeams = [
    'Barcelona',
    'Real Madrid',
    'Bayern Münih',
    'Manchester City',
    'Liverpool',
    'Juventus',
    'Paris Saint-Germain',
    'Chelsea',
    'Galatasaray',
    'Fenerbahçe',
    'Beşiktaş',
  ];

  // Takım ismine göre oyuncuları getirme
  Future<List<String>> getPlayersByTeam(String teamName) async {
    final results = await _query(
      'Takım oyuncuları',
      '''
        SELECT DISTINCT p.name FROM players p
        JOIN appearances a ON a.player_id = p.player_id
        WHERE a.player_club_id IN (
          SELECT club_id FROM clubs WHERE name = ? OR name LIKE ? OR short_name = ? OR short_name LIKE ?
        )
        ORDER BY p.name ASC
      ''',
      [teamName, '%$teamName%', teamName, '%$teamName%'],
    );
    return results.map((r) => r['name'] as String).toList();
  }

  // Dinamik olarak zorluk kurallarına göre oyuncu sorusu üretir
  Future<PlayerQuestion?> generateDynamicPlayerQuestion(
    String difficulty,
  ) async {
    if (_db == null) return null;
    try {
      await DifficultyRulesService().initialize();
      final random = Random();

      // Adım 1: Zorluğa uyan birinci oyuncuyu (P1) seç.
      // Değer/dönem SQL'de, lig tanınırlığı önceden hesaplanmış veriyle.
      final p1Row = await pickPlayerForDifficulty(
        difficulty,
        columns:
            'player_id, name, image_url, position, country_of_citizenship, '
            'highest_market_value_in_eur, last_season',
      );
      if (p1Row == null) return null;
      final p1Id = (p1Row['player_id'] as num).toInt();
      final p1Name = p1Row['name'] as String;

      // Adım 2: P1'in oynadığı kulüpleri bul
      final clubRows = await _query(
        'Dinamik oyuncu sorusu (P1 kulüpleri)',
        'SELECT DISTINCT player_club_id FROM appearances WHERE player_id = ?',
        [p1Id],
      );

      if (clubRows.isEmpty) return null;
      final List<int> p1Clubs = clubRows
          .map((r) => (r['player_club_id'] as num).toInt())
          .toList();
      final String clubsPlaceholder = p1Clubs.map((_) => '?').join(',');

      // Adım 3: Aynı kulüplerde oynamış ve zorluğa uyan ikinci oyuncuyu (P2) seç
      final p2Filter = _difficultyValueFilter(difficulty, prefix: 'p.');
      final p2Candidates = await _query(
        'Dinamik oyuncu sorusu (P2)',
        '''
          SELECT DISTINCT p.player_id, p.name FROM players p
          WHERE p.player_id != ?
            AND ${p2Filter.sql}
            AND p.player_id IN (
              SELECT player_id FROM appearances WHERE player_club_id IN ($clubsPlaceholder)
            )
          ORDER BY RANDOM() LIMIT 25
        ''',
        [p1Id, ...p2Filter.params, ...p1Clubs],
      );

      if (p2Candidates.isEmpty) return null;
      final p2Rows = await filterByDifficulty(difficulty, p2Candidates);

      // Rastgele bir P2 seç
      final p2Choice = p2Rows[random.nextInt(p2Rows.length)];
      final p2Id = (p2Choice['player_id'] as num).toInt();
      final p2Name = p2Choice['name'] as String;

      // Adım 4: Hem P1 hem P2 ile takım arkadaşlığı yapmış oyuncuları bul (Answers)
      //
      // DÜZELTME: Eski sorgu `appearances a1 JOIN appearances a2 ... JOIN players p
      // ON a1.player_id = p.player_id WHERE a1.player_id = p1 AND p.player_id != p1`
      // şeklindeydi; yani p her zaman P1'in kendisiydi ve ardından P1 dışlandığı
      // için sonuç DAİMA boş dönüyordu. Oyuncu modunda hiçbir zaman gerçek cevap
      // listesi/ipucu üretilemiyordu.
      // Cevap havuzu da zorluğa göre süzülür: "Kolay" oyunda cevabın da
      // tanınabilir olması gerekir, yalnızca sorunun değil.
      final rawAnswers = await _query(
        'Dinamik oyuncu sorusu (cevaplar)',
        '''
          SELECT DISTINCT p.name, p.player_id, p.country_of_citizenship, p.position, p.image_url
          FROM players p
          WHERE p.player_id != ? AND p.player_id != ?
            AND p.highest_market_value_in_eur >= 1000000
            AND p.player_id IN (
              SELECT player_id FROM appearances
              WHERE player_club_id IN (SELECT player_club_id FROM appearances WHERE player_id = ?)
            )
            AND p.player_id IN (
              SELECT player_id FROM appearances
              WHERE player_club_id IN (SELECT player_club_id FROM appearances WHERE player_id = ?)
            )
          ORDER BY COALESCE(p.highest_market_value_in_eur, 0) DESC
          LIMIT 30
        ''',
        [p1Id, p2Id, p1Id, p2Id],
      );
      final answersRows = rawAnswers.isEmpty
          ? rawAnswers
          : await filterByDifficulty(difficulty, rawAnswers);

      List<String> answers = [];
      List<Clue> clues = [];

      if (answersRows.isNotEmpty) {
        answers = answersRows.map((r) => r['name'] as String).toList();

        // Rastgele birini ipucu oyuncusu seç
        final cluePlayer = answersRows[random.nextInt(answersRows.length)];
        final cluePlayerId = cluePlayer['player_id'] as int;
        final nation =
            cluePlayer['country_of_citizenship'] as String? ?? 'Bilinmiyor';
        final pos = FootballPlayer.fromRow(cluePlayer).positionTr;

        // İpucu oyuncusunun oynadığı bazı kulüpleri bul
        final clueClubsRows = await _query(
          'Dinamik oyuncu sorusu (ipucu kulüpleri)',
          '''
            SELECT DISTINCT COALESCE(c.short_name, c.name) as name FROM clubs c
            WHERE c.club_id IN (SELECT player_club_id FROM appearances WHERE player_id = ?)
            LIMIT 3
          ''',
          [cluePlayerId],
        );
        final clubNames = clueClubsRows
            .map((r) => r['name'] as String)
            .join(' / ');

        clues = [
          Clue(type: "Uyruk", value: nation),
          Clue(type: "Mevki", value: pos),
          Clue(type: "Kulüpler", value: clubNames),
        ];
      } else {
        clues = [
          Clue(
            type: "Bilgi",
            value: "İki oyuncu da aynı kulüpte ter dökmüştür.",
          ),
          Clue(type: "Zorluk", value: difficulty.toUpperCase()),
        ];
        answers = [p1Name, p2Name];
      }

      return PlayerQuestion(
        difficulty: difficulty,
        player1: p1Name,
        player2: p2Name,
        answers: answers,
        clues: clues,
      );
    } catch (e) {
      _fail('Dinamik oyuncu sorusu', e);
      return null;
    }
  }

  // ==========================================
  // ZORLUK MOTORU (v2)
  // ==========================================

  /// Zorluğun SQL ile ucuza uygulanabilen kısmı: değer bandı ve dönem.
  ///
  /// Lig tanınırlığı burada YOK — çünkü oyuncunun kariyer ligini SQL'den
  /// çıkarmak sorgu başına ~700 ms tutuyor. O kısım [LeagueIntelligence] ile
  /// aday listesi üzerinde Dart tarafında uygulanır.
  _SqlFilter _difficultyValueFilter(String difficulty, {String prefix = ''}) {
    final config = DifficultyRulesService().getDifficultyConfig(difficulty);
    final buffer = StringBuffer();
    final params = <Object?>[];

    final minVal = (config['min_highest_market_value'] as num?)?.toInt() ?? 0;
    buffer.write('COALESCE(${prefix}highest_market_value_in_eur, 0) >= ?');
    params.add(minVal);

    final maxVal = (config['max_highest_market_value'] as num?)?.toInt();
    if (maxVal != null) {
      buffer.write(
        ' AND COALESCE(${prefix}highest_market_value_in_eur, 0) <= ?',
      );
      params.add(maxVal);
    }

    final maxSeason = (config['max_last_season'] as num?)?.toInt();
    if (maxSeason != null) {
      buffer.write(' AND ${prefix}last_season <= ?');
      params.add(maxSeason);
    }
    final minSeason = (config['min_last_season'] as num?)?.toInt();
    if (minSeason != null) {
      buffer.write(' AND ${prefix}last_season >= ?');
      params.add(minSeason);
    }

    return _SqlFilter(buffer.toString(), params);
  }

  /// Zorluğa uyan rastgele bir oyuncu satırı seçer.
  ///
  /// İki aşamalı çalışır:
  ///   1. SQL değer/dönem bandına uyan bir aday YIĞINI çeker (~5 ms)
  ///   2. Dart, adayları kariyer ligi tanınırlığına göre eler
  /// Böylece hem doğru semantik hem de hızlı sorgu elde edilir.
  Future<Map<String, Object?>?> pickPlayerForDifficulty(
    String difficulty, {
    String columns =
        'player_id, name, image_url, position, sub_position, '
        'country_of_citizenship, current_club_name, highest_market_value_in_eur, '
        'date_of_birth, foot, last_season',
    String extraWhere = '',
    List<Object?> extraParams = const [],
    int batchSize = 48,
    int maxBatches = 4,
  }) async {
    final candidates = await pickPlayersForDifficulty(
      difficulty,
      columns: columns,
      extraWhere: extraWhere,
      extraParams: extraParams,
      batchSize: batchSize,
      maxBatches: maxBatches,
      wanted: 1,
    );
    return candidates.isEmpty ? null : candidates.first;
  }

  /// [pickPlayerForDifficulty]'nin çoklu sonuç veren biçimi.
  Future<List<Map<String, Object?>>> pickPlayersForDifficulty(
    String difficulty, {
    String columns =
        'player_id, name, image_url, position, sub_position, '
        'country_of_citizenship, current_club_name, highest_market_value_in_eur, '
        'date_of_birth, foot, last_season',
    String extraWhere = '',
    List<Object?> extraParams = const [],
    int batchSize = 48,
    int maxBatches = 4,
    int wanted = 1,
  }) async {
    final rules = DifficultyRulesService();
    await rules.initialize();
    final league = LeagueIntelligence();
    await league.ensureLoaded();

    final allowed = rules.allowedLeaguesFor(difficulty);
    final filter = _difficultyValueFilter(difficulty);
    final where = extraWhere.isEmpty
        ? filter.sql
        : '${filter.sql} AND $extraWhere';
    final params = [...filter.params, ...extraParams];

    final picked = <Map<String, Object?>>[];
    final seen = <int>{};

    for (int batch = 0; batch < maxBatches && picked.length < wanted; batch++) {
      final rows = await _query(
        'Zorluk havuzu ($difficulty)',
        'SELECT $columns FROM players WHERE $where ORDER BY RANDOM() LIMIT ?',
        [...params, batchSize],
      );
      if (rows.isEmpty) break;

      for (final row in rows) {
        final id = (row['player_id'] as num?)?.toInt();
        if (id == null || !seen.add(id)) continue;
        if (!league.matchesExposure(id, allowed)) continue;
        picked.add(row);
        if (picked.length >= wanted) break;
      }
    }

    // Hiç aday kalmadıysa lig şartını gevşet — oyunun tamamen durmasındansa
    // bir seviye kolay/zor bir soru üretmek yeğdir.
    if (picked.isEmpty) {
      final rows = await _query(
        'Zorluk havuzu ($difficulty, gevşetilmiş)',
        'SELECT $columns FROM players WHERE $where ORDER BY RANDOM() LIMIT ?',
        [...params, wanted],
      );
      picked.addAll(rows);
    }
    return picked;
  }

  /// Zorluğun izin verdiği lig kodları (kural kitabı hazır değilse yükler).
  Future<List<String>> _leaguesForDifficulty(String difficulty) async {
    final rules = DifficultyRulesService();
    await rules.initialize();
    return rules.allowedLeaguesFor(difficulty).toList();
  }

  /// Verilen oyuncu kimliklerini zorluk kurallarına göre süzer.
  /// Cevap/ipucu havuzlarının da seviyeye uygun olmasını sağlar.
  Future<List<Map<String, Object?>>> filterByDifficulty(
    String difficulty,
    List<Map<String, Object?>> rows,
  ) async {
    final rules = DifficultyRulesService();
    await rules.initialize();
    final league = LeagueIntelligence();
    await league.ensureLoaded();
    final allowed = rules.allowedLeaguesFor(difficulty);

    final out = rows.where((r) {
      final id = (r['player_id'] as num?)?.toInt();
      if (id == null) return false;
      return league.matchesExposure(id, allowed);
    }).toList();
    return out.isEmpty ? rows : out;
  }

  // Dinamik olarak zorluk kurallarına göre takım sorusu üretir
  Future<TeamQuestion?> generateDynamicTeamQuestion(String difficulty) async {
    if (_db == null) return null;
    try {
      final rulesService = DifficultyRulesService();
      await rulesService.initialize();

      // Zorluğun izin verdiği ligler (ölçülmüş kademelerden)
      final allowedLeagues = rulesService
          .allowedLeaguesFor(difficulty)
          .toList();
      final bool allowAllLeagues = allowedLeagues.isEmpty;

      // Kulüp tanınırlığı zorlukla ölçekleniyor: Kolay modda yalnızca millî
      // takım oyuncusu bol, büyük kadrolu kulüpler sorulur.
      final int minNationalPlayers = difficulty == 'easy'
          ? 6
          : difficulty == 'medium'
          ? 3
          : 1;

      final random = Random();

      // Adım 1: Koşullara uyan birinci kulübü (C1) seç.
      // Dış döngü: bazı küçük kulüplerin `appearances` kayıtlarındaki oyuncular
      // `players` tablosunda bulunmuyor; böyle bir C1'e düşersek hiçbir aday
      // eşleşmiyor. Bu durumda baştan başka bir kulüple deniyoruz.
      for (int outer = 0; outer < 5; outer++) {
        String whereClause = 'squad_size >= 15 AND national_team_players >= ?';
        final List<Object?> c1Params = [minNationalPlayers];
        if (!allowAllLeagues) {
          final placeholder = allowedLeagues.map((_) => '?').join(',');
          whereClause += ' AND domestic_competition_id IN ($placeholder)';
          c1Params.addAll(allowedLeagues);
        }

        final c1Rows = await _query('Dinamik takım sorusu (C1)', '''
          SELECT club_id, COALESCE(short_name, name) as name FROM clubs
          WHERE $whereClause
          ORDER BY RANDOM() LIMIT 1
        ''', c1Params);

        if (c1Rows.isEmpty) return null;
        final c1Id = c1Rows[0]['club_id'] as int;
        final c1Name = c1Rows[0]['name'] as String;

        // Adım 2: C1 ile ortak oyuncuya sahip diğer kulüpleri bul
        String c2Where = 'cl.club_id != ?';
        final List<Object?> c2Params = [c1Id];
        if (!allowAllLeagues && allowedLeagues.isNotEmpty) {
          final placeholder = allowedLeagues.map((_) => '?').join(',');
          c2Where += ' AND cl.domestic_competition_id IN ($placeholder)';
          c2Params.addAll(allowedLeagues);
        }

        final c2Rows = await _query(
          'Dinamik takım sorusu (C2)',
          '''
          SELECT cl.club_id, COALESCE(cl.short_name, cl.name) as name FROM clubs cl
          WHERE $c2Where
            AND cl.club_id IN (
              SELECT player_club_id FROM appearances
              WHERE player_id IN (SELECT player_id FROM appearances WHERE player_club_id = ?)
            )
          ORDER BY RANDOM() LIMIT 10
        ''',
          [...c2Params, c1Id],
        );

        if (c2Rows.isEmpty) continue;

        // Adım 3: Ortak oyuncusu OLAN bir kulüp çifti bulana kadar aday listesini
        // dolaş. `appearances` verisi tüm dönemleri kapsamadığı için ilk seçilen
        // çiftin kesişimi bazen boş kalıyor ve soru üretilemiyordu (ölçüm: 5
        // denemenin 1'i). Tek çift denemek yerine hepsini deniyoruz.
        final shuffledC2 = [...c2Rows]..shuffle(random);
        int? c2Id;
        String? c2Name;
        List<Map<String, Object?>> answersRows = const [];

        for (final candidate in shuffledC2) {
          final id = (candidate['club_id'] as num).toInt();
          final rows = await _getSharedPlayersByClubId(
            c1Id,
            id,
            withDetails: true,
          );
          if (rows.isEmpty) continue;
          c2Id = id;
          c2Name = candidate['name'] as String;
          answersRows = rows;
          break;
        }
        if (c2Id == null || c2Name == null || answersRows.isEmpty) continue;

        final answers = answersRows.map((r) => r['name'] as String).toList();

        // İpucu oyuncusu
        final cluePlayer = answersRows[random.nextInt(answersRows.length)];
        final nation =
            cluePlayer['country_of_citizenship'] as String? ?? 'Bilinmiyor';
        final pos = FootballPlayer.fromRow(cluePlayer).positionTr;

        final clues = [
          Clue(type: "Uyruk", value: nation),
          Clue(type: "Mevki", value: pos),
          Clue(
            type: "Bilgi",
            value: "İki kulüpte de forma giymiş ortak bir futbolcu.",
          ),
        ];

        return TeamQuestion(
          difficulty: difficulty,
          team1: c1Name,
          team1Key: c1Id.toString(),
          team2: c2Name,
          team2Key: c2Id.toString(),
          answers: answers,
          clues: clues,
        );
      }
      return null;
    } catch (e) {
      _fail('Dinamik takım sorusu', e);
      return null;
    }
  }

  /// İki kulübün ortak oyuncuları. Kulüp ID'si üzerinden çalışır — eski
  /// sürümdeki "Türkçe harfleri % ile değiştir" hilesi yanlış kulüpleri
  /// eşleştirebiliyordu.
  Future<List<Map<String, Object?>>> _getSharedPlayersByClubId(
    int clubA,
    int clubB, {
    bool withDetails = false,
    int limit = 60,
  }) async {
    final columns = withDetails
        ? 'p.name, p.player_id, p.country_of_citizenship, p.position, p.image_url'
        : 'p.name';
    return _query(
      'Ortak oyuncular',
      '''
        SELECT DISTINCT $columns FROM players p
        WHERE p.player_id IN (SELECT player_id FROM appearances WHERE player_club_id = ?)
          AND p.player_id IN (SELECT player_id FROM appearances WHERE player_club_id = ?)
        ORDER BY COALESCE(p.highest_market_value_in_eur, 0) DESC
        LIMIT ?
      ''',
      [clubA, clubB, limit],
    );
  }

  // ==========================================
  // 10 OYUN İÇİN YARDIMCI SORGULAR
  // ==========================================

  // 1. Kariyer Yolu (Career Path Trivia)
  Future<Map<String, dynamic>?> getRandomPlayerWithCareer(
    String difficulty,
  ) async {
    if (_db == null) return null;
    try {
      // Zorluk motoru: değer bandı + dönem SQL'de, lig tanınırlığı önceden
      // hesaplanmış kariyer verisiyle uygulanır.
      final player = await pickPlayerForDifficulty(difficulty);
      if (player == null) return null;
      final int playerId = (player['player_id'] as num).toInt();

      // Kariyer kulüplerini kronolojik olarak çek
      final careerRows = await _query(
        'Kariyer yolu (kulüpler)',
        '''
          SELECT COALESCE(c.short_name, c.name) as club_name,
                 MIN(g.season) as first_season, MAX(g.season) as last_season
          FROM appearances a
          JOIN games g ON a.game_id = g.game_id
          JOIN clubs c ON a.player_club_id = c.club_id
          WHERE a.player_id = ?
          GROUP BY a.player_club_id
          ORDER BY first_season ASC
        ''',
        [playerId],
      );

      if (careerRows.isEmpty) return null;

      // DÜZELTME: eski sürüm her sezon için ayrı satır döndürüp aynı kulübü
      // defalarca listeliyordu (Barcelona, Barcelona, Barcelona...).
      final List<String> careerClubs = [];
      final List<String> careerLabels = [];
      for (final row in careerRows) {
        final club = row['club_name'] as String;
        final first = row['first_season']?.toString() ?? '';
        final last = row['last_season']?.toString() ?? '';
        careerClubs.add(club);
        careerLabels.add(
          first == last ? '$club ($first)' : '$club ($first–$last)',
        );
      }

      final info = FootballPlayer.fromRow(player);
      return {
        'player_id': playerId,
        'player_name': info.name,
        'image_url': info.imageUrl,
        'country': info.country ?? 'Bilinmiyor',
        'position': info.positionTr,
        'market_value': info.marketValue,
        'career': careerClubs,
        'career_labels': careerLabels,
      };
    } catch (e) {
      _fail('Kariyer yolu sorusu', e);
      return null;
    }
  }

  // 2. Yüksek / Düşük (Higher / Lower Market Value)
  Future<List<Map<String, dynamic>>?> getTwoRandomPlayersForValuation(
    String difficulty,
  ) async {
    if (_db == null) return null;
    try {
      final rows = await pickPlayersForDifficulty(
        difficulty,
        columns:
            'player_id, name, image_url, position, current_club_name, '
            'country_of_citizenship, highest_market_value_in_eur',
        wanted: 10,
        batchSize: 60,
      );
      if (rows.length < 2) return null;

      final List<Map<String, dynamic>> shuffled = rows.map((r) {
        final p = FootballPlayer.fromRow(r);
        return {
          'name': p.name,
          'value': p.marketValue,
          'image_url': p.imageUrl,
          'position': p.positionTr,
          'club': p.clubName ?? 'Serbest',
          'country': p.country ?? '',
        };
      }).toList();
      shuffled.shuffle();

      final p1 = shuffled[0];
      var p2 = shuffled[1];
      if (p1['value'] == p2['value'] && shuffled.length > 2) {
        p2 = shuffled[2];
      }
      return [p1, p2];
    } catch (e) {
      _fail('Piyasa değeri düellosu', e);
      return null;
    }
  }

  // 3. Pahalı Transfer Düellosu (Transfer Fee Duel)
  Future<List<Map<String, dynamic>>?> getTwoRandomTransfers(
    String difficulty,
  ) async {
    if (_db == null) return null;
    try {
      // Zorluk: bonservis eşiği yükseldikçe transferler daha tanıdık olur
      final int minFee = difficulty == 'easy'
          ? 25000000
          : difficulty == 'medium'
          ? 8000000
          : 2000000;

      final rows = await _query(
        'Transfer düellosu',
        '''
          SELECT p.name as player_name, p.image_url, p.position,
                 COALESCE(c1.short_name, t.from_club_name) as from_club_name,
                 COALESCE(c2.short_name, t.to_club_name) as to_club_name,
                 t.transfer_fee, t.transfer_season
          FROM transfers t
          JOIN players p ON t.player_id = p.player_id
          LEFT JOIN clubs c1 ON t.from_club_id = c1.club_id
          LEFT JOIN clubs c2 ON t.to_club_id = c2.club_id
          WHERE t.transfer_fee > ?
          ORDER BY RANDOM() LIMIT 10
        ''',
        [minFee],
      );
      if (rows.length < 2) return null;

      final List<Map<String, dynamic>> parsed = rows
          .map(
            (r) => {
              'player_name': r['player_name'] as String,
              'image_url': r['image_url'] as String?,
              'from_club': r['from_club_name'] as String? ?? 'Bilinmiyor',
              'to_club': r['to_club_name'] as String? ?? 'Bilinmiyor',
              'fee': (r['transfer_fee'] as num? ?? 0).toInt(),
              'season': r['transfer_season'] as String? ?? 'Bilinmiyor',
            },
          )
          .toList();
      parsed.shuffle();

      final t1 = parsed[0];
      var t2 = parsed[1];
      if (t1['fee'] == t2['fee'] && parsed.length > 2) {
        t2 = parsed[2];
      }
      return [t1, t2];
    } catch (e) {
      _fail('Transfer düellosu', e);
      return null;
    }
  }

  // 4. 11'deki Gizemli Futbolcu (Missing Lineup Player)
  //
  // DÜZELTME: Eski sürüm "toplam 8+ kadro satırı olan" bir maç seçip yalnızca
  // EV SAHİBİNİN kadrosunu çekiyordu. Sayım iki takımın toplamı olduğu için
  // ev sahibinin 8 oyuncusu olmayabiliyor ve soru boş dönüyordu. Artık ev
  // sahibi yetmezse deplasman kadrosuna geçiyor, olmazsa başka maç deniyoruz.
  Future<Map<String, dynamic>?> getRandomGameWithMissingLineup(
    String difficulty,
  ) async {
    if (_db == null) return null;
    try {
      final random = Random();

      // Maç zorluğa göre seçilir: "Kolay" modda yalnızca tanınan liglerin
      // kadroları sorulur.
      final leagues = await _leaguesForDifficulty(difficulty);
      final leagueClause = leagues.isEmpty
          ? ''
          : 'AND hc.domestic_competition_id IN (${leagues.map((_) => '?').join(',')})';

      for (int attempt = 0; attempt < 6; attempt++) {
        final gameRows = await _query(
          'Gizemli 11 (maç)',
          '''
            SELECT g.game_id,
                   COALESCE(hc.short_name, hc.name) as home_name,
                   COALESCE(ac.short_name, ac.name) as away_name,
                   g.season, g.home_club_id, g.away_club_id,
                   g.home_club_goals, g.away_club_goals, g.stadium
            FROM games g
            JOIN clubs hc ON g.home_club_id = hc.club_id
            JOIN clubs ac ON g.away_club_id = ac.club_id
            WHERE g.game_id IN (SELECT game_id FROM game_lineups)
              $leagueClause
            ORDER BY RANDOM() LIMIT 1
          ''',
          [...leagues],
        );
        if (gameRows.isEmpty) return null;
        final game = gameRows.first;
        final int gameId = game['game_id'] as int;

        // Önce ev sahibi, yetmezse deplasman kadrosunu dene
        for (final side in const ['home', 'away']) {
          final clubId = game['${side}_club_id'];
          final lineupRows = await _query(
            'Gizemli 11 (kadro)',
            '''
              SELECT p.name as player_name, p.image_url, gl.position, gl.number
              FROM game_lineups gl
              JOIN players p ON gl.player_id = p.player_id
              WHERE gl.game_id = ? AND gl.club_id = ? AND gl.type = 'starting_lineup'
              LIMIT 11
            ''',
            [gameId, clubId],
          );
          if (lineupRows.length < 10) continue;

          final List<Map<String, String?>> lineup = lineupRows.map((r) {
            final rawPos = r['position'] as String?;
            return <String, String?>{
              'name': r['player_name'] as String,
              'position': FootballPlayer(
                playerId: 0,
                name: '',
                position: rawPos,
              ).positionTr,
              'image_url': r['image_url'] as String?,
            };
          }).toList();

          final int hideIdx = random.nextInt(lineup.length);
          final hiddenPlayer = lineup[hideIdx];

          final List<String> visiblePlayers = [];
          for (int i = 0; i < lineup.length; i++) {
            if (i == hideIdx) {
              visiblePlayers.add("❓ (${lineup[i]['position']})");
            } else {
              visiblePlayers.add(lineup[i]['name']!);
            }
          }

          final String squadTeam = side == 'home'
              ? game['home_name'] as String
              : game['away_name'] as String;

          return {
            'home_team': game['home_name'] as String,
            'away_team': game['away_name'] as String,
            'squad_team': squadTeam,
            'score':
                '${game['home_club_goals'] ?? '?'} - ${game['away_club_goals'] ?? '?'}',
            'stadium': game['stadium'] as String? ?? '',
            'season': game['season']?.toString() ?? 'Bilinmiyor',
            'hidden_player': hiddenPlayer['name'],
            'hidden_position': hiddenPlayer['position'],
            'image_url': hiddenPlayer['image_url'],
            'lineup': visiblePlayers,
          };
        }
      }
      return null;
    } catch (e) {
      _fail('Gizemli 11 sorusu', e);
      return null;
    }
  }

  // 5. Transfer Köprüsü (Transfer Chain Linker)
  //
  // DÜZELTME: Eski sürüm rastgele bir transfer kaydından iki kulüp seçiyordu.
  // Ancak transfers tablosu appearances'tan daha geniş bir dönemi kapsıyor;
  // seçilen kulüp çiftinin ortak oyuncusu çoğu zaman bulunamıyor ve oyun
  // "soru yüklenemedi" ile kalıyordu (ölçüm: 10 denemenin 4'ü boş).
  // Artık kulüp çiftini, İKİ KULÜPTE DE forma giydiği veriyle sabit olan bir
  // futbolcudan türetiyoruz — kesişim boş olamaz.
  Future<Map<String, dynamic>?> getRandomClubPairForLinker(
    String difficulty,
  ) async {
    if (_db == null) return null;
    try {
      final random = Random();
      // Zorluk: pahalı transferler daha bilinen kulüp çiftleri üretir
      final int bridgeMinFee = difficulty == 'easy'
          ? 25000000
          : difficulty == 'medium'
          ? 10000000
          : 3000000;

      for (int attempt = 0; attempt < 8; attempt++) {
        final playerRows = await _query(
          'Transfer köprüsü (oyuncu)',
          '''
            SELECT player_id FROM transfers
            WHERE transfer_fee > ?
            ORDER BY RANDOM() LIMIT 1
          ''',
          [bridgeMinFee],
        );
        if (playerRows.isEmpty) return null;
        final int playerId = (playerRows.first['player_id'] as num).toInt();

        final clubRows = await _query(
          'Transfer köprüsü (kulüpler)',
          '''
            SELECT DISTINCT a.player_club_id as club_id,
                   COALESCE(c.short_name, c.name) as name
            FROM appearances a
            JOIN clubs c ON c.club_id = a.player_club_id
            WHERE a.player_id = ?
          ''',
          [playerId],
        );
        if (clubRows.length < 2) continue;

        final shuffled = [...clubRows]..shuffle(random);
        final c1 = shuffled[0];
        final c2 = shuffled[1];

        final answersRows = await _getSharedPlayersByClubId(
          (c1['club_id'] as num).toInt(),
          (c2['club_id'] as num).toInt(),
        );
        final List<String> answers = answersRows
            .map((r) => r['name'] as String)
            .toList();
        if (answers.isEmpty) continue;

        return {
          'club1': c1['name'] as String,
          'club2': c2['name'] as String,
          'answers': answers,
        };
      }
      return null;
    } catch (e) {
      _fail('Transfer köprüsü', e);
      return null;
    }
  }

  // 6. Tarihi Maç: Golü Kim Attı? (Match Goalscorer Trivia)
  //
  // DÜZELTME: `game_events.player_id` her zaman `players` tablosunda karşılık
  // bulmuyor; tek gollü ya da eşleşmeyen maçlarda soru boş dönüyordu. Artık en
  // az 2 geçerli golcüsü olan bir maç bulana kadar deniyoruz (tek gollü maçta
  // zaten gizlenecek gol dışında ipucu kalmıyor).
  Future<Map<String, dynamic>?> getRandomGameWithGoalscorer(
    String difficulty,
  ) async {
    if (_db == null) return null;
    try {
      final random = Random();

      // Maç da zorluğa göre seçilir: "Kolay" modda yalnızca tanınan liglerin
      // maçları sorulur. Eskiden zorluk bu oyunda hiç dikkate alınmıyordu.
      final leagues = await _leaguesForDifficulty(difficulty);
      final matchLeagueClause = leagues.isEmpty
          ? ''
          : 'AND hc.domestic_competition_id IN (${leagues.map((_) => '?').join(',')})';
      final matchLeagueParams = <Object?>[...leagues];

      for (int attempt = 0; attempt < 6; attempt++) {
        final gameRows = await _query('Golcü sorusu (maç)', '''
            SELECT g.game_id,
                   COALESCE(hc.short_name, hc.name) as home_name,
                   COALESCE(ac.short_name, ac.name) as away_name,
                   g.home_club_goals, g.away_club_goals, g.season, g.home_club_id, g.stadium
            FROM games g
            JOIN clubs hc ON g.home_club_id = hc.club_id
            JOIN clubs ac ON g.away_club_id = ac.club_id
            WHERE g.game_id IN (SELECT game_id FROM game_events WHERE type = 'Goals')
              $matchLeagueClause
            ORDER BY RANDOM() LIMIT 1
          ''', matchLeagueParams);
        if (gameRows.isEmpty) return null;
        final game = gameRows.first;
        final int gameId = game['game_id'] as int;

        final goalRows = await _query(
          'Golcü sorusu (goller)',
          '''
            SELECT ge.minute, p.name as player_name, p.image_url, ge.club_id
            FROM game_events ge
            JOIN players p ON ge.player_id = p.player_id
            WHERE ge.game_id = ? AND ge.type = 'Goals' AND ge.minute IS NOT NULL
            ORDER BY ge.minute ASC
          ''',
          [gameId],
        );

        if (goalRows.length < 2) continue;

        final int targetIdx = random.nextInt(goalRows.length);
        final targetGoal = goalRows[targetIdx];
        final homeName = game['home_name'] as String;
        final awayName = game['away_name'] as String;

        final List<String> goalClues = [];
        for (int i = 0; i < goalRows.length; i++) {
          final row = goalRows[i];
          final String teamPrefix = row['club_id'] == game['home_club_id']
              ? homeName
              : awayName;
          if (i == targetIdx) {
            goalClues.add("$teamPrefix · ${row['minute']}' — ❓❓❓");
          } else {
            goalClues.add(
              "$teamPrefix · ${row['minute']}' — ${row['player_name']}",
            );
          }
        }

        return {
          'match_title':
              "$homeName ${game['home_club_goals']} - ${game['away_club_goals']} $awayName",
          'season': game['season']?.toString() ?? 'Bilinmiyor',
          'stadium': game['stadium'] as String? ?? '',
          'goal_clues': goalClues,
          'target_minute': targetGoal['minute'].toString(),
          'answer': targetGoal['player_name'] as String,
          'answer_image': targetGoal['image_url'] as String?,
        };
      }
      return null;
    } catch (e) {
      _fail('Golcü sorusu', e);
      return null;
    }
  }

  // 7. Koleksiyoncu Grid (Immaculate Grid)
  //
  // DÜZELTME: Eski sürüm 12 rastgele kulüpten 4'ünü seçip dört kesişimin de
  // dolu olmasını umuyordu. Ölçümde 3 denemenin 3'ü de başarısız oldu; oyun
  // pratikte hiç açılmıyordu. Ayrıca kulüpleri isimle eşleştirip Türkçe
  // harfleri '%' jokerine çevirdiği için yanlış kulüpleri de kesiştirebiliyordu.
  //
  // Yeni algoritma kesişimi GARANTİ ediyor:
  //   1. Sütunlar: iki kulüpte de forma giymiş gerçek bir futbolcunun kulüpleri
  //   2. Satırlar: her iki sütunla da ortak oyuncusu olan kulüpler (tek sorgu)
  // Sonuç: her zorlukta 8/8 başarı, ~185 ms.
  Future<Map<String, dynamic>?> getRandomImmaculateGridConfig(
    String difficulty,
  ) async {
    if (_db == null) return null;
    try {
      final rules = DifficultyRulesService();
      await rules.initialize();
      final allowedLeagues = rules.allowedLeaguesFor(difficulty).toList();

      final int minNationalPlayers = difficulty == 'easy'
          ? 8
          : difficulty == 'medium'
          ? 4
          : 1;
      final random = Random();

      // Kulüp filtresini zorluğun izin verdiği liglerle sınırla — böylece
      // "Kolay" gridinde Romanya/Ukrayna kulüpleri çıkmaz.
      final String leagueClause = allowedLeagues.isEmpty
          ? ''
          : ' AND c.domestic_competition_id IN (${allowedLeagues.map((_) => '?').join(',')})';

      for (int attempt = 0; attempt < 6; attempt++) {
        // 1) Zorluğa uyan, çok kulüplü bir futbolcu seç
        final seed = await pickPlayerForDifficulty(
          difficulty,
          columns: 'player_id',
        );
        if (seed == null) return null;
        final int seedId = (seed['player_id'] as num).toInt();

        // 2) Bu futbolcunun forma giydiği (yeterince tanınmış) kulüpler = sütunlar
        final colRows = await _query(
          'Grid (sütunlar)',
          '''
            SELECT DISTINCT a.player_club_id as club_id,
                   COALESCE(c.short_name, c.name) as name
            FROM appearances a
            JOIN clubs c ON c.club_id = a.player_club_id
            WHERE a.player_id = ? AND c.squad_size > 18
              AND c.national_team_players >= ?$leagueClause
          ''',
          [seedId, minNationalPlayers, ...allowedLeagues],
        );
        if (colRows.length < 2) continue;

        final cols = [...colRows]..shuffle(random);
        final int c1Id = (cols[0]['club_id'] as num).toInt();
        final int c2Id = (cols[1]['club_id'] as num).toInt();

        // 3) Her iki sütunla da kesişen iki kulüp = satırlar
        final rowRows = await _query(
          'Grid (satırlar)',
          '''
            SELECT cl.club_id, COALESCE(cl.short_name, cl.name) as name FROM clubs cl
            WHERE cl.club_id NOT IN (?, ?)
              AND cl.squad_size > 18 AND cl.national_team_players >= ?
              AND cl.club_id IN (
                SELECT player_club_id FROM appearances
                WHERE player_id IN (SELECT player_id FROM appearances WHERE player_club_id = ?)
              )
              AND cl.club_id IN (
                SELECT player_club_id FROM appearances
                WHERE player_id IN (SELECT player_id FROM appearances WHERE player_club_id = ?)
              )
            ORDER BY RANDOM() LIMIT 2
          ''',
          [c1Id, c2Id, minNationalPlayers, c1Id, c2Id],
        );
        if (rowRows.length < 2) continue;

        final int r1Id = (rowRows[0]['club_id'] as num).toInt();
        final int r2Id = (rowRows[1]['club_id'] as num).toInt();

        final a11 = await _sharedPlayerNames(r1Id, c1Id);
        final a12 = await _sharedPlayerNames(r1Id, c2Id);
        final a21 = await _sharedPlayerNames(r2Id, c1Id);
        final a22 = await _sharedPlayerNames(r2Id, c2Id);
        if (a11.isEmpty || a12.isEmpty || a21.isEmpty || a22.isEmpty) continue;

        return {
          'row1': rowRows[0]['name'] as String,
          'row2': rowRows[1]['name'] as String,
          'col1': cols[0]['name'] as String,
          'col2': cols[1]['name'] as String,
          'answers11': a11,
          'answers12': a12,
          'answers21': a21,
          'answers22': a22,
        };
      }

      return null;
    } catch (e) {
      _fail('Grid yapılandırması', e);
      return null;
    }
  }

  Future<List<String>> _sharedPlayerNames(int clubA, int clubB) async {
    final rows = await _getSharedPlayersByClubId(clubA, clubB);
    return rows.map((r) => r['name'] as String).toList();
  }

  // 8. Stadyum Atlası (Stadium Capacity Quiz)
  Future<Map<String, dynamic>?> getRandomStadiumQuiz(String difficulty) async {
    if (_db == null) return null;
    try {
      // Zorluk: hangi liglerin stadyumları sorulacak + minimum kapasite
      final leagues = await _leaguesForDifficulty(difficulty);
      final leagueClause = leagues.isEmpty
          ? ''
          : 'AND domestic_competition_id IN (${leagues.map((_) => '?').join(',')})';
      final int minSeats = difficulty == 'easy'
          ? 40000
          : difficulty == 'medium'
          ? 25000
          : 15000;

      final correctRows = await _query(
        'Stadyum sorusu',
        '''
          SELECT club_id, COALESCE(short_name, name) as club_name, stadium_name, stadium_seats
          FROM clubs
          WHERE stadium_name IS NOT NULL AND stadium_name != '' AND stadium_seats > ?
            $leagueClause
          ORDER BY RANDOM() LIMIT 1
        ''',
        [minSeats, ...leagues],
      );
      if (correctRows.isEmpty) return null;
      final correct = correctRows.first;

      final incorrectRows = await _query(
        'Stadyum sorusu (çeldiriciler)',
        '''
          SELECT COALESCE(short_name, name) as club_name FROM clubs
          WHERE club_id != ? AND stadium_name IS NOT NULL AND stadium_name != ''
            AND stadium_seats > ?
            $leagueClause
          ORDER BY RANDOM() LIMIT 3
        ''',
        [correct['club_id'], (minSeats * 0.6).round(), ...leagues],
      );

      if (incorrectRows.length < 3) return null;

      final List<String> options = [
        correct['club_name'] as String,
        ...incorrectRows.map((r) => r['club_name'] as String),
      ];
      options.shuffle();

      return {
        'stadium_name': correct['stadium_name'] as String,
        'seats': (correct['stadium_seats'] as num? ?? 0).toInt(),
        'correct_answer': correct['club_name'] as String,
        'options': options,
      };
    } catch (e) {
      _fail('Stadyum sorusu', e);
      return null;
    }
  }

  // 9. Kart Cezası Canavarı (The Card King)
  //
  // DÜZELTME: Eski sorgu 1.88M satırlık `appearances` tablosunun TAMAMINI
  // GROUP BY + ORDER BY RANDOM() ile tarıyordu (masaüstünde ~12 sn, telefonda
  // uygulamayı kilitleyecek kadar uzun). Artık önce rastgele bir oyuncu seçip
  // sadece o oyuncunun satırlarını topluyoruz (~20 ms).
  Future<Map<String, dynamic>?> getRandomCardKingQuiz(String difficulty) async {
    if (_db == null) return null;
    try {
      for (int attempt = 0; attempt < 12; attempt++) {
        final candidate = await pickPlayerForDifficulty(difficulty);
        if (candidate == null) return null;
        final player = FootballPlayer.fromRow(candidate);

        final statRows = await _query(
          'Kart kralı (istatistik)',
          '''
            SELECT COALESCE(SUM(a.yellow_cards),0) as yellow,
                   COALESCE(SUM(a.red_cards),0) as red,
                   COUNT(DISTINCT a.game_id) as apps
            FROM appearances a WHERE a.player_id = ?
          ''',
          [player.playerId],
        );
        if (statRows.isEmpty) continue;

        final yellow = (statRows.first['yellow'] as num?)?.toInt() ?? 0;
        final red = (statRows.first['red'] as num?)?.toInt() ?? 0;
        final apps = (statRows.first['apps'] as num?)?.toInt() ?? 0;
        if (yellow < 8) continue; // yeterince "hırçın" değil, başka aday dene

        final clubRows = await _query(
          'Kart kralı (kulüp)',
          '''
            SELECT COALESCE(c.short_name, c.name) as club_name, COUNT(*) as n
            FROM appearances a JOIN clubs c ON c.club_id = a.player_club_id
            WHERE a.player_id = ?
            GROUP BY a.player_club_id ORDER BY n DESC LIMIT 1
          ''',
          [player.playerId],
        );

        return {
          'player_name': player.name,
          'image_url': player.imageUrl,
          'position': player.positionTr,
          'country': player.country ?? 'Bilinmiyor',
          'yellow': yellow,
          'red': red,
          'apps': apps,
          'club_name': clubRows.isEmpty
              ? (player.clubName ?? 'Bilinmiyor')
              : clubRows.first['club_name'] as String,
        };
      }
      return null;
    } catch (e) {
      _fail('Kart kralı sorusu', e);
      return null;
    }
  }

  // 10. Zirve İstatistikler (Top Stats Quiz)
  //
  // DÜZELTME: Eski sorgu appearances × games × competitions birleşimini
  // tamamen tarayıp (oyuncu, sezon, turnuva) bazında grupluyordu (~15 sn).
  // Artık önce oyuncu seçip sadece onun sezonlarını topluyoruz.
  Future<Map<String, dynamic>?> getRandomTopStatsQuiz(String difficulty) async {
    if (_db == null) return null;
    try {
      for (int attempt = 0; attempt < 12; attempt++) {
        // Gol krallığı sorusu olduğu için hücum oyuncularıyla sınırlı
        final candidate = await pickPlayerForDifficulty(
          difficulty,
          extraWhere: "position = 'Attack'",
        );
        if (candidate == null) return null;
        final player = FootballPlayer.fromRow(candidate);

        final seasonRows = await _query(
          'Zirve istatistik (sezon)',
          '''
            SELECT g.season, g.competition_id, SUM(a.goals) as goals_count,
                   SUM(a.assists) as assists_count
            FROM appearances a
            JOIN games g ON g.game_id = a.game_id
            WHERE a.player_id = ?
            GROUP BY g.season, g.competition_id
            HAVING goals_count >= 12
            ORDER BY goals_count DESC LIMIT 5
          ''',
          [player.playerId],
        );
        if (seasonRows.isEmpty) continue;

        final pick = seasonRows[Random().nextInt(seasonRows.length)];
        final compRows = await _query(
          'Zirve istatistik (turnuva)',
          'SELECT name FROM competitions WHERE competition_id = ? LIMIT 1',
          [pick['competition_id']],
        );

        return {
          'player_name': player.name,
          'image_url': player.imageUrl,
          'position': player.positionTr,
          'country': player.country ?? '',
          'goals': (pick['goals_count'] as num?)?.toInt() ?? 0,
          'assists': (pick['assists_count'] as num?)?.toInt() ?? 0,
          'competition': compRows.isEmpty
              ? (pick['competition_id']?.toString() ?? 'Bilinmiyor')
              : compRows.first['name'] as String,
          'season': pick['season']?.toString() ?? 'Bilinmiyor',
        };
      }
      return null;
    } catch (e) {
      _fail('Zirve istatistik sorusu', e);
      return null;
    }
  }

  // 11. Oyuncu Piyasa Değeri Tahmini (Player Valuation Quiz - Multiple Choice)
  Future<Map<String, dynamic>?> getRandomPlayerValuationQuiz(
    String difficulty,
  ) async {
    if (_db == null) return null;
    try {
      final row = await pickPlayerForDifficulty(difficulty);
      if (row == null) return null;
      final player = FootballPlayer.fromRow(row);
      final int correctVal = player.marketValue;

      final List<int> incorrectVals = [
        (correctVal * 0.6).round(),
        (correctVal * 1.4).round(),
        (correctVal * 1.9).round(),
      ];

      final List<String> options = <String>{
        FootballPlayer.formatEuro(correctVal),
        ...incorrectVals.map(FootballPlayer.formatEuro),
      }.toList();
      options.shuffle();

      return {
        'player_name': player.name,
        'image_url': player.imageUrl,
        'club_name': player.clubName ?? 'Serbest',
        'position': player.positionTr,
        'country': player.country ?? '',
        'correct_answer': FootballPlayer.formatEuro(correctVal),
        'options': options,
      };
    } catch (e) {
      _fail('Piyasa değeri quizi', e);
      return null;
    }
  }
}

/// Dinamik olarak kurulan WHERE parçası + parametreleri.
class _SqlFilter {
  final String sql;
  final List<Object?> params;
  const _SqlFilter(this.sql, this.params);
}
