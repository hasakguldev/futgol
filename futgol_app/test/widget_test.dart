import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:futgol_app/common/models/football_player.dart';
import 'package:futgol_app/features/stopwatch/models/stopwatch_models.dart';
import 'package:futgol_app/features/stopwatch/widgets/roster_strip.dart';
import 'package:futgol_app/features/stopwatch/widgets/action_stage_card.dart';
import 'package:futgol_app/common/theme/neobrutalist_theme.dart';

MatchPlayer _p(int slot, String name) =>
    MatchPlayer(slot: slot, profile: FootballPlayer(playerId: slot + 1, name: name));

void main() {
  group('MatchPlayer — kadro durumu', () {
    test('sarı kart sınırını doğru raporlar', () {
      final p = _p(3, 'Arda Güler');
      expect(p.isOnBooking, isFalse);
      p.yellowCards = 1;
      expect(p.isOnBooking, isTrue);
      expect(p.statusLabel, 'KART SINIRINDA');
      p.yellowCards = 2;
      p.hasRedCard = true;
      expect(p.isOnBooking, isFalse);
      expect(p.isAvailable, isFalse);
    });

    test('sakat oyuncu seçilemez ve geri sayımı gösterir', () {
      final p = _p(7, 'Mesut Özil')
        ..injured = true
        ..injuryCountdown = 4;
      expect(p.isAvailable, isFalse);
      expect(p.statusIcons, contains('🏥4'));
    });

    test('gol sayısı rozete yansır', () {
      final p = _p(0, 'Mauro Icardi')..goals = 3;
      expect(p.statusIcons.first, '⚽3');
    });
  });

  group('MatchAction — hamle sahibi', () {
    test('cümle yerine ad ve hareketi ayrı taşır', () {
      const action = MatchAction(
        ownerPlayerNum: 2,
        headline: 'GOOOL!',
        detail: 'Ağlar havalandı.',
        emoji: '⚽',
        color: NeobrutalistColors.green,
        playerName: 'Arda Güler',
        playerSlot: 5,
      );
      expect(action.playerName, 'Arda Güler');
      expect(action.headline, 'GOOOL!');
      expect(action.opponentSummary, 'Arda Güler · GOOOL!');
      // Hamle sahibi 2. oyuncu; kart onun yarısında gösterilmeli.
      expect(action.ownerPlayerNum, 2);
    });
  });

  group('FootballPlayer', () {
    test('mevkiyi Türkçeleştirir', () {
      const p = FootballPlayer(playerId: 1, name: 'X', position: 'Goalkeeper');
      expect(p.positionTr, 'Kaleci');
      expect(p.positionBadge, 'KL');
    });

    test('piyasa değerini okunur biçimde yazar', () {
      expect(FootballPlayer.formatEuro(180000000), '180M €');
      expect(FootballPlayer.formatEuro(6500000), '6.5M €');
      expect(FootballPlayer.formatEuro(750000), '750K €');
    });

    test('baş harfleri üretir', () {
      const p = FootballPlayer(playerId: 1, name: 'Lionel Messi');
      expect(p.initials, 'LM');
    });
  });

  testWidgets('RosterStrip 10 futbolcuyu numaralarıyla çizer', (tester) async {
    final roster = List.generate(10, (i) => _p(i, 'Oyuncu $i Soyad$i'));
    roster[2].hasRedCard = true;
    roster[5].goals = 2;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 380,
          child: RosterStrip(
            roster: roster,
            selectedSlot: 5,
            isMyTurn: true,
            accent: NeobrutalistColors.blue,
          ),
        ),
      ),
    ));

    // 0-9 arası kadro numaraları ekranda olmalı (kronometre hanesiyle eşleşir)
    for (int i = 0; i < 10; i++) {
      expect(find.text('$i'), findsOneWidget, reason: '$i numaralı kadro yeri görünmüyor');
    }
    // Durum ikonları
    expect(find.text('🟥'), findsOneWidget);
    expect(find.text('⚽2'), findsOneWidget);
  });

  testWidgets('ActionStageCard oyuncu adını ve hareketi büyük basar', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: ActionStageCard(
          action: MatchAction(
            ownerPlayerNum: 1,
            headline: 'SARI KART',
            detail: 'Artık kart sınırında.',
            emoji: '🟨',
            color: NeobrutalistColors.orange,
            playerName: 'Arda Güler',
            playerSlot: 5,
          ),
        ),
      ),
    ));

    expect(find.text('ARDA GÜLER'), findsOneWidget);
    expect(find.text('SARI KART'), findsOneWidget);
    expect(find.text('#5'), findsOneWidget);

    final nameStyle = tester.widget<Text>(find.text('ARDA GÜLER')).style!;
    final headlineStyle = tester.widget<Text>(find.text('SARI KART')).style!;
    // İsim ve hareket, açıklama metninden belirgin şekilde büyük olmalı
    expect(nameStyle.fontSize! >= 15, isTrue);
    expect(headlineStyle.fontSize! >= 20, isTrue);
  });

  testWidgets('OpponentWaitCard sıra sende / sıra rakipte ayrımını yapar', (tester) async {
    Future<void> pump(bool isMyTurn) => tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: OpponentWaitCard(
              lastOpponentAction: const MatchAction(
                ownerPlayerNum: 1,
                headline: 'GOOOL!',
                detail: '',
                emoji: '⚽',
                color: NeobrutalistColors.green,
                playerName: 'Icardi',
              ),
              isMyTurn: isMyTurn,
            ),
          ),
        ));

    await pump(true);
    expect(find.text('▶️ SIRA SENDE'), findsOneWidget);

    await pump(false);
    expect(find.text('⏳ SIRA RAKİPTE'), findsOneWidget);
  });
}
