import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'names.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    // Create tables if they don't exist
    await db.execute(
        "CREATE TABLE IF NOT EXISTS User(IdUser INTEGER PRIMARY KEY, Name TEXT, Init INTEGER)");

    await db.execute(
        "CREATE TABLE IF NOT EXISTS Day(IdDay INTEGER PRIMARY KEY, Name TEXT)");

    await db.execute(
        "CREATE TABLE IF NOT EXISTS Tr(IdTr INTEGER PRIMARY KEY, Name TEXT, Type TEXT)");

    await db.execute(
        "CREATE TABLE IF NOT EXISTS Tr_Day(IdTr_Day INTEGER PRIMARY KEY, CodDay INTEGER, CodTr INTEGER, FOREIGN KEY (CodTr) REFERENCES Tr(IdTr), FOREIGN KEY (CodDay) REFERENCES Day(IdDay))");

    await db.execute(
        "CREATE TABLE IF NOT EXISTS Exer(IdExer INTEGER PRIMARY KEY, Name TEXT)");

    await db.execute(
        "CREATE TABLE IF NOT EXISTS Serie(IdSerie INTEGER PRIMARY KEY, Peso INTEGER, Rep INTEGER, CodExer INTEGER, FOREIGN KEY (CodExer) REFERENCES Exer(IdExer))");

    await db.execute(
        "CREATE TABLE IF NOT EXISTS Tr_Exer(IdTr_Exer INTEGER PRIMARY KEY, CodExer INTEGER, CodTr INTEGER, CodAlt INTEGER, ExerOrder INT, FOREIGN KEY (CodExer) REFERENCES Exer(IdExer), FOREIGN KEY (CodTr) REFERENCES Tr(IdTr), FOREIGN KEY (CodAlt) REFERENCES Exer(IdExer))");

    await db.execute(
        "CREATE TABLE IF NOT EXISTS Macro(IdMacro INTEGER PRIMARY KEY, Qtt INTEGER, RSerie INTEGER, RExer INTEGER)");

    await db.execute(
        "CREATE TABLE IF NOT EXISTS Exer_Macro(IdExer_Macro INTEGER PRIMARY KEY, CodMacro INTEGER, CodExer INTEGER, MacroOrder INT, FOREIGN KEY (CodExer) REFERENCES Exer(IdExer), FOREIGN KEY (CodMacro) REFERENCES Macro(IdMacro))");

    await db.execute(
        "CREATE TABLE IF NOT EXISTS Tr_Macro(IdTr_Macro INTEGER PRIMARY KEY, CodMacro INTEGER, CodTr INTEGER, ExerOrder INT, FOREIGN KEY (CodTr) REFERENCES Tr(IdTr), FOREIGN KEY (CodMacro) REFERENCES Macro(IdMacro))");

    final List<String> weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    // Loop through each day and insert into the Day table with the correct order
    for (int i = 0; i < weekdays.length; i++) {
      await db.insert(
        'Day',
        {
          'IdDay': i + 1, // Assuming IdDay is the primary key and starts at 1
          'Name': weekdays[i],
        },
        // conflictAlgorithm: ConflictAlgorithm.ignore, // To avoid duplicates
      );
    }
  }

// Insert a new user
  Future<int> insertUser(String name) async {
    Database db = await database;
    return await db.insert('User', {
      'Name': name,
      'Init': 0
    }); // Insert into User table with 'Init' default value
  }

// Retrieve all user names
  Future<List<String>> getUserNames() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('User');
    return List.generate(maps.length, (i) {
      return maps[i]['Name'];
    });
  }

// Execute a custom SQL query
  Future<List<Map<String, dynamic>>> customQuery(String sqlQuery,
      [String? string]) async {
    Database db = await database;
    return await db.rawQuery(sqlQuery);
  }

// Update a training's details (Tr table)
  Future<int> updateTraining(int id, String name, String type) async {
    Database db = await database;
    return await db.update(
      'Tr',
      {'Name': name, 'Type': type},
      where: 'IdTr = ?',
      whereArgs: [id],
    );
  }

// Update an exercise's details (Exer table)
  Future<int> updateExercise(int id, String name) async {
    Database db = await database;
    return await db.update(
      'Exer',
      {'Name': name},
      where: 'IdExer = ?',
      whereArgs: [id],
    );
  }

// Update the training day (adjusted to match CodDay field)
  Future<int> updateTrainingDay(int id, int dayId) async {
    Database db = await database;
    return await db.update(
      'Tr_Day',
      {'CodDay': dayId}, // Ensure correct field
      where: 'IdTr_Day = ?',
      whereArgs: [id],
    );
  }

// Clear all training days for a specific training
  Future<void> clearTrainingDays(int trainingId) async {
    Database db = await database;
    await db.delete(
      'Tr_Day',
      where: 'CodTr = ?',
      whereArgs: [trainingId],
    );
  }

// Insert a training day with reference to CodDay and CodTr
  Future<void> insertTrainingDay(int trainingId, int dayId) async {
    Database db = await database;
    await db.insert('Tr_Day', {
      'CodDay': dayId, // Changed to match correct schema
      'CodTr': trainingId,
    });
  }

// Update series details (weight and repetitions)
  Future<int> updateSeries(int seriesId, double weight, int reps) async {
    Database db = await database;
    return await db.update(
      'Serie',
      {'Peso': weight, 'Rep': reps},
      where: 'IdSerie = ?', // Primary key of the series
      whereArgs: [seriesId],
    );
  }

// Insert a new series entry for a specific exercise
  Future<int> insertSeries(int exerciseId, double weight, int reps) async {
    Database db = await database;
    return await db.insert(
      'Serie',
      {'CodExer': exerciseId, 'Peso': weight, 'Rep': reps},
    );
  }

// Delete a series by ID
  Future<int> deleteSeries(int seriesId) async {
    Database db = await database;
    return await db.delete(
      'Serie',
      where:
          'IdSerie = ?', // Assuming 'IdSerie' is the primary key of the series
      whereArgs: [seriesId],
    );
  }

// Get details of an exercise including its series info
  Future<List<Map<String, dynamic>>> getExerciseDetails(int exerciseId) async {
    Database db = await database;

    String sqlQuery = '''
    SELECT Exer.Name, Serie.Peso, Serie.Rep
    FROM Exer
    JOIN Serie ON Exer.IdExer = Serie.CodExer
    WHERE Exer.IdExer = ?
  ''';

    return await db.rawQuery(sqlQuery, [exerciseId]);
  }

// Retrieve series based on exercise ID
  Future<List<Map<String, dynamic>>> getSeriesByExerciseId(
      int exerciseId) async {
    Database db = await database;

    return await db.query(
      'Serie',
      where: 'CodExer = ?',
      whereArgs: [exerciseId],
    );
  }

  Future<bool> isOrderUniqueForTraining(int trainingId, int order) async {
    Database db = await database;

    // Query `Tr_Exer` and `Tr_Macro` for the specified `CodTr` and `Order`
    List<Map<String, dynamic>> exerOrder = await db.query(
      'Tr_Exer',
      where: 'CodTr = ? AND Order = ?',
      whereArgs: [trainingId, order],
    );

    List<Map<String, dynamic>> macroOrder = await db.query(
      'Tr_Macro',
      where: 'CodTr = ? AND Order = ?',
      whereArgs: [trainingId, order],
    );

    // The `Order` is unique if both queries return empty results
    return exerOrder.isEmpty && macroOrder.isEmpty;
  }

  // Insert an exercise with unique order for the training
  Future<int> insertTrainingExercise(
      int exerciseId, int trainingId, int order) async {
    if (!await isOrderUniqueForTraining(trainingId, order)) {
      throw Exception(
          "Order $order already exists for training $trainingId in either Tr_Exer or Tr_Macro.");
    }

    Database db = await database;
    return await db.insert(
      'Tr_Exer',
      {
        'CodExer': exerciseId,
        'CodTr': trainingId,
        'Order': order,
      },
    );
  }

// Insert a macro with unique order for the training
  Future<int> insertTrainingMacro(
      int macroId, int trainingId, int order) async {
    if (!await isOrderUniqueForTraining(trainingId, order)) {
      throw Exception(
          "Order $order already exists for training $trainingId in either Tr_Exer or Tr_Macro.");
    }

    Database db = await database;
    return await db.insert(
      'Tr_Macro',
      {
        'CodMacro': macroId,
        'CodTr': trainingId,
        'Order': order,
      },
    );
  }
}
