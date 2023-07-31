// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import '../utils.dart';

void main() {
  group('returned Future from expectLater()', () {
    test('completes immediately for a sync matcher', () {
      expect(expectLater(true, isTrue), completes);
    });

    test('contains the expect failure', () {
      expect(expectLater(Future.value(true), completion(isFalse)),
          throwsA(isTestFailure(anything)));
    });

    test('contains an async error', () {
      expect(expectLater(Future.error('oh no'), completion(isFalse)),
          throwsA('oh no'));
    });
  });

  group('an async matcher that fails synchronously', () {
    test('throws synchronously', () {
      expect(() => expect(() {}, throws), throwsA(isTestFailure(anything)));
    });

    test('can be used with synchronous operators', () {
      expect(() {}, isNot(throws));
    });
  });
}
