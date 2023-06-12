import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common/src/mixin/import_mixin.dart';
import 'package:test/test.dart';

/// Common open step
var protocolOpenStep = [
  'openDatabase',
  {'path': ':memory:', 'singleInstance': false},
  {'id': 1}
];

/// Common close step
var protocolCloseStep = [
  'closeDatabase',
  {'id': 1},
  null
];

class MockMethodCall {
  String? expectedMethod;
  dynamic expectedArguments;

  /// Response can be an exception
  dynamic response;

  @override
  String toString() => '$expectedMethod $expectedArguments $response';
}

class MockScenario {
  MockScenario(this.factory, List<List> data) {
    methodsCalls = data
        .map((list) => MockMethodCall()
          ..expectedMethod = list[0]?.toString()
          ..expectedArguments = list[1]
          ..response = list[2])
        .toList(growable: false);
  }

  final DatabaseFactory factory;
  late List<MockMethodCall> methodsCalls;
  var index = 0;
  dynamic exception;

  void end() {
    expect(exception, isNull, reason: '$exception');
    expect(index, methodsCalls.length);
  }
}

MockScenario startScenario(List<List> data) {
  late MockScenario scenario;
  final databaseFactoryMock = buildDatabaseFactory(
      tag: 'mock',
      invokeMethod: (String method, [Object? arguments]) async {
        final index = scenario.index++;
        // devPrint('$index ${scenario.methodsCalls[index]}');
        final item = scenario.methodsCalls[index];
        try {
          expect(method, item.expectedMethod);
          expect(arguments, item.expectedArguments);
        } catch (e) {
          // devPrint(e);
          scenario.exception ??= '$e $index';
        }
        if (item.response is DatabaseException) {
          throw item.response as DatabaseException;
        }
        return item.response;
      });
  scenario = MockScenario(databaseFactoryMock, data);
  return scenario;
}
