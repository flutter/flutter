// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:stream_transform/stream_transform.dart';
import 'package:test/test.dart';

void main() {
  test('forwards only events that match the type', () async {
    var values = Stream.fromIterable([null, 'a', null, 'b']);
    var filtered = values.whereNotNull();
    expect(await filtered.toList(), ['a', 'b']);
  });

  test('can result in empty stream', () async {
    var values = Stream<Object?>.fromIterable([null, null]);
    var filtered = values.whereNotNull();
    expect(await filtered.isEmpty, true);
  });

  test('forwards values to multiple listeners', () async {
    var values = StreamController<Object?>.broadcast();
    var filtered = values.stream.whereNotNull();
    var firstValues = [];
    var secondValues = [];
    filtered
      ..listen(firstValues.add)
      ..listen(secondValues.add);
    values
      ..add(null)
      ..add('a')
      ..add(null)
      ..add('b');
    await Future(() {});
    expect(firstValues, ['a', 'b']);
    expect(secondValues, ['a', 'b']);
  });

  test('closes streams with multiple listeners', () async {
    var values = StreamController<Object?>.broadcast();
    var filtered = values.stream.whereNotNull();
    var firstDone = false;
    var secondDone = false;
    filtered
      ..listen(null, onDone: () => firstDone = true)
      ..listen(null, onDone: () => secondDone = true);
    values
      ..add(null)
      ..add('a');
    await values.close();
    expect(firstDone, true);
    expect(secondDone, true);
  });
}
