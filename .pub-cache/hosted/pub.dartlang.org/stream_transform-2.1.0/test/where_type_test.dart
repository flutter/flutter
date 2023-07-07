// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:stream_transform/stream_transform.dart';
import 'package:test/test.dart';

void main() {
  test('forwards only events that match the type', () async {
    var values = Stream.fromIterable([1, 'a', 2, 'b']);
    var filtered = values.whereType<String>();
    expect(await filtered.toList(), ['a', 'b']);
  });

  test('can result in empty stream', () async {
    var values = Stream.fromIterable([1, 2, 3, 4]);
    var filtered = values.whereType<String>();
    expect(await filtered.isEmpty, true);
  });

  test('forwards values to multiple listeners', () async {
    var values = StreamController.broadcast();
    var filtered = values.stream.whereType<String>();
    var firstValues = [];
    var secondValues = [];
    filtered
      ..listen(firstValues.add)
      ..listen(secondValues.add);
    values
      ..add(1)
      ..add('a')
      ..add(2)
      ..add('b');
    await Future(() {});
    expect(firstValues, ['a', 'b']);
    expect(secondValues, ['a', 'b']);
  });

  test('closes streams with multiple listeners', () async {
    var values = StreamController.broadcast();
    var filtered = values.stream.whereType<String>();
    var firstDone = false;
    var secondDone = false;
    filtered
      ..listen(null, onDone: () => firstDone = true)
      ..listen(null, onDone: () => secondDone = true);
    values
      ..add(1)
      ..add('a');
    await values.close();
    expect(firstDone, true);
    expect(secondDone, true);
  });
}
