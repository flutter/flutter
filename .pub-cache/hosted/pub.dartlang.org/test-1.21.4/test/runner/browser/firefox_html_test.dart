// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('firefox')
import 'dart:html';

import 'package:test/test.dart';

void main() {
  // Regression test for #274. Firefox doesn't compute styles within hidden
  // iframes (https://bugzilla.mozilla.org/show_bug.cgi?id=548397), so we have
  // to do some special stuff to make sure tests that care about that work.
  test('getComputedStyle() works', () {
    expect(document.body!.getComputedStyle(), isNotNull);
  });
}
