// lib/menu_screen.dart

import 'package:final_proj/GameHistoryScreen.dart';
import 'package:final_proj/PlayerInfoScreen.dart';
import 'package:final_proj/SavedGame.dart';
import 'package:flutter/material.dart';
import 'package:final_proj/scores_display_screen.dart';
import 'package:final_proj/saved_games_screen.dart'; // Corrected import
import 'package:final_proj/player_info_screen.dart';
import 'package:final_proj/game_history_screen.dart'; // Import GameHistoryScreen

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6D5B8),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'MENU SCREEN',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PlayerInfoScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5F1E9),
                  fixedSize: const Size(200, 50),
                ),
                child: const Text('NEW GAME'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    // 'const' hata diya gaya hai
                    MaterialPageRoute(builder: (context) => SavedGamesScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5F1E9),
                  fixedSize: const Size(200, 50),
                ),
                child: const Text('SAVED GAME'),
              ),
              const SizedBox(height: 20),
              // --- Yahan "GAME HISTORY" button add kiya gaya hai ---
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    // 'const' hata diya gaya hai
                    MaterialPageRoute(builder: (context) => GameHistoryScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5F1E9),
                  fixedSize: const Size(200, 50),
                ),
                child: const Text('GAME HISTORY'), // Button ka text
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ScoresDisplayScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5F1E9),
                  fixedSize: const Size(200, 50),
                ),
                child: const Text('SCORES'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5F1E9),
                  fixedSize: const Size(200, 50),
                ),
                child: const Text('EXIT'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}