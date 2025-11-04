
// black.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:stockfish/stockfish.dart';

// You will also need a chess logic library to validate moves and manage the board state.
// The 'chess' package is a popular choice. Add it to your pubspec.yaml.
// Example: import 'package:chess/chess.dart' as chess;

class BlackPlayerScreen extends StatefulWidget {
  // You might pass the initial board state (FEN string) to this screen.
  final String initialFen;

  const BlackPlayerScreen({Key? key, required this.initialFen}) : super(key: key);

  @override
  _BlackPlayerScreenState createState() => _BlackPlayerScreenState();
}

class _BlackPlayerScreenState extends State<BlackPlayerScreen> {
  late final Stockfish stockfish;
  StreamSubscription? _stockfishSubscription;
  String _engineMove = '';
  String _currentFen = '';
  bool _isEngineThinking = false;

  @override
  void initState() {
    super.initState();
    _currentFen = widget.initialFen;

    // 1. Create an instance of the Stockfish engine.
    stockfish = Stockfish();

    // 2. Listen for output from the engine.
    _stockfishSubscription = stockfish.stdout.listen((message) {
      print("Engine says: $message"); // For debugging

      // Check if the message contains the best move.
      if (message.startsWith('bestmove')) {
        // The message format is "bestmove e2e4 ponder e7e5"
        final parts = message.split(' ');
        if (parts.length >= 2) {
          final bestMove = parts[1];

          setState(() {
            _engineMove = bestMove;
            _isEngineThinking = false;
          });

          // Here, you would update your game state with the engine's move.
          // For example, update the board UI and then wait for the user's next move.
          _updateBoardWithEngineMove(bestMove);
        }
      }
    });

    // It's good practice to wait for the engine to be ready.
    stockfish.state.addListener(() {
      if (stockfish.state.value == StockfishState.ready) {
        // Engine is ready, we can start interacting with it.
        // For example, if it's black's turn to move immediately.
        _requestEngineMove();
      }
    });
  }

  // 3. Create a function to ask the engine for a move.
  void _requestEngineMove() {
    if (_isEngineThinking) return;

    setState(() {
      _isEngineThinking = true;
      _engineMove = ''; // Clear previous move
    });

    // Send the current board position to the engine.
    // Replace _currentFen with the actual FEN string of your game.
    stockfish.stdin = 'position fen $_currentFen';

    // Ask the engine to think for 2 seconds (2000 milliseconds) and find the best move.
    stockfish.stdin = 'go movetime 2000';
  }

  // 4. A placeholder function to update your game state
  void _updateBoardWithEngineMove(String move) {
    // This is where you would integrate with your chess logic library.
    // For example, using the 'chess' package:
    /*
    final game = chess.Chess.fromFEN(_currentFen);
    game.move(move);
    setState(() {
      _currentFen = game.fen;
      // Also update your visual chessboard here.
    });
    */
    print("Board updated with move: $move. New FEN: $_currentFen");
  }


  @override
  void dispose() {
    // 5. IMPORTANT: Clean up resources.
    _stockfishSubscription?.cancel(); // Stop listening to the stream.
    stockfish.dispose(); // Shut down the engine process.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Black Player (Stockfish)'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Current FEN:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SelectableText(_currentFen),
            ),
            const SizedBox(height: 20),
            if (_isEngineThinking)
              const CircularProgressIndicator()
            else
              Text(
                _engineMove.isEmpty ? 'Waiting for move...' : 'Engine chose: $_engineMove',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            const SizedBox(height: 30),
            ElevatedButton(
              // You can use a button to manually trigger the engine's move.
              // In a real game, you would call this automatically when it's black's turn.
              onPressed: _isEngineThinking ? null : _requestEngineMove,
              child: const Text("Get Black's Move"),
            ),
          ],
        ),
      ),
    );
  }
}
