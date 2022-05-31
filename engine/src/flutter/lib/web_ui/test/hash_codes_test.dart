// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: deprecated_member_use_from_same_package

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/ui.dart';

// The biggest integer value that can be represented in JavaScript is 1 << 53.
// However, the 1 << 53 expression cannot be used in JavaScript because that
// would apply the bitwise shift to a "number" (i.e. float64), which is
// meaningless. Instead, a decimal literal is used here.
const int _kBiggestExactJavaScriptInt = 9007199254740992;

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  test('hashValues can hash lots of huge values effectively', () {
    expect(
      hashValues(
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
      ),
      496984395,
    );
    // Hash a slightly smaller number to verify that the hash code is different.
    expect(
      hashValues(
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt - 1,
      ),
      455584273,
    );
  });

  test('hashList can hash lots of huge values effectively', () {
    expect(
      hashList(<int>[
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
      ]),
      496984395,
    );
    // Hash a slightly smaller number to verify that the hash code is different.
    expect(
      hashList(<int>[
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt,
        _kBiggestExactJavaScriptInt - 1,
      ]),
      455584273,
    );
  });
}
