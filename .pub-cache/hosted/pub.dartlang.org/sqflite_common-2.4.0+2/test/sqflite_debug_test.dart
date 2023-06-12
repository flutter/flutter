import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common/src/constant.dart';
import 'package:sqflite_common/src/method_call.dart';
import 'package:sqflite_common/src/mixin/factory.dart';
import 'package:test/test.dart';

var logs = <SqfliteMethodCall>[];
var databaseFactoryMock = buildDatabaseFactory(
    tag: 'mock',
    invokeMethod: (method, [arguments]) async {
      logs.add(SqfliteMethodCall(method, arguments));
      if (method == methodGetDatabasesPath) {
        return 'mock_path';
      }
    });

void main() {
  test('simple sqflite example', () async {
    logs.clear();
    // ignore: deprecated_member_use_from_same_package
    await databaseFactoryMock.debugSetLogLevel(sqfliteLogLevelVerbose);
    expect(logs.map((log) => log.toMap()), [
      {
        'method': 'options',
        'arguments': {'logLevel': 2}
      }
    ]);
  });
  test('databasesPath', () async {
    final oldDatabasePath = await databaseFactoryMock.getDatabasesPath();
    try {
      await databaseFactoryMock.setDatabasesPath('.');
      final path = await databaseFactoryMock.getDatabasesPath();
      expect(path, '.');
    } finally {
      await databaseFactoryMock.setDatabasesPath(oldDatabasePath);
    }
  });
}
