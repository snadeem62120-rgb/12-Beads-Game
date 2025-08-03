import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ScoreScreen(),
    );
  }
}

class ScoreScreen extends StatelessWidget {
  // Example player data (aap ise Player Info se replace kar sakte hain)
  final List<Map<String, String>> players = [
    {'name': 'Ali', 'score': '9'},
    {'name': 'Ayesha', 'score': '7'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE6D5B8), // Background color
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(0), // AppBar ki height 0 kar di taake visible na ho
        child: AppBar(
          backgroundColor: Color(0xFFE6D5B8), // AppBar ka color background ke saath match kiya
          elevation: 0, // Shadow remove karne ke liye
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // SCORES Section
            Container(
              color: Color(0xFFE6D5B8), // Same color as background
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'SCORES',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black, // Text color black rakha hai
                    ),
                  ),
                  SizedBox(height: 10), // Text aur line ke beech thoda space
                  Divider(
                    color: Colors.black, // Divider color black rakha hai
                    thickness: 2, // Divider ki thickness
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            // Player Info Table
            Container(
              decoration: BoxDecoration(
                color: Color(0xFFE6D5B8), // Same color as background
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'NAME',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black, // Text color black rakha hai
                        ),
                      ),
                      Text(
                        'SCORE',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black, // Text color black rakha hai
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  SizedBox(height: 10),
                  // Display Player Names and Scores
                  for (var player in players)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            player['name']!, // Player name left side par
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            player['score']!, // Player score right side par
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 20),
            // Back Button
            Align(
              alignment: Alignment.bottomLeft,
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: Colors.black,
                  size: 30,
                ),
                onPressed: () {
                  Navigator.pop(context); // Go back to the previous screen
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}