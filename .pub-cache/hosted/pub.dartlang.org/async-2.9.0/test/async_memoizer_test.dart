// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async/async.dart';
import 'package:test/test.dart';

void main() {
  late AsyncMemoizer cache;
  setUp(() => cache = AsyncMemoizer());

  test('runs the function only the first time runOnce() is called', () async {
    var count = 0;
    expect(await cache.runOnce(() => count++), equals(0));
    expect(count, equals(1));

    expect(await cache.runOnce(() => count++), equals(0));
    expect(count, equals(1));
  });

  test('forwards the return value from the function', () async {
    expect(cache.future, completion(equals('value')));
    expect(cache.runOnce(() => 'value'), completion(equals('value')));
    expect(cache.runOnce(() {}), completion(equals('value')));
  });

  test('forwards the return value from an async function', () async {
    expect(cache.future, completion(equals('value')));
    expect(cache.runOnce(() async => 'value'), completion(equals('value')));
    expect(cache.runOnce(() {}), completion(equals('value')));
  });

  test('forwards the error from an async function', () async {
    expect(cache.future, throwsA('error'));
    expect(cache.runOnce(() async => throw 'error'), throwsA('error'));
    expect(cache.runOnce(() {}), throwsA('error'));
  });
}
