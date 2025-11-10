import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ranking_entry.dart';
import '../audio_manager.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  late Future<List<RankingEntry>> _rankingFuture;

  @override
  void initState() {
    super.initState();
    _rankingFuture = _fetchRanking();
    AudioManager.instance.playMenuMusic();
  }

  Future<List<RankingEntry>> _fetchRanking() async {
    try {
      final List<dynamic> data =
          await Supabase.instance.client.rpc('get_top_scores');
      final entries = data
          .asMap()
          .entries
          .map((entry) => RankingEntry.fromMap(entry.value, entry.key + 1))
          .toList();
      return entries;
    } catch (e) {
      debugPrint('Error fetching ranking: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ranking'),
      ),
      body: FutureBuilder<List<RankingEntry>>(
        future: _rankingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay puntajes todavía.'));
          }

          final rankings = snapshot.data!;

          return ListView.builder(
            itemCount: rankings.length,
            itemBuilder: (context, index) {
              final entry = rankings[index];
              return ListTile(
                leading: Text(
                  '#${entry.rank}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                title: Text(entry.username),
                trailing: Text(
                  '${entry.score} pts',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

