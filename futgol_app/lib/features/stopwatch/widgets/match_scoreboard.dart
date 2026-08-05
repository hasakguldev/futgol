import 'package:flutter/material.dart';
import 'package:futgol_app/common/theme/neobrutalist_theme.dart';
import '../models/stopwatch_models.dart';

/// İki yarının arasında duran skor bandı.
///
/// Skorun yanı sıra maçın canlı olay şeridini de taşır (goller, kartlar,
/// sakatlıklar). Böylece iki oyuncu da maçın hikâyesini tek bakışta görür.
class MatchScoreboard extends StatelessWidget {
  final String team1Name;
  final String team2Name;
  final int score1;
  final int score2;
  final int activePlayer;
  final bool isFinished;
  final List<MatchEvent> events;
  final VoidCallback onExit;
  final VoidCallback? onRestart;

  const MatchScoreboard({
    super.key,
    required this.team1Name,
    required this.team2Name,
    required this.score1,
    required this.score2,
    required this.activePlayer,
    required this.isFinished,
    required this.events,
    required this.onExit,
    this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: NeobrutalistColors.black,
        border: Border(
          top: BorderSide(color: NeobrutalistColors.black, width: 3),
          bottom: BorderSide(color: NeobrutalistColors.black, width: 3),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _smallButton(
                label: 'ÇIKIŞ',
                color: NeobrutalistColors.pink,
                onTap: onExit,
              ),
              const SizedBox(width: 6),
              if (onRestart != null)
                _smallButton(
                  label: 'YENİDEN',
                  color: NeobrutalistColors.green,
                  onTap: onRestart!,
                ),
              const Spacer(),

              // Skor
              _scoreChip(score1, NeobrutalistColors.pink, activePlayer == 1 && !isFinished),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text('–',
                    style: NeobrutalistStyles.headlineStyle(
                        fontSize: 16, color: NeobrutalistColors.white)),
              ),
              _scoreChip(score2, NeobrutalistColors.blue, activePlayer == 2 && !isFinished),

              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isFinished
                      ? NeobrutalistColors.gray
                      : (activePlayer == 1
                          ? NeobrutalistColors.pink
                          : NeobrutalistColors.blue),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isFinished
                      ? 'BİTTİ'
                      : 'SIRA: ${activePlayer == 1 ? team1Name : team2Name}',
                  style: NeobrutalistStyles.headlineStyle(
                      fontSize: 8, color: NeobrutalistColors.white),
                ),
              ),
            ],
          ),

          // Canlı olay şeridi
          if (events.isNotEmpty) ...[
            const SizedBox(height: 5),
            SizedBox(
              height: 20,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: events.length,
                separatorBuilder: (_, _) => const SizedBox(width: 5),
                itemBuilder: (context, i) {
                  final e = events[i];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: e.playerNum == 1
                          ? NeobrutalistColors.pink
                          : NeobrutalistColors.blue,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${e.icon} ${e.text}',
                      style: NeobrutalistStyles.headlineStyle(
                          fontSize: 8, color: NeobrutalistColors.white),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _scoreChip(int score, Color color, bool active) => AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        decoration: BoxDecoration(
          color: active ? color : Colors.transparent,
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '$score',
          style: NeobrutalistStyles.headlineStyle(
            fontSize: 20,
            color: active ? NeobrutalistColors.white : color,
          ),
        ),
      );

  Widget _smallButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            label,
            style: NeobrutalistStyles.headlineStyle(
                fontSize: 8, color: NeobrutalistColors.white),
          ),
        ),
      );
}
