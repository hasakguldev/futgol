import 'package:flutter/material.dart';
import 'package:futgol_app/common/theme/neobrutalist_theme.dart';
import 'package:futgol_app/common/services/database_service.dart';
import 'package:futgol_app/common/models/football_player.dart';
import 'package:futgol_app/common/widgets/answer_reveal_card.dart';
import 'package:futgol_app/common/services/db_text_utils.dart';
import 'package:futgol_app/common/widgets/autocomplete_field.dart';
import 'package:futgol_app/common/widgets/game_setup_view.dart';
import 'package:futgol_app/common/utils/audio_helper.dart';
import 'package:futgol_app/features/common_link/widgets/guess_game_widgets.dart';

import '../../../common/services/multiplayer_service.dart';
import '../../../common/widgets/multiplayer_handoff_screen.dart';
import '../../../common/widgets/multiplayer_score_board.dart';
import '../../../common/widgets/turn_indicator.dart';

class CardKingScreen extends StatefulWidget {
  final VoidCallback onBackToMenu;

  const CardKingScreen({super.key, required this.onBackToMenu});

  @override
  State<CardKingScreen> createState() => _CardKingScreenState();
}

class _CardKingScreenState extends State<CardKingScreen> {
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();

  bool _isDbLoaded = false;
  bool _gameStarted = false;
  bool _isLoadingQuestion = false;
  final bool _isProcessing = false;
  bool _isGameOver = false;
  bool _isWon = false;

  String _difficulty = 'easy';
  int _lives = 3;
  int _streak = 0;

  Map<String, dynamic>? _questionData;
  String _feedbackMsg = '';
  List<FootballPlayer> _suggestions = [];

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
      _feedbackMsg = '';
    });

    // Rastgele seçim bazı zorluk/veri kombinasyonlarında boş dönebiliyor;
    // kullanıcıyı 'yüklenemedi' ile baş başa bırakmak yerine birkaç kez deniyoruz.
    var data = await _dbService.getRandomCardKingQuiz(_difficulty);
    for (int attempt = 0; data == null && attempt < 3; attempt++) {
      data = await _dbService.getRandomCardKingQuiz(_difficulty);
    }
    if (data == null) {
      setState(() {
        _isLoadingQuestion = false;
        _feedbackMsg = _dbService.lastError == null
            ? "⚠️ Bu zorluk için uygun soru bulunamadı. Zorluğu değiştirip tekrar deneyin."
            : "⚠️ Veritabanı hatası: ${_dbService.lastError}";
      });
      return;
    }

    setState(() {
      _questionData = data;
      _isLoadingQuestion = false;
      _gameStarted = true;
      _isGameOver = false;
      _isWon = false;
      _searchController.clear();
      _suggestions = [];
    });
  }

  void _onSearchChanged(String query) async {
    if (query.trim().length < 2) {
      setState(() {
        _suggestions = [];
      });
      return;
    }
    final results = await _dbService.searchPlayers(query);
    setState(() {
      _suggestions = results;
    });
  }

  void _submitGuess(String guess) {
    if (guess.trim().isEmpty || _questionData == null) return;

    final String correctAnswer = _questionData!['player_name'] as String;
    final service = MultiplayerService();
    final isMulti = service.mode != 'solo';
    final currentPlayerName = service.currentPlayer.name;

    if (DbText.namesMatch(guess, correctAnswer)) {
      AudioHelper().playSuccess();
      if (isMulti) {
        service.recordCorrectAnswer(currentPlayerName, basePoints: 100);
      }
      setState(() {
        _isWon = true;
        _streak++;
        _feedbackMsg = "TEBRİKLER! Hırçın Oyuncu: $correctAnswer";
      });
    } else {
      AudioHelper().playWrong();
      if (isMulti) {
        service.recordWrongAnswer(currentPlayerName);
      }
      setState(() {
        _lives--;
        _streak = 0;
        if (_lives <= 0) {
          _isGameOver = true;
          _feedbackMsg = "OYUN BİTTİ! Doğru Cevap: $correctAnswer";
        } else {
          _feedbackMsg = "Yanlış Cevap! Kalan canınız: $_lives";
        }
      });
    }
  }

  void _handleMultiplayerTransition() {
    final service = MultiplayerService();
    final prevName = service.currentPlayer.name;
    final prevScore = service.scores[prevName] ?? 0;

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
        _lives = 3 - (service.wrongAnswers[service.currentPlayer.name] ?? 0);
      });
    } else {
      setState(() {
        _showScoreboard = true;
      });
    }
  }

  void _handleNextStep() {
    final service = MultiplayerService();
    if (service.mode == 'solo') {
      _nextLevel();
      return;
    }

    if (service.mode == 'marathon') {
      if (_isWon) {
        _nextLevel();
      }
    } else if (service.mode == 'turn_based') {
      _handleMultiplayerTransition();
    }
  }

  void _restartGame() {
    setState(() {
      _lives = 3;
      _streak = 0;
    });
    _loadQuestion();
  }

  void _nextLevel() {
    setState(() {
      _lives = 3 - (MultiplayerService().mode != 'solo' ? (MultiplayerService().wrongAnswers[MultiplayerService().currentPlayer.name] ?? 0) : 0);
    });
    _loadQuestion();
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
        gameType: 'card_king',
        difficulty: _difficulty,
        durationSeconds: elapsed,
        onPlayAgain: () {
          service.setupMultiplayer(
            selectedPlayers: service.players,
            selectedMode: service.mode,
            h2hRounds: service.h2hTargetRounds,
          );
          setState(() {
            _lives = 3;
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
            _isWon = false;
            _isGameOver = false;
            _feedbackMsg = '';
            _searchController.clear();
            _suggestions = [];
          });
          _loadQuestion();
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
                "Kart raporları inceleniyor...",
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
        gameKey: "card_king",
        gameTitle: "KART CEZASI CANAVARI",
        gameDescription: "Zirve kariyeri boyunca en çok sarı ve kırmızı kart görmüş hırçın oyuncuları ipuçlarına bakarak tahmin edin.",
        difficulties: const ["easy", "medium", "hard", "veteran"],
        initialDifficulty: _difficulty,
        isDbRequired: true,
        isDbLoaded: _isDbLoaded,
        onBackToMenu: widget.onBackToMenu,
        onStart: (diff, mode) {
          setState(() {
            _difficulty = diff;
            _lives = 3;
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

    final int yellow = _questionData!['yellow'] as int;
    final int red = _questionData!['red'] as int;
    final String club = _questionData!['club_name'] as String;

    return Scaffold(
      backgroundColor: NeobrutalistColors.yellow,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
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
                            : "🔥 SKOR: $_streak",
                        style: NeobrutalistStyles.headlineStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (isMulti) const TurnIndicator(),
                const SizedBox(height: 8),

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
                            i < _lives ? "❤️" : "🖤",
                            style: const TextStyle(fontSize: 12),
                          )),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                if (_isGameOver)
                  StateCard(
                    emoji: "💀",
                    title: isMulti ? "TUR TAMAMLANDI" : "OYUN BİTTİ",
                    msg: isMulti 
                        ? "${service.currentPlayer.name} için oyun bitti. Toplam Puan: ${service.scores[service.currentPlayer.name] ?? 0}" 
                        : _feedbackMsg,
                    btnText: isMulti ? "DEVAM ET" : "YENİDEN BAŞLA",
                    btnColor: NeobrutalistColors.yellow,
                    onBtnPressed: isMulti ? _handleMultiplayerTransition : _restartGame,
                    additionalWidget: AnswerRevealCard(
                      label: 'CEVAP',
                      playerName: _questionData!['player_name'] as String,
                      imageUrl: _questionData!['image_url'] as String?,
                      facts: ['🟨 ${_questionData!['yellow']}', '🟥 ${_questionData!['red']}', _questionData!['club_name']?.toString() ?? ''],
                      color: NeobrutalistColors.pink,
                    ),
                  )
                else if (_isWon)
                  StateCard(
                    emoji: "🎉",
                    title: "TEBRİKLER!",
                    msg: _feedbackMsg,
                    btnText: "SONRAKİ ADIM",
                    btnColor: NeobrutalistColors.green,
                    onBtnPressed: _handleNextStep,
                    additionalWidget: AnswerRevealCard(
                      playerName: _questionData!['player_name'] as String,
                      imageUrl: _questionData!['image_url'] as String?,
                      facts: ['🟨 ${_questionData!['yellow']}', '🟥 ${_questionData!['red']}', _questionData!['club_name']?.toString() ?? ''],
                      color: NeobrutalistColors.green,
                    ),
                  )
                else ...[
                  NeobrutalistCard(
                    padding: const EdgeInsets.all(20),
                    backgroundColor: NeobrutalistColors.white,
                    child: Column(
                      children: [
                        const Text("🟥🟨", style: TextStyle(fontSize: 40)),
                        const SizedBox(height: 12),
                        Text(
                          "HAKEMLERİN KORKULU RÜYASI!",
                          style: NeobrutalistStyles.headlineStyle(fontSize: 12, color: NeobrutalistColors.pink),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Bu oyuncu kariyeri boyunca toplam:",
                          style: NeobrutalistStyles.bodyStyle(fontSize: 9),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: NeobrutalistColors.yellow,
                                border: Border.all(color: Colors.black, width: 1.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text("$yellow SARI KART", style: NeobrutalistStyles.headlineStyle(fontSize: 9, color: Colors.black)),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: NeobrutalistColors.pink,
                                border: Border.all(color: Colors.black, width: 1.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text("$red KIRMIZI KART", style: NeobrutalistStyles.headlineStyle(fontSize: 9, color: Colors.white)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "En çok maça çıktığı kulüp: $club",
                          style: NeobrutalistStyles.headlineStyle(fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  NeobrutalistCard(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: NeobrutalistColors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_feedbackMsg.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: NeobrutalistColors.white,
                              border: NeobrutalistStyles.border(width: 2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _feedbackMsg,
                              textAlign: TextAlign.center,
                              style: NeobrutalistStyles.headlineStyle(fontSize: 10),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        NeobrutalistAutocompleteField(
                          controller: _searchController,
                          hintText: "Oyuncu adını yazın...",
                          enabled: !_isProcessing,
                          playerSuggestions: _suggestions,
                          onSuggestionSelected: (name) {
                            setState(() {
                              _searchController.text = name;
                              _suggestions = [];
                            });
                          },
                          onChanged: _onSearchChanged,
                        ),
                        const SizedBox(height: 12),
                        NeobrutalistButton(
                          onPressed: () => _submitGuess(_searchController.text),
                          disabled: _isProcessing,
                          backgroundColor: NeobrutalistColors.blue,
                          shadowColor: NeobrutalistColors.black,
                          child: Text(
                            "TAHMİN ET",
                            style: NeobrutalistStyles.headlineStyle(fontSize: 12, color: NeobrutalistColors.white),
                          ),
                        ),
                      ],
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
