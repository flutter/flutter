// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test plurals without translation.
///
/// This exercises the plural selection rules. We aren't worried about the text,
/// just that it picks the right phrase for the right number.

library plural_test;

import 'package:intl/intl.dart';
import 'package:test/test.dart';

/// Hard-coded expected values for a Russian plural rule.
///
/// Note that the way I'm interpreting this is that if there's a case for zero,
/// one or two and the number is exactly that, then use that value. Otherwise we
/// use One for the singular, Few for the genitive singular, and Many for the
/// genitive plural. Other would be used for fractional values if we supported
/// those.
var expectedRu = '''
0:Zero
1:One
2:Few
3:Few
4:Few
5:Many
6:Many
7:Many
8:Many
9:Many
10:Many
11:Many
12:Many
13:Many
14:Many
15:Many
16:Many
17:Many
18:Many
19:Many
20:Many
21:One
22:Few
23:Few
24:Few
25:Many
26:Many
27:Many
28:Many
29:Many
30:Many
31:One
32:Few
59:Many
60:Many
61:One
62:Few
63:Few
64:Few
65:Many
66:Many
67:Many
68:Many
69:Many
70:Many
71:One
72:Few
100:Many
101:One
102:Few
103:Few
104:Few
105:Many
106:Many
107:Many
108:Many
109:Many
110:Many
111:Many
112:Many
113:Many
114:Many
115:Many
116:Many
117:Many
118:Many
119:Many
120:Many
121:One
122:Few
129:Many
130:Many
131:One
132:Few
139:Many
140:Many
141:One
142:Few
143:Few
144:Few
145:Many
''';

var expectedEn = '''
0:Zero
1:One
2:Other
3:Other
4:Other
5:Other
6:Other
7:Other
8:Other
9:Other
10:Other
11:Other
12:Other
13:Other
14:Other
15:Other
16:Other
17:Other
18:Other
19:Other
20:Other
21:Other
22:Other
145:Other
''';

var expectedRo = '''
0:Few
1:One
2:Few
12:Few
23:Other
1212:Few
1223:Other
''';

var expectedSr = '''
0:Other
1:One
31:One
3:Few
33:Few
5:Other
10:Other
35:Other
37:Other
40:Other
2:Few
20:Other
21:One
22:Few
23:Few
24:Few
25:Other
''';

String plural(n, locale) => Intl.plural(n,
    locale: locale,
    name: 'plural',
    desc: 'A simple plural test case',
    examples: {'n': 1},
    args: [n],
    zero: '$n:Zero',
    one: '$n:One',
    few: '$n:Few',
    many: '$n:Many',
    other: '$n:Other');

String pluralNoZero(n, locale) => Intl.plural(n,
    locale: locale,
    name: 'plural',
    desc: 'A simple plural test case',
    examples: {'n': 1},
    args: [n],
    one: '$n:One',
    few: '$n:Few',
    many: '$n:Many',
    other: '$n:Other');

void main() {
  verify(expectedRu, 'ru', plural);
  verify(expectedRu, 'ru_RU', plural);
  verify(expectedEn, 'en', plural);
  verify(expectedRo, 'ro', pluralNoZero);
  verify(expectedSr, 'sr', pluralNoZero);

  test('Check null howMany', () {
    expect(plural(0, null), '0:Zero');
    expect(() => plural(null, null), throwsA(isA<Error>()));
    expect(() => plural(null, 'ru'), throwsA(isA<Error>()));
  });

  verifyWithPrecision('1 dollar', 'en', 1, 0);
  // This would not work in back-compatibility for one vs. =1 in plurals,
  // because of this test in intl.dart:
  //    if (howMany == 1 && one != null) return one;
  // That one will ignore the precision and always return one, while the
  // test below requires the result to be 'other'
  // verify_with_precision('1.00 dollars', 'en', 1, 2);

  verifyWithPrecision('1 dollar', 'en', 1.2, 0);
  verifyWithPrecision('1.20 dollars', 'en', 1.2, 2);

  verifyWithPrecision('3 dollars', 'en', 3.14, 0);
  verifyWithPrecision('3.14 dollars', 'en', 3.14, 2);
}

void verify(String expectedValues, String locale, pluralFunction) {
  var lines = expectedValues.split('\n').where((x) => x.isNotEmpty).toList();
  for (var i = 0; i < lines.length; i++) {
    test(lines[i], () {
      var number = int.parse(lines[i].split(':').first);
      expect(pluralFunction(number, locale), lines[i]);
      var float = number.toDouble();
      var lineWithFloat = lines[i].replaceFirst('$number', '$float');
      expect(pluralFunction(float, locale), lineWithFloat);
    });
  }
}

void verifyWithPrecision(String expected, String locale, num n, int precision) {
  test('verify_with_precision(howMany: $n, precision: $precision)', () {
    var nString = n.toStringAsFixed(precision);
    var actual = Intl.plural(n,
        locale: locale,
        precision: precision,
        one: '$nString dollar',
        other: '$nString dollars');
    expect(actual, expected);
  });
}
