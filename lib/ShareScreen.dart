// lib/screens/share_screen.dart

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:final_proj/db_helper.dart'; // DBHelper import karein

class ShareScreen extends StatelessWidget {
  final List<Map<String, dynamic>> savedGamesToShare;

  const ShareScreen({
    super.key,
    required this.savedGamesToShare,
  });

  // --- File sharing ka function ---
  Future<void> _shareGameData(BuildContext context, int gameId, String gameSummary) async {
    try {
      final dbHelper = DBHelper();
      // Comprehensive game data fetch karein (game details + moves)
      final String jsonContent = await dbHelper.getGameDataJsonForSharing(gameId);

      // Temporary directory mein file save karein
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/game_data_${gameId}.json';
      final file = File(filePath);

      await file.writeAsString(jsonContent);

      // Share sheet open karein
      await Share.shareXFiles([XFile(filePath)],
          text: 'Here is the full game data for: $gameSummary');
    } catch (e) {
      print('Error sharing game data: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share game data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6D5B8),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          backgroundColor: const Color(0xFFE6D5B8),
          elevation: 0,
          centerTitle: true,
          title: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'SHARING',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 5),
              Container(
                height: 2,
                color: Colors.black,
                margin: const EdgeInsets.symmetric(horizontal: 50),
              ),
            ],
          ),
          automaticallyImplyLeading: false,
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Game Name', // Changed from 'Game' for clarity
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: savedGamesToShare.isEmpty
                      ? const Center(
                    child: Text(
                      'No games available for sharing.',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  )
                      : ListView.builder(
                    itemCount: savedGamesToShare.length,
                    itemBuilder: (context, index) {
                      final game = savedGamesToShare[index];
                      // !!! Yahan change kiya gaya hai !!!
                      final String player1Name = game['player1_name'] ?? 'Player 1';
                      final String player2Name = game['opponent_name'] ?? 'Player 2';
                      final String gameSummary = '$player1Name vs $player2Name';

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              gameSummary, // Dynamically display the game summary
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                            IconButton(
                              icon: Image.asset(
                                "assets/images/logo_whats.png", // Corrected path/name if needed
                                width: 30,
                                height: 30,
                              ),
                              onPressed: () {
                                // Call share function with specific game data
                                _shareGameData(context, game['game_id'], gameSummary);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.black,
                size: 30,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}