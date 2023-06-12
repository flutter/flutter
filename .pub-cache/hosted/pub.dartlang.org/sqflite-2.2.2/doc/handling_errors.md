# Handling errors & exceptions

Like any database, there is always a risk of native exceptions, I/O corruption, race conditions, flutter platform exceptions, handled and unhandled inner exceptions.
SQLite should answer the best it can to I/O corruption and race conditions.

In theory, any inner exception should come out wrapped in a `DatabaseException` being thrown.

*Personal advice*: avoid exceptions as much as possible

## Handling error when opening the database

Unless you open as read-only, you should not expect any exception. Some people have expected I/O issues on iOS that got
resolved by themselves by restarting the app. Maybe it might be worth trying to catch this exception and try again 1 s later if you
experience this scenario (if so, please share in a github issues).

If you open without doing anything during open callback, open might succeed but the first action would fail as reported
by SQLite. One easy workaround (maybe it should be part of sqflite) would be to trigger a dummy command such as `getVersion()` in `onOpen` even in read-only mode.

During development, it is sometimes very likely that the error thrown by `openDatabase` was thrown from a call made during open callbacks (onCreate, onOpen....).

## Handling SQL error

There could be 2 types of error:
- *Syntax error*: If a SQL command could not be parsed (by `sqflite` or `SQLite`). Here there is not much you can do but looking at the logs and fixing your implementation.
- *SQLite error*: SQLite specific error (Syntax error can be a SQLite error) 
- Unexpected error (I/O error, flutter platform state, sometimes impossible to recover...)

It is hard to catch error consistently on multiple platforms since most of the time we get the error as a text on the native side.

Your best bet is to try on both platform and parse the text accordingly. There are some helpers in `DatabaseException` that do something similar (very basic)
to find out what the error can be:
* `isNoSuchTableError`
* `isSyntaxError`
* `isOpenFailedError`
* `isDatabaseClosedError`
* `isReadOnlyError`
* `isUniqueConstraintError`

Improvements, tested additions are welcome.

For example if we perform the following SQL query if no table exists yet:

```dart
await db.query('Test');
// iOS: Error Domain=FMDatabase Code=19 "UNIQUE constraint failed: Test.name" UserInfo={NSLocalizedDescription=UNIQUE constraint failed: Test.name})
// Android: UNIQUE constraint failed: Test.name (code 2067))
```

This could be caught this way

```dart
try {
  await db.query('Test');
} on DatabaseException catch (e) {
  if (e.isNoSuchTableError()) {
    // ok I knew it
  }
}

```

## Strategy

One personal strategy is to avoid exceptions as much as possible. If any error occurs, it will likely be a developer 
error (SQL commands malformed, invalid input), an error will be logged and it 
will cancel the current transaction; good for testing and reproduce.

Most errors could be avoided however you might have indecies and a `isUniqueContraintError` could be thrown. Here as well you could decide to avoid the potential error by
reading data first and writing updates, everything in a transaction.

```dart
Future<bool> _exists(Transaction txn, Product product) async {
  return firstIntValue(await txn.query('Product',
          columns: ['COUNT(*)'],
          where: 'id = ?',
          whereArgs: [product.id])) ==
      1;
}

Future _update(Transaction txn, Product product) async {
  await txn.update('Product', product.toMap(),
      where: 'id = ?', whereArgs: [product.id]);
}

Future _insert(Transaction txn, Product product) async {
  await txn.insert('Product', product.toMap()..['id'] = product.id);
}

/// Product will saved (updated or inserted) by its id.
Future upsertRecord(Product product) async {
  await db.transaction((txn) async {
    if (await _exists(txn, product)) {
      await _update(txn, product);
    } else {
      await _insert(txn, product);
    }
  });
}

var product = Product()
          ..id = 'table'
          ..title = 'Table';
await upsertRecord(product);
await upsertRecord(product);
// only one record should be present
``` 

or you could try to insert and handle a constraint error:

```dart
Future _update(Product product) async {
  await db.update('Product', product.toMap(),
      where: 'id = ?', whereArgs: [product.id]);
}

Future< _insert(Product product) async {
  await db.insert('Product', product.toMap()..['id'] = product.id);
}

Future upsertRecord(Product product) async {
  try {
    await _insert(product);
  } on DatabaseException catch (e) {
    if (e.isUniqueConstraintError()) {
      await _update(product);
    }
  }
}

var product = Product()
  ..id = 'table'
  ..title = 'Table';
await upsertRecord(product);
await upsertRecord(product);
// only one record should be present
```

In the last example above, there is a short race condition between _insert and _update that depending on your use, should be avoided.

## Concurrency

- Every read/write/transaction operation is protected by a global mutex on the database. Each action runs one after the other, first
  action called, first ran. While it is a conservative solution, due to some
  native implementation, you can design an app which remains fast.
- `transaction` handle the 'all or nothing' scenario. If one command fails (and throws an error), all other commands called during the
  transaction are reverted. You can also throw an error to cancel a transaction.

## Limitations

### SQLiteBlobTooBigException (Row too big to fit into CursorWindow)

There seems to be a limit of (around) 1MB when reading on Android and iOS. I could not find a portable way to allow the developer to change
this limit.

I find the 1MB blob limit a good limitation (firestore has a similar limit) since otherwise performance would be pretty bad.

Solution: reduce the size of your blob or store your data in a external file and only save a reference to it in SQLite.