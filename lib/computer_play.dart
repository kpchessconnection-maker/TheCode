// lib/computer_play.dart

import 'package:flutter/material.dart';
import 'black.dart';
import 'white.dart'; // Assuming 'white.dart' contains 'BodyPage'
import 'main.dart';   // Assuming 'main.dart' contains 'RootPage'

// It's good practice to avoid using Dart's core type names for your widgets.
// I've renamed 'Color' to 'ColorSelectionScreen' to prevent confusion.
class ColorSelectionScreen extends StatefulWidget {
  const ColorSelectionScreen({super.key});

  @override
  State<ColorSelectionScreen> createState() => _ColorSelectionScreenState();
}

class _ColorSelectionScreenState extends State<ColorSelectionScreen> {
  // This variable holds the state of the chessboard.
  String currentFen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

  // --- NEW: State variable for difficulty ---
  // We'll store the Stockfish "Skill Level" (0-20). Let's define our levels.
  // We will default to Medium.
  int _skillLevel = 10; // Easy: 1, Medium: 10, Hard: 20

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chessmasters'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacement( // Using pushReplacement is often better for "back" buttons
              MaterialPageRoute(
                builder: (BuildContext context) {
                  return const RootPage();
                },
              ),
            );
          },
        ),
      ),
      body: Center(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.brown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- NEW: Difficulty Selection Menu ---
              const Text(
                'Select Difficulty',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: DropdownButton<int>(
                  value: _skillLevel,
                  isExpanded: true,
                  underline: const SizedBox(), // Removes the default underline
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Easy')),
                    DropdownMenuItem(value: 10, child: Text('Medium')),
                    DropdownMenuItem(value: 20, child: Text('Hard')),
                  ],
                  onChanged: (int? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _skillLevel = newValue;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 50), // Increased spacing

              // --- Play as White Button ---
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shadowColor: Colors.greenAccent,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40.0)),
                  minimumSize: const Size(120, 80),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (BuildContext context) {
                        // Assuming BodyPage is for playing as White
                        // You might also want to pass the skill level here if BodyPage uses Stockfish
                        return const BodyPage();
                      },
                    ),
                  );
                },
                child: const Text(
                  'Play as White',
                  style: TextStyle(
                      fontSize: 17,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 40),

              // --- Play as Black Button ---
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shadowColor: Colors.greenAccent,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40.0)),
                  minimumSize: const Size(120, 80),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (BuildContext context) {
                        // --- MODIFIED: Pass the skill level to the BlackPlayerScreen ---
                        // We will need to update BlackPlayerScreen to accept this.
                        return BlackPlayerScreen(
                          initialFen: currentFen,
                           skillLevel: _skillLevel, // This line will be enabled in the next step
                        );
                      },
                    ),
                  );
                },
                child: const Text(
                  'Play as black ',
                  style: TextStyle(
                      fontSize: 17,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
