// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart' show nonconst;
import '../flutter_test_alternative.dart';

void main() {
  test('TextSpan equals', () {
    final TextSpan a1 = TextSpan(text: nonconst('a'));
    final TextSpan a2 = TextSpan(text: nonconst('a'));
    final TextSpan b1 = TextSpan(children: <TextSpan>[ a1 ]);
    final TextSpan b2 = TextSpan(children: <TextSpan>[ a2 ]);
    final TextSpan c1 = TextSpan(text: nonconst(null));
    final TextSpan c2 = TextSpan(text: nonconst(null));

    expect(a1 == a2, isTrue);
    expect(b1 == b2, isTrue);
    expect(c1 == c2, isTrue);

    expect(a1 == b2, isFalse);
    expect(b1 == c2, isFalse);
    expect(c1 == a2, isFalse);

    expect(a1 == c2, isFalse);
    expect(b1 == a2, isFalse);
    expect(c1 == b2, isFalse);
  });

  test('TextSpan toStringDeep', () {
    const TextSpan test = TextSpan(
      text: 'a',
      style: TextStyle(
        fontSize: 10.0,
      ),
      children: <TextSpan>[
        TextSpan(
          text: 'b',
          children: <TextSpan>[
            TextSpan(),
          ],
        ),
        null,
        TextSpan(
          text: 'c',
        ),
      ],
    );
    expect(test.toStringDeep(), equals(
      'TextSpan:\n'
      '  inherit: true\n'
      '  size: 10.0\n'
      '  "a"\n'
      '  TextSpan:\n'
      '    "b"\n'
      '    TextSpan:\n'
      '      (empty)\n'
      '  <null child>\n'
      '  TextSpan:\n'
      '    "c"\n'
    ));
  });
}
