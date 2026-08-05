import '../models/player_info.dart';
import '../models/game_session.dart';

class MultiplayerService {
  static final MultiplayerService _instance = MultiplayerService._internal();
  factory MultiplayerService() => _instance;
  MultiplayerService._internal();

  List<PlayerInfo> players = [];
  int currentPlayerIndex = 0;
  String mode = 'solo'; // 'solo', 'turn_based', 'marathon', 'head_to_head'

  // Oyuncu İstatistikleri
  Map<String, int> scores = {};
  Map<String, int> correctAnswers = {};
  Map<String, int> wrongAnswers = {};
  Map<String, int> hintsUsed = {};
  Map<String, int> passesUsed = {};
  Map<String, int> currentStreaks = {};
  Map<String, int> bestStreaks = {};

  // H2H Mod Bilgileri
  int h2hTargetRounds = 5;
  int h2hCurrentRound = 1;
  Map<String, String> h2hAnswers = {};
  Map<String, Duration> h2hResponseTimes = {};

  void setupMultiplayer({
    required List<PlayerInfo> selectedPlayers,
    required String selectedMode,
    int h2hRounds = 5,
  }) {
    players = List.from(selectedPlayers);
    mode = selectedMode;
    currentPlayerIndex = 0;
    h2hTargetRounds = h2hRounds;
    h2hCurrentRound = 1;

    scores.clear();
    correctAnswers.clear();
    wrongAnswers.clear();
    hintsUsed.clear();
    passesUsed.clear();
    currentStreaks.clear();
    bestStreaks.clear();
    h2hAnswers.clear();
    h2hResponseTimes.clear();

    for (var player in players) {
      scores[player.name] = 0;
      correctAnswers[player.name] = 0;
      wrongAnswers[player.name] = 0;
      hintsUsed[player.name] = 0;
      passesUsed[player.name] = 0;
      currentStreaks[player.name] = 0;
      bestStreaks[player.name] = 0;
    }
  }

  PlayerInfo get currentPlayer => players[currentPlayerIndex];

  void nextPlayer() {
    if (players.isEmpty) return;
    currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
  }

  void recordCorrectAnswer(String playerName, {int basePoints = 100, int speedBonus = 0}) {
    correctAnswers[playerName] = (correctAnswers[playerName] ?? 0) + 1;
    currentStreaks[playerName] = (currentStreaks[playerName] ?? 0) + 1;

    final currentStreak = currentStreaks[playerName] ?? 0;
    final bestStreak = bestStreaks[playerName] ?? 0;
    if (currentStreak > bestStreak) {
      bestStreaks[playerName] = currentStreak;
    }

    final streakBonus = currentStreak >= 3 ? 50 : 0;
    final totalPoints = basePoints + speedBonus + streakBonus;

    scores[playerName] = (scores[playerName] ?? 0) + totalPoints;
  }

  void recordWrongAnswer(String playerName, {int pointsDeduction = 0}) {
    wrongAnswers[playerName] = (wrongAnswers[playerName] ?? 0) + 1;
    currentStreaks[playerName] = 0;
    scores[playerName] = (scores[playerName] ?? 0) - pointsDeduction;
  }

  void recordHintUsed(String playerName) {
    hintsUsed[playerName] = (hintsUsed[playerName] ?? 0) + 1;
    scores[playerName] = (scores[playerName] ?? 0) - 25;
  }

  void recordPassUsed(String playerName) {
    passesUsed[playerName] = (passesUsed[playerName] ?? 0) + 1;
    currentStreaks[playerName] = 0;
  }

  GameSession createGameSession({
    required String gameType,
    required String difficulty,
    required int durationSeconds,
  }) {
    final List<PlayerResult> results = [];
    for (var player in players) {
      results.add(PlayerResult(
        playerName: player.name,
        isProfileOwner: player.isProfileOwner,
        score: scores[player.name] ?? 0,
        correctAnswers: correctAnswers[player.name] ?? 0,
        wrongAnswers: wrongAnswers[player.name] ?? 0,
        hintsUsed: hintsUsed[player.name] ?? 0,
        passesUsed: passesUsed[player.name] ?? 0,
        bestStreak: bestStreaks[player.name] ?? 0,
      ));
    }

    return GameSession(
      gameType: gameType,
      difficulty: difficulty,
      playerCount: players.length,
      mode: mode,
      playedAt: DateTime.now(),
      durationSeconds: durationSeconds,
      results: results,
    );
  }
}
