import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:chess/chess.dart' as chess;
import 'dart:math';

class BodyPage extends StatefulWidget {
  const BodyPage({super.key});
  @override
  State<BodyPage> createState() => _BodyPageState();
}

class _BodyPageState extends State<BodyPage> {
  ChessBoardController controller = ChessBoardController();
  chess.Chess game = chess.Chess();

  double alphaBeta(chess.Chess game, int depth, double alpha, double beta,
      bool maximizingPlayer) {
    if (depth == 0 || game.game_over) {
      return evaluateBoard(game);
    }

    var moves = game.moves();
    if (maximizingPlayer) {
      double maxEval = double.negativeInfinity;
      for (var move in moves) {
        game.move(move);
        double eval = alphaBeta(game, depth - 1, alpha, beta, false);
        game.undo();
        maxEval = max(maxEval, eval);
        alpha = max(alpha, eval);
        if (beta <= alpha) {
          break;
        }
      }
      return maxEval;
    } else {
      double minEval = double.infinity;
      for (var move in moves) {
        game.move(move);
        double eval = alphaBeta(game, depth - 1, alpha, beta, true);
        game.undo();
        minEval = min(minEval, eval);
        beta = min(beta, eval);
        if (beta <= alpha) {
          break;
        }
      }
      return minEval;
    }
  }

  List<String> sortMoves(List<String> moves) {
    moves.sort((a, b) {
      if (a.contains('x') && !b.contains('x')) {
        return -1;
      } else if (!a.contains('x') && b.contains('x')) {
        return 1;
      } else {
        return 0;
      }
    });
    return moves;
  }

  void makeBestMove() {
    // ignore: prefer_typing_uninitialized_variables
    var bestMove;
    var bestValue = double.negativeInfinity;
    var moves = game.moves();
    for (var move in moves) {
      game.move(move);
      var boardValue =
      alphaBeta(game, 2, double.negativeInfinity, double.infinity, false);
      game.undo();
      if (boardValue > bestValue) {
        bestValue = boardValue;
        bestMove = move;
      }
    }
    game.move(bestMove);
    controller.game = game;
    if (bestMove.length >= 4) {
      var from = bestMove.substring(0, 2);
      var to = bestMove.substring(2, 4);
      controller.makeMove(from: from, to: to);
    }
  }

  double evaluateBoard(chess.Chess game) {
    double score = 0.0;
    String board = game.fen.split(' ')[0];
    for (int i = 0; i < board.length; i++) {
      switch (board[i]) {
        case 'P':
          score -= 100;
          break;
        case 'p':
          score += 100;
          break;
        case 'N':
        case 'B':
          score -= 300;
          break;
        case 'n':
        case 'b':
          score += 300;
          break;
        case 'R':
          score -= 500;
          break;
        case 'r':
          score += 500;
          break;
        case 'Q':
          score -= 900;
          break;
        case 'q':
          score += 900;
          break;
      }
    }
    return score;
  }

  @override
  void initState() {
    super.initState();
    controller = ChessBoardController();
    controller.addListener(() {
      game = controller.game;
      if (controller.game.turn == chess.Color.BLACK) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              makeBestMove();
            });
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chessmasters'),
        centerTitle: true,
      ),
      backgroundColor: Colors.brown,
      body: Column(
        children: [
          const SizedBox(height: 30),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: ChessBoard(
                  controller: controller,
                  boardColor: BoardColor.brown,
                  boardOrientation: PlayerColor.white,
                ),
              ),
            ),
          ),
          ValueListenableBuilder<Chess>(
            valueListenable: controller,
            builder: (context, game, _) {
              if (game.turn == chess.Color.BLACK) {
                return const Text(
                  "Computer is thinking...",
                  style: TextStyle(fontSize: 20),
                );
              } else {
                return Container();
              }
            },
          ),
          Expanded(
            child: ValueListenableBuilder<Chess>(
              valueListenable: controller,
              builder: (context, game, _) {
                return Text(
                  controller.getSan().fold(
                    '',
                        (previousValue, element) =>
                    '$previousValue\n${element ?? ''}',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}