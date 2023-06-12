import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

void main() {
  test('RangeStream', () async {
    final expected = const [1, 2, 3];
    var count = 0;

    final stream = RangeStream(1, 3);

    stream.listen(expectAsync1((actual) {
      expect(actual, expected[count++]);
    }, count: expected.length));
  });

  test('RangeStream.single.subscription', () async {
    final stream = RangeStream(1, 5);

    stream.listen(null);
    await expectLater(() => stream.listen(null), throwsA(isStateError));
  });

  test('RangeStream.single', () async {
    final stream = RangeStream(1, 1);

    stream.listen(expectAsync1((actual) {
      expect(actual, 1);
    }, count: 1));
  });

  test('RangeStream.reverse', () async {
    final expected = const [3, 2, 1];
    var count = 0;

    final stream = RangeStream(3, 1);

    stream.listen(expectAsync1((actual) {
      expect(actual, expected[count++]);
    }, count: expected.length));
  });

  test('Rx.range', () async {
    final expected = const [1, 2, 3];
    var count = 0;

    final stream = Rx.range(1, 3);

    stream.listen(expectAsync1((actual) {
      expect(actual, expected[count++]);
    }, count: expected.length));
  });
}
