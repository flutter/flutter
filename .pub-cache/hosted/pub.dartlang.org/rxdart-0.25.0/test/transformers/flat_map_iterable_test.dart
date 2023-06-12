import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

void main() {
  group('Rx.flatMapIterable', () {
    test('transforms a Stream<Iterable<S>> into individual items', () {
      expect(
          Rx.range(1, 4)
              .flatMapIterable((int i) => Stream<List<int>>.value(<int>[i])),
          emitsInOrder(<dynamic>[1, 2, 3, 4, emitsDone]));
    });
  });
  test('Rx.flatMapIterable accidental broadcast', () async {
    final controller = StreamController<int>();

    final stream = controller.stream
        .flatMapIterable((int i) => Stream<List<int>>.value(<int>[i]));

    stream.listen(null);
    expect(() => stream.listen(null), throwsStateError);

    controller.add(1);
  });
}
