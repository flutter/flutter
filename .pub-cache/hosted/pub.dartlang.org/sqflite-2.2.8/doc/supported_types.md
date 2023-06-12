# Supported types

The API offers a way to save a record as map of type `Map<String, Object?>`. This map cannot be an
arbitrary map:
- Keys are column in a table (declared when creating the table)
- Values are field values in the record of type `num`, `String` or `Uint8List`

Nested content is not supported. For example, the following simple map is not supported:

```dart
{
  "title": "Table",
  "size": {"width": 80, "height": 80}
}
```

It should be flattened. One solution is to modify the map structure:

```sql
CREATE TABLE Product (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT,
  width INTEGER,
  height INTEGER)
```

```dart
{"title": "Table", "width": 80, "height": 80}
```

Another solution is to encoded nested maps and lists as json (or other format), declaring the column
as a String.


```sql
CREATE TABLE Product (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT,
  size TEXT
)

```
```dart
{
  'title': 'Table',
  'size': '{"width":80,"height":80}'
};
```

## Supported SQLite types

No validity check is done on values yet so please avoid non supported types [https://www.sqlite.org/datatype3.html](https://www.sqlite.org/datatype3.html)

`DateTime` is not a supported SQLite type. Personally I store them as 
int (millisSinceEpoch) or string (iso8601). SQLite `TIMESTAMP` type sometimes requires using [date functions](https://www.sqlite.org/lang_datefunc.html). 
`TIMESTAMP` values are read as `String` that the application needs to parse.

`bool` is not a supported SQLite type. Use `INTEGER` and 0 and 1 values.

### INTEGER

* SQLite type: `INTEGER`
* Dart type: `int`
* Supported values: from -2^63 to 2^63 - 1

### REAL

* SQLite type: `REAL`
* Dart type: `num`

### TEXT

* SQLite type: `TEXT`
* Dart type: `String`

### BLOB

* SQLite typ: `BLOB`
* Dart type: `Uint8List`

On Android blob lookup does not work when using `Uint8List` as dart type in a query such as:

```dart
final id = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
await db.insert('test', {'id': id, 'value': 1});
var result = await db.query('test', where: 'id = ?', whereArgs: [id]);
```

This would lead to an empty result on Android. Native implementation can not handle this in a proper way.
The solution is to use the [`hex()` SQLite function](https://sqlite.org/lang_corefunc.html#hex).

```dart
import 'package:sqflite_common/utils/utils.dart' as utils;

result = await db.query('test', where: 'hex(id) = ?', whereArgs: [utils.hex(id)]);
```

```dart
final db = await openDatabase(
  inMemoryDatabasePath,
  version: 1,
  onCreate: (db, version) async {
    await db.execute(
      'CREATE TABLE test (id BLOB, value INTEGER)',
    );
  },
);
final id = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
await db.insert('test', {'id': id, 'value': 1});
var result = await db.query('test', where: 'id = ?', whereArgs: [id]);
print('regular blob lookup (failing on Android)): $result');

// The compatible way to lookup for BLOBs (even work on Android) using the hex function
result = await db.query('test', where: 'hex(id) = ?', whereArgs: [utils.hex(id)]);
print('correct blob lookup: $result');

expect(result.first['value'], 1);
```
