import 'package:flutter/material.dart';
import 'package:futgol_app/common/theme/neobrutalist_theme.dart';
import 'package:futgol_app/common/services/database_service.dart';
import 'package:futgol_app/common/widgets/game_setup_view.dart';
import 'package:futgol_app/common/utils/audio_helper.dart';
import 'package:futgol_app/features/common_link/widgets/guess_game_widgets.dart';

import '../../../common/services/multiplayer_service.dart';
import '../../../common/widgets/multiplayer_handoff_screen.dart';
import '../../../common/widgets/multiplayer_score_board.dart';
import '../../../common/widgets/split_screen_wrapper.dart';
import '../../../common/widgets/countdown_overlay.dart';
import '../../../common/widgets/turn_indicator.dart';

class StadiumCapacityScreen extends StatefulWidget {
  final VoidCallback onBackToMenu;

  const StadiumCapacityScreen({super.key, required this.onBackToMenu});

  @override
  State<StadiumCapacityScreen> createState() => _StadiumCapacityScreenState();
}

class _StadiumCapacityScreenState extends State<StadiumCapacityScreen> {
  final DatabaseService _dbService = DatabaseService();

  bool _isDbLoaded = false;
  bool _gameStarted = false;
  bool _isLoadingQuestion = false;
  bool _hasGuessed = false;
  bool _isCorrect = false;

  String _difficulty = 'easy';
  int _streak = 0;
  int _highScore = 0;

  Map<String, dynamic>? _questionData;
  String _feedbackMsg = '';
  String _selectedOption = '';

  // Çoklu Oyuncu Değişkenleri
  bool _showHandoff = false;
  bool _showScoreboard = false;
  String? _prevPlayerName;
  int? _prevPlayerScore;
  DateTime? _gameStartTime;

  // H2H Modu Değişkenleri
  bool _showH2HCountdown = false;
  bool _h2hRoundFinished = false;
  String? _h2hRoundWinner;
  String? _player1Choice;
  String? _player2Choice;

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
      _hasGuessed = false;
      _selectedOption = '';
      _feedbackMsg = '';
      _h2hRoundFinished = false;
      _h2hRoundWinner = null;
      _player1Choice = null;
      _player2Choice = null;
    });

    // Rastgele seçim bazı zorluk/veri kombinasyonlarında boş dönebiliyor;
    // kullanıcıyı 'yüklenemedi' ile baş başa bırakmak yerine birkaç kez deniyoruz.
    var data = await _dbService.getRandomStadiumQuiz(_difficulty);
    for (int attempt = 0; data == null && attempt < 3; attempt++) {
      data = await _dbService.getRandomStadiumQuiz(_difficulty);
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
    });
  }

  void _submitGuess(String option) {
    if (_questionData == null || _hasGuessed) return;

    final String correctAnswer = _questionData!['correct_answer'] as String;
    final bool correct = option == correctAnswer;

    final service = MultiplayerService();
    final isMulti = service.mode != 'solo';
    final currentPlayerName = service.currentPlayer.name;

    setState(() {
      _selectedOption = option;
      _hasGuessed = true;
      _isCorrect = correct;
      if (correct) {
        AudioHelper().playSuccess();
        if (isMulti) {
          service.recordCorrectAnswer(currentPlayerName, basePoints: 100);
        } else {
          _streak++;
          if (_streak > _highScore) {
            _highScore = _streak;
          }
        }
        _feedbackMsg = "DOĞRU! ${_questionData!['stadium_name']} stadyumu $correctAnswer kulübünün stadıdır.";
      } else {
        AudioHelper().playWrong();
        if (isMulti) {
          service.recordWrongAnswer(currentPlayerName);
        } else {
          _streak = 0;
        }
        _feedbackMsg = "YANLIŞ! Doğru cevap: $correctAnswer";
      }
    });

    if (isMulti && service.mode == 'marathon' && !correct) {
      final currentWrong = service.wrongAnswers[currentPlayerName] ?? 0;
      if (currentWrong >= 3) {
        _handleMultiplayerTransition();
      }
    }
  }

  void _submitH2HGuess(String playerName, String option, String opponentName) {
    if (_h2hRoundFinished || _questionData == null) return;

    final String correctAnswer = _questionData!['correct_answer'] as String;
    final bool correct = option == correctAnswer;

    final service = MultiplayerService();

    setState(() {
      _h2hRoundFinished = true;
      if (playerName == service.players[0].name) {
        _player1Choice = option;
      } else {
        _player2Choice = option;
      }

      if (correct) {
        AudioHelper().playSuccess();
        _h2hRoundWinner = playerName;
        service.recordCorrectAnswer(playerName, basePoints: 1);
      } else {
        AudioHelper().playWrong();
        _h2hRoundWinner = opponentName;
        service.recordCorrectAnswer(opponentName, basePoints: 1);
      }
    });
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
      _loadQuestion();
      return;
    }

    if (service.mode == 'marathon') {
      if (_isCorrect) {
        _loadQuestion();
      }
    } else if (service.mode == 'turn_based') {
      _handleMultiplayerTransition();
    }
  }

  void _restartGame() {
    setState(() {
      _streak = 0;
    });
    _loadQuestion();
  }

  @override
  Widget build(BuildContext context) {
    final service = MultiplayerService();
    final isMulti = service.mode != 'solo';
    final isH2H = service.mode == 'head_to_head';

    if (_showScoreboard) {
      final elapsed = _gameStartTime != null 
          ? DateTime.now().difference(_gameStartTime!).inSeconds 
          : 0;
      return MultiplayerScoreBoard(
        gameType: 'stadium_capacity',
        difficulty: _difficulty,
        durationSeconds: elapsed,
        onPlayAgain: () {
          service.setupMultiplayer(
            selectedPlayers: service.players,
            selectedMode: service.mode,
            h2hRounds: service.h2hTargetRounds,
          );
          setState(() {
            _streak = 0;
            _showHandoff = false;
            _showScoreboard = false;
            _prevPlayerName = null;
            _prevPlayerScore = null;
            _gameStartTime = DateTime.now();
          });
          if (isH2H) {
            setState(() {
              _showH2HCountdown = true;
            });
          }
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
            _hasGuessed = false;
            _feedbackMsg = '';
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
                "Stadyum koltukları sayılıyor...",
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
        gameKey: "stadium_capacity",
        gameTitle: "STADYUM ATLASI",
        gameDescription: "İsmi ve koltuk kapasitesi verilen stadyumun hangi kulübe ait olduğunu 4 seçenek arasından bulun.",
        difficulties: const ["easy", "medium", "hard", "veteran"],
        initialDifficulty: _difficulty,
        isDbRequired: true,
        supportsH2H: true,
        isDbLoaded: _isDbLoaded,
        onBackToMenu: widget.onBackToMenu,
        onStart: (diff, mode) {
          service.setupMultiplayer(
            selectedPlayers: service.players,
            selectedMode: mode,
            h2hRounds: service.h2hTargetRounds,
          );
          setState(() {
            _difficulty = diff;
            _streak = 0;
            _showHandoff = false;
            _showScoreboard = false;
            _prevPlayerName = null;
            _prevPlayerScore = null;
            _gameStartTime = DateTime.now();
          });
          if (mode == 'head_to_head') {
            setState(() {
              _showH2HCountdown = true;
            });
          }
          _loadQuestion();
        },
      );
    }

    final String stadiumName = _questionData!['stadium_name'] as String;
    final int seats = _questionData!['seats'] as int;
    final List<dynamic> options = _questionData!['options'] as List<dynamic>;
    final String correctAnswer = _questionData!['correct_answer'] as String;

    if (isH2H) {
      final p1 = service.players[0].name;
      final p2 = service.players[1].name;
      final p1Score = service.scores[p1] ?? 0;
      final p2Score = service.scores[p2] ?? 0;

      Widget buildH2HHalf(String playerName, String opponentName, String? myChoice, String? oppChoice) {
        return Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "🏟️ $stadiumName",
                style: NeobrutalistStyles.headlineStyle(fontSize: 10),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                "Kapasite: ${seats.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}",
                style: NeobrutalistStyles.bodyStyle(fontSize: 7.5, color: Colors.grey[600]!),
              ),
              const SizedBox(height: 10),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                childAspectRatio: 2.2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                children: options.map((opt) {
                  final optStr = opt.toString();
                  Color btnBg = NeobrutalistColors.white;
                  Color textCol = Colors.black;

                  if (_h2hRoundFinished) {
                    if (optStr == correctAnswer) {
                      btnBg = NeobrutalistColors.green;
                      textCol = Colors.white;
                    } else if (optStr == myChoice) {
                      btnBg = NeobrutalistColors.pink;
                      textCol = Colors.white;
                    } else if (optStr == oppChoice) {
                      btnBg = NeobrutalistColors.pink.withValues(alpha: 0.5);
                      textCol = Colors.white;
                    }
                  }

                  return NeobrutalistButton(
                    onPressed: _h2hRoundFinished 
                        ? () {} 
                        : () => _submitH2HGuess(playerName, optStr, opponentName),
                    backgroundColor: btnBg,
                    shadowColor: NeobrutalistColors.black,
                    child: Text(
                      optStr,
                      style: NeobrutalistStyles.headlineStyle(fontSize: 7.5, color: textCol),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      }

      return Stack(
        children: [
          SplitScreenWrapper(
            topChild: buildH2HHalf(p1, p2, _player1Choice, _player2Choice),
            bottomChild: buildH2HHalf(p2, p1, _player2Choice, _player1Choice),
            centerChild: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: NeobrutalistColors.black,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "$p1: $p1Score",
                    style: NeobrutalistStyles.headlineStyle(fontSize: 9, color: NeobrutalistColors.white),
                  ),
                  _h2hRoundFinished
                      ? NeobrutalistButton(
                          onPressed: () {
                            service.h2hCurrentRound++;
                            if (service.h2hCurrentRound > service.h2hTargetRounds) {
                              setState(() {
                                _showScoreboard = true;
                              });
                            } else {
                              setState(() {
                                _showH2HCountdown = true;
                              });
                              _loadQuestion();
                            }
                          },
                          backgroundColor: NeobrutalistColors.yellow,
                          shadowColor: NeobrutalistColors.white,
                          child: Text(
                            "${_h2hRoundWinner != null ? '$_h2hRoundWinner Kazandı! ' : ''}DEVAM ET ➡️",
                            style: NeobrutalistStyles.headlineStyle(fontSize: 8, color: NeobrutalistColors.black),
                          ),
                        )
                      : Text(
                          "RAUND ${service.h2hCurrentRound} / ${service.h2hTargetRounds}",
                          style: NeobrutalistStyles.headlineStyle(fontSize: 9, color: NeobrutalistColors.yellow),
                        ),
                  Text(
                    "$p2: $p2Score",
                    style: NeobrutalistStyles.headlineStyle(fontSize: 9, color: NeobrutalistColors.white),
                  ),
                ],
              ),
            ),
          ),
          if (_showH2HCountdown)
            CountdownOverlay(
              onFinished: () {
                setState(() {
                  _showH2HCountdown = false;
                });
              },
            ),
        ],
      );
    }

    final int currentWrong = service.wrongAnswers[service.currentPlayer.name] ?? 0;
    final int displayLives = 3 - currentWrong;
    final bool isGameOver = isMulti ? (currentWrong >= 3) : (_hasGuessed && !_isCorrect);

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

                if (isGameOver)
                  StateCard(
                    emoji: "💀",
                    title: isMulti ? "TUR TAMAMLANDI" : "OYUN BİTTİ",
                    msg: isMulti 
                        ? "${service.currentPlayer.name} için oyun bitti. Toplam Puan: ${service.scores[service.currentPlayer.name] ?? 0}" 
                        : "Yanlış Cevap! Doğru cevap: $correctAnswer",
                    btnText: isMulti ? "DEVAM ET" : "YENİDEN BAŞLA",
                    btnColor: NeobrutalistColors.yellow,
                    onBtnPressed: isMulti ? _handleMultiplayerTransition : _restartGame,
                  )
                else ...[
                  NeobrutalistCard(
                    padding: const EdgeInsets.all(20),
                    backgroundColor: NeobrutalistColors.white,
                    child: Column(
                      children: [
                        const Text("🏟️", style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 8),
                        Text(
                          stadiumName,
                          style: NeobrutalistStyles.headlineStyle(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Kapasite: ${seats.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} koltuk",
                          style: NeobrutalistStyles.bodyStyle(fontSize: 9, color: Colors.grey[600]!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Column(
                    children: options.map((opt) {
                      final String optionStr = opt.toString();
                      Color btnBg = NeobrutalistColors.white;
                      Color textCol = Colors.black;

                      if (_hasGuessed) {
                        if (optionStr == correctAnswer) {
                          btnBg = NeobrutalistColors.green;
                          textCol = Colors.white;
                        } else if (optionStr == _selectedOption) {
                          btnBg = NeobrutalistColors.pink;
                          textCol = Colors.white;
                        }
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        width: double.infinity,
                        child: NeobrutalistButton(
                          onPressed: _hasGuessed ? () {} : () => _submitGuess(optionStr),
                          backgroundColor: btnBg,
                          shadowColor: NeobrutalistColors.black,
                          child: Text(
                            optionStr,
                            style: NeobrutalistStyles.headlineStyle(
                              fontSize: 10,
                              color: textCol,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  if (_hasGuessed) ...[
                    const SizedBox(height: 16),
                    NeobrutalistCard(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: NeobrutalistColors.white,
                      child: Column(
                        children: [
                          Text(
                            _isCorrect ? "TEBRİKLER! 🎉" : "YANLIŞ CEVAP! 😢",
                            style: NeobrutalistStyles.headlineStyle(fontSize: 12, color: _isCorrect ? Colors.green : Colors.red),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _feedbackMsg,
                            style: NeobrutalistStyles.bodyStyle(fontSize: 9),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          NeobrutalistButton(
                            onPressed: _handleNextStep,
                            backgroundColor: NeobrutalistColors.blue,
                            shadowColor: NeobrutalistColors.black,
                            child: Text(
                              "SONRAKİ ADIM",
                              style: NeobrutalistStyles.headlineStyle(fontSize: 11, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
