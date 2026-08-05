class Clue {
  final String type;
  final String value;

  Clue({required this.type, required this.value});
}

class PlayerQuestion {
  final String difficulty;
  final String player1;
  final String player2;
  final List<String> answers;
  final List<Clue> clues;

  PlayerQuestion({
    required this.difficulty,
    required this.player1,
    required this.player2,
    required this.answers,
    required this.clues,
  });
}

class TeamQuestion {
  final String difficulty;
  final String team1;
  final String team1Key;
  final String team2;
  final String team2Key;
  final List<String> answers;
  final List<Clue> clues;

  TeamQuestion({
    required this.difficulty,
    required this.team1,
    required this.team1Key,
    required this.team2,
    required this.team2Key,
    required this.answers,
    required this.clues,
  });
}
