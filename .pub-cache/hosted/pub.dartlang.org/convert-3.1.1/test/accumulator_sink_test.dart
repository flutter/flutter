// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:convert/convert.dart';
import 'package:test/test.dart';

void main() {
  late AccumulatorSink<int> sink;
  setUp(() {
    sink = AccumulatorSink<int>();
  });

  test("provides access to events as they're added", () {
    expect(sink.events, isEmpty);

    sink.add(1);
    expect(sink.events, equals([1]));

    sink.add(2);
    expect(sink.events, equals([1, 2]));

    sink.add(3);
    expect(sink.events, equals([1, 2, 3]));
  });

  test('clear() clears the events', () {
    sink
      ..add(1)
      ..add(2)
      ..add(3);
    expect(sink.events, equals([1, 2, 3]));

    sink.clear();
    expect(sink.events, isEmpty);

    sink
      ..add(4)
      ..add(5)
      ..add(6);
    expect(sink.events, equals([4, 5, 6]));
  });

  test('indicates whether the sink is closed', () {
    expect(sink.isClosed, isFalse);
    sink.close();
    expect(sink.isClosed, isTrue);
  });

  test("doesn't allow add() to be called after close()", () {
    sink.close();
    expect(() => sink.add(1), throwsStateError);
  });
}
