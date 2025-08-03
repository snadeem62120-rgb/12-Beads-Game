import 'package:final_proj/MenuScreen.dart';
import 'package:final_proj/PlayerInfoScreen.dart';
import 'package:final_proj/SavedGame.dart';
import 'package:final_proj/SplashScreen.dart';
import 'package:flutter/material.dart'; // Cupertino.dart ki zaroorat nahi agar sirf material widgets use ho rahe hain

// Apni screens files ko import karein
import 'package:final_proj/menu_screen.dart'; // Updated MenuScreen
import 'package:final_proj/player_info_screen.dart'; // Assuming this exists for player input
import 'package:final_proj/splash_screen.dart'; // Your SplashScreen
import 'package:final_proj/scores_display_screen.dart'; // Your updated ScoresDisplayScreen
import 'package:final_proj/saved_game_screen.dart'; // Your updated SavedGameScreen
import 'package:final_proj/game_board_screen.dart'; // Your updated GameBoardScreen

// Agar aapke paas database_screen.dart hai, toh usko bhi import karein
// import 'package:final_proj/database_screen.dart'; // Example if you have a DB viewer screen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '12 Beads Game',
      theme: ThemeData(
        primarySwatch: Colors.brown, // Changed to brown for consistency with your app
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(), // Added const
        '/menu': (context) => const MenuScreen(), // Added const
        '/playerInfo': (context) => const PlayerInfoScreen(), // Added const (assuming it's a StatelessWidget)
        // Note: Scores and SavedGame are now pushed directly from MenuScreen,
        // so named routes for them might not be strictly necessary if only MenuScreen uses them this way.
        // But keeping them for completeness if other parts of app use them.
        '/scores': (context) => const ScoresDisplayScreen(), // <--- Corrected to ScoresDisplayScreen
        '/gameBoard': (context) => const GameBoardScreen(player1: 'Player 1', player2: 'Player 2'), // <--- GameBoardScreen needs player names. This is a placeholder.
        '/gameHistory': (context) => const SavedGamesScreen(), // <--- Corrected to SavedGameScreen
        // '/db': (context) => const DatabaseScreen(), // Uncomment if you have this screen
      },
    );
  }
}