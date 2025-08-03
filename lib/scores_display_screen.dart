// lib/scores_display_screen.dart

import 'package:flutter/material.dart';
import 'package:final_proj/db_helper.dart'; // DBHelper import karein

class ScoresDisplayScreen extends StatefulWidget {
  const ScoresDisplayScreen({super.key});

  @override
  State<ScoresDisplayScreen> createState() => _ScoresDisplayScreenState();
}

class _ScoresDisplayScreenState extends State<ScoresDisplayScreen> {
  late Future<List<Map<String, dynamic>>> _completedGamesFuture;
  late DBHelper _dbHelper;

  @override
  void initState() {
    super.initState();
    _dbHelper = DBHelper();
    _loadCompletedGames(); // Completed games load karein
  }

  // Completed games ko database se load karne ke liye function
  void _loadCompletedGames() {
    setState(() {
      _completedGamesFuture = _dbHelper.getCompletedGames();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6D5B8), // Aapke theme ke mutabik background color
      appBar: AppBar(
        // title: const Text( // <--- Yeh line comment/remove kar dein
        //   'SCORES',
        //   style: TextStyle(
        //     color: Color(0xFF6B4F35),
        //     fontWeight: FontWeight.bold,
        //   ),
        // ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF6B4F35)), // Back button icon color
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _completedGamesFuture, // Completed games ka future
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No completed games to show scores.',
                style: TextStyle(fontSize: 18, color: Color(0xFF6B4F35)),
                textAlign: TextAlign.center,
              ),
            );
          } else {
            final List<Map<String, dynamic>> completedGames = snapshot.data!;

            return Column(
              children: [
                // --- SCORES Header (mid wala) ---
                // Yeh wala 'SCORES' text screen ke center mein show hoga
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                  child: const Column(
                    children: [
                      Text(
                        'SCORES', // <--- Yeh wala 'SCORES' show hoga
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6B4F35), // Dark brown color
                        ),
                      ),
                      SizedBox(height: 10),
                      Divider(
                        color: Color(0xFF6B4F35), // Dark brown divider
                        thickness: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10), // Space between header and table headers

                // --- Table Headers (Player 1, Player 2, Score) ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      const Expanded(
                        flex: 2,
                        child: Text(
                          'Player 1',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF6B4F35),
                          ),
                        ),
                      ),
                      const Expanded(
                        flex: 2,
                        child: Text(
                          'Player 2',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF6B4F35),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Score',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color(0xFF6B4F35),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFF6B4F35)), // Divider below headers
                const SizedBox(height: 5), // Small space after headers

                // --- List of Scores ---
                Expanded(
                  child: ListView.builder(
                    itemCount: completedGames.length,
                    itemBuilder: (context, index) {
                      final game = completedGames[index];
                      final String player1Name = game['player1_name'] ?? 'N/A';
                      final String player2Name = game['opponent_name'] ?? 'N/A';
                      final int player1Score = game['player1_final_score'] ?? 0;
                      final int player2Score = game['player2_final_score'] ?? 0;

                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    player1Name,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    player2Name,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      '$player1Score - $player2Score', // Score format
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: Colors.black26), // Divider between rows
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}