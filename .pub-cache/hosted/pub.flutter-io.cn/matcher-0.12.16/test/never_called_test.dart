// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:term_glyph/term_glyph.dart' as glyph;
import 'package:test/test.dart';
import 'package:test_api/hooks_testing.dart';

import 'utils_new.dart';

void main() {
  setUpAll(() {
    glyph.ascii = true;
  });

  test("doesn't throw if it isn't called", () async {
    var monitor = await TestCaseMonitor.run(() {
      const Stream.empty().listen(neverCalled);
    });

    expectTestPassed(monitor);
  });

  group("if it's called", () {
    test('throws', () async {
      var monitor = await TestCaseMonitor.run(() {
        neverCalled();
      });

      expectTestFailed(
          monitor,
          'Callback should never have been called, but it was called with no '
          'arguments.');
    });

    test('pretty-prints arguments', () async {
      var monitor = await TestCaseMonitor.run(() {
        neverCalled(1, 'foo\nbar');
      });

      expectTestFailed(
          monitor,
          'Callback should never have been called, but it was called with:\n'
          '* <1>\n'
          "* 'foo\\n'\n"
          "    'bar'");
    });

    test('keeps the test alive', () async {
      var monitor = await TestCaseMonitor.run(() {
        pumpEventQueue(times: 10).then(neverCalled);
      });

      expectTestFailed(
          monitor,
          'Callback should never have been called, but it was called with:\n'
          '* <null>');
    });

    test("can't be caught", () async {
      var monitor = await TestCaseMonitor.run(() {
        try {
          neverCalled();
        } catch (_) {
          // Do nothing.
        }
      });

      expectTestFailed(
          monitor,
          'Callback should never have been called, but it was called with '
          'no arguments.');
    });
  });
}
