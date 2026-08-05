import 'package:flutter/material.dart';
import '../theme/neobrutalist_theme.dart';
import '../services/multiplayer_service.dart';
import '../services/statistics_service.dart';
import '../models/player_info.dart';

class MultiplayerScoreBoard extends StatefulWidget {
  final String gameType;
  final String difficulty;
  final int durationSeconds;
  final VoidCallback onPlayAgain;
  final VoidCallback onBackToMenu;

  const MultiplayerScoreBoard({
    super.key,
    required this.gameType,
    required this.difficulty,
    required this.durationSeconds,
    required this.onPlayAgain,
    required this.onBackToMenu,
  });

  @override
  State<MultiplayerScoreBoard> createState() => _MultiplayerScoreBoardState();
}

class _MultiplayerScoreBoardState extends State<MultiplayerScoreBoard> {
  late List<Map<String, dynamic>> _leaderboard;

  @override
  void initState() {
    super.initState();
    _buildLeaderboard();
    _saveSessionData();
  }

  void _buildLeaderboard() {
    final service = MultiplayerService();
    _leaderboard = service.players.map((player) {
      return {
        'player': player,
        'score': service.scores[player.name] ?? 0,
        'correct': service.correctAnswers[player.name] ?? 0,
        'wrong': service.wrongAnswers[player.name] ?? 0,
        'hints': service.hintsUsed[player.name] ?? 0,
        'passes': service.passesUsed[player.name] ?? 0,
      };
    }).toList();

    _leaderboard.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
  }

  void _saveSessionData() async {
    final session = MultiplayerService().createGameSession(
      gameType: widget.gameType,
      difficulty: widget.difficulty,
      durationSeconds: widget.durationSeconds,
    );
    await StatisticsService().saveSession(session);
  }

  @override
  Widget build(BuildContext context) {
    final service = MultiplayerService();
    final isSolo = service.mode == 'solo';

    return Scaffold(
      backgroundColor: NeobrutalistColors.yellow,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
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
                  const Center(
                    child: Text(
                      "🏆",
                      style: TextStyle(fontSize: 54),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isSolo ? "OYUN TAMAMLANDI" : "MAÇ SONUCU",
                    style: NeobrutalistStyles.headlineStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Süre: ${(widget.durationSeconds / 60).floor()} dk ${widget.durationSeconds % 60} sn",
                    style: NeobrutalistStyles.bodyStyle(fontSize: 9, color: Colors.grey[600]!),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _leaderboard.length,
                    itemBuilder: (context, index) {
                      final item = _leaderboard[index];
                      final player = item['player'] as PlayerInfo;
                      final score = item['score'] as int;
                      final correct = item['correct'] as int;
                      final wrong = item['wrong'] as int;

                      String rankEmoji = '🎗️';
                      if (index == 0) rankEmoji = '👑';
                      if (index == 1) rankEmoji = '🥈';
                      if (index == 2) rankEmoji = '🥉';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: player.color.withValues(alpha: 0.15),
                          border: Border.all(color: Colors.black, width: 3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Text(
                              rankEmoji,
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${player.emoji} ${player.name}",
                                    style: NeobrutalistStyles.headlineStyle(fontSize: 11),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Doğru: $correct  |  Yanlış: $wrong",
                                    style: NeobrutalistStyles.bodyStyle(fontSize: 8, color: Colors.grey[700]!),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: player.color,
                                border: Border.all(color: Colors.black, width: 2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "$score P",
                                style: NeobrutalistStyles.headlineStyle(
                                  fontSize: 10,
                                  color: player.color == NeobrutalistColors.black 
                                      ? Colors.white 
                                      : Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  NeobrutalistButton(
                    onPressed: widget.onPlayAgain,
                    backgroundColor: NeobrutalistColors.green,
                    child: Text(
                      "🔄 YENİDEN OYNA",
                      style: NeobrutalistStyles.headlineStyle(fontSize: 11),
                    ),
                  ),
                  const SizedBox(height: 12),
                  NeobrutalistButton(
                    onPressed: widget.onBackToMenu,
                    backgroundColor: NeobrutalistColors.pink,
                    child: Text(
                      "🏠 ANA MENÜYE DÖN",
                      style: NeobrutalistStyles.headlineStyle(fontSize: 11, color: Colors.white),
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
