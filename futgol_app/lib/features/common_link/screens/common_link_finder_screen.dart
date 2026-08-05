import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:futgol_app/common/theme/neobrutalist_theme.dart';
import 'package:futgol_app/common/services/database_service.dart';
import 'package:futgol_app/common/services/difficulty_rules_service.dart';
import 'package:futgol_app/common/services/db_text_utils.dart';
import 'package:futgol_app/common/models/question_models.dart';
import 'package:futgol_app/common/models/football_player.dart';
import 'package:futgol_app/common/utils/audio_helper.dart';
import 'package:futgol_app/features/common_link/widgets/guess_game_widgets.dart';
import 'package:futgol_app/features/common_link/widgets/guess_card_widget.dart';
import 'package:futgol_app/features/common_link/widgets/clues_section_widget.dart';
import 'package:futgol_app/common/widgets/game_setup_view.dart';

import '../../../common/services/multiplayer_service.dart';
import '../../../common/widgets/multiplayer_handoff_screen.dart';
import '../../../common/widgets/multiplayer_score_board.dart';
import '../../../common/widgets/turn_indicator.dart';

class CommonLinkFinderScreen extends StatefulWidget {
  final VoidCallback onBackToMenu;

  const CommonLinkFinderScreen({super.key, required this.onBackToMenu});

  @override
  State<CommonLinkFinderScreen> createState() => _CommonLinkFinderScreenState();
}

class _CommonLinkFinderScreenState extends State<CommonLinkFinderScreen> {
  String _gameMode = 'player'; // 'player' veya 'team'
  int _lives = 3;
  int _passes = 3;
  int _streak = 0;
  int _cluesOpened = 0; 
  final TextEditingController _searchController = TextEditingController();
  List<FootballPlayer> _suggestions = [];
  bool _isWon = false;
  bool _isGameOver = false;
  String _feedbackMsg = '';
  bool _feedbackIsError = false;
  List<String> _commonClubsFound = [];

  /// Sorudaki iki futbolcunun veritabanı profili (fotoğraf, mevki, uyruk).
  FootballPlayer? _profile1;
  FootballPlayer? _profile2;
  int _searchToken = 0;
  
  bool _isDbLoaded = false;
  bool _showOnhold = true;

  // Yeni Zorluk ve Mod Yönetim Değişkenleri
  bool _gameStarted = false;
  String _difficulty = 'easy';
  dynamic _dynamicQuestion;
  bool _isLoadingQuestion = false;
  bool _isProcessing = false;
  String _currentLoadingText = '';

  // Çoklu Oyuncu Değişkenleri
  bool _showHandoff = false;
  bool _showScoreboard = false;
  String? _prevPlayerName;
  int? _prevPlayerScore;
  DateTime? _gameStartTime;

  @override
  void initState() {
    super.initState();
    _loadGameData();
  }

  Future<void> _loadGameData() async {
    final prefs = await SharedPreferences.getInstance();
    final bool onboardingShown = prefs.getBool('onboarding_shown_guess') ?? false;
    final status = await DatabaseService().checkDatabaseStatus();
    if (mounted) {
      setState(() {
        _isDbLoaded = status;
        _showOnhold = !onboardingShown;
      });
    }

    try {
      final rulesService = DifficultyRulesService();
      await rulesService.initialize();
      await rulesService.syncRules(DifficultyRulesService.remoteRulesUrl);
    } catch (e) {
      debugPrint("Kuralları GitHub'dan güncellerken hata (Lokal fallback aktif): $e");
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_shown_guess', true);
    setState(() {
      _showOnhold = false;
    });
  }

  dynamic _getCurrentQuestion() {
    return _dynamicQuestion;
  }

  Future<void> _generateNextDynamicQuestion() async {
    if (!_isDbLoaded) {
      setState(() {
        _feedbackMsg = 'Oyun için veritabanı indirilmiş olmalıdır.';
      });
      return;
    }

    final List<String> loadingTexts = [
      "⚽ Sahaya çıkılıyor...",
      "📋 Taktik tahtası hazırlanıyor...",
      "🌱 Çimler sulanıyor...",
      "👟 Kramponlar bağlanıyor...",
      "📣 Tribünler dolduruluyor...",
      "🏃‍♂️ Isınma hareketleri yapılıyor..."
    ];

    setState(() {
      _isLoadingQuestion = true;
      _currentLoadingText = loadingTexts[Random().nextInt(loadingTexts.length)];
      _feedbackMsg = '';
      _feedbackIsError = false;
      _commonClubsFound = [];
      _profile1 = null;
      _profile2 = null;
    });

    dynamic question;
    try {
      if (_gameMode == 'player') {
        question = await DatabaseService().generateDynamicPlayerQuestion(_difficulty);
      } else {
        question = await DatabaseService().generateDynamicTeamQuestion(_difficulty);
      }
    } catch (e) {
      debugPrint("Dinamik soru çekilemedi: $e");
    }

    // Oyuncu modunda sorunun iki futbolcusunun portresini/mevkisini de çek.
    FootballPlayer? p1;
    FootballPlayer? p2;
    if (question != null && _gameMode == 'player' && question is PlayerQuestion) {
      p1 = await DatabaseService().getPlayerByName(question.player1);
      p2 = await DatabaseService().getPlayerByName(question.player2);
    }

    if (!mounted) return;
    setState(() {
      _dynamicQuestion = question;
      _profile1 = p1;
      _profile2 = p2;
      _isLoadingQuestion = false;
      _cluesOpened = 0;
      _isWon = false;
      if (question != null) {
        _gameStarted = true;
      } else {
        // Sessizce "üretilemedi" demek yerine gerçek nedeni göster.
        final err = DatabaseService().lastError;
        _feedbackMsg = err == null
            ? '⚠️ Bu zorluk için uygun soru bulunamadı. Farklı bir zorluk deneyin.'
            : '⚠️ Veritabanı hatası: $err';
        _feedbackIsError = true;
        _gameStarted = false;
      }
    });
  }

  Future<void> _onSearchChanged(String query) async {
    final token = ++_searchToken;
    if (query.trim().length < 2) {
      setState(() => _suggestions = []);
      return;
    }
    if (!_isDbLoaded) {
      setState(() => _suggestions = []);
      return;
    }
    final results = await DatabaseService().searchPlayers(query);
    // Yarışan aramalarda eski sonucun yenisini ezmesini engelle.
    if (!mounted || token != _searchToken) return;
    setState(() => _suggestions = results);
  }

  void _openClue(int index) {
    if (_cluesOpened >= index) return;
    setState(() {
      _cluesOpened = index;
      _feedbackMsg = '🔓 İpucu başarıyla açıldı.';
    });
    AudioHelper().playCorrect();
  }

  Future<void> _submitGuess(String guess) async {
    if (guess.trim().isEmpty || _isProcessing) return;
    
    setState(() {
      _isProcessing = true;
      _suggestions = [];
      
      final List<String> checkTexts = [
        "🔍 VAR incelemesi yapılıyor...",
        "📊 İstatistik kitapları taranıyor...",
        "👨‍⚖️ Hakem kararı bekleniyor...",
        "🥅 Pozisyon tekrar izleniyor..."
      ];
      _feedbackMsg = checkTexts[Random().nextInt(checkTexts.length)];
    });

    _searchController.clear();

    final currentQ = _getCurrentQuestion();
    final answersList = currentQ.answers;

    // Aksan ve soyadı toleranslı eşleşme: "guler" → "Arda Güler" kabul edilir.
    final isStaticCorrect =
        answersList.any((a) => DbText.namesMatch(guess, a.toString()));
    bool isDbCorrect = false;
    List<String> commonClubs = [];

    try {
      if (_isDbLoaded) {
        if (_gameMode == 'player') {
          final q = currentQ as PlayerQuestion;
          isDbCorrect = await DatabaseService().checkPlayerClubsCommon(guess, q.player1, q.player2);
          if (isDbCorrect) {
            commonClubs = await DatabaseService().getCommonClubs(q.player1, q.player2);
          }
        } else {
          final q = currentQ as TeamQuestion;
          isDbCorrect = await DatabaseService().checkClubPlayerCommon(guess, q.team1, q.team2);
          if (isDbCorrect) {
            commonClubs = [q.team1, q.team2];
          }
        }
      }
    } catch (e) {
      debugPrint("Tahmin doğrulama hatası: $e");
    }

    final service = MultiplayerService();
    final isMulti = service.mode != 'solo';
    final currentPlayerName = service.currentPlayer.name;

    if (mounted) {
      setState(() {
        _isProcessing = false;

        if (isStaticCorrect || isDbCorrect) {
          _isWon = true;
          _feedbackIsError = false;
          if (isMulti) {
            service.recordCorrectAnswer(currentPlayerName, basePoints: 100);
          } else {
            _streak++;
          }
          _commonClubsFound = commonClubs.isNotEmpty ? commonClubs : ['Eşleşme Doğrulandı'];
          _feedbackMsg = '🎉 DOĞRU CEVAP: ${guess.trim()}';
          AudioHelper().playSuccess();
        } else {
          AudioHelper().playWrong();
          _feedbackIsError = true;
          if (isMulti) {
            service.recordWrongAnswer(currentPlayerName);
          }

          if (_lives <= 1) {
            _isGameOver = true;
            _streak = 0;
            _feedbackMsg = '💀 Canınız bitti! Doğru cevaplardan biri: '
                '${answersList.isNotEmpty ? answersList[0] : "Bilinmiyor"}';
          } else {
            _lives--;
            _feedbackMsg = '❌ "${guess.trim()}" doğru değil. Kalan can: $_lives';
          }
        }
      });
    }
  }

  void _usePass() {
    if (_passes <= 0 || _isGameOver || _isWon) return;
    AudioHelper().playSuccess();
    setState(() {
      _passes--;
      _isWon = false;
      _cluesOpened = 0;
      _feedbackMsg = 'Soruyu pas geçtiniz!';
      _commonClubsFound = [];
    });
    _generateNextDynamicQuestion();
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
        _passes = 3;
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

  void _nextLevel() {
    setState(() {
      _isWon = false;
      _cluesOpened = 0;
      _feedbackMsg = '';
      _commonClubsFound = [];
      _lives = 3 - (MultiplayerService().mode != 'solo' ? (MultiplayerService().wrongAnswers[MultiplayerService().currentPlayer.name] ?? 0) : 0);
    });
    _generateNextDynamicQuestion();
  }

  void _restartGame() {
    setState(() {
      _lives = 3;
      _passes = 3;
      _streak = 0;
      _isGameOver = false;
      _isWon = false;
      _cluesOpened = 0;
      _feedbackMsg = '';
      _commonClubsFound = [];
    });
    _generateNextDynamicQuestion();
  }

  @override
  Widget build(BuildContext context) {
    final service = MultiplayerService();
    final isMulti = service.mode != 'solo';

    if (_showOnhold) {
      return GameOnboardingCard(onStart: _completeOnboarding);
    }

    if (_showScoreboard) {
      final elapsed = _gameStartTime != null 
          ? DateTime.now().difference(_gameStartTime!).inSeconds 
          : 0;
      return MultiplayerScoreBoard(
        gameType: 'common_link',
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
            _passes = 3;
            _streak = 0;
            _showHandoff = false;
            _showScoreboard = false;
            _prevPlayerName = null;
            _prevPlayerScore = null;
            _gameStartTime = DateTime.now();
          });
          _generateNextDynamicQuestion();
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
          _generateNextDynamicQuestion();
        },
      );
    }

    if (_isLoadingQuestion) {
      return Scaffold(
        backgroundColor: NeobrutalistColors.yellow,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(NeobrutalistColors.black),
                strokeWidth: 4,
              ),
              const SizedBox(height: 16),
              Text(
                _currentLoadingText.isNotEmpty ? _currentLoadingText : "Soru Hazırlanıyor...",
                style: const TextStyle(
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
        gameKey: "common_link",
        gameTitle: "ORTAK BAĞ BULUCU OYUNU",
        gameDescription: "İki oyuncu arasındaki ortak takım arkadaşlarını veya iki kulüp arasındaki ortak oyuncuları tahmin etmeye çalışın.",
        modes: const {
          "player": "TAKIM ARKADAŞI",
          "team": "AYNI KULÜP",
        },
        difficulties: const ["easy", "medium", "hard", "veteran"],
        initialDifficulty: _difficulty,
        initialMode: _gameMode,
        isDbRequired: true,
        isDbLoaded: _isDbLoaded,
        onBackToMenu: widget.onBackToMenu,
        onStart: (diff, mode) {
          setState(() {
            _difficulty = diff;
            _gameMode = mode;
            _lives = 3;
            _passes = 3;
            _streak = 0;
            _showHandoff = false;
            _showScoreboard = false;
            _prevPlayerName = null;
            _prevPlayerScore = null;
            _gameStartTime = DateTime.now();
          });
          _generateNextDynamicQuestion();
        },
      );
    }

    final currentQ = _getCurrentQuestion();
    final bool isPlayerMode = _gameMode == 'player';

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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                    if (!isMulti)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: NeobrutalistColors.black,
                          borderRadius: BorderRadius.circular(30),
                          border: NeobrutalistStyles.border(width: 2),
                        ),
                        child: Text(
                          "SERİ: 🔥 $_streak",
                          style: NeobrutalistStyles.headlineStyle(fontSize: 11, color: NeobrutalistColors.yellow),
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
                  )
                else if (_isWon)
                  StateCard(
                    emoji: "🎉",
                    title: "TEBRİKLER!",
                    msg: _feedbackMsg,
                    btnText: "SONRAKİ ADIM",
                    btnColor: NeobrutalistColors.green,
                    onBtnPressed: _handleNextStep,
                    additionalWidget: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        border: NeobrutalistStyles.border(width: 2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text("Ortak Bağlar", style: NeobrutalistStyles.headlineStyle(fontSize: 9, color: Colors.grey[600]!)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            alignment: WrapAlignment.center,
                            children: _commonClubsFound.map((c) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: NeobrutalistColors.green,
                                border: Border.all(color: Colors.black, width: 1.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(c, style: NeobrutalistStyles.headlineStyle(fontSize: 10, color: NeobrutalistColors.white)),
                            )).toList(),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  CluesSectionWidget(
                    clues: currentQ.clues,
                    cluesOpened: _cluesOpened,
                    onOpenClue: _openClue,
                  ),
                  const SizedBox(height: 20),
                  GuessCardWidget(
                    isPlayerMode: isPlayerMode,
                    item1: isPlayerMode ? currentQ.player1 : currentQ.team1,
                    item2: isPlayerMode ? currentQ.player2 : currentQ.team2,
                    profile1: _profile1,
                    profile2: _profile2,
                    feedbackMsg: _feedbackMsg,
                    feedbackIsError: _feedbackIsError,
                    searchController: _searchController,
                    isProcessing: _isProcessing,
                    suggestions: _suggestions,
                    onSearchChanged: _onSearchChanged,
                    onSuggestionSelected: (name) {
                      setState(() {
                        _searchController.text = name;
                        _suggestions = [];
                      });
                    },
                    onSubmitGuess: _submitGuess,
                    passes: isMulti ? 0 : _passes, // Çoklu oyuncuda pas desteğini kapatıyoruz
                    onPass: _usePass,
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
