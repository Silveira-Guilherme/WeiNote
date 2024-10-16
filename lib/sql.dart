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
    // Create User table
    await db.execute(
        "CREATE TABLE IF NOT EXISTS User(IdUser INTEGER PRIMARY KEY, Name TEXT, Init INTEGER)");

    // Create Exer table
    await db.execute(
        "CREATE TABLE IF NOT EXISTS Exer(IdExer INTEGER PRIMARY KEY, Name TEXT)");

    // Create Serie table
    await db.execute(
        "CREATE TABLE IF NOT EXISTS Serie(IdSerie INTEGER PRIMARY KEY, Peso INTEGER, Rep INTEGER, CodExer INTEGER, FOREIGN KEY (CodExer) REFERENCES Exer(IdExer))");

    // Create Tr table
    await db.execute(
        "CREATE TABLE IF NOT EXISTS Tr(IdTr INTEGER PRIMARY KEY, Name TEXT)");

    // Create Tr_Exer table (Fixed SQL syntax by adding closing parenthesis)
    await db.execute(
        "CREATE TABLE IF NOT EXISTS Tr_Exer(IdTr_Exer INTEGER PRIMARY KEY, CodExer INTEGER, CodTr INTEGER, FOREIGN KEY (CodExer) REFERENCES Exer(IdExer), FOREIGN KEY (CodTr) REFERENCES Tr(IdTr))");

    // Create Tr_Day table
    await db.execute(
        "CREATE TABLE IF NOT EXISTS Tr_Day(IdTr_Day INTEGER PRIMARY KEY, Day TEXT, CodTr INTEGER, FOREIGN KEY (CodTr) REFERENCES Tr(IdTr))");
  }

  Future<int> insertName(String name) async {
    Database db = await database;
    return await db.insert('User', {'Name': name}); // Insert into User table
  }

  Future<List<String>> getNames() async {
    Database db = await database;
    List<Map<String, dynamic>> maps =
        await db.query('User'); // Query from User table
    return List.generate(maps.length, (i) {
      return maps[i]['Name'];
    });
  }

  Future<List<Map<String, dynamic>>> customQuery(String sqlQuery) async {
    Database db = await database;
    return await db.rawQuery(sqlQuery);
  }
}
