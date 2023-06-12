import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common/src/constant.dart';
import 'package:sqflite_common/src/factory_mixin.dart';
import 'package:sqflite_common/src/mixin/factory.dart';
import 'package:test/test.dart';

import 'src_mixin_test.dart';

void main() {
  group('mixin_factory', () {
    test('public', () {
      // ignore: unnecessary_statements
      buildDatabaseFactory;
      // ignore: unnecessary_statements
      SqfliteInvokeHandler;
    });
    test('buildDatabaseFactory', () async {
      final methods = <String>[];
      final factory = buildDatabaseFactory(
          tag: 'mock',
          invokeMethod: (String method, [dynamic arguments]) async {
            final dynamic result = mockResult(method);
            methods.add(method);
            return result;
          });
      expect((factory as SqfliteDatabaseFactoryMixin).tag, 'mock');
      // ignore: unnecessary_type_check
      expect(factory is SqfliteInvokeHandler, isTrue);
      await factory.openDatabase(inMemoryDatabasePath);
      expect(methods, <String>['openDatabase']);
    });
  });
}
