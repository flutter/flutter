# Dev tips

## Debugging

Unfortunately at this point, we cannot use sqflite in unit test.
Here are some debugging tips when you encounter issues:

### Turn on SQL console logging

Temporarily turn on SQL logging on the console by adding the following call in your code before opening the first database

````dart
import 'package:sqflite_common/sqflite_dev.dart';
import 'package:sqflite/sqflite.dart';

Future<void> main() async {
  // Turn logging on
  await databaseFactory.setLogLevel(sqfliteLogLevelVerbose);
}
````

This call is `deprecated` on purpose to prevent keeping it in your app

### List existing tables

This will print all existing tables, views, index, trigger and their schema (`CREATE` statement).
You might see some system table (`sqlite_sequence` as well as `android_metadata` on Android)


````dart
print(await db.query("sqlite_master"));
````

### Dump a table content

you can simply dump an existing table content:

````dart
print(await db.query("my_table"));
````

## Unit tests

Errors in SQL statement are sometimes hard to debug, especially during migration where the status/schema
of the database can change.

As much as you can, try to extract your database logic using an abstract databaseFactory and database path
to allow unit tests using FFI during development:

Setup in `pubspec.yaml`:

```yaml
dev_dependencies:
  sqflite_common_ffi:
```

```dart
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';

void main() {
  // Init ffi loader if needed.
  sqfliteFfiInit();
  test('MyUnitTest', () async {
    var factory = databaseFactoryFfi;
    var db = await factory.openDatabase(inMemoryDatabasePath);

    // Should fail table does not exists
    try {
      await db.query('Test');
    } on DatabaseException catch (e) {
      // no such table: Test
      expect(e.isNoSuchTableError('Test'), isTrue);
      print(e.toString());
    }

    // Ok
    await db.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY)');
    await db.execute('ALTER TABLE Test ADD COLUMN name TEXT');
    // should succeed, but empty
    expect(await db.query('Test'), []);

    await db.close();
  });
}
```
## Extract SQLite database on Android

In Android Studio (> 3.0.1)
* Open `Device File Explorer via View > Tool Windows > Device File Explorer`
* Go to `data/data/<package_name>/databases`, where `<package_name>` is the name of your package.
  Location might depends how the path was specified (assuming here that are using `getDatabasesPath` to get its base location)
* Right click on the database and select Save As.... Save it anywhere you want on your PC.

## Enable WAL on Android

WAL is disabled by default on Android. Since sqflite v2.0.4-dev.1 You can turn it on by declaring the 
following in you app manifest (in the application object):

```xml
<application>
  ...
  <!-- Enable WAL -->
  <meta-data
    android:name="com.tekartik.sqflite.wal_enabled"
    android:value="true" />
  ...
</application>
```

Alternatively a more conservative (multiplatform) way is to call during onConfigure:

```db
await db.execute('PRAGMA journal_mode=WAL')
```