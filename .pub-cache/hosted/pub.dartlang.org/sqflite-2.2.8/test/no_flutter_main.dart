import 'dart:async';

import 'package:sqflite/sqlite_api.dart';
import 'package:sqflite/src/mixin/factory.dart';

Future<void> main() async {
  final factory = buildDatabaseFactory(
      invokeMethod: (String method, [Object? arguments]) async {
    Object? result;
    // ignore: avoid_print
    print('$method: $arguments');
    if (method == 'openDatabase') {
      result = 1;
    } else if (method == 'query' &&
        (arguments as Map)['sql'] == 'PRAGMA user_version') {
      result = {'user_version': 0};
    }
    return result;
  });
  final db = await factory.openDatabase(inMemoryDatabasePath);
  await db.getVersion();
}
