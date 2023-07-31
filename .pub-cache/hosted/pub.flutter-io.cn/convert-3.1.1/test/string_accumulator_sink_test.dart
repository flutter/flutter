// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:convert/convert.dart';
import 'package:test/test.dart';

void main() {
  late StringAccumulatorSink sink;
  setUp(() {
    sink = StringAccumulatorSink();
  });

  test('provides access to the concatenated string', () {
    expect(sink.string, isEmpty);

    sink.add('foo');
    expect(sink.string, equals('foo'));

    sink.addSlice(' bar baz', 1, 4, false);
    expect(sink.string, equals('foobar'));
  });

  test('clear() clears the string', () {
    sink.add('foo');
    expect(sink.string, equals('foo'));

    sink.clear();
    expect(sink.string, isEmpty);

    sink.add('bar');
    expect(sink.string, equals('bar'));
  });

  test('indicates whether the sink is closed', () {
    expect(sink.isClosed, isFalse);
    sink.close();
    expect(sink.isClosed, isTrue);
  });

  test('indicates whether the sink is closed via addSlice', () {
    expect(sink.isClosed, isFalse);
    sink.addSlice('', 0, 0, true);
    expect(sink.isClosed, isTrue);
  });

  test("doesn't allow add() to be called after close()", () {
    sink.close();
    expect(() => sink.add('x'), throwsStateError);
  });

  test("doesn't allow addSlice() to be called after close()", () {
    sink.close();
    expect(() => sink.addSlice('', 0, 0, false), throwsStateError);
  });
}
