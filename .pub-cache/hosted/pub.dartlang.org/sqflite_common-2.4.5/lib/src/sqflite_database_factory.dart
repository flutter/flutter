import 'package:meta/meta.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common/src/factory.dart';

SqfliteDatabaseFactory? _databaseFactory;

/// Default database factory.
@visibleForTesting
DatabaseFactory? get databaseFactoryOrNull => _databaseFactory;

/// Change the default factory.
set databaseFactoryOrNull(DatabaseFactory? databaseFactory) {
  if (databaseFactory != null) {
    if (databaseFactory is! SqfliteDatabaseFactory) {
      throw ArgumentError.value(
          databaseFactory, 'databaseFactory', 'Unsupported sqflite factory');
    }
    _databaseFactory = databaseFactory;
  } else {
    /// Unset
    _databaseFactory = null;
  }
}

/// sqflite Default factory.
DatabaseFactory get databaseFactory =>
    _databaseFactory ??
    () {
      throw StateError('''databaseFactory not initialized
databaseFactory is only initialized when using sqflite. When using `sqflite_common_ffi`
You must call `databaseFactory = databaseFactoryFfi;` before using global openDatabase API
''');
    }();

/// Change the default factory.
///
/// Be aware of the potential side effect. Any library using sqflite
/// will have this factory as the default for all operations.
///
/// This setter must be call only once, before any other calls to sqflite.
set databaseFactory(DatabaseFactory? databaseFactory) {
  // Warn when changing. might throw in the future
  if (databaseFactory != null) {
    if (_databaseFactory != null) {
      print('''
*** sqflite warning ***

You are changing sqflite default factory.
Be aware of the potential side effects. Any library using sqflite
will have this factory as the default for all operations.

*** sqflite warning ***
''');
    }
  }
  databaseFactoryOrNull = databaseFactory;
}
