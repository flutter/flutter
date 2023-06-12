import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

import 'utils/matchers.dart';

void main() {
  const buffer = 'a\nc';
  const context = Context(buffer, 0);
  test('context', () {
    expect(context.buffer, buffer);
    expect(context.position, 0);
    expect(context.toString(), 'Context[1:1]');
  });
  group('success', () {
    test('default', () {
      final success = context.success('result');
      expect(success.buffer, buffer);
      expect(success.position, 0);
      expect(success.value, 'result');
      expect(() => success.message, throwsA(isUnsupportedError));
      expect(success.isSuccess, isTrue);
      expect(success.isFailure, isFalse);
      expect(success.toString(), 'Success[1:1]: result');
    });
    test('with position', () {
      final success = context.success('result', 2);
      expect(success.buffer, buffer);
      expect(success.position, 2);
      expect(success.value, 'result');
      expect(() => success.message, throwsA(isUnsupportedError));
      expect(success.isSuccess, isTrue);
      expect(success.isFailure, isFalse);
      expect(success.toString(), 'Success[2:1]: result');
    });
    test('with mapping', () {
      final success = context.success('result', 2).map((value) {
        expect(value, 'result');
        return 123;
      });
      expect(success.buffer, buffer);
      expect(success.position, 2);
      expect(success.value, 123);
      expect(() => success.message, throwsA(isUnsupportedError));
      expect(success.isSuccess, isTrue);
      expect(success.isFailure, isFalse);
      expect(success.toString(), 'Success[2:1]: 123');
    });
  });
  group('failure', () {
    test('default', () {
      final failure = context.failure('error');
      expect(failure.buffer, buffer);
      expect(failure.position, 0);
      expect(
          () => failure.value,
          throwsA(isParserException
              .having((error) => error.failure, 'failure', same(failure))
              .having((error) => error.message, 'message', 'error')
              .having((error) => error.offset, 'offset', 0)
              .having((error) => error.source, 'source', same(buffer))
              .having(
                  (error) => error.toString(), 'toString', 'error at 1:1')));
      expect(failure.message, 'error');
      expect(failure.isSuccess, isFalse);
      expect(failure.isFailure, isTrue);
      expect(failure.toString(), 'Failure[1:1]: error');
    });
    test('with position', () {
      final failure = context.failure('error', 2);
      expect(failure.buffer, buffer);
      expect(failure.position, 2);
      expect(
          () => failure.value,
          throwsA(isParserException
              .having((error) => error.failure, 'failure', same(failure))
              .having((error) => error.message, 'message', 'error')
              .having((error) => error.offset, 'offset', 2)
              .having((error) => error.source, 'source', same(buffer))
              .having(
                  (error) => error.toString(), 'toString', 'error at 2:1')));
      expect(failure.message, 'error');
      expect(failure.isSuccess, isFalse);
      expect(failure.isFailure, isTrue);
      expect(failure.toString(), 'Failure[2:1]: error');
    });
    test('with mapping', () {
      final failure = context
          .failure('error', 2)
          .map((value) => fail('Not expected to be called'));
      expect(failure.buffer, buffer);
      expect(failure.position, 2);
      expect(
          () => failure.value,
          throwsA(isParserException
              .having((error) => error.failure, 'failure', same(failure))
              .having((error) => error.message, 'message', 'error')
              .having((error) => error.offset, 'offset', 2)
              .having((error) => error.source, 'source', same(buffer))
              .having(
                  (error) => error.toString(), 'toString', 'error at 2:1')));
      expect(failure.message, 'error');
      expect(failure.isSuccess, isFalse);
      expect(failure.isFailure, isTrue);
      expect(failure.toString(), 'Failure[2:1]: error');
    });
  });
}
