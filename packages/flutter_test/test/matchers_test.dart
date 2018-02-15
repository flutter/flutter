// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

/// Class that makes it easy to mock common toStringDeep behavior.
class _MockToStringDeep {
  _MockToStringDeep(String str) {
    final List<String> lines = str.split('\n');
    _lines = <String>[];
    for (int i = 0; i < lines.length - 1; ++i)
      _lines.add('${lines[i]}\n');

    // If the last line is empty, that really just means that the previous
    // line was terminated with a line break.
    if (lines.isNotEmpty && lines.last.isNotEmpty) {
      _lines.add(lines.last);
    }
  }

  _MockToStringDeep.fromLines(this._lines);

  /// Lines in the message to display when [toStringDeep] is called.
  /// For correct toStringDeep behavior, each line should be terminated with a
  /// line break.
  List<String> _lines;

  String toStringDeep({ String prefixLineOne: '', String prefixOtherLines: '' }) {
    final StringBuffer sb = new StringBuffer();
    if (_lines.isNotEmpty)
      sb.write('$prefixLineOne${_lines.first}');

    for (int i = 1; i < _lines.length; ++i)
      sb.write('$prefixOtherLines${_lines[i]}');

    return sb.toString();
  }

  @override
  String toString() => toStringDeep();
}

void main() {
  test('hasOneLineDescription', () {
    expect('Hello', hasOneLineDescription);
    expect('Hello\nHello', isNot(hasOneLineDescription));
    expect(' Hello', isNot(hasOneLineDescription));
    expect('Hello ', isNot(hasOneLineDescription));
    expect(new Object(), isNot(hasOneLineDescription));
  });

  test('hasAGoodToStringDeep', () {
    expect(new _MockToStringDeep('Hello\n World\n'), hasAGoodToStringDeep);
    // Not terminated with a line break.
    expect(new _MockToStringDeep('Hello\n World'), isNot(hasAGoodToStringDeep));
    // Trailing whitespace on last line.
    expect(new _MockToStringDeep('Hello\n World \n'),
        isNot(hasAGoodToStringDeep));
    expect(new _MockToStringDeep('Hello\n World\t\n'),
        isNot(hasAGoodToStringDeep));
    // Leading whitespace on line 1.
    expect(new _MockToStringDeep(' Hello\n World \n'),
        isNot(hasAGoodToStringDeep));

    // Single line.
    expect(new _MockToStringDeep('Hello World'), isNot(hasAGoodToStringDeep));
    expect(new _MockToStringDeep('Hello World\n'), isNot(hasAGoodToStringDeep));

    expect(new _MockToStringDeep('Hello: World\nFoo: bar\n'),
        hasAGoodToStringDeep);
    expect(new _MockToStringDeep('Hello: World\nFoo: 42\n'),
        hasAGoodToStringDeep);
    // Contains default Object.toString().
    expect(new _MockToStringDeep('Hello: World\nFoo: ${new Object()}\n'),
        isNot(hasAGoodToStringDeep));
    expect(new _MockToStringDeep('A\n├─B\n'), hasAGoodToStringDeep);
    expect(new _MockToStringDeep('A\n├─B\n╘══════\n'), hasAGoodToStringDeep);
    // Last line is all whitespace or vertical line art.
    expect(new _MockToStringDeep('A\n├─B\n\n'), isNot(hasAGoodToStringDeep));
    expect(new _MockToStringDeep('A\n├─B\n│\n'), isNot(hasAGoodToStringDeep));
    expect(new _MockToStringDeep('A\n├─B\n│\n'), isNot(hasAGoodToStringDeep));
    expect(new _MockToStringDeep('A\n├─B\n│\n'), isNot(hasAGoodToStringDeep));
    expect(new _MockToStringDeep('A\n├─B\n╎\n'), isNot(hasAGoodToStringDeep));
    expect(new _MockToStringDeep('A\n├─B\n║\n'), isNot(hasAGoodToStringDeep));
    expect(new _MockToStringDeep('A\n├─B\n │\n'), isNot(hasAGoodToStringDeep));
    expect(new _MockToStringDeep('A\n├─B\n ╎\n'), isNot(hasAGoodToStringDeep));
    expect(new _MockToStringDeep('A\n├─B\n ║\n'), isNot(hasAGoodToStringDeep));
    expect(new _MockToStringDeep('A\n├─B\n ││\n'), isNot(hasAGoodToStringDeep));

    expect(new _MockToStringDeep(
        'A\n'
        '├─B\n'
        '│\n'
        '└─C\n'), hasAGoodToStringDeep);
    // Last line is all whitespace or vertical line art.
    expect(new _MockToStringDeep(
        'A\n'
        '├─B\n'
        '│\n'), isNot(hasAGoodToStringDeep));

    expect(new _MockToStringDeep.fromLines(
        <String>['Paragraph#00000\n',
                 ' │ size: (400x200)\n',
                 ' ╘═╦══ text ═══\n',
                 '   ║ TextSpan:\n',
                 '   ║   "I polished up that handle so carefullee\n',
                 '   ║   That now I am the Ruler of the Queen\'s Navee!"\n',
                 '   ╚═══════════\n']), hasAGoodToStringDeep);

    // Text span
    expect(new _MockToStringDeep.fromLines(
        <String>['Paragraph#00000\n',
                 ' │ size: (400x200)\n',
                 ' ╘═╦══ text ═══\n',
                 '   ║ TextSpan:\n',
                 '   ║   "I polished up that handle so carefullee\nThat now I am the Ruler of the Queen\'s Navee!"\n',
                 '   ╚═══════════\n']), isNot(hasAGoodToStringDeep));
  });

  test('normalizeHashCodesEquals', () {
    expect('Foo#34219', equalsIgnoringHashCodes('Foo#00000'));
    expect('Foo#34219', equalsIgnoringHashCodes('Foo#12345'));
    expect('Foo#34219', equalsIgnoringHashCodes('Foo#abcdf'));
    expect('Foo#34219', isNot(equalsIgnoringHashCodes('Foo')));
    expect('Foo#34219', isNot(equalsIgnoringHashCodes('Foo#')));
    expect('Foo#34219', isNot(equalsIgnoringHashCodes('Foo#0')));
    expect('Foo#34219', isNot(equalsIgnoringHashCodes('Foo#00')));
    expect('Foo#34219', isNot(equalsIgnoringHashCodes('Foo#00000 ')));
    expect('Foo#34219', isNot(equalsIgnoringHashCodes('Foo#000000')));
    expect('Foo#34219', isNot(equalsIgnoringHashCodes('Foo#123456')));

    expect('Foo#34219:', equalsIgnoringHashCodes('Foo#00000:'));
    expect('Foo#34219:', isNot(equalsIgnoringHashCodes('Foo#00000')));

    expect('Foo#a3b4d', equalsIgnoringHashCodes('Foo#00000'));
    expect('Foo#a3b4d', equalsIgnoringHashCodes('Foo#12345'));
    expect('Foo#a3b4d', equalsIgnoringHashCodes('Foo#abcdf'));
    expect('Foo#a3b4d', isNot(equalsIgnoringHashCodes('Foo')));
    expect('Foo#a3b4d', isNot(equalsIgnoringHashCodes('Foo#')));
    expect('Foo#a3b4d', isNot(equalsIgnoringHashCodes('Foo#0')));
    expect('Foo#a3b4d', isNot(equalsIgnoringHashCodes('Foo#00')));
    expect('Foo#a3b4d', isNot(equalsIgnoringHashCodes('Foo#00000 ')));
    expect('Foo#a3b4d', isNot(equalsIgnoringHashCodes('Foo#000000')));
    expect('Foo#a3b4d', isNot(equalsIgnoringHashCodes('Foo#123456')));

    expect('Foo#A3b4D', isNot(equalsIgnoringHashCodes('Foo#00000')));

    expect('Foo#12345(Bar#9110f)',
        equalsIgnoringHashCodes('Foo#00000(Bar#00000)'));
    expect('Foo#12345(Bar#9110f)',
        isNot(equalsIgnoringHashCodes('Foo#00000(Bar#)')));

    expect('Foo', isNot(equalsIgnoringHashCodes('Foo#00000')));
    expect('Foo#', isNot(equalsIgnoringHashCodes('Foo#00000')));
    expect('Foo#3421', isNot(equalsIgnoringHashCodes('Foo#00000')));
    expect('Foo#342193', isNot(equalsIgnoringHashCodes('Foo#00000')));
  });

  test('moreOrLessEquals', () {
    expect(0.0, moreOrLessEquals(1e-11));
    expect(1e-11, moreOrLessEquals(0.0));
    expect(-1e-11, moreOrLessEquals(0.0));

    expect(0.0, isNot(moreOrLessEquals(1e11)));
    expect(1e11, isNot(moreOrLessEquals(0.0)));
    expect(-1e11, isNot(moreOrLessEquals(0.0)));

    expect(0.0, isNot(moreOrLessEquals(1.0)));
    expect(1.0, isNot(moreOrLessEquals(0.0)));
    expect(-1.0, isNot(moreOrLessEquals(0.0)));

    expect(1e-11, moreOrLessEquals(-1e-11));
    expect(-1e-11, moreOrLessEquals(1e-11));

    expect(11.0, isNot(moreOrLessEquals(-11.0, epsilon: 1.0)));
    expect(-11.0, isNot(moreOrLessEquals(11.0, epsilon: 1.0)));

    expect(11.0, moreOrLessEquals(-11.0, epsilon: 100.0));
    expect(-11.0, moreOrLessEquals(11.0, epsilon: 100.0));
  });

  test('within', () {
    expect(0.0, within<double>(distance: 0.1, from: 0.05));
    expect(0.0, isNot(within<double>(distance: 0.1, from: 0.2)));

    expect(0, within<int>(distance: 1, from: 1));
    expect(0, isNot(within<int>(distance: 1, from: 2)));

    expect(const Color(0x00000000), within<Color>(distance: 1, from: const Color(0x01000000)));
    expect(const Color(0x00000000), within<Color>(distance: 1, from: const Color(0x00010000)));
    expect(const Color(0x00000000), within<Color>(distance: 1, from: const Color(0x00000100)));
    expect(const Color(0x00000000), within<Color>(distance: 1, from: const Color(0x00000001)));
    expect(const Color(0x00000000), within<Color>(distance: 1, from: const Color(0x01010101)));
    expect(const Color(0x00000000), isNot(within<Color>(distance: 1, from: const Color(0x02000000))));

    expect(const Offset(1.0, 0.0), within(distance: 1.0, from: const Offset(0.0, 0.0)));
    expect(const Offset(1.0, 0.0), isNot(within(distance: 1.0, from: const Offset(-1.0, 0.0))));

    expect(
      () => within<bool>(distance: 1, from: false),
      throwsArgumentError,
    );

    expect(
      () => within<int>(distance: 1, from: 2, distanceFunction: (int a, int b) => -1).matches(1, <dynamic, dynamic>{}),
      throwsArgumentError,
    );
  });

  group('coversSameAreaAs', () {
    test('empty Paths', () {
      expect(
        new Path(),
        coversSameAreaAs(
          new Path(),
          areaToCompare: new Rect.fromLTRB(0.0, 0.0, 10.0, 10.0)
        ),
      );
    });

    test('mismatch', () {
      final Path rectPath = new Path()
        ..addRect(new Rect.fromLTRB(5.0, 5.0, 6.0, 6.0));
      expect(
        new Path(),
        isNot(coversSameAreaAs(
          rectPath,
          areaToCompare: new Rect.fromLTRB(0.0, 0.0, 10.0, 10.0)
        )),
      );
    });

    test('mismatch out of examined area', () {
      final Path rectPath = new Path()
        ..addRect(new Rect.fromLTRB(5.0, 5.0, 6.0, 6.0));
      rectPath.addRect(new Rect.fromLTRB(5.0, 5.0, 6.0, 6.0));
      expect(
        new Path(),
        coversSameAreaAs(
          rectPath,
          areaToCompare: new Rect.fromLTRB(0.0, 0.0, 4.0, 4.0)
        ),
      );
    });

    test('differently constructed rects match', () {
      final Path rectPath = new Path()
        ..addRect(new Rect.fromLTRB(5.0, 5.0, 6.0, 6.0));
      final Path linePath = new Path()
        ..moveTo(5.0, 5.0)
        ..lineTo(5.0, 6.0)
        ..lineTo(6.0, 6.0)
        ..lineTo(6.0, 5.0)
        ..close();
      expect(
        linePath,
        coversSameAreaAs(
          rectPath,
          areaToCompare: new Rect.fromLTRB(0.0, 0.0, 10.0, 10.0)
        ),
      );
    });

     test('partially overlapping paths', () {
      final Path rectPath = new Path()
        ..addRect(new Rect.fromLTRB(5.0, 5.0, 6.0, 6.0));
      final Path linePath = new Path()
        ..moveTo(5.0, 5.0)
        ..lineTo(5.0, 6.0)
        ..lineTo(6.0, 6.0)
        ..lineTo(6.0, 5.5)
        ..close();
      expect(
        linePath,
        isNot(coversSameAreaAs(
          rectPath,
          areaToCompare: new Rect.fromLTRB(0.0, 0.0, 10.0, 10.0)
        )),
      );
    });
  });
}
