// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';

import '../common/test_initialization.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  setUpUnitTests();

  test('Extract unicode info', () {
    const text =
        'World domination is such an ugly phrase - \nI prefer to call it world optimisation.';

    /*
0: grapheme softBreak word
1: grapheme
2: grapheme
3: grapheme
4: grapheme
5: whitespace grapheme word
6: grapheme softBreak word
7: grapheme
8: grapheme
9: grapheme
10: grapheme
11: grapheme
12: grapheme
13: grapheme
14: grapheme
15: grapheme
16: whitespace grapheme word
17: grapheme softBreak word
18: grapheme
19: whitespace grapheme word
20: grapheme softBreak word
21: grapheme
22: grapheme
23: grapheme
24: whitespace grapheme word
25: grapheme softBreak word
26: grapheme
27: whitespace grapheme word
28: grapheme softBreak word
29: grapheme
30: grapheme
31: grapheme
32: whitespace grapheme word
33: grapheme softBreak word
34: grapheme
35: grapheme
36: grapheme
37: grapheme
38: grapheme
39: whitespace grapheme word
40: grapheme softBreak word
41: whitespace grapheme word
42: whitespace grapheme word
43: grapheme hardBreak word
44: whitespace grapheme word
45: grapheme softBreak word
46: grapheme
47: grapheme
48: grapheme
49: grapheme
50: grapheme
51: whitespace grapheme word
52: grapheme softBreak word
53: grapheme
54: whitespace grapheme word
55: grapheme softBreak word
56: grapheme
57: grapheme
58: grapheme
59: whitespace grapheme word
60: grapheme softBreak word
61: grapheme
62: whitespace grapheme word
63: grapheme softBreak word
64: grapheme
65: grapheme
66: grapheme
67: grapheme
68: whitespace grapheme word
69: grapheme softBreak word
70: grapheme
71: grapheme
72: grapheme
73: grapheme
74: grapheme
75: grapheme
76: grapheme
77: grapheme
78: grapheme
79: grapheme
80: grapheme
81: grapheme word
82: grapheme softBreak word
*/

    final codeUnitFlags = AllCodeUnitFlags(text);
    for (var i = 0; i < text.length; i++) {
      expect(
        codeUnitFlags.hasFlag(i, CodeUnitFlag.grapheme),
        isTrue,
        reason: 'Expected grapheme start at index $i',
      );
      if (i == 0 ||
          i == 6 ||
          i == 17 ||
          i == 20 ||
          i == 25 ||
          i == 28 ||
          i == 33 ||
          i == 40 ||
          i == 45 ||
          i == 52 ||
          i == 55 ||
          i == 60 ||
          i == 63 ||
          i == 69 ||
          i == 82) {
        expect(
          codeUnitFlags.hasFlag(i, CodeUnitFlag.softLineBreak),
          isTrue,
          reason: 'Expected soft line break at index $i',
        );
      } else {
        expect(
          codeUnitFlags.hasFlag(i, CodeUnitFlag.softLineBreak),
          isFalse,
          reason: 'Expected no soft line break at index $i',
        );
      }
      if (i == 43) {
        expect(
          codeUnitFlags.hasFlag(i, CodeUnitFlag.hardLineBreak),
          isTrue,
          reason: 'Expected hard line break at index $i',
        );
      } else {
        expect(
          codeUnitFlags.hasFlag(i, CodeUnitFlag.hardLineBreak),
          isFalse,
          reason: 'Expected no hard line break at index $i',
        );
      }
      if (i == 0 ||
          i == 5 ||
          i == 6 ||
          i == 16 ||
          i == 17 ||
          i == 19 ||
          i == 20 ||
          i == 24 ||
          i == 25 ||
          i == 27 ||
          i == 28 ||
          i == 32 ||
          i == 33 ||
          i == 39 ||
          i == 40 ||
          i == 41 ||
          i == 42 ||
          i == 43 ||
          i == 44 ||
          i == 45 ||
          i == 51 ||
          i == 52 ||
          i == 54 ||
          i == 55 ||
          i == 59 ||
          i == 60 ||
          i == 62 ||
          i == 63 ||
          i == 68 ||
          i == 69 ||
          i == 81 ||
          i == 82) {
        expect(
          codeUnitFlags.hasFlag(i, CodeUnitFlag.wordBreak),
          isTrue,
          reason: 'Expected word break at index $i',
        );
      } else {
        expect(
          codeUnitFlags.hasFlag(i, CodeUnitFlag.wordBreak),
          isFalse,
          reason: 'Expected no word break at index $i',
        );
      }
      if (i == 5 ||
          i == 16 ||
          i == 19 ||
          i == 24 ||
          i == 27 ||
          i == 32 ||
          i == 39 ||
          i == 41 ||
          i == 42 ||
          i == 44 ||
          i == 51 ||
          i == 54 ||
          i == 59 ||
          i == 62 ||
          i == 68) {
        expect(
          codeUnitFlags.hasFlag(i, CodeUnitFlag.whitespace),
          isTrue,
          reason: 'Expected whitespace at index $i',
        );
      } else {
        expect(
          codeUnitFlags.hasFlag(i, CodeUnitFlag.whitespace),
          isFalse,
          reason: 'Expected no whitespace at index $i',
        );
      }
      i += 1;
    }
  });
}
