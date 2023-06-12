// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:term_glyph/term_glyph.dart' as glyph;
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  setUpAll(() {
    glyph.ascii = true;
  });

  test("doesn't throw if it isn't called", () async {
    var liveTest = await runTestBody(() {
      const Stream.empty().listen(neverCalled);
    });

    expectTestPassed(liveTest);
  });

  group("if it's called", () {
    test('throws', () async {
      var liveTest = await runTestBody(() {
        neverCalled();
      });

      expectTestFailed(
          liveTest,
          'Callback should never have been called, but it was called with no '
          'arguments.');
    });

    test('pretty-prints arguments', () async {
      var liveTest = await runTestBody(() {
        neverCalled(1, 'foo\nbar');
      });

      expectTestFailed(
          liveTest,
          'Callback should never have been called, but it was called with:\n'
          '* <1>\n'
          "* 'foo\\n'\n"
          "    'bar'");
    });

    test('keeps the test alive', () async {
      var liveTest = await runTestBody(() {
        pumpEventQueue(times: 10).then(neverCalled);
      });

      expectTestFailed(
          liveTest,
          'Callback should never have been called, but it was called with:\n'
          '* <null>');
    });

    test("can't be caught", () async {
      var liveTest = await runTestBody(() {
        try {
          neverCalled();
        } catch (_) {
          // Do nothing.
        }
      });

      expectTestFailed(
          liveTest,
          'Callback should never have been called, but it was called with '
          'no arguments.');
    });
  });
}
