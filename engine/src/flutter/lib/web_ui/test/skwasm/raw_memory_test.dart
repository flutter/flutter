// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine/skwasm/skwasm_impl.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('withStackScope', () {
    test('throws AssertionError when closure is async', () {
      expect(
        () => withStackScope((scope) async {
          return 1;
        }),
        throwsA(
          isA<AssertionError>().having(
            (e) => e.message,
            'message',
            contains('withStackScope() closure returned a Future'),
          ),
        ),
      );
    });

    test('works with synchronous closure', () {
      final int result = withStackScope((scope) {
        return 42;
      });
      expect(result, 42);
    });
  });
}
