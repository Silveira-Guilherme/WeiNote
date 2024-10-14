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
    await db.execute("DROP TABLE IF EXISTS User;");
    await db.execute("DROP TABLE IF EXISTS Exer;");
    await db.execute("DROP TABLE IF EXISTS Serie;");
    await db.execute("DROP TABLE IF EXISTS Tr;");
    await db.execute("DROP TABLE IF EXISTS Tr_Exer;");
    await db.execute("DROP TABLE IF EXISTS  Tr_Day;");

    await db.execute(
        "CREATE TABLE User(IdUser INTEGER PRIMARY KEY, Name TEXT, init INTEGER)");

    await db
        .execute("CREATE TABLE Exer(IdExer INTEGER PRIMARY KEY,Name TEXT,)");

    await db.execute(
        "CREATE TABLE Serie(IdSerie INTEGER PRIMARY KEY, Peso int,Rep int,CodExer INTEGER,FOREIGN KEY (CodExer) REFERENCES Exer(IdExer))");

    await db.execute("CREATE TABLE Tr(IdTr INTEGER PRIMARY KEY,Name TEXT)");

    await db.execute(
        "CREATE TABLE Tr_Exer(IdTr_Exer INTEGER PRIMARY KEY,CodExer INTEGER,FOREIGN KEY (CodExer) REFERENCES Exer(IdExer),CodTr INTEGER,FOREIGN KEY (CodTr) REFERENCES Tr(IdTr))");

    await db.execute(
        "CREATE TABLE Tr_Day(IdTr_Day INTEGER PRIMARY KEY,Day TEXT,CodTr INTEGER,FOREIGN KEY (CodTr) REFERENCES Tr(IdTr))");
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
