// lib/db_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'dart:convert'; // Add this import for jsonEncode

class DBHelper {
  static Database? _database;
  // IMPORTANT: Increment the version when you make schema changes (like adding new columns)
  // Version 2 is for scores and undo/redo flags.
  // Version 3 is for captured_bead_x and captured_bead_y columns in Moves table.
  static final int _version = 3; // Changed to Version 3

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    var databasesPath = await getDatabasesPath();
    var path = join(databasesPath, "FYP12beads.db");

    var exists = await databaseExists(path);
    Database db;

    if (!exists) {
      try {
        await Directory(dirname(path)).create(recursive: true);
        // It's generally better practice to create the DB schema from code
        // rather than copying from assets if schema changes are frequent.
        // For new installations, onCreate will be called.
        // For existing, onUpgrade will handle it.
        // If you still want to copy the pre-filled DB, ensure it matches _version.
        // If not, you might consider removing this section or managing asset DB versions.

        // If you are copying a pre-existing DB, make sure its schema matches _version.
        // Otherwise, it might cause issues with onUpgrade.
        // For safety during schema changes, it's often better to just let onCreate build the schema.
        // If `FYP12beads.db` in assets is empty/template, this is fine.
        // If it has old data/schema, it might conflict.
        ByteData data = await rootBundle.load(join("assets", "Database", "FYP12beads.db"));
        List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await File(path).writeAsBytes(bytes, flush: true);
        print("DB_HELPER: Database copied from assets to: $path");

        db = await openDatabase(
          path,
          version: _version, // Use the static _version
          onUpgrade: _onUpgrade,
          onCreate: _createDb, // onCreate will be called if DB didn't exist
        );

      } catch (e) {
        print("DB_HELPER ERROR: Error copying database from assets: $e. Attempting to create from scratch.");
        db = await openDatabase(
          path,
          version: _version, // Use the static _version
          onCreate: _createDb,
          onUpgrade: _onUpgrade,
        );
      }
    } else {
      print("DB_HELPER: Database already exists at: $path. Opening existing database.");
      db = await openDatabase(
        path,
        version: _version, // Use the static _version
        onUpgrade: _onUpgrade,
      );
    }

    print("DB_HELPER: Database opened successfully with version ${await db.getVersion()}.");
    return db;
  }

  // Common function to create tables, to be used in onCreate (for new DBs)
  // This should always create the schema for the LATEST version (Version 3)
  Future<void> _createDb(Database db, int version) async {
    print("DB_HELPER: _createDb called for version $version.");
    await db.execute('''
      CREATE TABLE IF NOT EXISTS "Player" (
          "player_id"      INTEGER,
          "name"  TEXT,
          "total_wins"    INTEGER DEFAULT 0,
          "total_losses"  INTEGER DEFAULT 0,
          PRIMARY KEY("player_id" AUTOINCREMENT)
      )
    ''');
    await db.execute('''
      CREATE TABLE Game (
        game_id INTEGER PRIMARY KEY AUTOINCREMENT,
        player_id INTEGER,
        opponent_id INTEGER,
        player_bead_color TEXT,
        opponent_bead_color TEXT,
        date TEXT,
        winner TEXT, -- NULL if game is not finished
        total_moves INTEGER DEFAULT 0,
        player1_final_score INTEGER DEFAULT 0, -- Default to 0 for new games
        player2_final_score INTEGER DEFAULT 0, -- Default to 0 for new games
        FOREIGN KEY (player_id) REFERENCES "Player"(player_id),
        FOREIGN KEY (opponent_id) REFERENCES "Player"(player_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE Moves (
        move_id INTEGER PRIMARY KEY AUTOINCREMENT,
        game_id INTEGER,
        move_number INTEGER,
        bead_color TEXT,
        from_x INTEGER,
        from_y INTEGER,
        to_x INTEGER,
        to_y INTEGER,
        capture INTEGER,
        undo_flag INTEGER DEFAULT 0,
        redo_flag INTEGER DEFAULT 0,
        captured_bead_x INTEGER, -- NEW COLUMN FOR VERSION 3
        captured_bead_y INTEGER, -- NEW COLUMN FOR VERSION 3
        timestamp TEXT,
        FOREIGN KEY (game_id) REFERENCES Game(game_id)
      )
    ''');
    print("DB_HELPER: Tables created via onCreate callback for version $version.");
  }

  // IMPORTANT: onUpgrade function to add new columns to existing database
  // This handles upgrade to version 2 (adding final scores and undo/redo flags)
  // And to version 3 (adding captured_bead_x and captured_bead_y)
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print("DB_HELPER: Upgrading database from version $oldVersion to $newVersion.");

    if (oldVersion < 2) {
      // Add player1_final_score and player2_final_score for upgrade to version 2
      var gameTableInfo = await db.rawQuery("PRAGMA table_info(Game);");
      bool hasPlayer1Score = gameTableInfo.any((col) => col['name'] == 'player1_final_score');
      bool hasPlayer2Score = gameTableInfo.any((col) => col['name'] == 'player2_final_score');

      if (!hasPlayer1Score) {
        await db.execute("ALTER TABLE Game ADD COLUMN player1_final_score INTEGER DEFAULT 0;");
        print("DB_HELPER: 'player1_final_score' column added to 'Game' table.");
      }
      if (!hasPlayer2Score) {
        await db.execute("ALTER TABLE Game ADD COLUMN player2_final_score INTEGER DEFAULT 0;");
        print("DB_HELPER: 'player2_final_score' column added to 'Game' table.");
      }

      // Add undo_flag and redo_flag to Moves table for upgrade to version 2
      var movesTableInfo = await db.rawQuery("PRAGMA table_info(Moves);");
      bool hasUndoFlag = movesTableInfo.any((col) => col['name'] == 'undo_flag');
      bool hasRedoFlag = movesTableInfo.any((col) => col['name'] == 'redo_flag');

      if (!hasUndoFlag) {
        await db.execute("ALTER TABLE Moves ADD COLUMN undo_flag INTEGER DEFAULT 0;");
        print("DB_HELPER: 'undo_flag' column added to 'Moves' table.");
      }
      if (!hasRedoFlag) {
        await db.execute("ALTER TABLE Moves ADD COLUMN redo_flag INTEGER DEFAULT 0;");
        print("DB_HELPER: 'redo_flag' column added to 'Moves' table.");
      }

      // Add total_wins and total_losses to Player table for upgrade to version 2
      var playerTableInfo = await db.rawQuery("PRAGMA table_info(Player);");
      bool hasTotalWins = playerTableInfo.any((col) => col['name'] == 'total_wins');
      bool hasTotalLosses = playerTableInfo.any((col) => col['name'] == 'total_losses');

      if (!hasTotalWins) {
        await db.execute("ALTER TABLE Player ADD COLUMN total_wins INTEGER DEFAULT 0;");
        print("DB_HELPER: 'total_wins' column added to 'Player' table.");
      }
      if (!hasTotalLosses) {
        await db.execute("ALTER TABLE Player ADD COLUMN total_losses INTEGER DEFAULT 0;");
        print("DB_HELPER: 'total_losses' column added to 'Player' table.");
      }
    }

    if (oldVersion < 3) {
      // Add captured_bead_x and captured_bead_y for upgrade to version 3
      var movesTableInfo = await db.rawQuery("PRAGMA table_info(Moves);");
      bool hasCapturedBeadX = movesTableInfo.any((col) => col['name'] == 'captured_bead_x');
      bool hasCapturedBeadY = movesTableInfo.any((col) => col['name'] == 'captured_bead_y');

      if (!hasCapturedBeadX) {
        await db.execute("ALTER TABLE Moves ADD COLUMN captured_bead_x INTEGER;");
        print("DB_HELPER: 'captured_bead_x' column added to 'Moves' table.");
      }
      if (!hasCapturedBeadY) {
        await db.execute("ALTER TABLE Moves ADD COLUMN captured_bead_y INTEGER;");
        print("DB_HELPER: 'captured_bead_y' column added to 'Moves' table.");
      }
    }
  }

  // --- Functions for 'Player' Table ---
  Future<void> insertPlayersByName(String name1, String name2) async {
    try {
      final db = await database;
      // Use INSERT OR IGNORE to avoid duplicate entries and simplify logic
      await db.insert('Player', {'name': name1}, conflictAlgorithm: ConflictAlgorithm.ignore);
      print('DB_HELPER: Player "$name1" inserted or already exists.');
      await db.insert('Player', {'name': name2}, conflictAlgorithm: ConflictAlgorithm.ignore);
      print('DB_HELPER: Player "$name2" inserted or already exists.');
    } catch (e) {
      print("DB_HELPER ERROR: Error inserting players: $e");
    }
  }

  Future<List<Map<String, dynamic>>> getPlayers() async {
    final db = await database;
    final players = await db.query('Player');
    print('DB_HELPER: Fetched Players: $players');
    return players;
  }

  Future<Map<String, dynamic>> getPlayerById(int playerId) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'Player',
      where: 'player_id = ?',
      whereArgs: [playerId],
    );
    return result.first; // Assuming player with given ID always exists
  }

  // --- Update Player Wins/Losses ---
  Future<void> updatePlayerWinsLosses(int playerId, {bool isWin = true}) async {
    final db = await database;
    await db.rawUpdate('''
      UPDATE Player
      SET total_wins = total_wins + ?,
          total_losses = total_losses + ?
      WHERE player_id = ?
    ''', [isWin ? 1 : 0, isWin ? 0 : 1, playerId]);
    print('DB_HELPER: Player ID $playerId updated. isWin: $isWin');
  }

  // --- Functions for 'Game' Table ---
  Future<int> insertGame({
    required int playerId,
    required int opponentId,
    required String playerBeadColor,
    required String opponentBeadColor,
    String? winner,
    int totalMoves = 0,
    int? player1FinalScore,
    int? player2FinalScore,
  }) async {
    try {
      final db = await database;
      final gameId = await db.insert(
        'Game',
        {
          'player_id': playerId,
          'opponent_id': opponentId,
          'player_bead_color': playerBeadColor,
          'opponent_bead_color': opponentBeadColor,
          'date': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
          'winner': winner,
          'total_moves': totalMoves,
          'player1_final_score': player1FinalScore ?? 0, // Default to 0
          'player2_final_score': player2FinalScore ?? 0, // Default to 0
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('DB_HELPER: Game inserted with ID: $gameId. Player1 ID: $playerId, Player2 ID: $opponentId.');
      return gameId;
    } catch (e) {
      print("DB_HELPER ERROR: Error inserting game: $e");
      return -1;
    }
  }

  Future<void> updateGame({
    required int gameId,
    String? winner,
    int? totalMoves,
    int? player1FinalScore,
    int? player2FinalScore,
  }) async {
    try {
      final db = await database;
      Map<String, dynamic> values = {};
      if (winner != null) values['winner'] = winner;
      if (totalMoves != null) values['total_moves'] = totalMoves;
      if (player1FinalScore != null) values['player1_final_score'] = player1FinalScore;
      if (player2FinalScore != null) values['player2_final_score'] = player2FinalScore;

      if (values.isNotEmpty) {
        int rowsAffected = await db.update(
          'Game',
          values,
          where: 'game_id = ?',
          whereArgs: [gameId],
        );
        print('DB_HELPER: Game $gameId updated. Rows Affected: $rowsAffected. New values: $values');
      } else {
        print('DB_HELPER: No values to update for Game ID: $gameId.');
      }
    } catch (e) {
      print("DB_HELPER ERROR: Error updating game: $e");
    }
  }

  // --- METHOD: Get incomplete (continue) games ---
  Future<List<Map<String, dynamic>>> getIncompleteGames() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT
        G.game_id,
        P1.name AS player1_name,
        P2.name AS opponent_name,
        G.player_bead_color,
        G.opponent_bead_color,
        G.date,
        G.winner,
        G.total_moves,
        G.player1_final_score,
        G.player2_final_score
      FROM Game G
      JOIN Player P1 ON G.player_id = P1.player_id
      JOIN Player P2 ON G.opponent_id = P2.player_id
      WHERE G.winner IS NULL
      ORDER BY G.date DESC
    ''');
  }

  // --- METHOD: Get completed (history) games ---
  Future<List<Map<String, dynamic>>> getCompletedGames() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT
        G.game_id,
        P1.name AS player1_name,
        P2.name AS opponent_name,
        G.player_bead_color,
        G.opponent_bead_color,
        G.date,
        G.winner,
        G.total_moves,
        G.player1_final_score,
        G.player2_final_score
      FROM Game G
      JOIN Player P1 ON G.player_id = P1.player_id
      JOIN Player P2 ON G.opponent_id = P2.player_id
      WHERE G.winner IS NOT NULL
      ORDER BY G.date DESC
    ''');
  }

  // Original getGames method (can keep for debugging or if other parts use it)
  Future<List<Map<String, dynamic>>> getGames() async {
    final db = await database;
    final games = await db.rawQuery('''
      SELECT
        G.game_id,
        P1.name AS player1_name,
        P2.name AS opponent_name,
        G.player_bead_color,
        G.opponent_bead_color,
        G.date,
        G.winner,
        G.total_moves,
        G.player1_final_score,
        G.player2_final_score
      FROM Game G
      JOIN Player P1 ON G.player_id = P1.player_id
      JOIN Player P2 ON G.opponent_id = P2.player_id
      ORDER BY G.date DESC
    ''');
    print('DB_HELPER: Fetched ALL Games: ${games.length} games found.');
    return games;
  }


  // --- Functions for 'Moves' Table ---
  // Updated insertMove to also track undo/redo actions for a player
  // Added capturedBeadX and capturedBeadY parameters
  Future<int> insertMove({
    required int gameId,
    required int moveNumber,
    required String beadColor,
    required int fromX,
    required int fromY,
    required int toX,
    required int toY,
    required int capture,
    int undoFlag = 0, // This is a flag for THIS specific move entry
    int redoFlag = 0, // This is a flag for THIS specific move entry
    int? capturedBeadX, // NEW PARAMETER
    int? capturedBeadY, // NEW PARAMETER
  }) async {
    try {
      final db = await database;
      final moveId = await db.insert(
        'Moves',
        {
          'game_id': gameId,
          'move_number': moveNumber,
          'bead_color': beadColor,
          'from_x': fromX,
          'from_y': fromY,
          'to_x': toX,
          'to_y': toY,
          'capture': capture,
          'undo_flag': undoFlag,
          'redo_flag': redoFlag,
          'captured_bead_x': capturedBeadX, // NEW COLUMN INSERTION
          'captured_bead_y': capturedBeadY, // NEW COLUMN INSERTION
          'timestamp': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('DB_HELPER: Move inserted. Game ID: $gameId, Move No: $moveNumber, Bead: $beadColor, From: ($fromX,$fromY) To: ($toX,$toY), Capture: $capture, Undo: $undoFlag, Redo: $redoFlag, Captured: ($capturedBeadX,$capturedBeadY)');
      return moveId;
    } catch (e) {
      print("DB_HELPER ERROR: Error inserting move: $e");
      return -1;
    }
  }

  Future<List<Map<String, dynamic>>> getMovesForGame(int gameId) async {
    final db = await database;
    final moves = await db.rawQuery('''
      SELECT
        move_id, game_id, move_number, bead_color,
        from_x, from_y, to_x, to_y, capture,
        undo_flag, redo_flag, captured_bead_x, captured_bead_y, timestamp -- Included new columns
      FROM Moves
      WHERE game_id = ?
      ORDER BY move_number ASC
    ''', [gameId]);
    print('DB_HELPER: Fetched ${moves.length} moves for Game ID: $gameId.');
    return moves;
  }

  // --- Get Undo/Redo Counts Per Player for a Game ---
  Future<Map<String, int>> getUndoRedoCountsForGame(int gameId) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT
        M.bead_color, -- Or join with Player table for player names directly
        SUM(M.undo_flag) AS total_undos,
        SUM(M.redo_flag) AS total_redos
      FROM Moves M
      WHERE M.game_id = ?
      GROUP BY M.bead_color
    ''', [gameId]);

    Map<String, int> counts = {
      'black_undos': 0,
      'black_redos': 0,
      'white_undos': 0,
      'white_redos': 0,
    };

    for (var row in results) {
      String beadColor = row['bead_color'] as String;
      int undos = row['total_undos'] as int? ?? 0;
      int redos = row['total_redos'] as int? ?? 0;

      if (beadColor == 'black') {
        counts['black_undos'] = undos;
        counts['black_redos'] = redos;
      } else if (beadColor == 'white') {
        counts['white_undos'] = undos;
        counts['white_redos'] = redos;
      }
    }
    print('DB_HELPER: Undo/Redo Counts for Game $gameId: $counts');
    return counts;
  }


  // --- Utility Functions for generic database Browse ---
  Future<List<String>> getAllTables() async {
    final db = await database;
    final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_metadata';");
    print('DB_HELPER: Fetched tables: ${tables.map((row) => row['name'] as String).toList()}');
    return tables.map((row) => row['name'] as String).toList();
  }

  Future<List<Map<String, dynamic>>> getAllRows(String tableName) async {
    final db = await database;
    final rows = await db.query(tableName);
    print('DB_HELPER: Fetched ${rows.length} rows from table "$tableName".');
    return rows;
  }

  // --- General Functions ---
  Future<void> deleteAllFromTable(String tableName) async {
    final db = await database;
    await db.delete(tableName);
    print('DB_HELPER: All records deleted from $tableName.');
  }

  // --- FUNCTION FOR SHARING GAME DATA ---
  Future<String> getGameDataJsonForSharing(int gameId) async {
    final db = await database;

    // 1. Fetch Game Details
    final List<Map<String, dynamic>> gameResult = await db.rawQuery('''
      SELECT
        G.game_id,
        P1.name AS player_name,
        P2.name AS opponent_name,
        G.player_id,
        G.opponent_id,
        G.player_bead_color,
        G.opponent_bead_color,
        G.date,
        G.winner,
        G.total_moves,
        G.player1_final_score,
        G.player2_final_score
      FROM Game G
      JOIN Player P1 ON G.player_id = P1.player_id
      JOIN Player P2 ON G.opponent_id = P2.player_id
      WHERE G.game_id = ?
    ''', [gameId]);

    if (gameResult.isEmpty) {
      return jsonEncode({'error': 'Game not found for ID: $gameId'});
    }

    final Map<String, dynamic> gameData = gameResult.first;

    // 2. Fetch Player Details for both players using their IDs (including wins/losses)
    Map<String, dynamic>? player1FullDetails;
    Map<String, dynamic>? player2FullDetails;

    if (gameData['player_id'] != null) {
      player1FullDetails = await getPlayerById(gameData['player_id']);
    }
    if (gameData['opponent_id'] != null) {
      player2FullDetails = await getPlayerById(gameData['opponent_id']);
    }

    // 3. Fetch Moves for this Game (including new columns)
    final List<Map<String, dynamic>> moves = await db.rawQuery('''
      SELECT
        move_id, game_id, move_number, bead_color,
        from_x, from_y, to_x, to_y, capture,
        undo_flag, redo_flag, captured_bead_x, captured_bead_y, timestamp
      FROM Moves
      WHERE game_id = ?
      ORDER BY move_number ASC
    ''', [gameId]);

    // 4. Combine all data into a single map
    final Map<String, dynamic> combinedData = {
      'game_details': {
        ...gameData,
        'player1_full_details': player1FullDetails,
        'player2_full_details': player2FullDetails,
      },
      'game_moves': moves,
    };

    // 5. Convert to JSON string
    return jsonEncode(combinedData);
  }
}