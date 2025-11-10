class RankingEntry {
  final String username;
  final int score;
  final int rank;

  RankingEntry({
    required this.username,
    required this.score,
    required this.rank,
  });

  factory RankingEntry.fromMap(Map<String, dynamic> map, int rank) {
    return RankingEntry(
      username: map['username'] as String,
      score: map['max_score'] as int,
      rank: rank,
    );
  }
}
