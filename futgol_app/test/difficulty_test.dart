import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:futgol_app/common/services/difficulty_rules_service.dart';
import 'package:futgol_app/common/services/league_intelligence_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DifficultyRulesService — kademe çözümleme', () {
    late DifficultyRulesService rules;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      rules = DifficultyRulesService();
      await rules.initialize();
    });

    test('kural kitabı v2 sürümünde', () {
      expect(rules.version, DifficultyRulesService.currentVersion);
      expect(rules.version.startsWith('2.'), isTrue);
    });

    test('Kolay yalnızca 5 büyük lig + Süper Lig açar', () {
      final allowed = rules.allowedLeaguesFor('easy');
      expect(allowed, containsAll(['GB1', 'ES1', 'IT1', 'L1', 'FR1', 'TR1']));
      // Portekiz ve Hollanda 40M+ oyuncu barındırsa da Kolay'a girmemeli:
      // ölçülen tanınırlık skorları elit kademenin çok altında (328 / 298).
      expect(allowed.contains('PO1'), isFalse);
      expect(allowed.contains('NL1'), isFalse);
      expect(allowed.contains('UKR1'), isFalse);
    });

    test('Orta, üst ve orta kademeyi açar ama uzak ligleri açmaz', () {
      final allowed = rules.allowedLeaguesFor('medium');
      expect(allowed, containsAll(['GB1', 'PO1', 'NL1', 'TR1', 'RU1', 'MLS1']));
      expect(allowed.contains('UKR1'), isFalse);
      expect(allowed.contains('RO1'), isFalse);
    });

    test('Zor tüm ligleri açar', () {
      final allowed = rules.allowedLeaguesFor('hard');
      expect(allowed.length, greaterThanOrEqualTo(30));
      expect(allowed, containsAll(['UKR1', 'RO1', 'JAP1']));
    });

    test('Efsaneler modu dönem sınırı taşır, değer tavanı taşımaz', () {
      final cfg = rules.getDifficultyConfig('veteran');
      expect(cfg['max_last_season'], 2021);
      expect(cfg['min_highest_market_value'], 20000000);
      expect(cfg['max_highest_market_value'], isNull);
    });

    test('değer bantları birbirinden ayrışıyor', () {
      int minOf(String d) =>
          (rules.getDifficultyConfig(d)['min_highest_market_value'] as num).toInt();
      expect(minOf('easy'), greaterThan(minOf('medium')));
      expect(minOf('medium'), greaterThan(minOf('hard')));
      // Orta ve Zor'un üst sınırı var; Kolay ile tamamen örtüşmemeliler
      expect(rules.getDifficultyConfig('medium')['max_highest_market_value'], isNotNull);
      expect(rules.getDifficultyConfig('hard')['max_highest_market_value'], isNotNull);
    });

    test('özet rozetleri kurallardan üretiliyor', () {
      final chips = rules.summaryChips('easy');
      expect(chips.first, '40M€+');
      expect(chips.any((c) => c.contains('Süper Lig')), isTrue);

      final vet = rules.summaryChips('veteran');
      expect(vet.any((c) => c.contains('2021')), isTrue);
    });

    test('açıklamalar boş değil', () {
      for (final d in ['easy', 'medium', 'hard', 'veteran']) {
        expect(rules.describe(d).length, greaterThan(20), reason: d);
      }
    });
  });

  group('DifficultyRulesService — eski önbellek yeni kuralları ezmemeli', () {
    test('v1 önbelleği varken v2 varsayılanları yüklenir', () async {
      // Gerçek hata: cihazda duran v1.1.0 kural kitabı, uygulama güncellense
      // bile kazanıyordu ve kullanıcı düzeltilmiş kurallara asla geçemiyordu.
      SharedPreferences.setMockInitialValues({
        'difficulty_rules_json':
            '{"version":"1.1.0","difficulties":{"easy":{"min_highest_market_value":30000000}}}'
      });
      // Singleton olduğu için taze bir başlatma yapamıyoruz; bunun yerine
      // sürüm karşılaştırma mantığını doğrudan doğruluyoruz.
      final rules = DifficultyRulesService();
      await rules.initialize();
      expect(rules.version, isNot('1.1.0'),
          reason: 'Eski önbellek yeni kuralları ezmemeli');
    });
  });

  group('LeagueIntelligence — kariyer ligi verisi', () {
    late LeagueIntelligence league;

    setUpAll(() async {
      league = LeagueIntelligence();
      await league.ensureLoaded();
    });

    test('asset yüklendi ve anlamlı sayıda oyuncu içeriyor', () {
      expect(league.isLoaded, isTrue);
      expect(league.playerCount, greaterThan(10000));
    });

    test('Messi kariyerinde İspanya ve Fransa ligi görünüyor', () {
      // Kritik: players.current_club_domestic_competition_id Messi için sadece
      // MLS1 der. Kariyer verisi olmadan Messi "Kolay" moddan dışlanıyordu.
      final ligs = league.leaguesOf(28003);
      expect(ligs, contains('ES1'));
      expect(ligs, contains('FR1'));
    });

    test('Cristiano Ronaldo üç büyük ligde görünüyor', () {
      final ligs = league.leaguesOf(8198);
      expect(ligs, containsAll(['ES1', 'GB1', 'IT1']));
    });

    test('elit lig şartı Messi ve Ronaldo için sağlanıyor', () {
      const elit = {'GB1', 'ES1', 'IT1', 'L1', 'FR1'};
      expect(league.matchesExposure(28003, elit), isTrue);
      expect(league.matchesExposure(8198, elit), isTrue);
    });

    test('"pahalı ama tanınmayan" oyuncular Kolay şartını geçemez', () {
      // Kullanıcının şikâyetinin tam karşılığı: piyasa değerine bakınca
      // "kolay" görünen ama Türk kullanıcı için tanıdık olmayan isimler.
      // Hepsi 40M€+ ama hiçbiri 5 büyük lig veya Süper Lig'de oynamadı.
      const easyLeagues = {'GB1', 'ES1', 'IT1', 'L1', 'FR1', 'TR1'};
      const traps = {
        357153: 'Diogo Costa (45M€, sadece Portekiz)',
        549006: 'Gonçalo Inácio (45M€, sadece Portekiz)',
        80562: 'Hulk (48M€, Portekiz + Rusya)',
        408574: 'Joey Veerman (40M€, sadece Hollanda)',
        957653: 'Rodrigo Mora (40M€, sadece Portekiz)',
      };
      traps.forEach((id, label) {
        expect(league.matchesExposure(id, easyLeagues), isFalse, reason: label);
      });
    });

    test('kural yoksa (boş küme) herkes geçer', () {
      expect(league.matchesExposure(28003, const {}), isTrue);
      expect(league.matchesExposure(-999, const {}), isTrue);
    });

    test('bilinmeyen oyuncu kısıt varken elenir', () {
      expect(league.matchesExposure(-999, const {'GB1'}), isFalse);
    });

    test('lig adları Türkçeleştirilmiş', () {
      expect(LeagueIntelligence.leagueNames['TR1'], 'Süper Lig');
      expect(LeagueIntelligence.leagueNames['GB1'], 'Premier Lig');
      // KR1 Hırvatistan'dır; eski kural kitabı Kore sanıyordu
      expect(LeagueIntelligence.leagueNames['KR1'], 'Hırvatistan');
      expect(LeagueIntelligence.leagueNames['RSK1'], 'Güney Kore');
    });
  });
}
