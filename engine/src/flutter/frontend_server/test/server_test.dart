import 'dart:async';

import 'package:frontend_server/server.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:vm/frontend_server.dart' as frontend show CompilerInterface;

class _MockedCompiler extends Mock implements frontend.CompilerInterface {}

Future<int> main() async {
  group('basic', () {
    final frontend.CompilerInterface compiler = _MockedCompiler();

    test('train with mocked compiler completes', () async {
      expect(await starter(<String>['--train'], compiler: compiler), equals(0));
    });
  });
  return 0;
}
