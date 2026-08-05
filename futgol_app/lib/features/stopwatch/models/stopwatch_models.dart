import 'package:flutter/material.dart';
import 'package:futgol_app/common/models/football_player.dart';
import 'package:futgol_app/common/theme/neobrutalist_theme.dart';

/// Kronometre Futbolu'nda kadrodaki tek bir futbolcunun maç içi durumu.
/// `slot` alanı kronometreden yakalanan rakamla (0-9) birebir eşleşir —
/// bu yüzden ekranda mutlaka görünür olmalıdır.
class MatchPlayer {
  final int slot; // 0-9: kronometrenin son hanesi bu oyuncuyu seçer
  final FootballPlayer profile;

  int goals;
  int ownGoals;
  int yellowCards;
  bool hasRedCard;
  bool injured;
  int injuryCountdown;

  MatchPlayer({
    required this.slot,
    required this.profile,
    this.goals = 0,
    this.ownGoals = 0,
    this.yellowCards = 0,
    this.hasRedCard = false,
    this.injured = false,
    this.injuryCountdown = 0,
  });

  String get name => profile.name;
  String get displayName => profile.shortName;

  bool get isAvailable => !hasRedCard && !injured;

  /// Bir sarı kartı olan oyuncu "kart sınırında" sayılır: ikinci sarı = kırmızı.
  bool get isOnBooking => yellowCards == 1 && !hasRedCard;

  /// Kadro rozetinde gösterilecek durum ikonları.
  List<String> get statusIcons {
    final icons = <String>[];
    if (goals > 0) icons.add(goals > 1 ? '⚽$goals' : '⚽');
    if (hasRedCard) {
      icons.add('🟥');
    } else if (yellowCards > 0) {
      icons.add(yellowCards > 1 ? '🟨$yellowCards' : '🟨');
    }
    if (injured) icons.add('🏥$injuryCountdown');
    return icons;
  }

  String get statusLabel {
    if (hasRedCard) return 'KIRMIZI KART — OYUN DIŞI';
    if (injured) return 'SAKAT — $injuryCountdown el daha yok';
    if (isOnBooking) return 'KART SINIRINDA';
    return 'HAZIR';
  }

  Color get statusColor {
    if (hasRedCard) return NeobrutalistColors.pink;
    if (injured) return NeobrutalistColors.orange;
    if (isOnBooking) return NeobrutalistColors.yellow;
    return NeobrutalistColors.green;
  }
}

/// Ekranda gösterilecek son hamlenin tüm görsel bilgisi.
/// Cümle kurmak yerine "kim" ve "ne" bilgisini ayrı ayrı taşır; böylece
/// oyuncu adı ve hareket tipi büyük puntoyla, gösterişli şekilde basılabilir.
class MatchAction {
  /// Hamleyi yapan oyuncu (1 = üst, 2 = alt). 0 = maç geneli (başlangıç/bitiş).
  final int ownerPlayerNum;
  final String headline; // "GOL!", "SARI KART", "SAKATLIK"
  final String? playerName; // Büyük puntoyla basılacak futbolcu adı
  final int? playerSlot; // Kadro numarası
  final String? playerImageUrl;
  final String detail; // Tek satırlık kısa açıklama
  final String emoji;
  final Color color;
  final ActionTone tone;

  const MatchAction({
    required this.ownerPlayerNum,
    required this.headline,
    required this.detail,
    required this.emoji,
    required this.color,
    this.playerName,
    this.playerSlot,
    this.playerImageUrl,
    this.tone = ActionTone.neutral,
  });

  static const MatchAction kickoff = MatchAction(
    ownerPlayerNum: 0,
    headline: 'HAZIR!',
    detail: 'Kronometreyi başlatıp saliseyi yakalayın.',
    emoji: '⚽',
    color: NeobrutalistColors.blue,
  );

  /// Rakip yarıda gösterilecek özet: "ARDA GÜLER — GOL!"
  String get opponentSummary =>
      playerName == null ? headline : '$playerName · $headline';
}

enum ActionTone { good, bad, neutral }

/// Orta bantta akan maç olayları şeridi için tek satırlık kayıt.
class MatchEvent {
  final int playerNum; // 1 veya 2
  final String icon;
  final String text;

  const MatchEvent({
    required this.playerNum,
    required this.icon,
    required this.text,
  });
}
