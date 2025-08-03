import 'package:flutter/material.dart';
import 'package:final_proj/db_helper.dart'; // Ensure correct path

class MovesListScreen extends StatefulWidget {
  final int gameId;
  const MovesListScreen({super.key, required this.gameId});

  @override
  State<MovesListScreen> createState() => _MovesListScreenState();
}

class _MovesListScreenState extends State<MovesListScreen> {
  List<Map<String, dynamic>> _moves = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMoves();
  }

  Future<void> _loadMoves() async {
    try {
      final moves = await DBHelper().getMovesForGame(widget.gameId);
      setState(() {
        _moves = moves;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading moves: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Moves for Game ID: ${widget.gameId}'),
        backgroundColor: const Color(0xFF6B4F35),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _moves.isEmpty
          ? const Center(child: Text('No moves found for this game.'))
          : ListView.builder(
        itemCount: _moves.length,
        itemBuilder: (context, index) {
          final move = _moves[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF6B4F35),
                foregroundColor: Colors.white,
                child: Text('${move['move_number']}'),
              ),
              title: Text('Bead: ${move['bead_color']} - From (${move['from_x']},${move['from_y']}) to (${move['to_x']},${move['to_y']})'),
              subtitle: Text(
                'Capture: ${move['capture'] == 1 ? 'Yes' : 'No'} | ' +
                    'Undo: ${move['undo_flag'] == 1 ? 'Yes' : 'No'} | ' +
                    'Redo: ${move['redo_flag'] == 1 ? 'Yes' : 'No'} | ' +
                    'Time: ${move['timestamp'] ?? 'N/A'}',
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadMoves,
        backgroundColor: const Color(0xFF6B4F35),
        foregroundColor: Colors.white,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}