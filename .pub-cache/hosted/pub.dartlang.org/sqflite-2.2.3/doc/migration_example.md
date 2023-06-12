## Migration example

Here is a simple example of a database schema migration where:
* a column is added to an existing table
* a table is added

```dart
// Our database path
String path;
// Our database once opened
Database db;
```

In the examples below, `factory` can be replaced by `sqfliteDatabaseFactory` when using `sqflite`.

## 1st version

The first version creates a `Company` table with a `name` column.

```dart
/// Create tables
void _createTableCompanyV1(Batch batch) {
  batch.execute('DROP TABLE IF EXISTS Company');
  batch.execute('''CREATE TABLE Company (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT
)''');
}

// First version of the database
db = await factory.openDatabase(path,
    options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          var batch = db.batch();
          _createTableCompanyV1(batch);
          await batch.commit();
        },
        onDowngrade: onDatabaseDowngradeDelete));

```

## 2nd version

Let say we want to add a new table `Employee` with a reference to a `Company` entity.
We also want to add a new column `description` in the `Company` entity.

We handle the creation of a fresh database in `onCreate` and handle the schema migration in `onUpgrade`. Also since we
want to use foreign key constraints, we configure our access in `onConfigure`.

```dart
/// Let's use FOREIGN KEY constraints
Future onConfigure(Database db) async {
  await db.execute('PRAGMA foreign_keys = ON');
}

/// Create Company table V2
void _createTableCompanyV2(Batch batch) {
  batch.execute('DROP TABLE IF EXISTS Company');
  batch.execute('''CREATE TABLE Company (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT,
    description TEXT
)''');
}

/// Update Company table V1 to V2
void _updateTableCompanyV1toV2(Batch batch) {
  batch.execute('ALTER TABLE Company ADD description TEXT');
}

/// Create Employee table V2
void _createTableEmployeeV2(Batch batch) {
  batch.execute('DROP TABLE IF EXISTS Employee');
  batch.execute('''CREATE TABLE Employee (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT,
    companyId INTEGER,
    FOREIGN KEY (companyId) REFERENCES Company(id) ON DELETE CASCADE
)''');
}

// 2nd version of the database
db = await factory.openDatabase(path,
    options: OpenDatabaseOptions(
        version: 2,
        onConfigure: onConfigure,
        onCreate: (db, version) async {
          var batch = db.batch();
          // We create all the tables
          _createTableCompanyV2(batch);
          _createTableEmployeeV2(batch);
          await batch.commit();
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          var batch = db.batch();
          if (oldVersion == 1) {
            // We update existing table and create the new tables
            _updateTableCompanyV1toV2(batch);
            _createTableEmployeeV2(batch);
          }
          await batch.commit();
        },
        onDowngrade: onDatabaseDowngradeDelete));

```

You will have to restart your app when you change your application schema. Flutter Hot-reload won't work unless you properly close currently opened databases.