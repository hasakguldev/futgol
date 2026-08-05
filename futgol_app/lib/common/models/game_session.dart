class GameSession {
  final int? id;
  final String gameType;         // 'career_path', 'stadium_quiz' vb.
  final String difficulty;       // 'easy', 'medium', 'hard', 'veteran'
  final int playerCount;         // 1, 2, 3, 4
  final String mode;             // 'solo', 'turn_based', 'marathon', 'head_to_head'
  final DateTime playedAt;       // Oynanma tarihi
  final int durationSeconds;     // Toplam süre
  final List<PlayerResult> results; // Her oyuncunun sonuçları

  GameSession({
    this.id,
    required this.gameType,
    required this.difficulty,
    required this.playerCount,
    required this.mode,
    required this.playedAt,
    required this.durationSeconds,
    required this.results,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'gameType': gameType,
    'difficulty': difficulty,
    'playerCount': playerCount,
    'mode': mode,
    'playedAt': playedAt.toIso8601String(),
    'durationSeconds': durationSeconds,
    'results': results.map((r) => r.toJson()).toList(),
  };

  factory GameSession.fromJson(Map<String, dynamic> json) {
    var rawResults = json['results'] as List?;
    return GameSession(
      id: json['id'] as int?,
      gameType: json['gameType'] as String,
      difficulty: json['difficulty'] as String,
      playerCount: json['playerCount'] as int,
      mode: json['mode'] as String,
      playedAt: DateTime.parse(json['playedAt'] as String),
      durationSeconds: json['durationSeconds'] as int,
      results: rawResults != null
          ? rawResults.map((r) => PlayerResult.fromJson(r as Map<String, dynamic>)).toList()
          : [],
    );
  }
}

class PlayerResult {
  final String playerName;       // Profil adı veya ek oyuncu adı
  final bool isProfileOwner;     // Telefon sahibinin profili mi?
  final int score;
  final int correctAnswers;
  final int wrongAnswers;
  final int hintsUsed;
  final int passesUsed;
  final int bestStreak;          // En uzun doğru serisi

  PlayerResult({
    required this.playerName,
    required this.isProfileOwner,
    required this.score,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.hintsUsed,
    required this.passesUsed,
    required this.bestStreak,
  });

  Map<String, dynamic> toJson() => {
    'playerName': playerName,
    'isProfileOwner': isProfileOwner,
    'score': score,
    'correctAnswers': correctAnswers,
    'wrongAnswers': wrongAnswers,
    'hintsUsed': hintsUsed,
    'passesUsed': passesUsed,
    'bestStreak': bestStreak,
  };

  factory PlayerResult.fromJson(Map<String, dynamic> json) => PlayerResult(
    playerName: json['playerName'] as String,
    isProfileOwner: json['isProfileOwner'] as bool? ?? false,
    score: json['score'] as int,
    correctAnswers: json['correctAnswers'] as int,
    wrongAnswers: json['wrongAnswers'] as int,
    hintsUsed: json['hintsUsed'] as int,
    passesUsed: json['passesUsed'] as int,
    bestStreak: json['bestStreak'] as int,
  );
}
