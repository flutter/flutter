import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sql.dart';

T? _ambiguate<T>(T? value) => value;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('sqflite', () {
    const channel = MethodChannel('com.tekartik.sqflite');

    final log = <MethodCall>[];
    String? response;

    _ambiguate(TestDefaultBinaryMessengerBinding.instance)!
        .defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      log.add(methodCall);
      return response;
    });

    tearDown(() {
      log.clear();
    });

    test('exported', () {
      expect(ConflictAlgorithm.abort, isNotNull);
    });

    test('escapeName_export', () {
      expect(escapeName('group'), '"group"');
    });

    test('unescapeName_export', () {
      expect(unescapeName('"group"'), 'group');
    });
  });
}
