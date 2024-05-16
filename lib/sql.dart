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
    await db.execute('''
    CREATE TABLE User(
      id INTEGER PRIMARY KEY,
      name TEXT,
      init INTEGER
    )
  ''');

    // Create Dias table
    await db.execute('''
    CREATE TABLE Dias(
      id INTEGER PRIMARY KEY,
      name TEXT,
      iduser INTEGER,
      obj TEXT,
      FOREIGN KEY (iduser) REFERENCES User(id)
    )
  ''');

    // Create Exer table
    await db.execute('''
    CREATE TABLE Exer(
      id INTEGER PRIMARY KEY,
      name TEXT,
      coddia INTEGER,
      FOREIGN KEY (coddia) REFERENCES Dias(id)
    )
  ''');

    // Create Peso table
    await db.execute('''
    CREATE TABLE Peso(
      id INTEGER PRIMARY KEY,
      name TEXT,
      reps INTEGER,
      qtd INTEGER,
      codexer INTEGER,
      FOREIGN KEY (codexer) REFERENCES Exer(id)
    )
  ''');
  }

  Future<int> insertName(String name) async {
    Database db = await database;
    return await db.insert('Names', {'name': name});
  }

  Future<List<String>> getNames() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('Names');
    return List.generate(maps.length, (i) {
      return maps[i]['name'];
    });
  }

  Future<List<Map<String, dynamic>>> customQuery(String sqlQuery) async {
    Database db = await database;
    return await db.rawQuery(sqlQuery);
  }
}
