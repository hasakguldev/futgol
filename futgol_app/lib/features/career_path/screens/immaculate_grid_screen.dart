import 'package:flutter/material.dart';
import 'package:futgol_app/common/theme/neobrutalist_theme.dart';
import 'package:futgol_app/common/services/database_service.dart';
import 'package:futgol_app/common/models/football_player.dart';
import 'package:futgol_app/common/services/db_text_utils.dart';
import 'package:futgol_app/common/widgets/autocomplete_field.dart';
import 'package:futgol_app/common/widgets/game_setup_view.dart';
import 'package:futgol_app/common/utils/audio_helper.dart';

import '../../../common/services/multiplayer_service.dart';
import '../../../common/widgets/multiplayer_handoff_screen.dart';
import '../../../common/widgets/multiplayer_score_board.dart';
import '../../../common/widgets/turn_indicator.dart';

class ImmaculateGridScreen extends StatefulWidget {
  final VoidCallback onBackToMenu;

  const ImmaculateGridScreen({super.key, required this.onBackToMenu});

  @override
  State<ImmaculateGridScreen> createState() => _ImmaculateGridScreenState();
}

class _ImmaculateGridScreenState extends State<ImmaculateGridScreen> {
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();

  bool _isDbLoaded = false;
  bool _gameStarted = false;
  bool _isLoadingQuestion = false;

  Map<String, dynamic>? _gridData;
  List<FootballPlayer> _suggestions = [];

  String? _cell11;
  String? _cell12;
  String? _cell21;
  String? _cell22;

  bool _isWon = false;
  int _streak = 0;
  int _highScore = 0;

  // Çoklu Oyuncu Değişkenleri
  bool _showHandoff = false;
  bool _showScoreboard = false;
  String? _prevPlayerName;
  int? _prevPlayerScore;
  DateTime? _gameStartTime;

  @override
  void initState() {
    super.initState();
    _checkDbStatus();
  }

  Future<void> _checkDbStatus() async {
    final loaded = await _dbService.checkDatabaseStatus();
    setState(() {
      _isDbLoaded = loaded;
    });
  }

  Future<void> _loadQuestion() async {
    setState(() {
      _isLoadingQuestion = true;
      _cell11 = null;
      _cell12 = null;
      _cell21 = null;
      _cell22 = null;
      _isWon = false;
    });

    Map<String, dynamic>? data;
    for (int i = 0; i < 5; i++) {
      data = await _dbService.getRandomImmaculateGridConfig(_difficulty);
      if (data != null) break;
    }

    if (data == null) {
      setState(() {
        _isLoadingQuestion = false;
      });
      return;
    }

    setState(() {
      _gridData = data;
      _isLoadingQuestion = false;
      _gameStarted = true;
    });
  }

  String _difficulty = 'easy';

  void _showGuessDialog(int row, int col, String labelRow, String labelCol, List<dynamic> validAnswers) {
    _searchController.clear();
    _suggestions = [];

    final service = MultiplayerService();
    final isMulti = service.mode != 'solo';
    final currentPlayerName = service.currentPlayer.name;

    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: NeobrutalistColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Colors.black, width: 3),
              ),
              title: Text(
                "Kesişim: $labelRow ✖️ $labelCol",
                style: NeobrutalistStyles.headlineStyle(fontSize: 10),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NeobrutalistAutocompleteField(
                    controller: _searchController,
                    hintText: "Ortak oyuncu adını yazın...",
                    playerSuggestions: _suggestions,
                    onSuggestionSelected: (name) {
                      setDialogState(() {
                        _searchController.text = name;
                        _suggestions = [];
                      });
                    },
                    onChanged: (query) async {
                      if (query.trim().length < 2) {
                        setDialogState(() {
                          _suggestions = [];
                        });
                        return;
                      }
                      final results = await _dbService.searchPlayers(query);
                      setDialogState(() {
                        _suggestions = results;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                NeobrutalistButton(
                  onPressed: () {
                    final String guess = _searchController.text.trim();
                    if (guess.isEmpty) return;

                    final bool isCorrect = validAnswers.any(
                        (ans) => DbText.namesMatch(guess, ans.toString()));

                    if (isCorrect) {
                      AudioHelper().playSuccess();
                      setState(() {
                        if (row == 1 && col == 1) _cell11 = guess;
                        if (row == 1 && col == 2) _cell12 = guess;
                        if (row == 2 && col == 1) _cell21 = guess;
                        if (row == 2 && col == 2) _cell22 = guess;

                        if (isMulti) {
                          service.recordCorrectAnswer(currentPlayerName, basePoints: 100);
                        } else {
                          _streak++;
                          if (_streak > _highScore) _highScore = _streak;
                        }

                        if (_cell11 != null && _cell12 != null && _cell21 != null && _cell22 != null) {
                          _isWon = true;
                        }
                      });
                      Navigator.of(ctx).pop();

                      if (isMulti) {
                        final isGridSolved = _cell11 != null && _cell12 != null && _cell21 != null && _cell22 != null;
                        if (service.mode == 'turn_based' || (service.mode == 'marathon' && isGridSolved)) {
                          _handleMultiplayerTransition();
                        }
                      }
                    } else {
                      AudioHelper().playWrong();
                      if (isMulti) {
                        service.recordWrongAnswer(currentPlayerName);
                        final currentWrong = service.wrongAnswers[currentPlayerName] ?? 0;
                        if (currentWrong >= 3) {
                          Navigator.of(ctx).pop();
                          _handleMultiplayerTransition();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Yanlış Oyuncu! Kalan canınız: ${3 - currentWrong}"),
                              backgroundColor: Colors.red,
                            ),
                          );
                          if (service.mode == 'turn_based') {
                            Navigator.of(ctx).pop();
                            _handleMultiplayerTransition();
                          }
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Yanlış Oyuncu! Bu iki kulüpte de oynamış birini girin."),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  backgroundColor: NeobrutalistColors.blue,
                  shadowColor: NeobrutalistColors.black,
                  child: Text(
                    "DOĞRULA",
                    style: NeobrutalistStyles.headlineStyle(fontSize: 10, color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _handleMultiplayerTransition() {
    final service = MultiplayerService();
    final prevName = service.currentPlayer.name;
    final prevScore = service.scores[prevName] ?? 0;

    final isGridSolved = _cell11 != null && _cell12 != null && _cell21 != null && _cell22 != null;

    if (service.mode == 'turn_based' && isGridSolved) {
      setState(() {
        _showScoreboard = true;
      });
      return;
    }

    bool foundNext = false;
    int startIndex = service.currentPlayerIndex;
    int nextIndex = startIndex;

    do {
      nextIndex = (nextIndex + 1) % service.players.length;
      if (service.mode == 'marathon') {
        if (nextIndex > startIndex) {
          foundNext = true;
          break;
        } else {
          break;
        }
      } else {
        final nextPlayer = service.players[nextIndex];
        if ((service.wrongAnswers[nextPlayer.name] ?? 0) < 3) {
          foundNext = true;
          break;
        }
      }
    } while (nextIndex != startIndex);

    if (foundNext) {
      setState(() {
        _prevPlayerName = prevName;
        _prevPlayerScore = prevScore;
        _showHandoff = true;
        service.currentPlayerIndex = nextIndex;

        if (service.mode == 'marathon') {
          _cell11 = null;
          _cell12 = null;
          _cell21 = null;
          _cell22 = null;
          _isWon = false;
        }
      });
    } else {
      setState(() {
        _showScoreboard = true;
      });
    }
  }

  Widget _buildGridCell(int row, int col, String labelRow, String labelCol, List<dynamic> validAnswers, String? solvedVal) {
    final bool isSolved = solvedVal != null;
    return Expanded(
      child: GestureDetector(
        onTap: isSolved ? null : () => _showGuessDialog(row, col, labelRow, labelCol, validAnswers),
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isSolved ? NeobrutalistColors.green : NeobrutalistColors.white,
              border: NeobrutalistStyles.border(width: 2.5),
              borderRadius: BorderRadius.circular(12),
              boxShadow: isSolved 
                ? null 
                : NeobrutalistStyles.shadow(offset: const Offset(3, 3)),
            ),
            child: Center(
              child: Text(
                isSolved ? solvedVal : "❓",
                style: NeobrutalistStyles.headlineStyle(
                  fontSize: isSolved ? 7.5 : 14,
                  color: isSolved ? Colors.white : Colors.grey[400]!,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Expanded(
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: NeobrutalistColors.purple,
            border: NeobrutalistStyles.border(width: 2.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Text(
                text,
                style: NeobrutalistStyles.headlineStyle(fontSize: 7.5, color: Colors.white),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = MultiplayerService();
    final isMulti = service.mode != 'solo';

    if (_showScoreboard) {
      final elapsed = _gameStartTime != null 
          ? DateTime.now().difference(_gameStartTime!).inSeconds 
          : 0;
      return MultiplayerScoreBoard(
        gameType: 'immaculate_grid',
        difficulty: _difficulty,
        durationSeconds: elapsed,
        onPlayAgain: () {
          service.setupMultiplayer(
            selectedPlayers: service.players,
            selectedMode: service.mode,
            h2hRounds: service.h2hTargetRounds,
          );
          setState(() {
            _cell11 = null;
            _cell12 = null;
            _cell21 = null;
            _cell22 = null;
            _isWon = false;
            _streak = 0;
            _showHandoff = false;
            _showScoreboard = false;
            _prevPlayerName = null;
            _prevPlayerScore = null;
            _gameStartTime = DateTime.now();
          });
          _loadQuestion();
        },
        onBackToMenu: widget.onBackToMenu,
      );
    }

    if (_showHandoff) {
      return MultiplayerHandoffScreen(
        title: service.mode == 'marathon' ? "MARATON GEÇİŞİ" : "SIRADAKİ OYUNCU",
        previousPlayerName: _prevPlayerName,
        previousPlayerScore: _prevPlayerScore,
        onStart: () {
          setState(() {
            _showHandoff = false;
            _searchController.clear();
            _suggestions = [];
          });
          if (service.mode == 'marathon') {
            _loadQuestion();
          }
        },
      );
    }

    if (_isLoadingQuestion) {
      return Scaffold(
        backgroundColor: NeobrutalistColors.yellow,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(NeobrutalistColors.black),
                strokeWidth: 4,
              ),
              SizedBox(height: 16),
              Text(
                "İnteraktif grid çiziliyor...",
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: NeobrutalistColors.black,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_gameStarted) {
      return SoccerGameSetupView(
        gameKey: "immaculate_grid",
        gameTitle: "KOLEKSİYONCU GRİD",
        gameDescription: "2x2 kesişim tablosundaki her hücre için, o satır ve sütundaki kulüplerin her ikisinde de oynamış ortak oyuncuları bulun.",
        difficulties: const ["easy", "medium", "hard", "veteran"],
        initialDifficulty: _difficulty,
        isDbRequired: true,
        isDbLoaded: _isDbLoaded,
        onBackToMenu: widget.onBackToMenu,
        onStart: (diff, mode) {
          setState(() {
            _difficulty = diff;
            _streak = 0;
            _showHandoff = false;
            _showScoreboard = false;
            _prevPlayerName = null;
            _prevPlayerScore = null;
            _gameStartTime = DateTime.now();
          });
          _loadQuestion();
        },
      );
    }

    final String row1 = _gridData!['row1'] as String;
    final String row2 = _gridData!['row2'] as String;
    final String col1 = _gridData!['col1'] as String;
    final String col2 = _gridData!['col2'] as String;

    final answers11 = _gridData!['answers11'] as List<dynamic>;
    final answers12 = _gridData!['answers12'] as List<dynamic>;
    final answers21 = _gridData!['answers21'] as List<dynamic>;
    final answers22 = _gridData!['answers22'] as List<dynamic>;

    final currentWrong = service.wrongAnswers[service.currentPlayer.name] ?? 0;
    final int displayLives = 3 - currentWrong;

    return Scaffold(
      backgroundColor: NeobrutalistColors.yellow,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: NeobrutalistColors.white,
                    border: NeobrutalistStyles.border(width: 3),
                    borderRadius: NeobrutalistStyles.radius20,
                    boxShadow: NeobrutalistStyles.shadow(offset: const Offset(4, 4)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _gameStarted = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: NeobrutalistColors.pink,
                            border: NeobrutalistStyles.border(width: 2),
                            borderRadius: NeobrutalistStyles.radius12,
                          ),
                          child: Text(
                            "ÇIKIŞ",
                            style: NeobrutalistStyles.headlineStyle(fontSize: 10, color: NeobrutalistColors.white),
                          ),
                        ),
                      ),
                      Text(
                        isMulti
                            ? "🔥 PUAN: ${service.scores[service.currentPlayer.name] ?? 0}"
                            : "🔥 SKOR: $_streak | EN İYİ: $_highScore",
                        style: NeobrutalistStyles.headlineStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (isMulti) const TurnIndicator(),
                const SizedBox(height: 8),

                if (isMulti) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: NeobrutalistColors.black,
                          borderRadius: BorderRadius.circular(30),
                          border: NeobrutalistStyles.border(width: 2),
                        ),
                        child: Row(
                          children: [
                            Text("CANLAR: ", style: NeobrutalistStyles.headlineStyle(fontSize: 11, color: NeobrutalistColors.white)),
                            ...List.generate(3, (i) => Text(
                              i < displayLives ? "❤️" : "🖤",
                              style: const TextStyle(fontSize: 12),
                            )),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                NeobrutalistCard(
                  padding: const EdgeInsets.all(12),
                  backgroundColor: NeobrutalistColors.white,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Expanded(child: SizedBox()),
                          _buildHeaderCell(col1),
                          _buildHeaderCell(col2),
                        ],
                      ),
                      Row(
                        children: [
                          _buildHeaderCell(row1),
                          _buildGridCell(1, 1, row1, col1, answers11, _cell11),
                          _buildGridCell(1, 2, row1, col2, answers12, _cell12),
                        ],
                      ),
                      Row(
                        children: [
                          _buildHeaderCell(row2),
                          _buildGridCell(2, 1, row2, col1, answers21, _cell21),
                          _buildGridCell(2, 2, row2, col2, answers22, _cell22),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (_isWon) ...[
                  NeobrutalistCard(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: NeobrutalistColors.white,
                    child: Column(
                      children: [
                        Text(
                          "GRID ÇÖZÜLDÜ! 🎉",
                          style: NeobrutalistStyles.headlineStyle(fontSize: 12, color: Colors.green),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Tüm hücreleri başarıyla doldurdunuz!",
                          style: NeobrutalistStyles.bodyStyle(fontSize: 9),
                        ),
                        const SizedBox(height: 16),
                        NeobrutalistButton(
                          onPressed: isMulti ? _handleMultiplayerTransition : _loadQuestion,
                          backgroundColor: NeobrutalistColors.blue,
                          shadowColor: NeobrutalistColors.black,
                          child: Text(
                            isMulti ? "DEVAM ET" : "SIRADAKİ GRİD",
                            style: NeobrutalistStyles.headlineStyle(fontSize: 11, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: NeobrutalistColors.white,
                      border: NeobrutalistStyles.border(width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Kesişim hücrelerine tıklayın ve her iki kulübün de formasını giymiş ortak bir oyuncu yazın.",
                      style: NeobrutalistStyles.bodyStyle(fontSize: 8.5, color: Colors.grey[700]!),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
