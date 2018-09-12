// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:quiver/testing/async.dart';
import '../flutter_test_alternative.dart';

import 'capture_output.dart';

void main() {
  test('debugPrint', () {
    expect(
      captureOutput(() { debugPrintSynchronously('Hello, world'); }),
      equals(<String>['Hello, world'])
    );

    expect(
      captureOutput(() { debugPrintSynchronously('Hello, world', wrapWidth: 10); }),
      equals(<String>['Hello,\nworld'])
    );

    for (int i = 0; i < 14; ++i) {
      expect(
        captureOutput(() { debugPrintSynchronously('Hello,   world', wrapWidth: i); }),
        equals(<String>['Hello,\nworld'])
      );
    }

    expect(
      captureOutput(() { debugPrintThrottled('Hello, world'); }),
      equals(<String>['Hello, world'])
    );

    expect(
      captureOutput(() { debugPrintThrottled('Hello, world', wrapWidth: 10); }),
      equals(<String>['Hello,', 'world'])
    );
  });

  test('debugPrint throttling', () {
    FakeAsync().run((FakeAsync async) {
      List<String> log = captureOutput(() {
        debugPrintThrottled('A' * (22 * 1024) + '\nB');
      });
      expect(log.length, 1);
      async.elapse(const Duration(seconds: 2));
      expect(log.length, 2);

      log = captureOutput(() {
        debugPrintThrottled('C' * (22 * 1024));
        debugPrintThrottled('D');
      });

      expect(log.length, 1);
      async.elapse(const Duration(seconds: 2));
      expect(log.length, 2);
    });
  });
}
