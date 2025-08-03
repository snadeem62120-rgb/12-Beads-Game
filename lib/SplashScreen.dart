import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async'; // Import for Timer

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Start a timer to navigate to the menu screen after 3 seconds
    Timer(Duration(seconds: 5), () {
      // Navigate to menu screen
      Navigator.pushReplacementNamed(context, '/menu');
    });

    return Scaffold(
      backgroundColor: Color(0xFFE6D5B8), // Beige background color
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // SPLASH SCREEN Section
            Container(
              color: Color(0xFFE6D5B8), // Same color as background
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'SPLASH SCREEN',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black, // Text color black to match your other screens
                    ),
                  ),
                  SizedBox(height: 10), // Space between text and divider
                  Divider(
                    color: Colors.black, // Divider color black to match your other screens
                    thickness: 2, // Divider thickness
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            // Game Logo
            Image.asset('assets/images/splash.png', height: 400,width: 400,), // Game logo
            // Removed the "12 BEADS GAME" text and any other elements below the image
          ],
        ),
      ),
    );
  }
}