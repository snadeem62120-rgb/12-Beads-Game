// lib/game_history_screen.dart

import 'package:flutter/material.dart';
import 'package:final_proj/db_helper.dart'; // DBHelper ko import karein

class GameHistoryScreen extends StatefulWidget {
  const GameHistoryScreen({super.key});

  @override
  State<GameHistoryScreen> createState() => _GameHistoryScreenState();
}

class _GameHistoryScreenState extends State<GameHistoryScreen> {
  List<Map<String, dynamic>> _completedGames = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCompletedGames(); // Completed games load karein
  }

  Future<void> _loadCompletedGames() async {
    setState(() {
      _isLoading = true;
    });
    final dbHelper = DBHelper();
    // Sirf complete ki hui games fetch karein (jinka winner NULL nahi hai)
    final games = await dbHelper.getCompletedGames(); // <--- Important: yahan getCompletedGames() use karein

    _completedGames = games;

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6D5B8), // Aapki theme ka color
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Transparent for custom title layout
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              color: const Color(0xFFE6D5B8),
              padding: const EdgeInsets.all(16),
              child: const Column(
                children: [
                  Text(
                    'GAME HISTORY', // Screen title
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 10),
                  Divider(
                    color: Colors.black,
                    thickness: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Table Headers (Game, Winner, Score, Date)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Game',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Winner',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Score',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE6D5B8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.brown))
                    : _completedGames.isEmpty
                    ? const Center(
                  child: Text(
                    'No completed games found.',
                    style: TextStyle(fontSize: 18, color: Colors.black54),
                  ),
                )
                    : ListView.builder(
                  itemCount: _completedGames.length,
                  itemBuilder: (context, index) {
                    final game = _completedGames[index];
                    final String gameSummary =
                        '${game['player1_name']} vs ${game['opponent_name']}';
                    final String winnerName = game['winner'] ?? 'N/A'; // Agar winner NULL ho toh N/A
                    final String score = (game['player1_final_score'] != null && game['player2_final_score'] != null)
                        ? '${game['player1_final_score']} - ${game['player2_final_score']}'
                        : 'N/A'; // Score display karein

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  gameSummary,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  winnerName,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  score,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: Colors.black),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on DBHelper {
  getCompletedGames() {}
}