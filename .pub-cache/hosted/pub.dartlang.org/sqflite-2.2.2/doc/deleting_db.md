# Deleting a database

While you might be enclined to simply delete the file, you should however use
`deleteDatabase` to properly delete a database.

```dart
# Do not call File.delete, it will not work in a hot restart scenario
await File(path).delete();

# Instead do
await deleteDatabase(path);
```

* it will properly close any existing database connection
* it will properly handle the hot-restart scenario which put `SQLite` in a
  weird state (basically the 'dart' side think the database is closed while
  the database is in fact open on the native side)
  
If you call `File.delete`, while you might think it work (i.e. the file does not
exist anymore), since the database might still be opened in a hot restart scenario
the next open will re-use the open connection and at some point will get written
with the old data and `onCreate` will not be called the next time you open
the database.