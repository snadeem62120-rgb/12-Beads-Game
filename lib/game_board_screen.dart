// lib/game_board_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:final_proj/db_helper.dart'; // Make sure this path is correct
import 'package:final_proj/scores_display_screen.dart'; // Make sure this path is correct

class GameBoardScreen extends StatefulWidget {
  final String player1;
  final String player2;
  final int? gameToResumeId;
  final int? startingPlayerIndex;
  final selectedDestroyed;

  const GameBoardScreen({
    super.key,
    required this.player1,
    required this.player2,
    this.gameToResumeId,
    this.startingPlayerIndex,
    this.selectedDestroyed,
  });

  @override
  _GameBoardScreenState createState() => _GameBoardScreenState();
}

class _GameBoardScreenState extends State<GameBoardScreen> {
  // --- DATABASE RELATED VARIABLES ---
  int? _gameId;
  int _player1DbId = -1;
  int _player2DbId = -1;
  int _currentMoveNumber = 0;
  String _player1BeadColor = "black";
  String _player2BeadColor = "white";

  // --- SCORE VARIABLES ---
  int _player1Score = 0;
  int _player2Score = 0;

  // --- Adjacency Map for valid moves ---
  final Map<Offset, List<Offset>> _adjacencies = {};

  // --- GAME STATE VARIABLES ---
  final List<Offset> validPositions = [
    for (int y = 0; y < 5; y++)
      for (int x = 0; x < 5; x++) Offset(x.toDouble(), y.toDouble())
  ];

  Map<Offset, int> beadPositions = {};
  Offset? selectedBead;
  int currentPlayer = 0; // 0 for player 1 (black), 1 for player 2 (white)
  List<Map<String, dynamic>> _undoHistory = [];
  List<Map<String, dynamic>> _redoHistory = [];

  // --- UNDO/REDO LIMIT VARIABLES (Player-Specific) ---
  static const int _maxUndoRedoLimit = 3;
  Map<int, int> _playerUndoCounts = {0: 0, 1: 0};
  Map<int, int> _playerRedoCounts = {0: 0, 1: 0};

  // --- LOST BEADS TRACKING ---
  final List<Offset> _player1LostBeads = []; // Stores coordinates of beads lost by Player 1 (black beads captured)
  final List<Offset> _player2LostBeads = []; // Stores coordinates of beads lost by Player 2 (white beads captured)


  // --- TURN TIMER RELATED VARIABLES ---
  Timer? _turnTimer;
  int _currentTurnTime = 10;
  final int _maxTurnTime = 10;

  // --- OVERALL GAME TIMER VARIABLES ---
  Timer? _overallGameTimer;
  int _currentOverallGameTime = 800; // 10 minutes (600 seconds) for example, adjusted to 200 for testing
  final int _maxOverallGameTime = 800;

  @override
  void initState() {
    super.initState();
    _initializeAdjacencies();
    _initializeGame();
    _startTurnTimer();
    _startOverallGameTimer();
  }

  @override
  void dispose() {
    _turnTimer?.cancel();
    _overallGameTimer?.cancel();
    super.dispose();
  }

  // --- Overall Game Timer Function ---
  void _startOverallGameTimer() {
    _overallGameTimer?.cancel();
    if (widget.gameToResumeId == null) {
      _currentOverallGameTime = _maxOverallGameTime;
    }

    _overallGameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_currentOverallGameTime > 0) {
          _currentOverallGameTime--;
        } else {
          timer.cancel();
          _handleOverallTimeUp();
        }
      });
    });
  }

  // --- Handle Overall Game Time Up ---
  void _handleOverallTimeUp() {
    print('Overall game time is up!');
    String? gameResult = _checkGameOver(); // Re-check game over conditions

    // Fallback: Determine winner based on bead count if gameResult is still null
    int blackBeads = beadPositions.values.where((p) => p == 0).length;
    int whiteBeads = beadPositions.values.where((p) => p == 1).length;

    String finalWinner;
    if (blackBeads == 0) {
      finalWinner = widget.player2; // White wins if black has no beads
    } else if (whiteBeads == 0) {
      finalWinner = widget.player1; // Black wins if white has no beads
    } else if (blackBeads == 2 && whiteBeads == 1) {
      finalWinner = widget.player1; // Black wins if 2 beads vs 1
    } else if (whiteBeads == 2 && blackBeads == 1) {
      finalWinner = widget.player2; // White wins if 2 beads vs 1
    } else if (blackBeads > whiteBeads) {
      finalWinner = widget.player1; // Black wins if more beads
    } else if (whiteBeads > blackBeads) {
      finalWinner = widget.player2; // White wins if more beads
    } else if (blackBeads == whiteBeads) {
      finalWinner = "Draw"; // Draw if same number of beads left when time is up
    } else {
      finalWinner = "Draw"; // Default to Draw if no clear winner by beads
    }

    _endGame(finalWinner);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Overall game time is up! Game has ended. Result: $finalWinner',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  // --- Turn Timer related functions ---
  void _startTurnTimer() {
    _turnTimer?.cancel();
    _currentTurnTime = 10; // Reset to 10 seconds (max turn time)
    _turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_currentTurnTime > 0) {
          _currentTurnTime--;
        } else {
          timer.cancel();
          _handleTimeUp();
        }
      });
    });
  }

  void _resetTurnTimer() {
    if (mounted) {
      _turnTimer?.cancel();
      _startTurnTimer();
    }
  }

  void _handleTimeUp() {
    print('${currentPlayer == 0 ? widget.player1 : widget.player2}\'s time is up!');
    setState(() {
      currentPlayer = 1 - currentPlayer; // Switch player
      selectedBead = null; // Deselect any selected bead
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Time is up for ${currentPlayer == 0 ? widget.player2 : widget.player1}! It\'s ${currentPlayer == 0 ? widget.player1 : widget.player2}\'s turn.',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueGrey,
        duration: const Duration(seconds: 3),
      ),
    );

    _resetTurnTimer();
  }


  void _initializeAdjacencies() {
    void addConnection(Offset p1, Offset p2) {
      if (!validPositions.contains(p1) || !validPositions.contains(p2)) {
        return;
      }
      _adjacencies.putIfAbsent(p1, () => []).add(p2);
      _adjacencies.putIfAbsent(p2, () => []).add(p1);
    }

    for (int y = 0; y < 5; y++) {
      for (int x = 0; x < 5; x++) {
        Offset current = Offset(x.toDouble(), y.toDouble());
        if (x + 1 < 5) addConnection(current, Offset((x + 1).toDouble(), y.toDouble()));
        if (y + 1 < 5) addConnection(current, Offset(x.toDouble(), (y + 1).toDouble()));
      }
    }

    List<List<int>> diagonalConnections = [
      [2, 0, 1, 1], [0, 0, 1, 1], [2, 0, 3, 1], [1, 1, 2, 2],
      [3, 1, 4, 2], [0, 2, 1, 3], [2, 2, 3, 3], [1, 3, 2, 4],
      [3, 3, 4, 4], [4, 0, 3, 1], [1, 1, 0, 2], [3, 1, 2, 2],
      [2, 2, 1, 3], [4, 2, 3, 3], [1, 3, 0, 4], [3, 3, 2, 4]
    ];

    for (var d in diagonalConnections) {
      addConnection(Offset(d[0].toDouble(), d[1].toDouble()), Offset(d[2].toDouble(), d[3].toDouble()));
    }

    _adjacencies.forEach((key, value) {
      _adjacencies[key] = value.toSet().toList();
    });
  }


  Future<void> _initializeGame() async {
    final dbHelper = DBHelper();

    await dbHelper.insertPlayersByName(widget.player1, widget.player2);
    final players = await dbHelper.getPlayers();
    _player1DbId = players.firstWhere((p) => p['name'] == widget.player1)['player_id'];
    _player2DbId = players.firstWhere((p) => p['name'] == widget.player2)['player_id'];

    if (widget.gameToResumeId != null) {
      _gameId = widget.gameToResumeId;
      print('Resuming game with ID: $_gameId');
      await _loadGameState(_gameId!);
    } else {
      _gameId = await dbHelper.insertGame(
        playerId: _player1DbId,
        opponentId: _player2DbId,
        playerBeadColor: _player1BeadColor,
        opponentBeadColor: _player2BeadColor,
        winner: null,
        player1FinalScore: null,
        player2FinalScore: null,
      );
      print('New game started with ID: $_gameId');
      _initializeBoard();
      setState(() {
        _player1Score = 0;
        _player2Score = 0;
        _currentMoveNumber = 0;
        currentPlayer = widget.startingPlayerIndex ?? 0;
      });
      _saveCurrentState();
    }
    _playerUndoCounts = {0: 0, 1: 0};
    _playerRedoCounts = {0: 0, 1: 0};
    _player1LostBeads.clear();
    _player2LostBeads.clear();
  }

  Future<void> _loadGameState(int gameId) async {
    final dbHelper = DBHelper();
    final gameMoves = await dbHelper.getMovesForGame(gameId);

    setState(() {
      _initializeBoard();
      _player1Score = 0;
      _player2Score = 0;
      _currentMoveNumber = 0;
      _undoHistory.clear();
      _redoHistory.clear();
      _player1LostBeads.clear();
      _player2LostBeads.clear();
    });

    for (var move in gameMoves) {
      final fromX = move['from_x'];
      final fromY = move['from_y'];
      final toX = move['to_x'];
      final toY = move['to_y'];
      final capture = move['capture'];
      final beadColorOfMover = move['bead_color'];
      final moveNumber = move['move_number'];

      final fromPosition = Offset(fromX.toDouble(), fromY.toDouble());
      final toPosition = Offset(toX.toDouble(), toY.toDouble());

      setState(() {
        int moverPlayer = (beadColorOfMover == _player1BeadColor) ? 0 : 1;
        int? capturedBeadColor = null;

        beadPositions.remove(fromPosition);
        beadPositions[toPosition] = moverPlayer;

        if (capture == 1) {
          Offset? jumpedOver;
          double dx = (toX - fromX).abs().toDouble();
          double dy = (toY - fromY).abs().toDouble();

          if (dx == 2 && dy == 0) jumpedOver = Offset((fromX + toX) / 2, fromY.toDouble());
          else if (dx == 0 && dy == 2) jumpedOver = Offset(fromX.toDouble(), (fromY + toY) / 2);
          else if (dx == 2 && dy == 2) jumpedOver = Offset((fromX + toX) / 2, (fromY + toY) / 2);

          if (jumpedOver != null && beadPositions.containsKey(jumpedOver)) {
            capturedBeadColor = beadPositions[jumpedOver];
            beadPositions.remove(jumpedOver);

            if (capturedBeadColor == 0) {
              _player1LostBeads.add(jumpedOver);
            } else {
              _player2LostBeads.add(jumpedOver);
            }

            if (moverPlayer == 0) {
              _player1Score++;
            } else {
              _player2Score++;
            }
          }
        }
        _currentMoveNumber = moveNumber;
      });
    }

    setState(() {
      currentPlayer = (_currentMoveNumber % 2 == 0) ? 0 : 1;
    });

    print('Game state loaded for game ID: $gameId. Final scores: P1:$_player1Score, P2:$_player2Score. Current Player: ${currentPlayer == 0 ? widget.player1 : widget.player2}');
    _redoHistory.clear();
    _resetTurnTimer();
    _saveCurrentState();
  }

  void _recordMove(Offset from, Offset to, int capture) async {
    if (_gameId != null) {
      _currentMoveNumber++;
      await DBHelper().insertMove(
        gameId: _gameId!,
        moveNumber: _currentMoveNumber,
        beadColor: currentPlayer == 0 ? _player1BeadColor : _player2BeadColor,
        fromX: from.dx.toInt(),
        fromY: from.dy.toInt(),
        toX: to.dx.toInt(),
        toY: to.dy.toInt(),
        capture: capture,
      );
      await DBHelper().updateGame(gameId: _gameId!, totalMoves: _currentMoveNumber);
    }
  }

  void _endGame(String winner) async {
    if (_gameId != null) {
      await DBHelper().updateGame(
        gameId: _gameId!,
        winner: winner,
        totalMoves: _currentMoveNumber,
        player1FinalScore: _player1Score,
        player2FinalScore: _player2Score,
      );
      print('Game $_gameId ended. Winner: $winner, Scores: $_player1Score - $_player2Score. Data saved to DB.');
    } else {
      print('Game ID not set, cannot update game in DB.');
    }

    _turnTimer?.cancel();
    _overallGameTimer?.cancel();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const ScoresDisplayScreen(),
      ),
    );
  }

  void _initializeBoard() {
    setState(() {
      beadPositions.clear();
      for (int i = 0; i < 12; i++) {
        beadPositions[validPositions[i]] = 0;
      }
      for (int i = validPositions.length - 12; i < validPositions.length; i++) {
        beadPositions[validPositions[i]] = 1;
      }
      _undoHistory.clear();
      _redoHistory.clear();
      _player1Score = 0;
      _player2Score = 0;
      _currentMoveNumber = 0;
      _player1LostBeads.clear();
      _player2LostBeads.clear();
    });
  }

  void _saveCurrentState() {
    if (_undoHistory.length >= _maxUndoRedoLimit + 1) {
      _undoHistory.removeAt(0);
    }
    _undoHistory.add({
      'beadPositions': Map.of(beadPositions),
      'player1Score': _player1Score,
      'player2Score': _player2Score,
      'currentPlayer': currentPlayer,
      'currentMoveNumber': _currentMoveNumber,
      'player1LostBeads': List<Offset>.from(_player1LostBeads),
      'player2LostBeads': List<Offset>.from(_player2LostBeads),
    });
    _redoHistory.clear();
    _playerUndoCounts = {0: 0, 1: 0};
    _playerRedoCounts = {0: 0, 1: 0};
  }

  void _onBeadTapped(Offset position) {
    if (beadPositions[position] == currentPlayer) {
      setState(() {
        selectedBead = position;
      });
    } else if (selectedBead != null && !beadPositions.containsKey(position)) {
      if (_isValidMove(selectedBead!, position)) {
        _moveBead(selectedBead!, position);
      } else {
        setState(() {
          selectedBead = null;
        });
      }
    } else {
      setState(() {
        selectedBead = null;
      });
    }
  }

  bool _isValidMove(Offset from, Offset to) {
    if (beadPositions.containsKey(to)) return false;

    if (_adjacencies[from]?.contains(to) == true) {
      return true;
    }

    double dx = (to.dx - from.dx).abs();
    double dy = (to.dy - from.dy).abs();

    if (dx == 2 && dy == 0) {
      Offset jumpedOver = Offset((from.dx + to.dx) / 2, from.dy);
      return beadPositions.containsKey(jumpedOver) &&
          beadPositions[jumpedOver] != currentPlayer &&
          _adjacencies[from]?.contains(jumpedOver) == true &&
          _adjacencies[to]?.contains(jumpedOver) == true;
    }
    if (dx == 0 && dy == 2) {
      Offset jumpedOver = Offset(from.dx, (from.dy + to.dy) / 2);
      return beadPositions.containsKey(jumpedOver) &&
          beadPositions[jumpedOver] != currentPlayer &&
          _adjacencies[from]?.contains(jumpedOver) == true &&
          _adjacencies[to]?.contains(jumpedOver) == true;
    }
    if (dx == 2 && dy == 2) {
      Offset jumpedOver = Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2);
      return beadPositions.containsKey(jumpedOver) &&
          beadPositions[jumpedOver] != currentPlayer &&
          _adjacencies[from]?.contains(jumpedOver) == true &&
          _adjacencies[to]?.contains(jumpedOver) == true;
    }

    return false;
  }

  void _moveBead(Offset from, Offset to) {
    setState(() {
      _saveCurrentState();

      Offset? jumpedOver;
      double dx = (to.dx - from.dx).abs();
      double dy = (to.dy - from.dy).abs();
      int capture = 0;

      if (dx == 2 && dy == 0) jumpedOver = Offset((from.dx + to.dx) / 2, from.dy);
      else if (dx == 0 && dy == 2) jumpedOver = Offset(from.dx, (from.dy + to.dy) / 2);
      else if (dx == 2 && dy == 2) jumpedOver = Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2);

      beadPositions.remove(from);
      beadPositions[to] = currentPlayer;

      if (jumpedOver != null &&
          beadPositions.containsKey(jumpedOver) &&
          beadPositions[jumpedOver] != currentPlayer) {
        int capturedBeadPlayer = beadPositions[jumpedOver]!;
        beadPositions.remove(jumpedOver);
        capture = 1;

        if (capturedBeadPlayer == 0) {
          _player1LostBeads.add(jumpedOver);
        } else {
          _player2LostBeads.add(jumpedOver);
        }

        if (currentPlayer == 0) {
          _player1Score++;
        } else {
          _player2Score++;
        }

        if (_canJumpFrom(to)) {
          selectedBead = to;
        } else {
          selectedBead = null;
          currentPlayer = 1 - currentPlayer;
          _handleGameOver();
          _resetTurnTimer();
        }
      } else {
        selectedBead = null;
        currentPlayer = 1 - currentPlayer;
        _handleGameOver();
        _resetTurnTimer();
      }
      _recordMove(from, to, capture);
    });
  }


  bool _canJumpFrom(Offset position) {
    for (var target in validPositions) {
      if (_isValidMove(position, target)) {
        double dx = (target.dx - position.dx).abs();
        double dy = (target.dy - position.dy).abs();
        if ((dx == 2 && dy == 0) || (dx == 0 && dy == 2) || (dx == 2 && dy == 2)) {
          return true;
        }
      }
    }
    return false;
  }


  void _undoMove() {
    int currentUndoCount = _playerUndoCounts[currentPlayer] ?? 0;
    bool canUndoInHistory = _undoHistory.length > 1;

    if (currentUndoCount < _maxUndoRedoLimit && canUndoInHistory) {
      setState(() {
        final Map<String, dynamic> currentState = {
          'beadPositions': Map.of(beadPositions),
          'player1Score': _player1Score,
          'player2Score': _player2Score,
          'currentPlayer': currentPlayer,
          'currentMoveNumber': _currentMoveNumber,
          'player1LostBeads': List<Offset>.from(_player1LostBeads),
          'player2LostBeads': List<Offset>.from(_player2LostBeads),
        };
        _redoHistory.add(currentState);

        final Map<String, dynamic> previousState = _undoHistory.removeLast();
        beadPositions = Map.of(previousState['beadPositions']);
        _player1Score = previousState['player1Score'];
        _player2Score = previousState['player2Score'];
        currentPlayer = previousState['currentPlayer'];
        _currentMoveNumber = previousState['currentMoveNumber'];
        _player1LostBeads.clear();
        _player1LostBeads.addAll(List<Offset>.from(previousState['player1LostBeads']));
        _player2LostBeads.clear();
        _player2LostBeads.addAll(List<Offset>.from(previousState['player2LostBeads']));
        selectedBead = null;
        _resetTurnTimer();
        _playerUndoCounts[currentPlayer] = currentUndoCount + 1;
        _playerRedoCounts[currentPlayer] = 0;
      });
    } else if (currentUndoCount >= _maxUndoRedoLimit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your undo limit reached (3 undos max).')),
      );
    } else if (!canUndoInHistory) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No more moves to undo.')),
      );
    }
  }

  void _redoMove() {
    int currentRedoCount = _playerRedoCounts[currentPlayer] ?? 0;

    if (currentRedoCount < _maxUndoRedoLimit && _redoHistory.isNotEmpty) {
      setState(() {
        final Map<String, dynamic> currentState = {
          'beadPositions': Map.of(beadPositions),
          'player1Score': _player1Score,
          'player2Score': _player2Score,
          'currentPlayer': currentPlayer,
          'currentMoveNumber': _currentMoveNumber,
          'player1LostBeads': List<Offset>.from(_player1LostBeads),
          'player2LostBeads': List<Offset>.from(_player2LostBeads),
        };
        _undoHistory.add(currentState);

        final Map<String, dynamic> nextState = _redoHistory.removeLast();
        beadPositions = Map.of(nextState['beadPositions']);
        _player1Score = nextState['player1Score'];
        _player2Score = nextState['player2Score'];
        currentPlayer = nextState['currentPlayer'];
        _currentMoveNumber = nextState['currentMoveNumber'];
        _player1LostBeads.clear();
        _player1LostBeads.addAll(List<Offset>.from(nextState['player1LostBeads']));
        _player2LostBeads.clear();
        _player2LostBeads.addAll(List<Offset>.from(nextState['player2LostBeads']));
        selectedBead = null;
        _resetTurnTimer();
        _playerRedoCounts[currentPlayer] = currentRedoCount + 1;
      });
    } else if (currentRedoCount >= _maxUndoRedoLimit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your redo limit reached (3 redos max).')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No more moves to redo.')),
      );
    }
  }


  String? _checkGameOver() {
    int blackBeads = beadPositions.values.where((p) => p == 0).length;
    int whiteBeads = beadPositions.values.where((p) => p == 1).length;

    if (blackBeads == 0) {
      return widget.player2;
    }
    if (whiteBeads == 0) {
      return widget.player1;
    }

    bool currentPlayerHasMoves = false;
    for (var entry in beadPositions.entries) {
      Offset pos = entry.key;
      int player = entry.value;

      if (player == currentPlayer) {
        for (var target in validPositions) {
          if (!beadPositions.containsKey(target) && _isValidMove(pos, target)) {
            currentPlayerHasMoves = true;
            break;
          }
        }
      }
      if (currentPlayerHasMoves) break;
    }

    if (!currentPlayerHasMoves) {
      return (currentPlayer == 0) ? widget.player2 : widget.player1;
    }

    if (blackBeads == 2 && whiteBeads == 1) {
      return widget.player1;
    }
    if (whiteBeads == 2 && blackBeads == 1) {
      return widget.player2;
    }

    return null;
  }


  void _handleGameOver() {
    String? winner = _checkGameOver();
    if (winner != null) {
      _endGame(winner);
    }
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  static const double _boardWidth = 360;
  static const double _boardHeight = 300;

  Widget _buildBoard() {
    return SizedBox(
      width: _boardWidth,
      height: _boardHeight,
      child: Stack(
        children: [
          CustomPaint(size: const Size(_boardWidth, _boardHeight), painter: BoardPainter()),
          ...validPositions.map((pos) => Positioned(
            left: pos.dx * 72 + 20,
            top: pos.dy * 60 + 20,
            child: GestureDetector(
              onTap: () => _onBeadTapped(pos),
              child: _buildBeadOrSpace(pos, 30),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildBeadOrSpace(Offset pos, double size) {
    int? player = beadPositions[pos];
    if (player != null) {
      return _buildBead(pos, player, size);
    } else {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400, width: 1.0),
          shape: BoxShape.circle,
        ),
      );
    }
  }

  Widget _buildBead(Offset pos, int player, double size) {
    Color borderColor = Colors.black;
    bool isSelected = (selectedBead == pos);
    if (isSelected) {
      borderColor = (currentPlayer == 0) ? Colors.red : Colors.green;
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: player == 0 ? Colors.black : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
      ),
    );
  }

  // Modified to directly show "Lost" with coordinates and a small bead icon
  Widget _buildLostBeadsDisplay(List<Offset> lostBeads, Color beadColor) {
    if (lostBeads.isEmpty) {
      return const SizedBox.shrink(); // Don't display anything if no beads are lost
    }

    // Format coordinates: (x,y), (x,y)
    final String coordinatesText = lostBeads
        .map((bead) => '(${bead.dx.toInt()},${bead.dy.toInt()})')
        .join(', ');


    return Row(
      mainAxisSize: MainAxisSize.min, // Keep the row content tight
      children: [
        // Small circle representing the bead color
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: beadColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black54, width: 0.5),
          ),
        ),
        // ElevatedButton(
        //   onPressed: () {
        //     //_turnTimer?.cancel();
        //     //_overallGameTimer?.cancel();
        //     ScaffoldMessenger.of(context).showSnackBar(
        //       const SnackBar(content: Text('Destroy!')),
        //     );
        //     Navigator.pop(context);
        //   },
        //   style: ElevatedButton.styleFrom(
        //     backgroundColor: Colors.black,
        //     foregroundColor: Colors.white,
        //     shape: const OvalBorder(),
        //     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        //     minimumSize: const Size(80, 45),
        //   ),
        //   child: const Text('DestroyBeads', style: TextStyle(fontSize: 15)),
        // ),
    //     ElevatedButton(
    //       onPressed: (){},
    //       style: ElevatedButton.styleFrom(
    // backgroundColor: Colors.black,
    //         shape: RoundedRectangleBorder(
    //           borderRadius: BorderRadius.circular(10),
    //         ),
    //         fixedSize: const Size(60, 50),
    //       ),
    //       child: const Text('w1'),
    //     ),
        const SizedBox(width: 4), // Small gap between bead icon and text
        Expanded( // Use Expanded to allow text to take available space
          child: Text(
            'Lost: $coordinatesText',
            style: const TextStyle(
              fontSize: 14, // Smaller font size
              color: Colors.black54, // Subtler color
            ),
            overflow: TextOverflow.ellipsis, // Prevent text overflow
            maxLines: 1, // Ensure it stays on one line
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    int currentPlayerUndoCount = _playerUndoCounts[currentPlayer] ?? 0;
    int currentPlayerRedoCount = _playerRedoCounts[currentPlayer] ?? 0;

    int remainingUndos = _maxUndoRedoLimit - currentPlayerUndoCount;
    int remainingRedos = _maxUndoRedoLimit - currentPlayerRedoCount;

    bool canUndo = remainingUndos > 0 && _undoHistory.length > 1;
    bool canRedo = remainingRedos > 0 && _redoHistory.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFE6D5B8),
      body: SafeArea(
        // Wrap the whole Column in a SingleChildScrollView
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min, // Make column take minimum space
            children: [
              const SizedBox(height: 10),
              const Text(
                "TWELVE PIECE GAME",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const Divider(thickness: 2, color: Colors.black, indent: 50, endIndent: 50),
              const SizedBox(height: 10),

              // Player 1 Info and Lost Beads (Top)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPlayerInfo(widget.player1, Icons.person),
                    _buildLostBeadsDisplay(_player1LostBeads, Colors.black), // Lost black beads
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Score and Turn Information
              Text(
                'Score: ${widget.player1}: $_player1Score - ${widget.player2}: $_player2Score',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 5),
          // Row(
          //   children: [
          //     ElevatedButton(
          //       onPressed: (){
          //         _undoMove();
          //       },
          //       style: ElevatedButton.styleFrom(
          //         backgroundColor: Colors.blue,
          //         shape: RoundedRectangleBorder(
          //           borderRadius: BorderRadius.circular(20),
          //         ),
          //         fixedSize: const Size(5, 5),
          //       ),
          //       child: const Text('w'),
          //     ),
          //         ElevatedButton(
          //           onPressed: (){
          //             _undoMove();
          //           },
          //           style: ElevatedButton.styleFrom(
          //             backgroundColor: Colors.blue,
          //             shape: RoundedRectangleBorder(
          //               borderRadius: BorderRadius.circular(20),
          //             ),
          //             fixedSize: const Size(5, 5),
          //           ),
          //           child: const Text('w'),
          //         ),
          //         ElevatedButton(
          //           onPressed: (){
          //             _undoMove();
          //           },
          //           style: ElevatedButton.styleFrom(
          //             backgroundColor: Colors.blue,
          //             shape: RoundedRectangleBorder(
          //               borderRadius: BorderRadius.circular(20),
          //             ),
          //             fixedSize: const Size(5, 5),
          //           ),
          //           child: const Text('w'),
          //         ),
          //         ElevatedButton(
          //           onPressed: (){
          //             _undoMove();
          //           },
          //           style: ElevatedButton.styleFrom(
          //             backgroundColor: Colors.blue,
          //             shape: RoundedRectangleBorder(
          //               borderRadius: BorderRadius.circular(20),
          //             ),
          //             fixedSize: const Size(5, 5),
          //           ),
          //           child: const Text('w'),
          //         ),
          //         ElevatedButton(
          //           onPressed: (){
          //             _undoMove();
          //           },
          //           style: ElevatedButton.styleFrom(
          //             backgroundColor: Colors.blue,
          //             shape: RoundedRectangleBorder(
          //               borderRadius: BorderRadius.circular(20),
          //             ),
          //             fixedSize: const Size(5, 5),
          //           ),
          //           child: const Text('w'),
          //         ),
          //         ElevatedButton(
          //           onPressed: (){
          //             _undoMove();
          //           },
          //           style: ElevatedButton.styleFrom(
          //             backgroundColor: Colors.blue,
          //             shape: RoundedRectangleBorder(
          //               borderRadius: BorderRadius.circular(20),
          //             ),
          //             fixedSize: const Size(5, 5),
          //           ),
          //           child: const Text('w'),
          //         ),
          // ]
          // ),
          //     ElevatedButton(
          //       onPressed: (){},
          //       style: ElevatedButton.styleFrom(
          //         backgroundColor: Colors.blue,
          //         shape: RoundedRectangleBorder(
          //           borderRadius: BorderRadius.circular(20),
          //         ),
          //         fixedSize: const Size(5, 5),
          //       ),
          //       child: const Text('w'),
          //     ),
          //     ElevatedButton(
          //       onPressed: (){},
          //       style: ElevatedButton.styleFrom(
          //         backgroundColor: Colors.blue,
          //         shape: RoundedRectangleBorder(
          //           borderRadius: BorderRadius.circular(20),
          //         ),
          //         fixedSize: const Size(5, 5),
          //       ),
          //       child: const Text('w'),
          //     ),
          //     ElevatedButton(
          //       onPressed: (){},
          //       style: ElevatedButton.styleFrom(
          //         backgroundColor: Colors.blue,
          //         shape: RoundedRectangleBorder(
          //           borderRadius: BorderRadius.circular(20),
          //         ),
          //         fixedSize: const Size(5, 5),
          //       ),
          //       child: const Text('w'),
          //     ),
          //     ElevatedButton(
          //       onPressed: (){},
          //       style: ElevatedButton.styleFrom(
          //         backgroundColor: Colors.blue,
          //         shape: RoundedRectangleBorder(
          //           borderRadius: BorderRadius.circular(20),
          //         ),
          //         fixedSize: const Size(5, 5),
          //       ),
          //       child: const Text('w'),
          //     ),
          //     ElevatedButton(
          //       onPressed: (){},
          //       style: ElevatedButton.styleFrom(
          //         backgroundColor: Colors.blue,
          //         shape: RoundedRectangleBorder(
          //           borderRadius: BorderRadius.circular(20),
          //         ),
          //         fixedSize: const Size(5, 5),
          //       ),
          //       child: const Text('w'),
          //     ),
          //     ]
          // ),
              Text(
                '${currentPlayer == 0 ? widget.player1 : widget.player2}\'s Turn',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Turn Time: $_currentTurnTime seconds',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _currentTurnTime <= 5 ? Colors.red : Colors.blueGrey[800],
                ),
              ),
              const SizedBox(height: 10),

              // Undo/Redo Buttons and their counts
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.reply,
                          color: canUndo ? Colors.green : Colors.grey,
                          size: 30,
                        ),
                        onPressed: canUndo ? _undoMove : null,
                      ),
                      Text(
                        'Undo: $remainingUndos',
                        style: TextStyle(
                          fontSize: 12,
                          color: canUndo ? Colors.black : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  // Column(
                  //   children: [
                  //     ElevatedButton(
                  //       onPressed: (){},
                  //       style: ElevatedButton.styleFrom(
                  //         padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
                  //         backgroundColor: Colors.blue,
                  //         shape: RoundedRectangleBorder(
                  //           borderRadius: BorderRadius.circular(20),
                  //         ),
                  //         fixedSize: const Size(5, 5),
                  //       ),
                  //       child: const Text('w'),
                  //     ),
                  //   ],
                  // ),
                  Column(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.reply,
                          color: canRedo ? Colors.red : Colors.grey,
                          size: 30,
                          textDirection: TextDirection.rtl,
                        ),
                        onPressed: canRedo ? _redoMove : null,
                      ),
                      Text(
                        'Redo: $remainingRedos',
                        style: TextStyle(
                          fontSize: 12,
                          color: canRedo ? Colors.black : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 2),
              // Row(
              //   children: [
              //     ElevatedButton(
              //       onPressed: (){},
              //       style: ElevatedButton.styleFrom(
              //         backgroundColor: Colors.blue,
              //         shape: RoundedRectangleBorder(
              //           borderRadius: BorderRadius.circular(20),
              //         ),
              //         fixedSize: const Size(5, 5),
              //       ),
              //       child: const Text('w'),
              //     ),
              //
              //     ElevatedButton(
              //       onPressed: (){},
              //       style: ElevatedButton.styleFrom(
              //         backgroundColor: Colors.blue,
              //         shape: RoundedRectangleBorder(
              //           borderRadius: BorderRadius.circular(20),
              //         ),
              //         fixedSize: const Size(10, 10),
              //       ),
              //       child: const Text('w'),
              //     ),
              //
              //     ElevatedButton(
              //       onPressed: (){},
              //       style: ElevatedButton.styleFrom(
              //         backgroundColor: Colors.blue,
              //         shape: RoundedRectangleBorder(
              //           borderRadius: BorderRadius.circular(20),
              //         ),
              //         fixedSize: const Size(5, 5),
              //       ),
              //       child: const Text('w'),
              //     ),
              //
              //     ElevatedButton(
              //       onPressed: (){},
              //       style: ElevatedButton.styleFrom(
              //         backgroundColor: Colors.blue,
              //         shape: RoundedRectangleBorder(
              //           borderRadius: BorderRadius.circular(20),
              //         ),
              //         fixedSize: const Size(5, 5),
              //       ),
              //       child: const Text('w'),
              //     ),
              //
              //     ElevatedButton(
              //       onPressed: (){},
              //       style: ElevatedButton.styleFrom(
              //         backgroundColor: Colors.blue,
              //         shape: RoundedRectangleBorder(
              //           borderRadius: BorderRadius.circular(20),
              //         ),
              //         fixedSize: const Size(5, 5),
              //       ),
              //       child: const Text('w'),
              //     ),
              //
              //     ElevatedButton(
              //       onPressed: (){},
              //       style: ElevatedButton.styleFrom(
              //         backgroundColor: Colors.blue,
              //         shape: RoundedRectangleBorder(
              //           borderRadius: BorderRadius.circular(20),
              //         ),
              //         fixedSize: const Size(5, 5),
              //       ),
              //       child: const Text('w'),
              //     ),
              //   ],
              // ),
              // Game Board
              Center(
                child: Card(
                  color: Colors.brown,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildBoard(),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Player 2 Info and Lost Beads (Bottom)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildPlayerInfo(widget.player2, Icons.person),
                    _buildLostBeadsDisplay(_player2LostBeads, Colors.white), // Lost white beads
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Leave and Save buttons and Overall Timer
              Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 20.0), // Increased bottom padding slightly
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            _turnTimer?.cancel();
                            _overallGameTimer?.cancel();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: const OvalBorder(),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            minimumSize: const Size(80, 45),
                          ),
                          child: const Text('LEAVE', style: TextStyle(fontSize: 15)),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _turnTimer?.cancel();
                            _overallGameTimer?.cancel();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Game Saved!')),
                            );
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: const OvalBorder(),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            minimumSize: const Size(80, 45),
                          ),
                          child: const Text('SAVE', style: TextStyle(fontSize: 15)),
                        ),

                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Overall Game Time: ${_formatTime(_currentOverallGameTime)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _currentOverallGameTime <= 60 ? Colors.red : Colors.blueGrey[800],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

  }

  Widget _buildPlayerInfo(String name, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 22, color: Colors.black),
        const SizedBox(width: 5),
        Text(
          name,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class BoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2;

    const double gridUnitX = 72;
    const double gridUnitY = 60;
    const double offset = 35;

    for (int i = 0; i < 5; i++) {
      canvas.drawLine(
        Offset(0 * gridUnitX + offset, i * gridUnitY + offset),
        Offset(4 * gridUnitX + offset, i * gridUnitY + offset),
        paint,
      );
    }

    for (int j = 0; j < 5; j++) {
      canvas.drawLine(
        Offset(j * gridUnitX + offset, 0 * gridUnitY + offset),
        Offset(j * gridUnitX + offset, 4 * gridUnitY + offset),
        paint,
      );
    }

    canvas.drawLine(Offset(0 * gridUnitX + offset, 0 * gridUnitY + offset), Offset(4 * gridUnitX + offset, 4 * gridUnitY + offset), paint);
    canvas.drawLine(Offset(4 * gridUnitX + offset, 0 * gridUnitY + offset), Offset(0 * gridUnitX + offset, 4 * gridUnitY + offset), paint);

    canvas.drawLine(Offset(1 * gridUnitX + offset, 1 * gridUnitY + offset), Offset(3 * gridUnitX + offset, 3 * gridUnitY + offset), paint);
    canvas.drawLine(Offset(3 * gridUnitX + offset, 1 * gridUnitY + offset), Offset(1 * gridUnitX + offset, 3 * gridUnitY + offset), paint);

    canvas.drawLine(Offset(0 * gridUnitX + offset, 2 * gridUnitY + offset), Offset(2 * gridUnitX + offset, 0 * gridUnitY + offset), paint);
    canvas.drawLine(Offset(2 * gridUnitX + offset, 0 * gridUnitY + offset), Offset(4 * gridUnitX + offset, 2 * gridUnitY + offset), paint);

    canvas.drawLine(Offset(0 * gridUnitX + offset, 2 * gridUnitY + offset), Offset(2 * gridUnitX + offset, 4 * gridUnitY + offset), paint);
    canvas.drawLine(Offset(2 * gridUnitX + offset, 4 * gridUnitY + offset), Offset(4 * gridUnitX + offset, 2 * gridUnitY + offset), paint);

    List<List<int>> diagonals = [
      [2, 0, 1, 1], [0, 0, 1, 1], [2, 0, 3, 1], [1, 1, 2, 2],
      [3, 1, 4, 2], [0, 2, 1, 3], [2, 2, 3, 3], [1, 3, 2, 4],
      [3, 3, 4, 4], [4, 0, 3, 1], [1, 1, 0, 2], [3, 1, 2, 2],
      [2, 2, 1, 3], [4, 2, 3, 3], [1, 3, 0, 4], [3, 3, 2, 4]
    ];

    for (var d in diagonals) {
      canvas.drawLine(
        Offset(d[0] * gridUnitX + offset, d[1] * gridUnitY + offset),
        Offset(d[2] * gridUnitX + offset, d[3] * gridUnitY + offset),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}