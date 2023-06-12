import 'dart:async';

import 'package:test/test.dart';

void main() {
  test('Rx.distinct', () async {
    const expected = 1;

    final stream = Stream.fromIterable(const [expected, expected]).distinct();

    stream.listen(expectAsync1((actual) {
      expect(actual, expected);
    }));
  });
  test('Rx.distinct accidental broadcast', () async {
    final controller = StreamController<int>();

    final stream = controller.stream.distinct();

    stream.listen(null);
    expect(() => stream.listen(null), throwsStateError);

    controller.add(1);
  });
}
