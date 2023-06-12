import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

const channel = MethodChannel('com.tekartik.sqflite');

class MockMethodCall {
  String? expectedMethod;
  dynamic expectedArguments;
  dynamic response;

  @override
  String toString() => '$expectedMethod $expectedArguments $response';
}

class MockScenario {
  MockScenario(List<List> data) {
    methodsCalls = data
        .map((list) => MockMethodCall()
          ..expectedMethod = list[0]?.toString()
          ..expectedArguments = list[1]
          ..response = list[2])
        .toList(growable: false);
  }

  late List<MockMethodCall> methodsCalls;
  var index = 0;
  dynamic exception;

  void end() {
    expect(exception, isNull, reason: '$exception');
    expect(index, methodsCalls.length);
  }
}

MockScenario startScenario(List<List> data) {
  final scenario = MockScenario(data);

  channel.setMockMethodCallHandler((MethodCall methodCall) async {
    final index = scenario.index++;
    // devPrint('$index ${scenario.methodsCalls[index]}');
    final item = scenario.methodsCalls[index];
    try {
      expect(methodCall.method, item.expectedMethod);
      expect(methodCall.arguments, item.expectedArguments);
    } catch (e) {
      scenario.exception ??= '$e $index';
    }
    return item.response;
  });
  return scenario;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('sqflite', () {
    test('open', () async {
      final scenario = startScenario([
        [
          'openDatabase',
          {'path': ':memory:', 'singleInstance': true},
          1
        ],
        [
          'closeDatabase',
          {'id': 1},
          null
        ],
      ]);
      final db = await openDatabase(inMemoryDatabasePath);
      await db.close();
      scenario.end();
    });
    test('open with version', () async {
      final scenario = startScenario([
        [
          'openDatabase',
          {'path': ':memory:', 'singleInstance': true},
          1
        ],
        [
          'query',
          {'sql': 'PRAGMA user_version', 'id': 1},
          // ignore: inference_failure_on_collection_literal
          {}
        ],
        [
          'execute',
          {
            'sql': 'BEGIN EXCLUSIVE',
            'id': 1,
            'transactionId': null,
            'inTransaction': true
          },
          null
        ],
        [
          'query',
          {'sql': 'PRAGMA user_version', 'id': 1},
          // ignore: inference_failure_on_collection_literal
          {}
        ],
        [
          'execute',
          {'sql': 'PRAGMA user_version = 1', 'id': 1},
          null
        ],
        [
          'execute',
          {'sql': 'COMMIT', 'id': 1, 'inTransaction': false},
          null
        ],
        [
          'closeDatabase',
          {'id': 1},
          null
        ],
      ]);
      final db = await openDatabase(inMemoryDatabasePath,
          version: 1, onCreate: (db, version) {});
      await db.close();
      scenario.end();
    });
  });
}
