// lib/player_info_screen.dart
import 'package:final_proj/db_helper.dart';
import 'package:final_proj/game_board_screen.dart';
import 'package:flutter/material.dart';
import 'dart:math'; // Random functionality ke liye import karein

class PlayerInfoScreen extends StatefulWidget {
  const PlayerInfoScreen({super.key});

  @override
  _PlayerInfoScreenState createState() => _PlayerInfoScreenState();
}

class _PlayerInfoScreenState extends State<PlayerInfoScreen> {
  final TextEditingController _player1Controller = TextEditingController();
  final TextEditingController _player2Controller = TextEditingController();

  @override
  void dispose() {
    _player1Controller.dispose();
    _player2Controller.dispose();
    super.dispose();
  }

  Future<void> _handleStart() async {
    String p1 = _player1Controller.text.trim();
    String p2 = _player2Controller.text.trim();

    if (p1.isNotEmpty && p2.isNotEmpty) {
      await DBHelper().insertPlayersByName(p1, p2);

      // Show success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Players added successfully')),
      );

      // --- Randomly determine who starts (0 for Player 1, 1 for Player 2) ---
      final Random random = Random();
      final int startingPlayerIndex = random.nextInt(2); // Generates 0 or 1

      // Navigate after short delay
      Future.delayed(const Duration(milliseconds: 300), () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GameBoardScreen(
              player1: p1,
              player2: p2,
              startingPlayerIndex: startingPlayerIndex, // Random index pass kiya
            ),
          ),
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both player names')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6D5B8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'PLAYER DETAIL',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B4F35),
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField(_player1Controller, 'PLAYER 1'),
            const SizedBox(height: 20),
            _buildTextField(_player2Controller, 'PLAYER 2'),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _handleStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5F1E9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                fixedSize: const Size(150, 50),
              ),
              child: const Text('START'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF6B4F35)),
        filled: true,
        fillColor: const Color(0xFFF5F1E9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}