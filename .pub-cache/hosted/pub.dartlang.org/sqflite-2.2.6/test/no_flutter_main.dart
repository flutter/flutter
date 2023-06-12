import 'dart:async';

import 'package:sqflite/sqlite_api.dart';
import 'package:sqflite/src/mixin/factory.dart';

Future<void> main() async {
  final factory = buildDatabaseFactory(
      invokeMethod: (String method, [Object? arguments]) async {
    dynamic result;
    // ignore: avoid_print
    print('$method: $arguments');
    return result;
  });
  final db = await factory.openDatabase(inMemoryDatabasePath);
  await db.getVersion();
}
