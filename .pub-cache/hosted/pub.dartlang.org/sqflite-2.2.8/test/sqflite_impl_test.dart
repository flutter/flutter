import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/src/factory_impl.dart';
import 'package:sqflite/src/mixin/factory.dart';
import 'package:sqflite/src/sqflite_impl.dart';

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

    test('databaseFactory', () async {
      expect(databaseFactorySqflitePlugin is SqfliteInvokeHandler, isTrue);
    });

    test('supportsConcurrency', () async {
      expect(supportsConcurrency, isFalse);
    });

    test('deprecated', () {
      sqfliteDatabaseFactory = null;
      for (var element in [
        // ignore: unnecessary_statements
        sqfliteDatabaseFactory
      ]) {
        expect(element, isNotNull);
      }
    });
  });
}
