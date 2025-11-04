// lib/computer_play.dart (or whatever you have named this file)

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
  // --- FIX APPLIED HERE ---
  // 1.  A 'currentFen' variable is now defined for this state.
  // 2.  It's initialized with the standard FEN string for the start of a chess game.
  //
  // This variable will hold the state of the chessboard.
  String currentFen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

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
                        // --- FIX APPLIED HERE ---
                        // Now 'currentFen' exists and can be passed to BlackPlayerScreen.
                        // We also remove 'const' because 'currentFen' is a variable, not a compile-time constant.
                        return BlackPlayerScreen(initialFen: currentFen);
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
