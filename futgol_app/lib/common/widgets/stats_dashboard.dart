import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/neobrutalist_theme.dart';
import '../services/statistics_service.dart';
import '../services/profile_service.dart';
import '../models/user_profile.dart';

class StatsDashboard extends StatefulWidget {
  final VoidCallback onBackToMenu;

  const StatsDashboard({super.key, required this.onBackToMenu});

  @override
  State<StatsDashboard> createState() => _StatsDashboardState();
}

class _StatsDashboardState extends State<StatsDashboard> {
  final _statsService = StatisticsService();
  UserProfile? _profile;
  Map<String, dynamic> _globalStats = {};
  final Map<String, Map<String, dynamic>> _gameStats = {};
  Map<String, Map<String, int>> _h2hStats = {};
  bool _isLoading = true;

  final Map<String, String> _gameNames = {
    'career_path': '⚽ Kariyer Yolu',
    'market_value': '💰 Yüksek / Düşük',
    'transfer_fee': '💸 Transfer Düellosu',
    'missing_lineup': '🕵️ Gizemli 11',
    'transfer_bridge': '🔗 Transfer Köprüsü',
    'match_goalscorer': '⚽ Maç Dedektifi',
    'immaculate_grid': '🧩 Koleksiyoncu Grid',
    'stadium_capacity': '🏟️ Stadyum Atlası',
    'card_king': '🎴 Kart Canavarı',
    'top_stats': '📊 Zirve İstatistikler',
    'market_value_quiz': '💶 Değer Tahmini',
    'common_link': '🤝 Ortak Bağ Bulucu',
    'stopwatch': '⏱️ Kronometre Futbolu',
  };

  @override
  void initState() {
    super.initState();
    _loadAllStats();
  }

  void _loadAllStats() async {
    setState(() => _isLoading = true);
    _profile = await ProfileService().getProfile();
    _globalStats = await _statsService.getGlobalStats();
    _h2hStats = await _statsService.getH2HStats();

    _gameStats.clear();
    for (var key in _gameNames.keys) {
      _gameStats[key] = await _statsService.getGameStats(key);
    }

    setState(() => _isLoading = false);
  }

  void _clearStats() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Colors.black, width: 4),
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: NeobrutalistColors.yellow,
          title: Text(
            "VERİLERİ SIFIRLA?",
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900),
          ),
          content: Text(
            "Tüm oyun geçmişinizi ve istatistiklerinizi sıfırlamak istediğinize emin misiniz?",
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "İPTAL",
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, color: Colors.black),
              ),
            ),
            GestureDetector(
              onTap: () async {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                await _statsService.clearStatistics();
                navigator.pop();
                _loadAllStats();
                messenger.showSnackBar(
                  const SnackBar(content: Text("Tüm istatistikler sıfırlandı.")),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: NeobrutalistColors.pink,
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "SIFIRLA",
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: NeobrutalistColors.yellow,
        body: Center(
          child: CircularProgressIndicator(color: Colors.black),
        ),
      );
    }

    final ownerName = _profile?.name ?? "Kullanıcı";
    final ownerEmoji = _profile?.emoji ?? "⚽";

    // Oynanmış oyun listesini filtrele
    final playedGames = _gameStats.entries.where((e) => (e.value['played'] as int? ?? 0) > 0).toList();

    return Scaffold(
      backgroundColor: NeobrutalistColors.yellow,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: widget.onBackToMenu,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black, width: 2.5),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: NeobrutalistStyles.shadow(offset: const Offset(2, 2)),
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.black),
                    ),
                  ),
                  Text(
                    "İSTATİSTİKLER",
                    style: NeobrutalistStyles.headlineStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black, width: 3),
                  borderRadius: NeobrutalistStyles.radius20,
                  boxShadow: NeobrutalistStyles.shadow(offset: const Offset(4, 4)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: NeobrutalistColors.green,
                        border: Border.all(color: Colors.black, width: 2.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(ownerEmoji, style: const TextStyle(fontSize: 28)),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ownerName.toUpperCase(),
                          style: NeobrutalistStyles.headlineStyle(fontSize: 14),
                        ),
                        Text(
                          "Genel Oyuncu Profili",
                          style: NeobrutalistStyles.bodyStyle(fontSize: 8, color: Colors.grey[600]!),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  _buildMetricCard("TOPLAM MAÇ", _globalStats['total_games'].toString(), NeobrutalistColors.orange),
                  const SizedBox(width: 12),
                  _buildMetricCard("DOĞRULUK", "%${(_globalStats['accuracy'] as double).toStringAsFixed(0)}", NeobrutalistColors.pink),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildMetricCard("EN UZUN SERİ", "${_globalStats['best_streak']} 🔥", NeobrutalistColors.green),
                  const SizedBox(width: 12),
                  _buildMetricCard("SÜRE (DK)", _globalStats['total_duration_minutes'].toString(), NeobrutalistColors.purple),
                ],
              ),
              const SizedBox(height: 20),

              if (_h2hStats.isNotEmpty) ...[
                Text("⚔️ DÜELLO REKABETLERİ (H2H)", style: NeobrutalistStyles.headlineStyle(fontSize: 12)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black, width: 3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: _h2hStats.entries.map((entry) {
                      final name = entry.key;
                      final wins = entry.value['wins'] ?? 0;
                      final losses = entry.value['losses'] ?? 0;
                      final draws = entry.value['draws'] ?? 0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("vs $name", style: NeobrutalistStyles.headlineStyle(fontSize: 10)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: NeobrutalistColors.yellow,
                                border: Border.all(color: Colors.black, width: 1.5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "$wins G - $losses M - $draws B",
                                style: NeobrutalistStyles.headlineStyle(fontSize: 9),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              Text("📊 OYUN BAZLI DETAYLAR", style: NeobrutalistStyles.headlineStyle(fontSize: 12)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black, width: 3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: playedGames.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20.0),
                        child: Center(
                          child: Text(
                            "Henüz oynanmış oyun bulunmuyor.",
                            style: NeobrutalistStyles.bodyStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ),
                      )
                    : Column(
                        children: playedGames.map((entry) {
                          final key = entry.key;
                          final stats = entry.value;
                          final name = _gameNames[key] ?? key;
                          final played = stats['played'] as int? ?? 0;
                          final accuracy = stats['accuracy'] as double? ?? 0.0;
                          final highScore = stats['high_score'] as int? ?? 0;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(name, style: NeobrutalistStyles.headlineStyle(fontSize: 10)),
                                    Text("En Yüksek: $highScore P", style: NeobrutalistStyles.headlineStyle(fontSize: 8, color: Colors.grey[600]!)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Stack(
                                        children: [
                                          Container(
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              border: Border.all(color: Colors.black, width: 1.5),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                          ),
                                          FractionallySizedBox(
                                            widthFactor: accuracy / 100,
                                            child: Container(
                                              height: 12,
                                              decoration: BoxDecoration(
                                                color: NeobrutalistColors.green,
                                                border: Border.all(color: Colors.black, width: 1.5),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 60,
                                      child: Text(
                                        "%${accuracy.toStringAsFixed(0)} ($played M)",
                                        style: NeobrutalistStyles.headlineStyle(fontSize: 8),
                                        textAlign: TextAlign.end,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(color: Colors.grey, height: 16),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),

              const SizedBox(height: 24),
              NeobrutalistButton(
                onPressed: _clearStats,
                backgroundColor: NeobrutalistColors.pink,
                child: Text(
                  "🗑️ VERİLERİ SIFIRLA",
                  style: NeobrutalistStyles.headlineStyle(fontSize: 11, color: Colors.white),
                ),
              ),
              const SizedBox(height: 12),
              NeobrutalistButton(
                onPressed: widget.onBackToMenu,
                backgroundColor: NeobrutalistColors.green,
                child: Text(
                  "🏠 MENÜYE DÖN",
                  style: NeobrutalistStyles.headlineStyle(fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, Color color) {
    final isWhiteText = color == NeobrutalistColors.purple || color == NeobrutalistColors.pink;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: Colors.black, width: 3),
          borderRadius: BorderRadius.circular(16),
          boxShadow: NeobrutalistStyles.shadow(offset: const Offset(3, 3)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: NeobrutalistStyles.headlineStyle(fontSize: 9, color: isWhiteText ? Colors.white : Colors.black),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: NeobrutalistStyles.headlineStyle(fontSize: 18, color: isWhiteText ? Colors.white : Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}
