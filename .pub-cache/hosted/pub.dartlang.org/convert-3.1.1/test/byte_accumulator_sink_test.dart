// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:convert/convert.dart';
import 'package:test/test.dart';

void main() {
  late ByteAccumulatorSink sink;
  setUp(() {
    sink = ByteAccumulatorSink();
  });

  test('provides access to the concatenated bytes', () {
    expect(sink.bytes, isEmpty);

    sink.add([1, 2, 3]);
    expect(sink.bytes, equals([1, 2, 3]));

    sink.addSlice([4, 5, 6, 7, 8], 1, 4, false);
    expect(sink.bytes, equals([1, 2, 3, 5, 6, 7]));
  });

  test('clear() clears the bytes', () {
    sink.add([1, 2, 3]);
    expect(sink.bytes, equals([1, 2, 3]));

    sink.clear();
    expect(sink.bytes, isEmpty);

    sink.add([4, 5, 6]);
    expect(sink.bytes, equals([4, 5, 6]));
  });

  test('indicates whether the sink is closed', () {
    expect(sink.isClosed, isFalse);
    sink.close();
    expect(sink.isClosed, isTrue);
  });

  test('indicates whether the sink is closed via addSlice', () {
    expect(sink.isClosed, isFalse);
    sink.addSlice([], 0, 0, true);
    expect(sink.isClosed, isTrue);
  });

  test("doesn't allow add() to be called after close()", () {
    sink.close();
    expect(() => sink.add([1]), throwsStateError);
  });

  test("doesn't allow addSlice() to be called after close()", () {
    sink.close();
    expect(() => sink.addSlice([], 0, 0, false), throwsStateError);
  });
}
