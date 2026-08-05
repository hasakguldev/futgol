import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_session.dart';

class StatisticsService {
  static final StatisticsService _instance = StatisticsService._internal();
  factory StatisticsService() => _instance;
  StatisticsService._internal();

  static const String _keySessions = 'game_sessions_json_list';

  Future<List<GameSession>> getSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keySessions);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final list = jsonDecode(jsonStr) as List;
      return list.map((item) => GameSession.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveSession(GameSession session) async {
    final sessions = await getSessions();
    sessions.add(session);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySessions, jsonEncode(sessions.map((s) => s.toJson()).toList()));
  }

  Future<void> clearStatistics() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySessions);
  }

  // Genel İstatistikler
  Future<Map<String, dynamic>> getGlobalStats() async {
    final sessions = await getSessions();
    if (sessions.isEmpty) {
      return {
        'total_games': 0,
        'accuracy': 0.0,
        'best_streak': 0,
        'total_duration_minutes': 0,
      };
    }

    int totalCorrect = 0;
    int totalWrong = 0;
    int bestStreak = 0;
    int totalDuration = 0;

    for (var session in sessions) {
      totalDuration += session.durationSeconds;
      for (var result in session.results) {
        if (result.isProfileOwner) {
          totalCorrect += result.correctAnswers;
          totalWrong += result.wrongAnswers;
          if (result.bestStreak > bestStreak) {
            bestStreak = result.bestStreak;
          }
        }
      }
    }

    final totalAnswers = totalCorrect + totalWrong;
    final accuracy = totalAnswers > 0 ? (totalCorrect / totalAnswers) * 100 : 0.0;

    return {
      'total_games': sessions.length,
      'accuracy': accuracy,
      'best_streak': bestStreak,
      'total_duration_minutes': (totalDuration / 60).round(),
    };
  }

  // Oyun Bazlı İstatistikler
  Future<Map<String, dynamic>> getGameStats(String gameType) async {
    final sessions = (await getSessions()).where((s) => s.gameType == gameType).toList();
    if (sessions.isEmpty) {
      return {
        'played': 0,
        'accuracy': 0.0,
        'high_score': 0,
      };
    }

    int totalCorrect = 0;
    int totalWrong = 0;
    int highScore = 0;

    for (var session in sessions) {
      for (var result in session.results) {
        if (result.isProfileOwner) {
          totalCorrect += result.correctAnswers;
          totalWrong += result.wrongAnswers;
          if (result.score > highScore) {
            highScore = result.score;
          }
        }
      }
    }

    final totalAnswers = totalCorrect + totalWrong;
    final accuracy = totalAnswers > 0 ? (totalCorrect / totalAnswers) * 100 : 0.0;

    return {
      'played': sessions.length,
      'accuracy': accuracy,
      'high_score': highScore,
    };
  }

  // H2H (İki Kişilik) İstatistikler
  Future<Map<String, Map<String, int>>> getH2HStats() async {
    final sessions = (await getSessions()).where((s) => s.playerCount == 2).toList();
    final Map<String, Map<String, int>> stats = {};

    for (var session in sessions) {
      if (session.results.length < 2) continue;
      
      // Profil sahibi oyuncu sonucunu bul
      final ownerResult = session.results.firstWhere(
        (r) => r.isProfileOwner, 
        orElse: () => session.results.first
      );
      // Rakip oyuncu sonucunu bul
      final opponentResult = session.results.firstWhere(
        (r) => !r.isProfileOwner, 
        orElse: () => session.results.last
      );

      final opponentName = opponentResult.playerName;
      if (!stats.containsKey(opponentName)) {
        stats[opponentName] = {'wins': 0, 'losses': 0, 'draws': 0};
      }

      if (ownerResult.score > opponentResult.score) {
        stats[opponentName]!['wins'] = stats[opponentName]!['wins']! + 1;
      } else if (ownerResult.score < opponentResult.score) {
        stats[opponentName]!['losses'] = stats[opponentName]!['losses']! + 1;
      } else {
        stats[opponentName]!['draws'] = stats[opponentName]!['draws']! + 1;
      }
    }

    return stats;
  }
}
