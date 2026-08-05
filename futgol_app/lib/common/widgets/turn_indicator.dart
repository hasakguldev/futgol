import 'package:flutter/material.dart';
import '../theme/neobrutalist_theme.dart';
import '../services/multiplayer_service.dart';

class TurnIndicator extends StatelessWidget {
  const TurnIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final service = MultiplayerService();
    if (service.mode == 'solo') return const SizedBox.shrink();

    final currentPlayer = service.currentPlayer;
    final isMarathon = service.mode == 'marathon';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: currentPlayer.color,
        border: Border.all(color: Colors.black, width: 2.5),
        borderRadius: BorderRadius.circular(8),
        boxShadow: NeobrutalistStyles.shadow(offset: const Offset(2.5, 2.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            currentPlayer.emoji,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 6),
          Text(
            isMarathon ? "MARATON: ${currentPlayer.name}" : "SIRA: ${currentPlayer.name}",
            style: NeobrutalistStyles.headlineStyle(
              fontSize: 10,
              color: currentPlayer.color == NeobrutalistColors.black 
                  ? Colors.white 
                  : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
