// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/painting.dart';

import 'package:test/test.dart';

void main() {
  test('TextSpan equals', () {
    TextSpan a1 = new TextSpan(text: 'a'); // ignore: prefer_const_constructor
    TextSpan a2 = new TextSpan(text: 'a'); // ignore: prefer_const_constructor
    TextSpan b1 = new TextSpan(children: <TextSpan>[ a1 ]);
    TextSpan b2 = new TextSpan(children: <TextSpan>[ a2 ]);
    TextSpan c1 = new TextSpan(); // ignore: prefer_const_constructor
    TextSpan c2 = new TextSpan(); // ignore: prefer_const_constructor

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

  test('TextSpan', () {
    final TextSpan test = const TextSpan(
      text: 'a',
      style: const TextStyle(
        fontSize: 10.0
      ),
      children: const <TextSpan>[
        const TextSpan(
          text: 'b',
          children: const <TextSpan>[
            const TextSpan()
          ]
        ),
        null,
        const TextSpan(
          text: 'c'
        ),
      ]
    );
    expect(test.toString(), equals(
      'TextSpan:\n'
      '  inherit: true\n'
      '  size: 10.0\n'
      '  "a"\n'
      '  TextSpan:\n'
      '    "b"\n'
      '    TextSpan:\n'
      '      (empty)\n'
      '  <null>\n'
      '  TextSpan:\n'
      '    "c"\n'
    ));
  });
}
