// lib/black.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:stockfish/stockfish.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:chess/chess.dart' as chess_logic;

class BlackPlayerScreen extends StatefulWidget {
  final String initialFen;

  const BlackPlayerScreen({super.key, required this.initialFen});

  @override
  State<BlackPlayerScreen> createState() => _BlackPlayerScreenState();
}

class _BlackPlayerScreenState extends State<BlackPlayerScreen> {
  // 1. CONTROLLERS AND STATE VARIABLES
  late final Stockfish stockfish;
  StreamSubscription? _stockfishSubscription;
  final ChessBoardController _boardController = ChessBoardController();
  late chess_logic.Chess _game;
  bool _isEngineThinking = false;

  @override
  void initState() {
    super.initState();
    _game = chess_logic.Chess.fromFEN(widget.initialFen);
    _boardController.loadFen(_game.fen);
    stockfish = Stockfish();
    _stockfishSubscription = stockfish.stdout.listen(_handleEngineMessage);

    stockfish.state.addListener(() {
      if (stockfish.state.value == StockfishState.ready) {
        print("Stockfish engine is ready.");
        if (_game.turn == chess_logic.Color.BLACK) {
          _requestEngineMove();
        }
      }
    });
  }

  // 2. STOCKFISH COMMUNICATION
  void _handleEngineMessage(String message) {
    print("Engine says: $message");

    if (message.startsWith('bestmove')) {
      final parts = message.split(' ');
      if (parts.length >= 2) {
        final bestMove = parts[1];
        // This was the line causing Error #1, the method it calls is now re-added below
        _makeEngineMoveOnBoard(bestMove);
      }
    }
  }

  void _requestEngineMove() {
    if (_isEngineThinking || _game.game_over) return;
    setState(() {
      _isEngineThinking = true;
    });
    stockfish.stdin = 'position fen ${_game.fen}';
    stockfish.stdin = 'go movetime 1500';
  }

  // 3. GAME LOGIC AND UI INTERACTION

  // --- FIX FOR ERROR #1: This method was missing and has been re-added ---
  /// Called when Stockfish returns its best move.
  void _makeEngineMoveOnBoard(String bestMove) {
    // Use the chess logic to validate and apply the engine's move
    final moveResult = _game.move(bestMove);

    if (moveResult != null) {
      // The engine's move was legal, now update the visual board
      _boardController.makeMove(
        from: bestMove.substring(0, 2),
        to: bestMove.substring(2, 4),
      );
    }

    setState(() {
      _isEngineThinking = false;
    });

    // Check for game over conditions
    if (_game.in_checkmate) {
      _showGameOverDialog("Checkmate!");
    } else if (_game.in_draw) {
      _showGameOverDialog("Draw!");
    }
  }

  // --- FIX FOR ERROR #2: Logic updated for new package API ---
  /// Called when the player (White) makes a move on the board.
  void _onPlayerMove() {
    // A move was made on the UI.
    // The flutter_chess_board controller automatically handles move validation.
    // We just need to get the FEN of the new position from it.
    final newFen = _boardController.getFen();

    // Sync our local game instance with the new FEN from the board.
    // We compare FENs to see if a legal move was actually made.
    if (_game.fen != newFen) {
      _game.load(newFen);
      // A legal move was made, so now it's the engine's turn.
      _requestEngineMove();
    } else {
      // An illegal move was attempted and the board controller reverted it.
      print("Illegal move attempted.");
    }
  }

  @override
  void dispose() {
    _stockfishSubscription?.cancel();
    stockfish.dispose();
    _boardController.dispose();
    super.dispose();
  }

  // 4. WIDGET BUILD METHOD AND UI HELPERS
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Play against Stockfish'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: ChessBoard(
                controller: _boardController,
                boardColor: BoardColor.brown,
                boardOrientation: PlayerColor.white,
                onMove: () {
                  // This callback is correct, it takes no arguments
                  _onPlayerMove();
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Stockfish is thinking...",
                  style: TextStyle(fontSize: 18),
                ),
                if (_isEngineThinking)
                  const Padding(
                    padding: EdgeInsets.only(left: 10),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showGameOverDialog(String title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text('The game has ended.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Play Again'),
              onPressed: () {
                _game.reset();
                _boardController.loadFen(_game.fen);
                Navigator.of(context).pop();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }
}
