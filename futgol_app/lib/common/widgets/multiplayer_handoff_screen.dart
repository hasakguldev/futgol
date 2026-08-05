import 'package:flutter/material.dart';
import '../theme/neobrutalist_theme.dart';
import '../services/multiplayer_service.dart';

class MultiplayerHandoffScreen extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onStart;
  
  // Maraton mod için önceki oyuncunun sonuçları
  final String? previousPlayerName;
  final int? previousPlayerScore;

  const MultiplayerHandoffScreen({
    super.key,
    required this.title,
    this.subtitle,
    required this.onStart,
    this.previousPlayerName,
    this.previousPlayerScore,
  });

  @override
  Widget build(BuildContext context) {
    final service = MultiplayerService();
    final currentPlayer = service.currentPlayer;

    return Scaffold(
      backgroundColor: NeobrutalistColors.yellow,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 4),
                borderRadius: NeobrutalistStyles.radius20,
                boxShadow: NeobrutalistStyles.shadow(offset: const Offset(6, 6)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: NeobrutalistStyles.headlineStyle(fontSize: 16),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      subtitle!,
                      textAlign: TextAlign.center,
                      style: NeobrutalistStyles.bodyStyle(fontSize: 10, color: Colors.grey[700]!),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Önceki Oyuncunun Skoru (Maraton mod için)
                  if (previousPlayerName != null && previousPlayerScore != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: NeobrutalistColors.pink,
                        border: Border.all(color: Colors.black, width: 3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "🏁 TUR TAMAMLANDI!",
                            style: NeobrutalistStyles.headlineStyle(fontSize: 10, color: Colors.white),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "$previousPlayerName: $previousPlayerScore Puan",
                            style: NeobrutalistStyles.headlineStyle(fontSize: 14, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Sıradaki Oyuncu Kartı
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: currentPlayer.color,
                      border: Border.all(color: Colors.black, width: 3.5),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: NeobrutalistStyles.shadow(offset: const Offset(4, 4)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          currentPlayer.emoji,
                          style: const TextStyle(fontSize: 48),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          currentPlayer.name.toUpperCase(),
                          style: NeobrutalistStyles.headlineStyle(
                            fontSize: 18, 
                            color: currentPlayer.color == NeobrutalistColors.black 
                                ? Colors.white 
                                : Colors.black
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Sıra Sende!",
                          style: NeobrutalistStyles.headlineStyle(
                            fontSize: 10, 
                            color: currentPlayer.color == NeobrutalistColors.black 
                                ? Colors.white.withValues(alpha: 0.8) 
                                : Colors.black.withValues(alpha: 0.8)
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Text(
                    "Telefonu ${currentPlayer.name} isimli oyuncuya verin ve hazır olduğunda aşağıdaki butona bassın.",
                    textAlign: TextAlign.center,
                    style: NeobrutalistStyles.bodyStyle(fontSize: 9),
                  ),

                  const SizedBox(height: 24),

                  // Hazırım Butonu
                  NeobrutalistButton(
                    onPressed: onStart,
                    backgroundColor: NeobrutalistColors.black,
                    shadowColor: Colors.grey[800]!,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "✅ HAZIRIM, BAŞLAT!",
                          style: NeobrutalistStyles.headlineStyle(fontSize: 12, color: NeobrutalistColors.yellow),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.play_arrow, color: NeobrutalistColors.yellow, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
