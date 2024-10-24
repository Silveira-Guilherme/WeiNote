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
        "CREATE TABLE IF NOT EXISTS Exer(IdExer INTEGER PRIMARY KEY, Name TEXT)");

    await db.execute(
        "CREATE TABLE IF NOT EXISTS Serie(IdSerie INTEGER PRIMARY KEY, Peso INTEGER, Rep INTEGER, CodExer INTEGER, FOREIGN KEY (CodExer) REFERENCES Exer(IdExer))");

    await db.execute(
        "CREATE TABLE IF NOT EXISTS Tr(IdTr INTEGER PRIMARY KEY, Name TEXT)");

    await db.execute(
        "CREATE TABLE IF NOT EXISTS Tr_Exer(IdTr_Exer INTEGER PRIMARY KEY, CodExer INTEGER, CodTr INTEGER, FOREIGN KEY (CodExer) REFERENCES Exer(IdExer), FOREIGN KEY (CodTr) REFERENCES Tr(IdTr))");

    await db.execute(
        "CREATE TABLE IF NOT EXISTS Tr_Day(IdTr_Day INTEGER PRIMARY KEY, Day TEXT, CodTr INTEGER, FOREIGN KEY (CodTr) REFERENCES Tr(IdTr))");
  }

  Future<int> insertUser(String name) async {
    Database db = await database;
    return await db.insert('User', {'Name': name}); // Insert into User table
  }

  Future<List<String>> getUserNames() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('User');
    return List.generate(maps.length, (i) {
      return maps[i]['Name'];
    });
  }

  Future<List<Map<String, dynamic>>> customQuery(String sqlQuery,
      [String? string]) async {
    Database db = await database;
    return await db.rawQuery(sqlQuery);
  }

  // Update Training
  Future<int> updateTraining(int id, String name) async {
    Database db = await database;
    return await db.update(
      'Tr',
      {'Name': name},
      where: 'IdTr = ?',
      whereArgs: [id],
    );
  }

  // Update Exercise
  Future<int> updateExercise(int id, String name) async {
    Database db = await database;
    return await db.update(
      'Exer',
      {'Name': name},
      where: 'IdExer = ?',
      whereArgs: [id],
    );
  }

  // Update Training Day
  Future<int> updateTrainingDay(int id, String day) async {
    Database db = await database;
    return await db.update(
      'Tr_Day',
      {'Day': day},
      where: 'IdTr_Day = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearTrainingDays(int trainingId) async {
    Database db = await database;
    await db.delete(
      'Tr_Day',
      where: 'CodTr = ?',
      whereArgs: [trainingId],
    );
  }

  Future<void> insertTrainingDay(int trainingId, String day) async {
    Database db = await database;
    await db.insert('Tr_Day', {
      'Day': day,
      'CodTr': trainingId,
    });
  }

  // Method to delete a user
  Future<int> deleteUser(int id) async {
    Database db = await database;
    return await db.delete(
      'User',
      where: 'IdUser = ?',
      whereArgs: [id],
    );
  }

  // Method to fetch all exercises
  Future<List<Map<String, dynamic>>> getAllExercises() async {
    Database db = await database;
    return await db.query('Exer');
  }

  // Method to fetch all trainings
  Future<List<Map<String, dynamic>>> getAllTrainings() async {
    Database db = await database;
    return await db.query('Tr');
  }
}
