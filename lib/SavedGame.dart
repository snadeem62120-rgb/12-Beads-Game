// lib/saved_games_screen.dart

import 'package:flutter/material.dart';
import 'package:final_proj/db_helper.dart'; // Make sure this path is correct
import 'package:final_proj/game_board_screen.dart'; // To resume the game
import 'package:final_proj/ShareScreen.dart'; // ShareScreen ke liye import karein

class SavedGamesScreen extends StatefulWidget {
  const SavedGamesScreen({super.key});

  @override
  State<SavedGamesScreen> createState() => _SavedGamesScreenState();
}

class _SavedGamesScreenState extends State<SavedGamesScreen> {
  late Future<List<Map<String, dynamic>>> _incompleteGamesFuture;
  late DBHelper _dbHelper;

  @override
  void initState() {
    super.initState();
    _dbHelper = DBHelper();
    _loadIncompleteGames(); // Games load karein
  }

  // Games ko database se load karne ke liye function
  void _loadIncompleteGames() {
    setState(() {
      _incompleteGamesFuture = _dbHelper.getIncompleteGames();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6D5B8), // Aapke theme ke mutabik background color
      appBar: AppBar(
        // title: const Text( // <--- Yeh line comment/remove kar dein
        //   'Saved Games', // Pehle yahan tha
        //   style: TextStyle(
        //     color: Color(0xFF6B4F35),
        //     fontWeight: FontWeight.bold,
        //   ),
        // ),
        backgroundColor: Colors.transparent, // Transparent AppBar
        elevation: 0, // No shadow
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF6B4F35)), // Back button icon color
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _incompleteGamesFuture, // FutureBuilder ko use karein
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator()); // Data load ho raha hai
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}')); // Error hone par
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No saved games found. Start a new game to save!',
                style: TextStyle(fontSize: 18, color: Color(0xFF6B4F35)),
                textAlign: TextAlign.center,
              ),
            ); // Agar koi saved game nahi hai toh
          } else {
            // Jab data aa jaye toh list display karein
            final List<Map<String, dynamic>> games = snapshot.data!;
            return Stack( // Share button ke liye Stack ka istemal karein
              children: [
                Column( // Column to hold header and the list of games
                  children: [
                    // --- SAVED GAMES Header (mid wala) ---
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                      child: const Column(
                        children: [
                          Text(
                            'SAVED GAMES', // <--- Yeh wala 'SAVED GAMES' show hoga
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

                    // --- Table Headers (ID, Game Name, Status) ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          const Expanded(
                            flex: 1,
                            child: Text(
                              'ID',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Color(0xFF6B4F35),
                              ),
                            ),
                          ),
                          const Expanded(
                            flex: 3,
                            child: Text(
                              'Game Name',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Color(0xFF6B4F35),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'Status',
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

                    // --- List of Games (without Cards) ---
                    Expanded(
                      child: ListView.builder(
                        itemCount: games.length,
                        itemBuilder: (context, index) {
                          final game = games[index];
                          final String player1Name = game['player1_name'] ?? 'Unknown Player';
                          final String player2Name = game['opponent_name'] ?? 'Unknown Opponent';
                          final int gameId = game['game_id'];

                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        (index + 1).toString(), // Displaying serial number as ID
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.black, // Dark text for data
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '$player1Name vs $player2Name', // Game Name
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            // Resume game functionality
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => GameBoardScreen(
                                                  player1: player1Name,
                                                  player2: player2Name,
                                                  gameToResumeId: gameId,
                                                ),
                                              ),
                                            ).then((_) {
                                              // Jab GameBoardScreen se wapas aayein, toh list ko refresh karein
                                              _loadIncompleteGames();
                                            });
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue, // Button background color
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            minimumSize: Size.zero, // Remove default minimum size
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Shrink tap area
                                          ),
                                          child: const Text('Continue'), // Button text
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
                ),
                // Global Share button (bottom-right)
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: FloatingActionButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ShareScreen(
                            savedGamesToShare: games, // `games` variable mein loaded data hai
                          ),
                        ),
                      );
                    },
                    backgroundColor: Colors.green, // Share button ka color
                    child: const Icon(Icons.share, color: Colors.white), // Share icon
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