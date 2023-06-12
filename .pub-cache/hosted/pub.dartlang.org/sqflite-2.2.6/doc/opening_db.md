# Opening a database

## finding a location path for the database

Sqflite provides a basic location strategy using the databases path on Android and the Documents folder on iOS, as
recommended on both platform. The location can be retrieved using `getDatabasesPath`.

```dart
var databasesPath = await getDatabasesPath();
var path = join(databasesPath, dbName);

// Make sure the directory exists
try {
  await Directory(databasesPath).create(recursive: true);
} catch (_) {}
```

## Opening

A SQLite database is a file in the file system identified by a path. If relative, this path is relative to the path
obtained by `getDatabasesPath()`, which is the default database directory on Android and the documents directory on iOS.

```dart
var db = await openDatabase('my_db.db');
```

## Read-write

Opening a database in read-write mode is the default. One can specify a version to perform
migration strategy, can configure the database and its version.


### Configuration


`onConfigure` is the first optional callback called. It allows to perform database initialization
such as supporting cascade delete

```dart
_onConfigure(Database db) async {
  // Add support for cascade delete
  await db.execute("PRAGMA foreign_keys = ON");
}

var db = await openDatabase(path, onConfigure: _onConfigure);

```

### Preloading data

You might want to preload you database when opened the first time. You can either
* [Import an existing SQLite file](opening_asset_db.md) checking first whether the database file exists or not
* Populate data during `onCreate`:


```dart
_onCreate(Database db, int version) async {
  // Database is created, create the table
  await db.execute(
    "CREATE TABLE Test (id INTEGER PRIMARY KEY, value TEXT)");
  // populate data
  await db.insert(...);
}

// Open the database, specifying a version and an onCreate callback
var db = await openDatabase(path,
    version: 1,
    onCreate: _onCreate);
```
### Migration

To handle database upgrades (schema changes), there is a basic version mechanism
similar to the Android API. While `getVersion` and `setVersion` are exposed,
there should not be used and instead, migrations should be performed when opening
the database.

`onCreate`, `onUpgrade`, and `onDowngrade` are called when a `version` is
specified. If the database does not exist, `onCreate` is called. If `onCreate`
is not defined, `onUpgrade` is called instead with `oldVersion` having value 0.
If the database exists and the new version is higher than the current version,
`onUpgrade` is called. Inversely, if the new version is lower than the current
version, `onDowngrade` is called. Try to avoid this by always incrementing the
database version. For the downgrade case, a special `onDatabaseDowngradeDelete`
callback exist that will simply delete the database and call `onCreate` to
create it.

These 3 callbacks are called within a transaction just before the version is set on the database.


```dart
_onCreate(Database db, int version) async {
  // Database is created, create the table
  await db.execute(
    "CREATE TABLE Test (id INTEGER PRIMARY KEY, value TEXT)");
}

_onUpgrade(Database db, int oldVersion, int newVersion) async {
  // Database version is updated, alter the table
  await db.execute("ALTER TABLE Test ADD name TEXT");
}

// Special callback used for onDowngrade here to recreate the database
var db = await openDatabase(path,
  version: 1,
  onCreate: _onCreate,
  onUpgrade: _onUpgrade,
  onDowngrade: onDatabaseDowngradeDelete);
```

See a [complete migration example](migration_example.md)

### Post open callback

For convenience, `onOpen` is called after the database version is set and before `openDatabase` returns.

```dart
_onOpen(Database db) async {
  // Database is open, print its version
  print('db version ${await db.getVersion()}');
}

var db = await openDatabase(
  path,
  onOpen: _onOpen,
);
```
## Read-only

```dart
// open the database in read-only mode
var db = await openReadOnlyDatabase(path);
```

## Handle corruption

Android and iOS handles corruption in a different way:
* on iOS, it fails on first access to the database
* on Android, the existing file is removed.

I don't know yet how to make it consistent without breaking the existing behavior.

It seems that one way to check if a file is a valid database file is to open it in read-only 
and check its version (i.e. sqlite/iOS fails un-consistently on first access of a non-sqlite database).
Before making this a top-level function, more tests would be needed to validate the behavior.

```dart
/// Check if a file is a valid database file
///
/// An empty file is a valid empty sqlite file
Future<bool> isDatabase(String path) async {
  Database db;
  bool isDatabase = false;
  try {
    db = await openReadOnlyDatabase(path);
    int version = await db.getVersion();
    if (version != null) {
      isDatabase = true;
    }
  } catch (_) {} finally {
    await db?.close();
  }
  return isDatabase;
}
```

## Prevent database locked issue

It is strongly suggested to open a database only once. By default a database is open as
a single instance (`singleInstance: true`). i.e. re-opening the same file is safe and it 
will give you the same database.

If you open the same database multiple times using `singleInstance: false`, you might encounter (at least on Android):

    android.database.sqlite.SQLiteDatabaseLockedException: database is locked (code 5)
    
Let's consider the following helper class

```dart
class Helper {
  final String path;
  Helper(this.path);
  Database _db;

  Future<Database> getDb() async {
    if (_db == null) {
      _db = await openDatabase(path);
    }
    return _db;
  }
}
```

Since `openDatabase` is async, there is a race condition risk where openDatabase
might be called twice. You could fix this with the following:

```dart
class Helper {
  final String path;
  Helper(this.path);
  Future<Database> _db;

  Future<Database> getDb() {
    if (_db == null) {
      _db = openDatabase(path);
    }
    return _db;
  }
}
```

If you have some lenghty operations after `openDatabase` before considering it ready for the user
you should protect your code (put here in a private `_initDb()` method from concurrent access:

```dart
class Helper {
  final String path;
  Helper(this.path);
  Future<Database> _db;

  Future<Database> getDb() {
    _db ??= _initDb();
    return _db;
  }

  // Guaranteed to be called only once.
  Future<Database> _initDb() async {
    final db = await openDatabase(this.path);
    // do "tons of stuff in async mode"
    return db;
  }
}
```


## Solving exceptions

If you get exception when opening a database:
- check the [troubleshooting](troubleshooting.md) section
- Make sure the directory where you create the database exists
- Make sure the database path points to an existing database (or nothing) and
  not to a file which is not a sqlite database
- Handle any expected exception in the open callbacks (onCreate/onUpgrade/onConfigure/onOpen)
