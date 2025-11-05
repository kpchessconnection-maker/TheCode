// lib/black.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:stockfish/stockfish.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:chess/chess.dart' as chess_logic;

// --- MODIFICATION #1: Add skillLevel to the widget ---
class BlackPlayerScreen extends StatefulWidget {
  final String initialFen;
  final int skillLevel; // The new parameter for difficulty

  // Update the constructor to accept skillLevel
  const BlackPlayerScreen({
    super.key,
    required this.initialFen,
    required this.skillLevel,
  });

  @override
  State<BlackPlayerScreen> createState() => _BlackPlayerScreenState();
}

class _BlackPlayerScreenState extends State<BlackPlayerScreen> {
  late final Stockfish stockfish;
  StreamSubscription? _stockfishSubscription;
  final ChessBoardController _boardController = ChessBoardController();
  late chess_logic.Chess _game;
  bool _isEngineThinking = false;
  bool _isDialogShowing = false;

  @override
  void initState() {
    super.initState();
    _game = chess_logic.Chess.fromFEN(widget.initialFen);
    _boardController.loadFen(_game.fen);
    stockfish = Stockfish();
    _stockfishSubscription = stockfish.stdout.listen(_handleEngineMessage);

    // --- MODIFICATION #2: Set the skill level *after* the engine is ready ---
    stockfish.state.addListener(() {
      // This block runs when the engine's state changes.
      if (stockfish.state.value == StockfishState.ready) {
        print("Stockfish engine is ready.");

        // THIS IS THE FIX: Set the skill level option *only when the engine is ready*.
        stockfish.stdin = 'setoption name Skill Level value ${widget.skillLevel}';
        print("Stockfish skill level set to: ${widget.skillLevel}");

        // After setting the skill, if it's black's turn, ask for a move.
        if (_game.turn == chess_logic.Color.BLACK && !_game.game_over) {
          _requestEngineMove();
        }
      }
    });
  }

  void _handleEngineMessage(String message) {
    if (message.startsWith('bestmove')) {
      final parts = message.split(' ');
      if (parts.length >= 2) {
        final bestMove = parts[1];
        _makeEngineMoveOnBoard(bestMove);
      }
    }
  }

  void _requestEngineMove() {
    if (_game.game_over) return;
    stockfish.stdin = 'position fen ${_game.fen}';
    stockfish.stdin = 'go movetime 1500'; // You can also adjust movetime for difficulty
  }

  void _processMove(void Function() moveFunction) {
    if (_game.game_over) return;
    final bool wasGameOver = _game.game_over;
    setState(moveFunction);
    final bool isGameOver = _game.game_over;
    if (!wasGameOver && isGameOver) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showGameOverDialog();
      });
    }
  }

  void _makeEngineMoveOnBoard(String bestMove) {
    _processMove(() {
      _game.move(bestMove);
      _boardController.makeMove(
        from: bestMove.substring(0, 2),
        to: bestMove.substring(2, 4),
      );
      _isEngineThinking = false;
    });
  }

  void _onPlayerMove() {
    final newFen = _boardController.getFen();
    if (_game.fen != newFen) {
      _processMove(() {
        _game.load(newFen);
        if (!_game.game_over) {
          _isEngineThinking = true;
          _requestEngineMove();
        }
      });
    }
  }

  @override
  void dispose() {
    _stockfishSubscription?.cancel();
    stockfish.dispose();
    _boardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Play against Stockfish')),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: ChessBoard(
                controller: _boardController,
                boardColor: BoardColor.brown,
                boardOrientation: PlayerColor.white,
                onMove: _onPlayerMove,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildStatusText(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusText() {
    if (_game.game_over) {
      return const Text("Game Over",
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.redAccent));
    }
    if (_isEngineThinking) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Text("Stockfish is thinking...", style: TextStyle(fontSize: 18)),
          Padding(
            padding: EdgeInsets.only(left: 10),
            child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 3)),
          ),
        ],
      );
    }
    return const Text("Your turn",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
  }

  void _showGameOverDialog() {
    if (_isDialogShowing) return;
    _isDialogShowing = true;
    String title;
    String content;
    if (_game.in_checkmate) {
      title = "Checkmate!";
      final winner = _game.turn == chess_logic.Color.WHITE
          ? "Black (Stockfish)"
          : "White (You)";
      content = "$winner wins!";
    } else {
      title = "Draw!";
      content = "The game has ended in a draw.";
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('Play Again'),
              onPressed: () {
                _isDialogShowing = false;
                Navigator.of(context).pop();
                setState(() {
                  _game.reset();
                  _boardController.loadFen(_game.fen);
                  _isEngineThinking = false;
                });
              },
            ),
          ],
        );
      },
    ).then((_) {
      _isDialogShowing = false;
    });
  }
}

