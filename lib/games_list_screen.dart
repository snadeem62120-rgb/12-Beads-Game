import 'package:flutter/material.dart';
import 'package:final_proj/db_helper.dart'; // Ensure correct path
import 'package:final_proj/moves_list_screen.dart'; // Import MovesListScreen

class GamesListScreen extends StatefulWidget {
  const GamesListScreen({super.key});

  @override
  State<GamesListScreen> createState() => _GamesListScreenState();
}

class _GamesListScreenState extends State<GamesListScreen> {
  List<Map<String, dynamic>> _games = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  Future<void> _loadGames() async {
    try {
      final games = await DBHelper().getGames();
      setState(() {
        _games = games;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading games: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Games Played'),
        backgroundColor: const Color(0xFF6B4F35),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _games.isEmpty
          ? const Center(child: Text('No games found.'))
          : ListView.builder(
        itemCount: _games.length,
        itemBuilder: (context, index) {
          final game = _games[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: CircleAvatar(child: Text('${game['game_id']}')),
              title: Text('${game['player_name']} (${game['player_bead_color']}) vs ${game['opponent_name']} (${game['opponent_bead_color']})'),
              subtitle: Text(
                'Winner: ${game['winner'] ?? 'In Progress / Draw'}\n' +
                    'Total Moves: ${game['total_moves']}\n' +
                    'Date: ${game['date']}',
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MovesListScreen(gameId: game['game_id']),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadGames,
        backgroundColor: const Color(0xFF6B4F35),
        foregroundColor: Colors.white,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}