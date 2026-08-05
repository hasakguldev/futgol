import 'package:flutter/material.dart';
import '../theme/neobrutalist_theme.dart';
import 'player_avatar.dart';

/// Soru bittiğinde (doğru bilindi ya da canlar tükendi) cevabı fotoğrafıyla
/// birlikte açan kart.
///
/// Veritabanındaki `players.image_url` sayesinde oyuncu, tahmin ettiği ismin
/// yüzünü de görüyor — kuru bir metin yerine tatmin edici bir kapanış.
class AnswerRevealCard extends StatelessWidget {
  final String playerName;
  final String? imageUrl;
  final List<String> facts;
  final Color color;
  final String label;

  const AnswerRevealCard({
    super.key,
    required this.playerName,
    this.imageUrl,
    this.facts = const [],
    this.color = NeobrutalistColors.green,
    this.label = 'DOĞRU CEVAP',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: NeobrutalistStyles.border(width: 2.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: NeobrutalistStyles.headlineStyle(fontSize: 8, color: Colors.grey[700]!),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              PlayerAvatar(
                imageUrl: imageUrl,
                fallbackText: _initials(playerName),
                size: 56,
                borderWidth: 3,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        playerName.toUpperCase(),
                        maxLines: 1,
                        style: NeobrutalistStyles.headlineStyle(fontSize: 15),
                      ),
                    ),
                    if (facts.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 5,
                        runSpacing: 4,
                        children: facts
                            .where((f) => f.trim().isNotEmpty)
                            .map((f) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: color,
                                    border: Border.all(
                                        color: NeobrutalistColors.black, width: 1.5),
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: Text(
                                    f,
                                    style: NeobrutalistStyles.headlineStyle(
                                        fontSize: 8, color: NeobrutalistColors.white),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
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
