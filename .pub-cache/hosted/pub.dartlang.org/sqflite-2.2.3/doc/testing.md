# Unit test

Currently testing using the package `test` or `flutter_test` is not supported. Testing using sqflite requires running
on a real supported platforms. That's unfortunately an issue for all plugins where mocking cannot easily be done.

Possible alternative (not as good though) are:

## Using flutter_driver

A solution is to use flutter driver. Look at the example app:

```bash
flutter driver --target=test_driver/main.dart
```

## Using sqflite_common_ffi

This allow running unit tests using the desktop sqlite version installed. Be aware that the sqlite version used could be
different (and likely more recent).

Simple flutter test example:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Initialize sqflite for test.
void sqfliteTestInit() {
  // Initialize ffi implementation
  sqfliteFfiInit();
  // Set global factory
  databaseFactory = databaseFactoryFfi;
}

Future main() async {
  sqfliteTestInit();
  test('simple', () async {
    var db = await openDatabase(inMemoryDatabasePath);
    await db.execute('''
      CREATE TABLE Product (
        id INTEGER PRIMARY KEY,
        title TEXT
      )
  ''');
    await db.insert('Product', <String, Object?>{'title': 'Product 1'});
    await db.insert('Product', <String, Object?>{'title': 'Product 2'});

    var result = await db.query('Product');
    expect(result, [
      {'id': 1, 'title': 'Product 1'},
      {'id': 2, 'title': 'Product 2'}
    ]);
    await db.close();
  });
}
```
More info on [sqflite_common_ffi](https://github.com/tekartik/sqflite/tree/master/sqflite_common_ffi).

### Writing widget test

There seems to be several restrictions in widget test. One solution here is to use the ffi implementation
without isolate:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Initialize ffi implementation
  sqfliteFfiInit();
  // Set global factory, do not use isolate here
  databaseFactory = databaseFactoryFfiNoIsolate;

  testWidgets('Test sqflite database', (WidgetTester tester) async {
    var db = await openDatabase(inMemoryDatabasePath, version: 1,
        onCreate: (db, version) async {
      await db
          .execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, value TEXT)');
    });
    // Insert some data
    await db.insert('Test', {'value': 'my_value'});

    // Check content
    expect(await db.query('Test'), [
      {'id': 1, 'value': 'my_value'}
    ]);

    await db.close();
  });
}
```
