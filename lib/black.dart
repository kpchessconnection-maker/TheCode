// lib/black.dart

// Imports the 'dart:async' library, which provides tools for asynchronous programming like Streams.
import 'dart:async';

// Imports Flutter's core material design library for building UI components.
import 'package:flutter/material.dart';

// Imports the stockfish package, which allows communication with the Stockfish chess engine.
import 'package:stockfish/stockfish.dart';

// Imports the flutter_chess_board package, which provides the visual chessboard widget.
import 'package:flutter_chess_board/flutter_chess_board.dart';

// Imports the chess package for handling game logic, move validation, and FEN strings.
// 'as chess_logic' creates a prefix to avoid naming conflicts.
import 'package:chess/chess.dart' as chess_logic;

// Defines a StatefulWidget, which is a widget that can have mutable state.
class BlackPlayerScreen extends StatefulWidget {
  // A final variable to hold the initial board position (FEN string) passed to this screen.
  final String initialFen;

  // The constructor for this widget.
  // 'super.key' passes the key to the parent StatefulWidget.
  // 'required this.initialFen' means that 'initialFen' must be provided when creating this widget.
  const BlackPlayerScreen({super.key, required this.initialFen});

  // Creates the mutable state for this widget. Flutter calls this method to build the state object.
  @override
  State<BlackPlayerScreen> createState() => _BlackPlayerScreenState();
}

// The State class for BlackPlayerScreen. All the logic and mutable data lives here.
class _BlackPlayerScreenState extends State<BlackPlayerScreen> {
  // Declares a 'late final' variable for the Stockfish engine instance.
  // 'late' means it will be initialized before it's used. 'final' means it will be assigned only once.
  late final Stockfish stockfish;

  // A nullable StreamSubscription to manage the stream of messages from the Stockfish engine.
  StreamSubscription? _stockfishSubscription;

  // A final variable for the controller that manages the visual state of the flutter_chess_board widget.
  final ChessBoardController _boardController = ChessBoardController();

  // Declares a 'late' variable for the chess game logic object from the 'chess' package.
  late chess_logic.Chess _game;

  // A boolean flag to track whether the Stockfish engine is currently thinking.
  bool _isEngineThinking = false;

  // This method is called once when the widget is first inserted into the widget tree.
  @override
  void initState() {
    // Calls the initState method of the parent class (State).
    super.initState();
    // Initializes the logical game state (_game) by parsing the FEN string passed from the previous screen.
    _game = chess_logic.Chess.fromFEN(widget.initialFen);
    // Loads the same FEN string into the visual chessboard controller so the UI matches the logic.
    _boardController.loadFen(_game.fen);
    // Creates a new instance of the Stockfish engine.
    stockfish = Stockfish();
    // Subscribes to the standard output stream of the Stockfish engine to listen for messages.
    // '_handleEngineMessage' will be called for every message from the engine.
    _stockfishSubscription = stockfish.stdout.listen(_handleEngineMessage);

    // Adds a listener to the Stockfish engine's state property.
    stockfish.state.addListener(() {
      // Checks if the engine has become ready to receive commands.
      if (stockfish.state.value == StockfishState.ready) {
        // Prints a confirmation message to the debug console.
        print("Stockfish engine is ready.");
        // If it's Black's turn to play at the start of the game...
        if (_game.turn == chess_logic.Color.BLACK) {
          // ...tell the engine to start thinking about a move.
          _requestEngineMove();
        }
      }
    });
  }

  // A method to process messages received from the Stockfish engine.
  void _handleEngineMessage(String message) {
    // Prints the raw engine message for debugging purposes.
    print("Engine says: $message");

    // Checks if the message is the engine's final move decision.
    if (message.startsWith('bestmove')) {
      // Splits the message string by spaces to isolate the move part (e.g., "bestmove e7e5").
      final parts = message.split(' ');
      // Ensures the message is well-formed and contains a move.
      if (parts.length >= 2) {
        // Extracts the move itself (e.g., "e7e5").
        final bestMove = parts[1];
        // Calls the method to apply the engine's move to the board.
        _makeEngineMoveOnBoard(bestMove);
      }
    }
  }

  // A method to ask the Stockfish engine to calculate a move.
  void _requestEngineMove() {
    // If the engine is already thinking or the game is over, do nothing.
    if (_isEngineThinking || _game.game_over) return;
    // Calls setState to rebuild the UI, showing the "thinking" indicator.
    setState(() {
      // Sets the thinking flag to true.
      _isEngineThinking = true;
    });
    // Sends the current board position (FEN) to the engine.
    stockfish.stdin = 'position fen ${_game.fen}';
    // Asks the engine to think for a maximum of 1500 milliseconds (1.5 seconds).
    stockfish.stdin = 'go movetime 1500';
  }

  // A method that applies the engine's calculated move to the game.
  void _makeEngineMoveOnBoard(String bestMove) {
    // Applies the move to our internal, logical game state.
    final moveResult = _game.move(bestMove);

    // Checks if the move was legal (moveResult is not null if legal).
    if (moveResult != null) {
      // If the move was legal, animate it on the visual chessboard.
      _boardController.makeMove(
        // The starting square of the move (e.g., "e7").
        from: bestMove.substring(0, 2),
        // The ending square of the move (e.g., "e5").
        to: bestMove.substring(2, 4),
      );
    }

    // Calls setState to rebuild the UI, hiding the "thinking" indicator.
    setState(() {
      // Sets the thinking flag to false.
      _isEngineThinking = false;
    });
    final newFen = _boardController.getFen();

    // Compares the new FEN with the old FEN to see if a legal move was made.
    // If the move was illegal, the board controller reverts it, and the FENs will be the same.
    if (_game.fen != newFen) {
      // If a legal move was made, update our logical game state with the new position.
      _game.load(newFen);
    }
    // After the move, check if the game has ended.
    if (_game.in_checkmate) {
      // If it's checkmate, show the game over dialog.
      _showGameOverDialog("Checkmate!");
    } else if (_game.in_draw) {
      // If it's a draw, show the game over dialog.
      _showGameOverDialog("DRAW");
    }
  }

  // A method called when the human player makes a move on the UI.
  void _onPlayerMove() {
    // Gets the new FEN string from the visual board controller after the player's move.
    final newFen = _boardController.getFen();

    // Compares the new FEN with the old FEN to see if a legal move was made.
    // If the move was illegal, the board controller reverts it, and the FENs will be the same.
    if (_game.fen != newFen) {
      // If a legal move was made, update our logical game state with the new position.
      _game.load(newFen);
      // Now that the player has moved, it's the engine's turn.
      _requestEngineMove();
    } else {
      // If the FENs are the same, the move was illegal.
      print("Illegal move attempted.");
    }
  }

  // This method is called when the widget is permanently removed from the widget tree.
  @override
  void dispose() {
    // Cancels the subscription to the engine's output stream to prevent memory leaks.
    _stockfishSubscription?.cancel();
    // Shuts down the Stockfish engine process.
    stockfish.dispose();
    // Disposes the chessboard controller to release its resources.
    _boardController.dispose();
    // Calls the dispose method of the parent class.
    super.dispose();
  }

  // This method builds the widget's UI. It is called by Flutter whenever the UI needs to be updated.
  @override
  Widget build(BuildContext context) {
    // Returns a Scaffold, which provides a standard app screen layout.
    return Scaffold(
      // The top app bar of the screen.
      appBar: AppBar(
        // The title displayed in the app bar.
        title: const Text('Play against Stockfish'),
      ),
      // The main content of the screen.
      body: Column(
        // Arranges children vertically.
        children: [
          // Expanded makes its child (the chessboard) take up all available vertical space.
          Expanded(
            // Centers the chessboard within the Expanded widget.
            child: Center(
              // The visual chessboard widget.
              child: ChessBoard(
                // Passes the controller to manage the board's state.
                controller: _boardController,
                // Sets the color scheme of the board squares.
                boardColor: BoardColor.brown,
                // Sets the board's orientation. The user is playing as White.
                boardOrientation: PlayerColor.white,
                // A callback function that is triggered whenever a move is made on the UI.
                onMove: () {
                  // Calls our handler for the player's move.
                  _onPlayerMove();
                },
              ),
            ),
          ),
          // Padding adds space around the status text at the bottom.
          Padding(
            // Adds 16 pixels of padding on all sides.
            padding: const EdgeInsets.all(16.0),
            // A Row to display the status text and a loading indicator horizontally.
            child: Row(
              // Centers the children horizontally.
              mainAxisAlignment: MainAxisAlignment.center,
              // The list of children in the Row.
              children: [
                // The static text part of the status message.
                const Text(
                  "Stockfish is thinking...",
                  // Sets the style for the text.
                  style: TextStyle(fontSize: 18),
                ),
                // Conditionally shows the progress indicator only if the engine is thinking.
                if (_isEngineThinking)
                  // Adds padding to the left of the indicator.
                  const Padding(
                    padding: EdgeInsets.only(left: 10),
                    // A container with a fixed size for the indicator.
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      // The circular loading spinner widget.
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

  // A helper method to display the game over dialog.
  void _showGameOverDialog(String title) {
    // A built-in Flutter function to show a dialog.
    showDialog(
      // The build context required to locate the dialog on the screen.
      context: context,
      // A function that builds the content of the dialog.
      builder: (BuildContext context) {
        // AlertDialog is a standard dialog with a title, content, and actions.
        return AlertDialog(
          // The title of the dialog (e.g., "Checkmate!").
          title: Text(title),
          // The main content/message of the dialog.
          content: const Text('The game has ended.'),
          // A list of action buttons at the bottom of the dialog.
          actions: <Widget>[
            // A clickable text button.
            TextButton(
              // The text displayed on the button.
              child: const Text('Play Again'),
              // The function to execute when the button is pressed.
              onPressed: () {
                // Resets the logical game state to the starting position.
                _game.reset();
                // Updates the visual board to match the reset logical state.
                _boardController.loadFen(_game.fen);
                // Closes the dialog.
                Navigator.of(context).pop();
                // Triggers a UI rebuild to reflect the reset state.
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }
}
