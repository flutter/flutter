// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
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

  String toStringDeep({ String prefixLineOne = '', String prefixOtherLines = '' }) {
    final StringBuffer sb = StringBuffer();
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
    expect(Object(), isNot(hasOneLineDescription));
  });

  test('hasAGoodToStringDeep', () {
    expect(_MockToStringDeep('Hello\n World\n'), hasAGoodToStringDeep);
    // Not terminated with a line break.
    expect(_MockToStringDeep('Hello\n World'), isNot(hasAGoodToStringDeep));
    // Trailing whitespace on last line.
    expect(_MockToStringDeep('Hello\n World \n'),
        isNot(hasAGoodToStringDeep));
    expect(_MockToStringDeep('Hello\n World\t\n'),
        isNot(hasAGoodToStringDeep));
    // Leading whitespace on line 1.
    expect(_MockToStringDeep(' Hello\n World \n'),
        isNot(hasAGoodToStringDeep));

    // Single line.
    expect(_MockToStringDeep('Hello World'), isNot(hasAGoodToStringDeep));
    expect(_MockToStringDeep('Hello World\n'), isNot(hasAGoodToStringDeep));

    expect(_MockToStringDeep('Hello: World\nFoo: bar\n'),
        hasAGoodToStringDeep);
    expect(_MockToStringDeep('Hello: World\nFoo: 42\n'),
        hasAGoodToStringDeep);
    // Contains default Object.toString().
    expect(_MockToStringDeep('Hello: World\nFoo: ${Object()}\n'),
        isNot(hasAGoodToStringDeep));
    expect(_MockToStringDeep('A\n├─B\n'), hasAGoodToStringDeep);
    expect(_MockToStringDeep('A\n├─B\n╘══════\n'), hasAGoodToStringDeep);
    // Last line is all whitespace or vertical line art.
    expect(_MockToStringDeep('A\n├─B\n\n'), isNot(hasAGoodToStringDeep));
    expect(_MockToStringDeep('A\n├─B\n│\n'), isNot(hasAGoodToStringDeep));
    expect(_MockToStringDeep('A\n├─B\n│\n'), isNot(hasAGoodToStringDeep));
    expect(_MockToStringDeep('A\n├─B\n│\n'), isNot(hasAGoodToStringDeep));
    expect(_MockToStringDeep('A\n├─B\n╎\n'), isNot(hasAGoodToStringDeep));
    expect(_MockToStringDeep('A\n├─B\n║\n'), isNot(hasAGoodToStringDeep));
    expect(_MockToStringDeep('A\n├─B\n │\n'), isNot(hasAGoodToStringDeep));
    expect(_MockToStringDeep('A\n├─B\n ╎\n'), isNot(hasAGoodToStringDeep));
    expect(_MockToStringDeep('A\n├─B\n ║\n'), isNot(hasAGoodToStringDeep));
    expect(_MockToStringDeep('A\n├─B\n ││\n'), isNot(hasAGoodToStringDeep));

    expect(_MockToStringDeep(
        'A\n'
        '├─B\n'
        '│\n'
        '└─C\n'), hasAGoodToStringDeep);
    // Last line is all whitespace or vertical line art.
    expect(_MockToStringDeep(
        'A\n'
        '├─B\n'
        '│\n'), isNot(hasAGoodToStringDeep));

    expect(_MockToStringDeep.fromLines(
        <String>['Paragraph#00000\n',
                 ' │ size: (400x200)\n',
                 ' ╘═╦══ text ═══\n',
                 '   ║ TextSpan:\n',
                 '   ║   "I polished up that handle so carefullee\n',
                 '   ║   That now I am the Ruler of the Queen\'s Navee!"\n',
                 '   ╚═══════════\n']), hasAGoodToStringDeep);

    // Text span
    expect(_MockToStringDeep.fromLines(
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

    expect(Rect.fromLTRB(0.0, 1.0, 2.0, 3.0), within<Rect>(distance: 4.0, from: Rect.fromLTRB(1.0, 3.0, 5.0, 7.0)));
    expect(Rect.fromLTRB(0.0, 1.0, 2.0, 3.0), isNot(within<Rect>(distance: 3.9, from: Rect.fromLTRB(1.0, 3.0, 5.0, 7.0))));

    expect(const Size(1.0, 1.0), within<Size>(distance: 1.415, from: const Size(2.0, 2.0)));
    expect(const Size(1.0, 1.0), isNot(within<Size>(distance: 1.414, from: const Size(2.0, 2.0))));

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
        Path(),
        coversSameAreaAs(
          Path(),
          areaToCompare: Rect.fromLTRB(0.0, 0.0, 10.0, 10.0)
        ),
      );
    });

    test('mismatch', () {
      final Path rectPath = Path()
        ..addRect(Rect.fromLTRB(5.0, 5.0, 6.0, 6.0));
      expect(
        Path(),
        isNot(coversSameAreaAs(
          rectPath,
          areaToCompare: Rect.fromLTRB(0.0, 0.0, 10.0, 10.0)
        )),
      );
    });

    test('mismatch out of examined area', () {
      final Path rectPath = Path()
        ..addRect(Rect.fromLTRB(5.0, 5.0, 6.0, 6.0));
      rectPath.addRect(Rect.fromLTRB(5.0, 5.0, 6.0, 6.0));
      expect(
        Path(),
        coversSameAreaAs(
          rectPath,
          areaToCompare: Rect.fromLTRB(0.0, 0.0, 4.0, 4.0)
        ),
      );
    });

    test('differently constructed rects match', () {
      final Path rectPath = Path()
        ..addRect(Rect.fromLTRB(5.0, 5.0, 6.0, 6.0));
      final Path linePath = Path()
        ..moveTo(5.0, 5.0)
        ..lineTo(5.0, 6.0)
        ..lineTo(6.0, 6.0)
        ..lineTo(6.0, 5.0)
        ..close();
      expect(
        linePath,
        coversSameAreaAs(
          rectPath,
          areaToCompare: Rect.fromLTRB(0.0, 0.0, 10.0, 10.0)
        ),
      );
    });

     test('partially overlapping paths', () {
      final Path rectPath = Path()
        ..addRect(Rect.fromLTRB(5.0, 5.0, 6.0, 6.0));
      final Path linePath = Path()
        ..moveTo(5.0, 5.0)
        ..lineTo(5.0, 6.0)
        ..lineTo(6.0, 6.0)
        ..lineTo(6.0, 5.5)
        ..close();
      expect(
        linePath,
        isNot(coversSameAreaAs(
          rectPath,
          areaToCompare: Rect.fromLTRB(0.0, 0.0, 10.0, 10.0)
        )),
      );
    });
  });

  group('matchesGoldenFile', () {
    _FakeComparator comparator;

    Widget boilerplate(Widget child) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: child,
      );
    }

    setUp(() {
      comparator = _FakeComparator();
      goldenFileComparator = comparator;
    });

    group('matches', () {
      testWidgets('if comparator succeeds', (WidgetTester tester) async {
        await tester.pumpWidget(boilerplate(const Text('hello')));
        final Finder finder = find.byType(Text);
        await expectLater(finder, matchesGoldenFile('foo.png'));
        expect(comparator.invocation, _ComparatorInvocation.compare);
        expect(comparator.imageBytes, hasLength(greaterThan(0)));
        expect(comparator.golden, Uri.parse('foo.png'));
      });
    });

    group('does not match', () {
      testWidgets('if comparator returns false', (WidgetTester tester) async {
        comparator.behavior = _ComparatorBehavior.returnFalse;
        await tester.pumpWidget(boilerplate(const Text('hello')));
        final Finder finder = find.byType(Text);
        try {
          await expectLater(finder, matchesGoldenFile('foo.png'));
          fail('TestFailure expected but not thrown');
        } on TestFailure catch (error) {
          expect(comparator.invocation, _ComparatorInvocation.compare);
          expect(error.message, contains('does not match'));
        }
      });

      testWidgets('if comparator throws', (WidgetTester tester) async {
        comparator.behavior = _ComparatorBehavior.throwTestFailure;
        await tester.pumpWidget(boilerplate(const Text('hello')));
        final Finder finder = find.byType(Text);
        try {
          await expectLater(finder, matchesGoldenFile('foo.png'));
          fail('TestFailure expected but not thrown');
        } on TestFailure catch (error) {
          expect(comparator.invocation, _ComparatorInvocation.compare);
          expect(error.message, contains('fake message'));
        }
      });

      testWidgets('if finder finds no widgets', (WidgetTester tester) async {
        await tester.pumpWidget(boilerplate(Container()));
        final Finder finder = find.byType(Text);
        try {
          await expectLater(finder, matchesGoldenFile('foo.png'));
          fail('TestFailure expected but not thrown');
        } on TestFailure catch (error) {
          expect(comparator.invocation, isNull);
          expect(error.message, contains('no widget was found'));
        }
      });

      testWidgets('if finder finds multiple widgets', (WidgetTester tester) async {
        await tester.pumpWidget(boilerplate(Column(
          children: const <Widget>[Text('hello'), Text('world')],
        )));
        final Finder finder = find.byType(Text);
        try {
          await expectLater(finder, matchesGoldenFile('foo.png'));
          fail('TestFailure expected but not thrown');
        } on TestFailure catch (error) {
          expect(comparator.invocation, isNull);
          expect(error.message, contains('too many widgets'));
        }
      });
    });

    testWidgets('calls update on comparator if autoUpdateGoldenFiles is true', (WidgetTester tester) async {
      autoUpdateGoldenFiles = true;
      await tester.pumpWidget(boilerplate(const Text('hello')));
      final Finder finder = find.byType(Text);
      await expectLater(finder, matchesGoldenFile('foo.png'));
      expect(comparator.invocation, _ComparatorInvocation.update);
      expect(comparator.imageBytes, hasLength(greaterThan(0)));
      expect(comparator.golden, Uri.parse('foo.png'));
      autoUpdateGoldenFiles = false;
    });
  });

  group('matchesSemanticsData', () {
    testWidgets('matches SemanticsData', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      const Key key = Key('semantics');
      await tester.pumpWidget(Semantics(
        key: key,
        namesRoute: true,
        header: true,
        button: true,
        onTap: () {},
        onLongPress: () {},
        label: 'foo',
        hint: 'bar',
        value: 'baz',
        increasedValue: 'a',
        decreasedValue: 'b',
        textDirection: TextDirection.rtl,
        onTapHint: 'scan',
        onLongPressHint: 'fill',
        customSemanticsActions: <CustomSemanticsAction, VoidCallback>{
          const CustomSemanticsAction(label: 'foo'): () {},
          const CustomSemanticsAction(label: 'bar'): () {},
        },
      ));

      expect(tester.getSemantics(find.byKey(key)),
        matchesSemantics(
          label: 'foo',
          hint: 'bar',
          value: 'baz',
          increasedValue: 'a',
          decreasedValue: 'b',
          textDirection: TextDirection.rtl,
          hasTapAction: true,
          hasLongPressAction: true,
          isButton: true,
          isHeader: true,
          namesRoute: true,
          onTapHint: 'scan',
          onLongPressHint: 'fill',
          customActions: <CustomSemanticsAction>[
            const CustomSemanticsAction(label: 'foo'),
            const CustomSemanticsAction(label: 'bar')
          ],
        ),
      );

      // Doesn't match custom actions
      expect(tester.getSemantics(find.byKey(key)),
        isNot(matchesSemantics(
          label: 'foo',
          hint: 'bar',
          value: 'baz',
          textDirection: TextDirection.rtl,
          hasTapAction: true,
          hasLongPressAction: true,
          isButton: true,
          isHeader: true,
          namesRoute: true,
          onTapHint: 'scan',
          onLongPressHint: 'fill',
          customActions: <CustomSemanticsAction>[
            const CustomSemanticsAction(label: 'foo'),
            const CustomSemanticsAction(label: 'barz')
          ],
        )),
      );

      // Doesn't match wrong hints
      expect(tester.getSemantics(find.byKey(key)),
        isNot(matchesSemantics(
          label: 'foo',
          hint: 'bar',
          value: 'baz',
          textDirection: TextDirection.rtl,
          hasTapAction: true,
          hasLongPressAction: true,
          isButton: true,
          isHeader: true,
          namesRoute: true,
          onTapHint: 'scans',
          onLongPressHint: 'fills',
          customActions: <CustomSemanticsAction>[
            const CustomSemanticsAction(label: 'foo'),
            const CustomSemanticsAction(label: 'bar')
          ],
        )),
      );

      handle.dispose();
    });

    testWidgets('Can match all semantics flags and actions', (WidgetTester tester) async {
      int actions = 0;
      int flags = 0;
      const CustomSemanticsAction action = CustomSemanticsAction(label: 'test');
      for (int index in SemanticsAction.values.keys)
        actions |= index;
      for (int index in SemanticsFlag.values.keys)
        flags |= index;
      final SemanticsData data = SemanticsData(
        flags: flags,
        actions: actions,
        label: 'a',
        increasedValue: 'b',
        value: 'c',
        decreasedValue: 'd',
        hint: 'e',
        textDirection: TextDirection.ltr,
        rect: Rect.fromLTRB(0.0, 0.0, 10.0, 10.0),
        textSelection: null,
        scrollIndex: null,
        scrollChildCount: null,
        scrollPosition: null,
        scrollExtentMax: null,
        scrollExtentMin: null,
        customSemanticsActionIds: <int>[CustomSemanticsAction.getIdentifier(action)],
      );
      final _FakeSemanticsNode node = _FakeSemanticsNode();
      node.data = data;

      expect(node, matchesSemantics(
         rect: Rect.fromLTRB(0.0, 0.0, 10.0, 10.0),
         size: const Size(10.0, 10.0),
         /* Flags */
         hasCheckedState: true,
         isChecked: true,
         isSelected: true,
         isButton: true,
         isTextField: true,
         hasEnabledState: true,
         isFocused: true,
         isEnabled: true,
         isInMutuallyExclusiveGroup: true,
         isHeader: true,
         isObscured: true,
         namesRoute: true,
         scopesRoute: true,
         isHidden: true,
         isImage: true,
         isLiveRegion: true,
         hasToggledState: true,
         isToggled: true,
         hasImplicitScrolling: true,
         /* Actions */
         hasTapAction: true,
         hasLongPressAction: true,
         hasScrollLeftAction: true,
         hasScrollRightAction: true,
         hasScrollUpAction: true,
         hasScrollDownAction: true,
         hasIncreaseAction: true,
         hasDecreaseAction: true,
         hasShowOnScreenAction: true,
         hasMoveCursorForwardByCharacterAction: true,
         hasMoveCursorBackwardByCharacterAction: true,
         hasMoveCursorForwardByWordAction: true,
         hasMoveCursorBackwardByWordAction: true,
         hasSetSelectionAction: true,
         hasCopyAction: true,
         hasCutAction: true,
         hasPasteAction: true,
         hasDidGainAccessibilityFocusAction: true,
         hasDidLoseAccessibilityFocusAction: true,
         hasDismissAction: true,
         customActions: <CustomSemanticsAction>[action],
      ));
    });

    testWidgets('Can match child semantics', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      const Key key = Key('a');
      await tester.pumpWidget(Semantics(
        key: key,
        label: 'Foo',
        container: true,
        explicitChildNodes: true,
        textDirection: TextDirection.ltr,
        child: Semantics(
          label: 'Bar',
          textDirection: TextDirection.ltr,
        ),
      ));
      final SemanticsNode node = tester.getSemantics(find.byKey(key));

      expect(node, matchesSemantics(
        label: 'Foo',
        textDirection: TextDirection.ltr,
        children: <Matcher>[
          matchesSemantics(
            label: 'Bar',
            textDirection: TextDirection.ltr,
          ),
        ],
      ));
      handle.dispose();
    });
  });
}

enum _ComparatorBehavior {
  returnTrue,
  returnFalse,
  throwTestFailure,
}

enum _ComparatorInvocation {
  compare,
  update,
}

class _FakeComparator implements GoldenFileComparator {
  _ComparatorBehavior behavior = _ComparatorBehavior.returnTrue;
  _ComparatorInvocation invocation;
  Uint8List imageBytes;
  Uri golden;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) {
    invocation = _ComparatorInvocation.compare;
    this.imageBytes = imageBytes;
    this.golden = golden;
    switch (behavior) {
      case _ComparatorBehavior.returnTrue:
        return Future<bool>.value(true);
      case _ComparatorBehavior.returnFalse:
        return Future<bool>.value(false);
      case _ComparatorBehavior.throwTestFailure:
        throw TestFailure('fake message');
    }
    return Future<bool>.value(false);
  }

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) {
    invocation = _ComparatorInvocation.update;
    this.golden = golden;
    this.imageBytes = imageBytes;
    return Future<void>.value();
  }
}

class _FakeSemanticsNode extends SemanticsNode {
  SemanticsData data;
  @override
  SemanticsData getSemanticsData() => data;
}