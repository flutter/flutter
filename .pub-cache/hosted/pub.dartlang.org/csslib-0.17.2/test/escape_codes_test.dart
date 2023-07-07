import 'package:csslib/parser.dart';
import 'package:test/test.dart';

import 'testing.dart';

void main() {
  final errors = <Message>[];

  tearDown(() {
    errors.clear();
  });

  group('handles escape codes', () {
    group('in an identifier', () {
      test('with trailing space', () {
        final selectorAst = selector(r'.\35 00px', errors: errors);
        expect(errors, isEmpty);
        expect(compactOutput(selectorAst), r'.\35 00px');
      });

      test('in an attribute selector value', () {
        final selectorAst = selector(r'[elevation=\31]', errors: errors);
        expect(errors, isEmpty);
        expect(compactOutput(selectorAst), r'[elevation=\31]');
      });
    });
  });
}
