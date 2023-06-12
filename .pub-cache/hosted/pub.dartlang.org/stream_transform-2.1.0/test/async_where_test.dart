// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:stream_transform/stream_transform.dart';
import 'package:test/test.dart';

void main() {
  test('forwards only events that pass the predicate', () async {
    var values = Stream.fromIterable([1, 2, 3, 4]);
    var filtered = values.asyncWhere((e) async => e > 2);
    expect(await filtered.toList(), [3, 4]);
  });

  test('allows predicates that go through event loop', () async {
    var values = Stream.fromIterable([1, 2, 3, 4]);
    var filtered = values.asyncWhere((e) async {
      await Future(() {});
      return e > 2;
    });
    expect(await filtered.toList(), [3, 4]);
  });

  test('allows synchronous predicate', () async {
    var values = Stream.fromIterable([1, 2, 3, 4]);
    var filtered = values.asyncWhere((e) => e > 2);
    expect(await filtered.toList(), [3, 4]);
  });

  test('can result in empty stream', () async {
    var values = Stream.fromIterable([1, 2, 3, 4]);
    var filtered = values.asyncWhere((e) => e > 4);
    expect(await filtered.isEmpty, true);
  });

  test('forwards values to multiple listeners', () async {
    var values = StreamController<int>.broadcast();
    var filtered = values.stream.asyncWhere((e) async => e > 2);
    var firstValues = [];
    var secondValues = [];
    filtered
      ..listen(firstValues.add)
      ..listen(secondValues.add);
    values
      ..add(1)
      ..add(2)
      ..add(3)
      ..add(4);
    await Future(() {});
    expect(firstValues, [3, 4]);
    expect(secondValues, [3, 4]);
  });

  test('closes streams with multiple listeners', () async {
    var values = StreamController.broadcast();
    var predicate = Completer<bool>();
    var filtered = values.stream.asyncWhere((_) => predicate.future);
    var firstDone = false;
    var secondDone = false;
    filtered
      ..listen(null, onDone: () => firstDone = true)
      ..listen(null, onDone: () => secondDone = true);
    values.add(1);
    await values.close();
    expect(firstDone, false);
    expect(secondDone, false);

    predicate.complete(true);
    await Future(() {});
    expect(firstDone, true);
    expect(secondDone, true);
  });

  test('forwards errors emitted by the test callback', () async {
    var errors = [];
    var emitted = [];
    var values = Stream.fromIterable([1, 2, 3, 4]);
    var filtered = values.asyncWhere((e) async {
      await Future(() {});
      if (e.isEven) throw Exception('$e');
      return true;
    });
    var done = Completer();
    filtered.listen(emitted.add, onError: errors.add, onDone: done.complete);
    await done.future;
    expect(emitted, [1, 3]);
    expect(errors.map((e) => '$e'), ['Exception: 2', 'Exception: 4']);
  });
}
