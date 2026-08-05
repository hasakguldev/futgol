import 'package:flutter/material.dart';
import 'package:futgol_app/common/theme/neobrutalist_theme.dart';
import 'package:futgol_app/common/models/question_models.dart';

class CluesSectionWidget extends StatelessWidget {
  final List<Clue> clues;
  final int cluesOpened;
  final Function(int index) onOpenClue;

  const CluesSectionWidget({
    super.key,
    required this.clues,
    required this.cluesOpened,
    required this.onOpenClue,
  });

  @override
  Widget build(BuildContext context) {
    return NeobrutalistCard(
      padding: const EdgeInsets.all(16),
      backgroundColor: NeobrutalistColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "İPUÇLARI (3 HAK)",
            style: NeobrutalistStyles.headlineStyle(fontSize: 10),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Column(
            children: List.generate(clues.length, (idx) {
              final clue = clues[idx];
              final bool isOpen = cluesOpened >= idx + 1;
              return GestureDetector(
                onTap: () => onOpenClue(idx + 1),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isOpen ? NeobrutalistColors.green : Colors.grey[100],
                    border: NeobrutalistStyles.border(width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "${clue.type == 'Arkadaş' ? 'Takım Arkadaşı' : clue.type == 'Kulüp' ? 'Aynı Kulüp' : clue.type}: ${isOpen ? clue.value : 'KİLİTLİ'}",
                          style: NeobrutalistStyles.headlineStyle(
                            fontSize: 10,
                            color: isOpen ? NeobrutalistColors.white : Colors.grey[600]!,
                          ),
                        ),
                      ),
                      if (!isOpen) const Icon(Icons.lock, size: 14),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
