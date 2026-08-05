import 'package:flutter/material.dart';
import 'package:futgol_app/common/theme/neobrutalist_theme.dart';
import 'package:futgol_app/common/widgets/player_avatar.dart';
import '../models/stopwatch_models.dart';

/// Hamle sonucunu SAHNE gibi gösteren kart.
///
/// Tasarım kararı: artık cümle kurulmuyor. Futbolcunun adı ve hareketin tipi
/// iki ayrı, büyük ve okunaklı satır olarak basılıyor:
///
///     [ #7 ][foto]  ARDA GÜLER
///                   G O L !
///
/// Eski sürümde her şey 8 puntoluk tek bir cümlenin içinde kayboluyordu.
class ActionStageCard extends StatelessWidget {
  final MatchAction action;
  final double maxHeight;

  const ActionStageCard({
    super.key,
    required this.action,
    this.maxHeight = 132,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasPlayer = action.playerName != null;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: Tween<double>(begin: 0.88, end: 1).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        ),
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: Container(
        key: ValueKey('${action.headline}|${action.playerName}|${action.detail}'),
        constraints: BoxConstraints(maxHeight: maxHeight),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: action.color,
          border: NeobrutalistStyles.border(width: 3.5),
          borderRadius: BorderRadius.circular(18),
          boxShadow: NeobrutalistStyles.shadow(offset: const Offset(5, 5)),
        ),
        child: Row(
          children: [
            if (hasPlayer) ...[
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PlayerAvatar(
                    imageUrl: action.playerImageUrl,
                    fallbackText: _initials(action.playerName!),
                    size: 46,
                    borderWidth: 3,
                  ),
                  if (action.playerSlot != null) ...[
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                      decoration: BoxDecoration(
                        color: NeobrutalistColors.black,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        '#${action.playerSlot}',
                        style: NeobrutalistStyles.headlineStyle(
                          fontSize: 8,
                          color: NeobrutalistColors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 10),
            ] else ...[
              Text(action.emoji, style: const TextStyle(fontSize: 34)),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasPlayer)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        action.playerName!.toUpperCase(),
                        maxLines: 1,
                        style: NeobrutalistStyles.headlineStyle(
                          fontSize: 17,
                          color: NeobrutalistColors.white,
                        ),
                      ),
                    ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasPlayer) ...[
                          Text(action.emoji, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          action.headline,
                          maxLines: 1,
                          style: NeobrutalistStyles.headlineStyle(
                            fontSize: hasPlayer ? 22 : 20,
                            color: NeobrutalistColors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    action.detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: NeobrutalistStyles.bodyStyle(
                      fontSize: 9,
                      color: NeobrutalistColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}

/// Son hamle karşı tarafta yapıldığında gösterilen kompakt panel.
///
/// İki farklı durumu ayırır:
///  • Sıra bende → "SIRA SENDE" (çünkü rakip hamlesini bitirdi ve top bana geçti)
///  • Sıra rakipte → "SIRA RAKİPTE"
/// Her iki durumda da rakibin son hamlesi tek satırlık özet olarak görünür.
class OpponentWaitCard extends StatelessWidget {
  final MatchAction? lastOpponentAction;
  final bool isMyTurn;
  final bool isTimeUp;
  final bool isFinished;

  const OpponentWaitCard({
    super.key,
    required this.lastOpponentAction,
    required this.isMyTurn,
    this.isTimeUp = false,
    this.isFinished = false,
  });

  @override
  Widget build(BuildContext context) {
    final action = lastOpponentAction;

    final String headline = isFinished
        ? '🏁 MAÇ BİTTİ'
        : isTimeUp
            ? '⏳ SÜRENİZ BİTTİ'
            : isMyTurn
                ? '▶️ SIRA SENDE'
                : '⏳ SIRA RAKİPTE';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isMyTurn && !isFinished && !isTimeUp
            ? NeobrutalistColors.yellow
            : NeobrutalistColors.white.withValues(alpha: 0.75),
        border: Border.all(color: NeobrutalistColors.black, width: 2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            headline,
            style: NeobrutalistStyles.headlineStyle(fontSize: 12),
          ),
          if (action != null && action.ownerPlayerNum != 0) ...[
            const SizedBox(height: 5),
            Text(
              'RAKİBİN SON HAMLESİ',
              style: NeobrutalistStyles.headlineStyle(
                  fontSize: 7, color: Colors.grey[700]!),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: action.color,
                border: Border.all(color: NeobrutalistColors.black, width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${action.emoji} ${action.opponentSummary}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: NeobrutalistStyles.headlineStyle(
                  fontSize: 9,
                  color: NeobrutalistColors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
