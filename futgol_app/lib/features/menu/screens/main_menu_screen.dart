import 'package:flutter/material.dart';
import 'package:futgol_app/common/models/user_profile.dart';
import 'package:futgol_app/common/services/profile_service.dart';
import 'package:futgol_app/common/services/statistics_service.dart';
import 'package:futgol_app/common/theme/neobrutalist_theme.dart';
import 'package:futgol_app/common/widgets/futboli_mascot.dart';

class GameInfo {
  final String key;
  final String title;
  final String description;
  final String emoji;
  final Color color;
  final List<String> badges;
  final GameCategory category;

  const GameInfo({
    required this.key,
    required this.title,
    required this.description,
    required this.emoji,
    required this.color,
    required this.badges,
    required this.category,
  });
}

enum GameCategory { duel, guess, quiz }

extension GameCategoryX on GameCategory {
  String get title {
    switch (this) {
      case GameCategory.duel:
        return '🎮 KARŞILIKLI OYNA';
      case GameCategory.guess:
        return '🕵️ FUTBOLCU BUL';
      case GameCategory.quiz:
        return '🧠 BİLGİ YARIŞMASI';
    }
  }

  String get subtitle {
    switch (this) {
      case GameCategory.duel:
        return 'Tek telefonda iki kişi';
      case GameCategory.guess:
        return 'İpuçlarından ismi çıkar';
      case GameCategory.quiz:
        return 'Doğru şıkkı seç, seriyi büyüt';
    }
  }
}

class MainMenuScreen extends StatefulWidget {
  final Function(String game) onSelectGame;
  final VoidCallback onOpenStats;
  final VoidCallback onOpenSettings;

  const MainMenuScreen({
    super.key,
    required this.onSelectGame,
    required this.onOpenStats,
    required this.onOpenSettings,
  });

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  UserProfile? _profile;
  Map<String, dynamic> _stats = const {};

  static const List<GameInfo> games = [
    GameInfo(
      key: 'stopwatch',
      title: "KRONOMETRE FUTBOLU",
      description: "İki kişilik salise düellosu: kadronu kur, saliseyi yakala, gol at.",
      emoji: "⏱️",
      color: NeobrutalistColors.blue,
      badges: ['👥', '⚡', '⏱️'],
      category: GameCategory.duel,
    ),
    GameInfo(
      key: 'common_link',
      title: "ORTAK BAĞ BULUCU",
      description: "İki futbolcunun ortak takım arkadaşını veya iki kulübün ortak oyuncusunu bul.",
      emoji: "🤝",
      color: NeobrutalistColors.pink,
      badges: ['👤', '🧠', '⚙️'],
      category: GameCategory.guess,
    ),
    GameInfo(
      key: 'career_path',
      title: "KARİYER YOLU",
      description: "Kronolojik takım geçişlerinden futbolcuyu tahmin et.",
      emoji: "🗺️",
      color: NeobrutalistColors.green,
      badges: ['👤', '🧠', '⚙️'],
      category: GameCategory.guess,
    ),
    GameInfo(
      key: 'missing_lineup',
      title: "11'DEKİ GİZEMLİ OYUNCU",
      description: "Tarihi ilk 11 kadrosundaki eksik ismi bul.",
      emoji: "🛡️",
      color: Colors.orange,
      badges: ['👤', '🧠', '⚙️'],
      category: GameCategory.guess,
    ),
    GameInfo(
      key: 'transfer_bridge',
      title: "TRANSFER KÖPRÜSÜ",
      description: "İki kulüpte de forma giymiş ortak futbolcuyu bul.",
      emoji: "🌉",
      color: Colors.cyan,
      badges: ['👤', '🧠', '⚙️'],
      category: GameCategory.guess,
    ),
    GameInfo(
      key: 'match_goalscorer',
      title: "MAÇ DEDEKTİFİ",
      description: "Skor ve gol dakikalarına bakarak eksik golcüyü bul.",
      emoji: "⚽",
      color: Colors.teal,
      badges: ['👤', '🧠', '⚙️'],
      category: GameCategory.guess,
    ),
    GameInfo(
      key: 'card_king',
      title: "KART CEZASI CANAVARI",
      description: "Kart istatistiklerine bakarak hırçın futbolcuyu bul.",
      emoji: "🟥",
      color: Colors.redAccent,
      badges: ['👤', '🧠', '⚙️'],
      category: GameCategory.guess,
    ),
    GameInfo(
      key: 'top_stats',
      title: "ZİRVE İSTATİSTİKLER",
      description: "Sezonun gol/asist kralını istatistiklerinden tanı.",
      emoji: "👑",
      color: Colors.amber,
      badges: ['👤', '🧠', '⚙️'],
      category: GameCategory.guess,
    ),
    GameInfo(
      key: 'immaculate_grid',
      title: "KOLEKSİYONCU GRİD",
      description: "Kesişim tablosunu iki kulüpte de oynamış futbolcularla doldur.",
      emoji: "🏁",
      color: Colors.deepOrangeAccent,
      badges: ['👤', '🧠', '⚙️'],
      category: GameCategory.guess,
    ),
    GameInfo(
      key: 'market_value',
      title: "YÜKSEK / DÜŞÜK DEĞER",
      description: "Hangi futbolcunun zirve piyasa değeri daha yüksek?",
      emoji: "📈",
      color: NeobrutalistColors.purple,
      badges: ['👤', '🧠', '⚙️'],
      category: GameCategory.quiz,
    ),
    GameInfo(
      key: 'market_value_quiz',
      title: "PİYASA DEĞERİ TAHMİN",
      description: "Futbolcunun ulaştığı en yüksek değeri şıklardan seç.",
      emoji: "💶",
      color: Colors.lightGreen,
      badges: ['👤', '🧠', '⚙️'],
      category: GameCategory.quiz,
    ),
    GameInfo(
      key: 'transfer_fee',
      title: "TRANSFER DÜELLOSU",
      description: "Hangi transferin bonservisi daha yüksekti?",
      emoji: "💰",
      color: NeobrutalistColors.yellow,
      badges: ['👤', '🧠', '⚙️'],
      category: GameCategory.quiz,
    ),
    GameInfo(
      key: 'stadium_capacity',
      title: "STADYUM ATLASI",
      description: "Stadyum adı ve kapasitesinden kulübü bul.",
      emoji: "🏟️",
      color: Colors.lime,
      badges: ['👤', '🧠', '⚙️'],
      category: GameCategory.quiz,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await ProfileService().getProfile();
    final stats = await StatisticsService().getGlobalStats();
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _stats = stats;
    });
  }

  String _badgeExplanation(String emoji) {
    switch (emoji) {
      case '👤':
        return "👤 Tek kişilik zekâ ve tahmin bulmacası.";
      case '👥':
        return "👥 Aynı telefonda karşılıklı iki kişilik düello.";
      case '🧠':
        return "🧠 Veritabanı tabanlı futbol genel kültürü.";
      case '⚡':
        return "⚡ Milisaniyelik zamanlama ve refleks.";
      case '⚙️':
        return "⚙️ Zorluk seçimi var (Kolay · Orta · Zor · Veteran).";
      case '⏱️':
        return "⏱️ Süreli oyun — zamana karşı yarışırsın.";
      default:
        return "$emoji Futgol oyun rozeti.";
    }
  }

  void _showBadgeExplanation(String emoji) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(
          _badgeExplanation(emoji),
          style: NeobrutalistStyles.headlineStyle(fontSize: 9, color: Colors.white),
        ),
        backgroundColor: NeobrutalistColors.purple,
        duration: const Duration(milliseconds: 1800),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeobrutalistColors.yellow,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopBar(),
              const SizedBox(height: 10),
              _buildProfileStrip(),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 10),
                  children: [
                    for (final category in GameCategory.values) ...[
                      _buildCategoryHeader(category),
                      const SizedBox(height: 8),
                      ...games
                          .where((g) => g.category == category)
                          .map(_buildGameCard),
                      const SizedBox(height: 6),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const FutboliMascot(size: 34),
            const SizedBox(width: 8),
            Text("FUTGOL", style: NeobrutalistStyles.headlineStyle(fontSize: 22)),
          ],
        ),
        Row(
          children: [
            _iconButton("🏆", NeobrutalistColors.orange, widget.onOpenStats),
            const SizedBox(width: 8),
            _iconButton("⚙️", NeobrutalistColors.blue, widget.onOpenSettings),
          ],
        ),
      ],
    );
  }

  Widget _iconButton(String emoji, Color color, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color,
            border: NeobrutalistStyles.border(width: 2),
            borderRadius: BorderRadius.circular(10),
            boxShadow: NeobrutalistStyles.shadow(offset: const Offset(2, 2)),
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 16)),
        ),
      );

  /// Kullanıcıya kim olduğunu ve genel başarısını hatırlatan şerit.
  Widget _buildProfileStrip() {
    final int totalGames = (_stats['total_games'] as int?) ?? 0;
    final double accuracy = (_stats['accuracy'] as num?)?.toDouble() ?? 0.0;
    final int bestStreak = (_stats['best_streak'] as int?) ?? 0;
    final double rate = accuracy / 100.0;

    return GestureDetector(
      onTap: widget.onOpenStats,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: NeobrutalistColors.black,
          border: NeobrutalistStyles.border(width: 2.5),
          borderRadius: BorderRadius.circular(14),
          boxShadow: NeobrutalistStyles.shadow(offset: const Offset(3, 3)),
        ),
        child: Row(
          children: [
            Text(_profile?.emoji ?? '⚽', style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _profile == null ? 'HOŞ GELDİN!' : 'HOŞ GELDİN, ${_profile!.name.toUpperCase()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: NeobrutalistStyles.headlineStyle(
                        fontSize: 11, color: NeobrutalistColors.white),
                  ),
                  Text(
                    totalGames == 0
                        ? 'Henüz istatistik yok — ilk oyununu oyna!'
                        : '$totalGames oyun · %${accuracy.toStringAsFixed(0)} doğruluk · en iyi seri $bestStreak',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: NeobrutalistStyles.bodyStyle(
                        fontSize: 8, color: NeobrutalistColors.yellow),
                  ),
                ],
              ),
            ),
            if (totalGames > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: rate >= 0.6
                      ? NeobrutalistColors.green
                      : rate >= 0.35
                          ? NeobrutalistColors.orange
                          : NeobrutalistColors.pink,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('%${accuracy.toStringAsFixed(0)}',
                    style: NeobrutalistStyles.headlineStyle(
                        fontSize: 10, color: NeobrutalistColors.white)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryHeader(GameCategory category) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Text(category.title, style: NeobrutalistStyles.headlineStyle(fontSize: 12)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              category.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: NeobrutalistStyles.bodyStyle(fontSize: 8, color: Colors.brown[700]!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard(GameInfo game) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: NeobrutalistColors.white,
        border: NeobrutalistStyles.border(width: 3),
        borderRadius: BorderRadius.circular(16),
        boxShadow: NeobrutalistStyles.shadow(offset: const Offset(4, 4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onSelectGame(game.key),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Renkli sol ray — oyunlar birbirinden görsel olarak ayrışsın
                Container(width: 8, color: game.color),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: game.color,
                            border: NeobrutalistStyles.border(width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(game.emoji, style: const TextStyle(fontSize: 24)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(game.title,
                                  style: NeobrutalistStyles.headlineStyle(fontSize: 11)),
                              const SizedBox(height: 3),
                              Text(
                                game.description,
                                style: NeobrutalistStyles.bodyStyle(
                                    fontSize: 8.2, color: Colors.grey[600]!),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: game.badges
                                    .map((b) => GestureDetector(
                                          onTap: () => _showBadgeExplanation(b),
                                          child: Container(
                                            margin: const EdgeInsets.only(right: 6),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: NeobrutalistColors.yellow
                                                  .withValues(alpha: 0.35),
                                              border: Border.all(
                                                  color: Colors.black, width: 1.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(b,
                                                style: const TextStyle(fontSize: 10)),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 15, color: Colors.black),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
