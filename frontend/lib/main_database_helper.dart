import 'package:parkngo/models/usermodel.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  late Database _database;

  DatabaseHelper() {
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    final databasePath = '/Users/mac/Desktop/parkngo/lib/main_database_helper.dart'; // Replace with your actual database path
    final version = 1; // Replace with your actual database version

    _database = await openDatabase(
      databasePath,
      version: version,
      onCreate: _createTables,
    );
  }

  Future<int> createUser(User newUser) async {
    return await _database.insert('user', newUser.toMap());
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
CREATE TABLE user(
id INTEGER PRIMARY KEY,
name TEXT,
email TEXT
)
''');
  }
}
