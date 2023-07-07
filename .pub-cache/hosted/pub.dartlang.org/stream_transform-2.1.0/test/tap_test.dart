// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:stream_transform/stream_transform.dart';
import 'package:test/test.dart';

void main() {
  test('calls function for values', () async {
    var valuesSeen = [];
    var stream = Stream.fromIterable([1, 2, 3]);
    await stream.tap(valuesSeen.add).last;
    expect(valuesSeen, [1, 2, 3]);
  });

  test('forwards values', () async {
    var stream = Stream.fromIterable([1, 2, 3]);
    var values = await stream.tap((_) {}).toList();
    expect(values, [1, 2, 3]);
  });

  test('calls function for errors', () async {
    dynamic error;
    var source = StreamController();
    source.stream.tap((_) {}, onError: (e, st) {
      error = e;
    }).listen((_) {}, onError: (_) {});
    source.addError('error');
    await Future(() {});
    expect(error, 'error');
  });

  test('forwards errors', () async {
    dynamic error;
    var source = StreamController();
    source.stream.tap((_) {}, onError: (e, st) {}).listen((_) {}, onError: (e) {
      error = e;
    });
    source.addError('error');
    await Future(() {});
    expect(error, 'error');
  });

  test('calls function on done', () async {
    var doneCalled = false;
    var source = StreamController();
    source.stream.tap((_) {}, onDone: () {
      doneCalled = true;
    }).listen((_) {});
    await source.close();
    expect(doneCalled, true);
  });

  test('forwards only once with multiple listeners on a broadcast stream',
      () async {
    var dataCallCount = 0;
    var source = StreamController.broadcast();
    source.stream.tap((_) {
      dataCallCount++;
    })
      ..listen((_) {})
      ..listen((_) {});
    source.add(1);
    await Future(() {});
    expect(dataCallCount, 1);
  });

  test(
      'forwards errors only once with multiple listeners on a broadcast stream',
      () async {
    var errorCallCount = 0;
    var source = StreamController.broadcast();
    source.stream.tap((_) {}, onError: (_, __) {
      errorCallCount++;
    })
      ..listen((_) {}, onError: (_, __) {})
      ..listen((_) {}, onError: (_, __) {});
    source.addError('error');
    await Future(() {});
    expect(errorCallCount, 1);
  });

  test('calls onDone only once with multiple listeners on a broadcast stream',
      () async {
    var doneCallCount = 0;
    var source = StreamController.broadcast();
    source.stream.tap((_) {}, onDone: () {
      doneCallCount++;
    })
      ..listen((_) {})
      ..listen((_) {});
    await source.close();
    expect(doneCallCount, 1);
  });

  test('forwards values to multiple listeners', () async {
    var source = StreamController.broadcast();
    var emittedValues1 = [];
    var emittedValues2 = [];
    source.stream.tap((_) {})
      ..listen(emittedValues1.add)
      ..listen(emittedValues2.add);
    source.add(1);
    await Future(() {});
    expect(emittedValues1, [1]);
    expect(emittedValues2, [1]);
  });

  test('allows null callback', () async {
    var stream = Stream.fromIterable([1, 2, 3]);
    await stream.tap(null).last;
  });
}
