// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';
import '../widgets/semantics_tester.dart';
import 'feedback_tester.dart';

class TestIcon extends StatefulWidget {
  const TestIcon({ super.key });

  @override
  TestIconState createState() => TestIconState();
}

class TestIconState extends State<TestIcon> {
  late IconThemeData iconTheme;

  @override
  Widget build(BuildContext context) {
    iconTheme = IconTheme.of(context);
    return const Icon(Icons.add);
  }
}

class TestText extends StatefulWidget {
  const TestText(this.text, { super.key });

  final String text;

  @override
  TestTextState createState() => TestTextState();
}

class TestTextState extends State<TestText> {
  late TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    textStyle = DefaultTextStyle.of(context).style;
    return Text(widget.text);
  }
}

void main() {
  testWidgets('ListTile geometry (LTR)', (WidgetTester tester) async {
    // See https://material.io/go/design-lists

    final Key leadingKey = GlobalKey();
    final Key trailingKey = GlobalKey();
    late bool hasSubtitle;

    const double leftPadding = 10.0;
    const double rightPadding = 20.0;
    Widget buildFrame({ bool dense = false, bool isTwoLine = false, bool isThreeLine = false, double textScaleFactor = 1.0, double? subtitleScaleFactor }) {
      hasSubtitle = isTwoLine || isThreeLine;
      subtitleScaleFactor ??= textScaleFactor;
      return MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            padding: const EdgeInsets.only(left: leftPadding, right: rightPadding),
            textScaleFactor: textScaleFactor,
          ),
          child: Material(
            child: Center(
              child: ListTile(
                leading: SizedBox(key: leadingKey, width: 24.0, height: 24.0),
                title: const Text('title'),
                subtitle: hasSubtitle ? Text('subtitle', textScaleFactor: subtitleScaleFactor) : null,
                trailing: SizedBox(key: trailingKey, width: 24.0, height: 24.0),
                dense: dense,
                isThreeLine: isThreeLine,
              ),
            ),
          ),
        ),
      );
    }

    void testChildren() {
      expect(find.byKey(leadingKey), findsOneWidget);
      expect(find.text('title'), findsOneWidget);
      if (hasSubtitle) {
        expect(find.text('subtitle'), findsOneWidget);
      }
      expect(find.byKey(trailingKey), findsOneWidget);
    }

    double left(String text) => tester.getTopLeft(find.text(text)).dx;
    double top(String text) => tester.getTopLeft(find.text(text)).dy;
    double bottom(String text) => tester.getBottomLeft(find.text(text)).dy;
    double height(String text) => tester.getRect(find.text(text)).height;

    double leftKey(Key key) => tester.getTopLeft(find.byKey(key)).dx;
    double rightKey(Key key) => tester.getTopRight(find.byKey(key)).dx;
    double widthKey(Key key) => tester.getSize(find.byKey(key)).width;
    double heightKey(Key key) => tester.getSize(find.byKey(key)).height;

    // ListTiles are contained by a SafeArea defined like this:
    // SafeArea(top: false, bottom: false, minimum: contentPadding)
    // The default contentPadding is 16.0 on the left and right.
    void testHorizontalGeometry() {
      expect(leftKey(leadingKey), math.max(16.0, leftPadding));
      expect(left('title'), 56.0 + math.max(16.0, leftPadding));
      if (hasSubtitle) {
        expect(left('subtitle'), 56.0 + math.max(16.0, leftPadding));
      }
      expect(left('title'), rightKey(leadingKey) + 32.0);
      expect(rightKey(trailingKey), 800.0 - math.max(16.0, rightPadding));
      expect(widthKey(trailingKey), 24.0);
    }

    void testVerticalGeometry(double expectedHeight) {
      final Rect tileRect = tester.getRect(find.byType(ListTile));
      expect(tileRect.size, Size(800.0, expectedHeight));
      expect(top('title'), greaterThanOrEqualTo(tileRect.top));
      if (hasSubtitle) {
        expect(top('subtitle'), greaterThanOrEqualTo(bottom('title')));
        expect(bottom('subtitle'), lessThan(tileRect.bottom));
      } else {
        expect(top('title'), equals(tileRect.top + (tileRect.height - height('title')) / 2.0));
      }
      expect(heightKey(trailingKey), 24.0);
    }

    await tester.pumpWidget(buildFrame());
    testChildren();
    testHorizontalGeometry();
    testVerticalGeometry(56.0);

    await tester.pumpWidget(buildFrame(dense: true));
    testChildren();
    testHorizontalGeometry();
    testVerticalGeometry(48.0);

    await tester.pumpWidget(buildFrame(isTwoLine: true));
    testChildren();
    testHorizontalGeometry();
    testVerticalGeometry(72.0);

    await tester.pumpWidget(buildFrame(isTwoLine: true, dense: true));
    testChildren();
    testHorizontalGeometry();
    testVerticalGeometry(64.0);

    await tester.pumpWidget(buildFrame(isThreeLine: true));
    testChildren();
    testHorizontalGeometry();
    testVerticalGeometry(88.0);

    await tester.pumpWidget(buildFrame(isThreeLine: true, dense: true));
    testChildren();
    testHorizontalGeometry();
    testVerticalGeometry(76.0);

    await tester.pumpWidget(buildFrame(textScaleFactor: 4.0));
    testChildren();
    testHorizontalGeometry();
    testVerticalGeometry(72.0);

    await tester.pumpWidget(buildFrame(dense: true, textScaleFactor: 4.0));
    testChildren();
    testHorizontalGeometry();
    testVerticalGeometry(72.0);

    await tester.pumpWidget(buildFrame(isTwoLine: true, textScaleFactor: 4.0));
    testChildren();
    testHorizontalGeometry();
    testVerticalGeometry(128.0);

    // Make sure that the height of a large subtitle is taken into account.
    await tester.pumpWidget(buildFrame(isTwoLine: true, textScaleFactor: 0.5, subtitleScaleFactor: 4.0));
    testChildren();
    testHorizontalGeometry();
    testVerticalGeometry(72.0);

    await tester.pumpWidget(buildFrame(isTwoLine: true, dense: true, textScaleFactor: 4.0));
    testChildren();
    testHorizontalGeometry();
    testVerticalGeometry(128.0);

    await tester.pumpWidget(buildFrame(isThreeLine: true, textScaleFactor: 4.0));
    testChildren();
    testHorizontalGeometry();
    testVerticalGeometry(128.0);

    await tester.pumpWidget(buildFrame(isThreeLine: true, dense: true, textScaleFactor: 4.0));
    testChildren();
    testHorizontalGeometry();
    testVerticalGeometry(128.0);
  });

  testWidgets('ListTile geometry (RTL)', (WidgetTester tester) async {
    const double leftPadding = 10.0;
    const double rightPadding = 20.0;
    await tester.pumpWidget(const MediaQuery(
      data: MediaQueryData(
        padding: EdgeInsets.only(left: leftPadding, right: rightPadding),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Material(
          child: Center(
            child: ListTile(
              leading: Text('L'),
              title: Text('title'),
              trailing: Text('T'),
            ),
          ),
        ),
      ),
    ));

    double left(String text) => tester.getTopLeft(find.text(text)).dx;
    double right(String text) => tester.getTopRight(find.text(text)).dx;

    void testHorizontalGeometry() {
      expect(right('L'), 800.0 - math.max(16.0, rightPadding));
      expect(right('title'), 800.0 - 56.0 - math.max(16.0, rightPadding));
      expect(left('T'), math.max(16.0, leftPadding));
    }

    testHorizontalGeometry();
  });

  testWidgets('ListTile.divideTiles', (WidgetTester tester) async {
    final List<String> titles = <String>[ 'first', 'second', 'third' ];

    await tester.pumpWidget(MaterialApp(
      home: Material(
        child: Builder(
          builder: (BuildContext context) {
            return ListView(
              children: ListTile.divideTiles(
                context: context,
                tiles: titles.map<Widget>((String title) => ListTile(title: Text(title))),
              ).toList(),
            );
          },
        ),
      ),
    ));

    expect(find.text('first'), findsOneWidget);
    expect(find.text('second'), findsOneWidget);
    expect(find.text('third'), findsOneWidget);
  });

  testWidgets('ListTile.divideTiles with empty list', (WidgetTester tester) async {
    final Iterable<Widget> output = ListTile.divideTiles(tiles: <Widget>[], color: Colors.grey);
    expect(output, isEmpty);
  });

  testWidgets('ListTile.divideTiles with single item list', (WidgetTester tester) async {
    final Iterable<Widget> output = ListTile.divideTiles(tiles: const <Widget>[SizedBox()], color: Colors.grey);
    expect(output.single, isA<SizedBox>());
  });

  testWidgets('ListTile.divideTiles only runs the generator once', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/pull/78879
    int callCount = 0;
    Iterable<Widget> generator() sync* {
      callCount += 1;
      yield const Text('');
      yield const Text('');
    }

    final List<Widget> output = ListTile.divideTiles(tiles: generator(), color: Colors.grey).toList();
    expect(output, hasLength(2));
    expect(callCount, 1);
  });

  testWidgets('ListTile semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      Material(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(),
            child: Column(
              children: <Widget>[
                const ListTile(
                  title: Text('one'),
                ),
                ListTile(
                  title: const Text('two'),
                  onTap: () {},
                ),
                const ListTile(
                  title: Text('three'),
                  selected: true,
                ),
                const ListTile(
                  title: Text('four'),
                  enabled: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(
      semantics,
      hasSemantics(
        TestSemantics.root(
          children: <TestSemantics>[
            TestSemantics.rootChild(
              flags: <SemanticsFlag>[
                SemanticsFlag.hasEnabledState,
                SemanticsFlag.isEnabled,
              ],
              label: 'one',
            ),
            TestSemantics.rootChild(
              flags: <SemanticsFlag>[
                SemanticsFlag.hasEnabledState,
                SemanticsFlag.isEnabled,
                SemanticsFlag.isFocusable,
              ],
              actions: <SemanticsAction>[SemanticsAction.tap],
              label: 'two',
            ),
            TestSemantics.rootChild(
              flags: <SemanticsFlag>[
                SemanticsFlag.isSelected,
                SemanticsFlag.hasEnabledState,
                SemanticsFlag.isEnabled,
              ],
              label: 'three',
            ),
            TestSemantics.rootChild(
              flags: <SemanticsFlag>[
                SemanticsFlag.hasEnabledState,
              ],
              label: 'four',
            ),
          ],
        ),
        ignoreTransform: true,
        ignoreId: true,
        ignoreRect: true,
      ),
    );

    semantics.dispose();
  });

  testWidgets('ListTile contentPadding', (WidgetTester tester) async {
    Widget buildFrame(TextDirection textDirection) {
      return MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: textDirection,
          child: Material(
            child: Container(
              alignment: Alignment.topLeft,
              child: const ListTile(
                contentPadding: EdgeInsetsDirectional.only(
                  start: 10.0,
                  end: 20.0,
                  top: 30.0,
                  bottom: 40.0,
                ),
                leading: Text('L'),
                title: Text('title'),
                trailing: Text('T'),
              ),
            ),
          ),
        ),
      );
    }

    double left(String text) => tester.getTopLeft(find.text(text)).dx;
    double right(String text) => tester.getTopRight(find.text(text)).dx;

    await tester.pumpWidget(buildFrame(TextDirection.ltr));

    expect(tester.getSize(find.byType(ListTile)), const Size(800.0, 126.0)); // 126 = 56 + 30 + 40
    expect(left('L'), 10.0); // contentPadding.start = 10
    expect(right('T'), 780.0); // 800 - contentPadding.end

    await tester.pumpWidget(buildFrame(TextDirection.rtl));

    expect(tester.getSize(find.byType(ListTile)), const Size(800.0, 126.0)); // 126 = 56 + 30 + 40
    expect(left('T'), 20.0); // contentPadding.end = 20
    expect(right('L'), 790.0); // 800 - contentPadding.start
  });

  testWidgets('ListTile wide leading Widget', (WidgetTester tester) async {
    const Key leadingKey = ValueKey<String>('L');

    Widget buildFrame(double leadingWidth, TextDirection textDirection) {
      return MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: textDirection,
          child: Material(
            child: Container(
              alignment: Alignment.topLeft,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: SizedBox(key: leadingKey, width: leadingWidth, height: 32.0),
                title: const Text('title'),
                subtitle: const Text('subtitle'),
              ),
            ),
          ),
        ),
      );
    }

    double left(String text) => tester.getTopLeft(find.text(text)).dx;
    double right(String text) => tester.getTopRight(find.text(text)).dx;

    // textDirection = LTR

    // Two-line tile's height = 72, leading 24x32 widget is positioned 16.0 pixels from the top.
    await tester.pumpWidget(buildFrame(24.0, TextDirection.ltr));
    expect(tester.getSize(find.byType(ListTile)), const Size(800.0, 72.0));
    expect(tester.getTopLeft(find.byKey(leadingKey)), const Offset(0.0, 16.0));
    expect(tester.getBottomRight(find.byKey(leadingKey)), const Offset(24.0, 16.0 + 32.0));

    // Leading widget's width is 20, so default layout: the left edges of the
    // title and subtitle are at 56dps (contentPadding is zero).
    expect(left('title'), 56.0);
    expect(left('subtitle'), 56.0);

    // If the leading widget is wider than 40 it is separated from the
    // title and subtitle by 16.
    await tester.pumpWidget(buildFrame(56.0, TextDirection.ltr));
    expect(tester.getSize(find.byType(ListTile)), const Size(800.0, 72.0));
    expect(tester.getTopLeft(find.byKey(leadingKey)), const Offset(0.0, 16.0));
    expect(tester.getBottomRight(find.byKey(leadingKey)), const Offset(56.0, 16.0 + 32.0));
    expect(left('title'), 72.0);
    expect(left('subtitle'), 72.0);

    // Same tests, textDirection = RTL

    await tester.pumpWidget(buildFrame(24.0, TextDirection.rtl));
    expect(tester.getSize(find.byType(ListTile)), const Size(800.0, 72.0));
    expect(tester.getTopRight(find.byKey(leadingKey)), const Offset(800.0, 16.0));
    expect(tester.getBottomLeft(find.byKey(leadingKey)), const Offset(800.0 - 24.0, 16.0 + 32.0));
    expect(right('title'), 800.0 - 56.0);
    expect(right('subtitle'), 800.0 - 56.0);

    await tester.pumpWidget(buildFrame(56.0, TextDirection.rtl));
    expect(tester.getSize(find.byType(ListTile)), const Size(800.0, 72.0));
    expect(tester.getTopRight(find.byKey(leadingKey)), const Offset(800.0, 16.0));
    expect(tester.getBottomLeft(find.byKey(leadingKey)), const Offset(800.0 - 56.0, 16.0 + 32.0));
    expect(right('title'), 800.0 - 72.0);
    expect(right('subtitle'), 800.0 - 72.0);
  });

  testWidgets('ListTile leading and trailing positions', (WidgetTester tester) async {
    // This test is based on the redlines at
    // https://material.io/design/components/lists.html#specs

    // DENSE "ONE"-LINE
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            children: const <Widget>[
              ListTile(
                dense: true,
                leading: CircleAvatar(),
                trailing: SizedBox(height: 24.0, width: 24.0, child: Placeholder()),
                title: Text('A\nB\nC\nD\nE\nF\nG\nH\nI\nJ\nK\nL\nM'),
              ),
              ListTile(
                dense: true,
                leading: CircleAvatar(),
                trailing: SizedBox(height: 24.0, width: 24.0, child: Placeholder()),
                title: Text('A'),
              ),
            ],
          ),
        ),
      ),
    );
    //                                                                          LEFT                  TOP          WIDTH  HEIGHT
    expect(tester.getRect(find.byType(ListTile).at(0)),     const Rect.fromLTWH(                0.0,          0.0, 800.0, 177.0));
    expect(tester.getRect(find.byType(CircleAvatar).at(0)), const Rect.fromLTWH(               16.0,         16.0,  40.0,  40.0));
    expect(tester.getRect(find.byType(Placeholder).at(0)),  const Rect.fromLTWH(800.0 - 24.0 - 16.0,         16.0,  24.0,  24.0));
    expect(tester.getRect(find.byType(ListTile).at(1)),     const Rect.fromLTWH(                0.0,        177.0, 800.0,  48.0));
    expect(tester.getRect(find.byType(CircleAvatar).at(1)), const Rect.fromLTWH(               16.0, 177.0 +  4.0,  40.0,  40.0));
    expect(tester.getRect(find.byType(Placeholder).at(1)),  const Rect.fromLTWH(800.0 - 24.0 - 16.0, 177.0 + 12.0,  24.0,  24.0));

    // NON-DENSE "ONE"-LINE
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            children: const <Widget>[
              ListTile(
                leading: CircleAvatar(),
                trailing: SizedBox(height: 24.0, width: 24.0, child: Placeholder()),
                title: Text('A\nB\nC\nD\nE\nF\nG\nH\nI\nJ\nK\nL\nM'),
              ),
              ListTile(
                leading: CircleAvatar(),
                trailing: SizedBox(height: 24.0, width: 24.0, child: Placeholder()),
                title: Text('A'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2)); // the text styles are animated when we change dense
    //                                                                          LEFT                 TOP                   WIDTH  HEIGHT
    expect(tester.getRect(find.byType(ListTile).at(0)),     const Rect.fromLTWH(                0.0,          0.0, 800.0, 216.0));
    expect(tester.getRect(find.byType(CircleAvatar).at(0)), const Rect.fromLTWH(               16.0,         16.0,  40.0,  40.0));
    expect(tester.getRect(find.byType(Placeholder).at(0)),  const Rect.fromLTWH(800.0 - 24.0 - 16.0,         16.0,  24.0,  24.0));
    expect(tester.getRect(find.byType(ListTile).at(1)),     const Rect.fromLTWH(                0.0, 216.0       , 800.0,  56.0));
    expect(tester.getRect(find.byType(CircleAvatar).at(1)), const Rect.fromLTWH(               16.0, 216.0 +  8.0,  40.0,  40.0));
    expect(tester.getRect(find.byType(Placeholder).at(1)),  const Rect.fromLTWH(800.0 - 24.0 - 16.0, 216.0 + 16.0,  24.0,  24.0));

    // DENSE "TWO"-LINE
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            children: const <Widget>[
              ListTile(
                dense: true,
                leading: CircleAvatar(),
                trailing: SizedBox(height: 24.0, width: 24.0, child: Placeholder()),
                title: Text('A'),
                subtitle: Text('A\nB\nC\nD\nE\nF\nG\nH\nI\nJ\nK\nL\nM'),
              ),
              ListTile(
                dense: true,
                leading: CircleAvatar(),
                trailing: SizedBox(height: 24.0, width: 24.0, child: Placeholder()),
                title: Text('A'),
                subtitle: Text('A'),
              ),
            ],
          ),
        ),
      ),
    );
    //                                                                          LEFT                 TOP          WIDTH  HEIGHT
    expect(tester.getRect(find.byType(ListTile).at(0)),     const Rect.fromLTWH(                0.0,          0.0, 800.0, 180.0));
    expect(tester.getRect(find.byType(CircleAvatar).at(0)), const Rect.fromLTWH(               16.0,         16.0,  40.0,  40.0));
    expect(tester.getRect(find.byType(Placeholder).at(0)),  const Rect.fromLTWH(800.0 - 24.0 - 16.0,         16.0,  24.0,  24.0));
    expect(tester.getRect(find.byType(ListTile).at(1)),     const Rect.fromLTWH(                0.0, 180.0,        800.0,  64.0));
    expect(tester.getRect(find.byType(CircleAvatar).at(1)), const Rect.fromLTWH(               16.0, 180.0 + 12.0,  40.0,  40.0));
    expect(tester.getRect(find.byType(Placeholder).at(1)),  const Rect.fromLTWH(800.0 - 24.0 - 16.0, 180.0 + 20.0,  24.0,  24.0));

    // NON-DENSE "TWO"-LINE
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            children: const <Widget>[
              ListTile(
                leading: CircleAvatar(),
                trailing: SizedBox(height: 24.0, width: 24.0, child: Placeholder()),
                title: Text('A'),
                subtitle: Text('A\nB\nC\nD\nE\nF\nG\nH\nI\nJ\nK\nL\nM'),
              ),
              ListTile(
                leading: CircleAvatar(),
                trailing: SizedBox(height: 24.0, width: 24.0, child: Placeholder()),
                title: Text('A'),
                subtitle: Text('A'),
              ),
            ],
          ),
        ),
      ),
    );
    //                                                                          LEFT                 TOP          WIDTH  HEIGHT
    expect(tester.getRect(find.byType(ListTile).at(0)),     const Rect.fromLTWH(                0.0,          0.0, 800.0, 180.0));
    expect(tester.getRect(find.byType(CircleAvatar).at(0)), const Rect.fromLTWH(               16.0,         16.0,  40.0,  40.0));
    expect(tester.getRect(find.byType(Placeholder).at(0)),  const Rect.fromLTWH(800.0 - 24.0 - 16.0,         16.0,  24.0,  24.0));
    expect(tester.getRect(find.byType(ListTile).at(1)),     const Rect.fromLTWH(                0.0, 180.0,        800.0,  72.0));
    expect(tester.getRect(find.byType(CircleAvatar).at(1)), const Rect.fromLTWH(               16.0, 180.0 + 16.0,  40.0,  40.0));
    expect(tester.getRect(find.byType(Placeholder).at(1)),  const Rect.fromLTWH(800.0 - 24.0 - 16.0, 180.0 + 24.0,  24.0,  24.0));

    // DENSE "THREE"-LINE
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            children: const <Widget>[
              ListTile(
                dense: true,
                isThreeLine: true,
                leading: CircleAvatar(),
                trailing: SizedBox(height: 24.0, width: 24.0, child: Placeholder()),
                title: Text('A'),
                subtitle: Text('A\nB\nC\nD\nE\nF\nG\nH\nI\nJ\nK\nL\nM'),
              ),
              ListTile(
                dense: true,
                isThreeLine: true,
                leading: CircleAvatar(),
                trailing: SizedBox(height: 24.0, width: 24.0, child: Placeholder()),
                title: Text('A'),
                subtitle: Text('A'),
              ),
            ],
          ),
        ),
      ),
    );
    //                                                                          LEFT                 TOP          WIDTH  HEIGHT
    expect(tester.getRect(find.byType(ListTile).at(0)),     const Rect.fromLTWH(                0.0,          0.0, 800.0, 180.0));
    expect(tester.getRect(find.byType(CircleAvatar).at(0)), const Rect.fromLTWH(               16.0,         16.0,  40.0,  40.0));
    expect(tester.getRect(find.byType(Placeholder).at(0)),  const Rect.fromLTWH(800.0 - 24.0 - 16.0,         16.0,  24.0,  24.0));
    expect(tester.getRect(find.byType(ListTile).at(1)),     const Rect.fromLTWH(                0.0, 180.0,        800.0,  76.0));
    expect(tester.getRect(find.byType(CircleAvatar).at(1)), const Rect.fromLTWH(               16.0, 180.0 + 16.0,  40.0,  40.0));
    expect(tester.getRect(find.byType(Placeholder).at(1)),  const Rect.fromLTWH(800.0 - 24.0 - 16.0, 180.0 + 16.0,  24.0,  24.0));

    // NON-DENSE THREE-LINE
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            children: const <Widget>[
              ListTile(
                isThreeLine: true,
                leading: CircleAvatar(),
                trailing: SizedBox(height: 24.0, width: 24.0, child: Placeholder()),
                title: Text('A'),
                subtitle: Text('A\nB\nC\nD\nE\nF\nG\nH\nI\nJ\nK\nL\nM'),
              ),
              ListTile(
                isThreeLine: true,
                leading: CircleAvatar(),
                trailing: SizedBox(height: 24.0, width: 24.0, child: Placeholder()),
                title: Text('A'),
                subtitle: Text('A'),
              ),
            ],
          ),
        ),
      ),
    );
    //                                                                          LEFT                 TOP          WIDTH  HEIGHT
    expect(tester.getRect(find.byType(ListTile).at(0)),     const Rect.fromLTWH(                0.0,          0.0, 800.0, 180.0));
    expect(tester.getRect(find.byType(CircleAvatar).at(0)), const Rect.fromLTWH(               16.0,         16.0,  40.0,  40.0));
    expect(tester.getRect(find.byType(Placeholder).at(0)),  const Rect.fromLTWH(800.0 - 24.0 - 16.0,         16.0,  24.0,  24.0));
    expect(tester.getRect(find.byType(ListTile).at(1)),     const Rect.fromLTWH(                0.0, 180.0,        800.0,  88.0));
    expect(tester.getRect(find.byType(CircleAvatar).at(1)), const Rect.fromLTWH(               16.0, 180.0 + 16.0,  40.0,  40.0));
    expect(tester.getRect(find.byType(Placeholder).at(1)),  const Rect.fromLTWH(800.0 - 24.0 - 16.0, 180.0 + 16.0,  24.0,  24.0));

    // "ONE-LINE" with Small Leading Widget
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            children: const <Widget>[
              ListTile(
                leading: SizedBox(height:12.0, width:24.0, child: Placeholder()),
                trailing: SizedBox(height: 24.0, width: 24.0, child: Placeholder()),
                title: Text('A\nB\nC\nD\nE\nF\nG\nH\nI\nJ\nK\nL\nM'),
              ),
              ListTile(
                leading: SizedBox(height:12.0, width:24.0, child: Placeholder()),
                trailing: SizedBox(height: 24.0, width: 24.0, child: Placeholder()),
                title: Text('A'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2)); // the text styles are animated when we change dense
    //                                                                          LEFT                 TOP           WIDTH  HEIGHT
    expect(tester.getRect(find.byType(ListTile).at(0)),     const Rect.fromLTWH(                0.0,          0.0, 800.0, 216.0));
    expect(tester.getRect(find.byType(Placeholder).at(0)),  const Rect.fromLTWH(               16.0,         16.0,  24.0,  12.0));
    expect(tester.getRect(find.byType(Placeholder).at(1)),  const Rect.fromLTWH(800.0 - 24.0 - 16.0,         16.0,  24.0,  24.0));
    expect(tester.getRect(find.byType(ListTile).at(1)),     const Rect.fromLTWH(                0.0, 216.0       , 800.0,  56.0));
    expect(tester.getRect(find.byType(Placeholder).at(2)),  const Rect.fromLTWH(               16.0, 216.0 + 16.0,  24.0,  12.0));
    expect(tester.getRect(find.byType(Placeholder).at(3)),  const Rect.fromLTWH(800.0 - 24.0 - 16.0, 216.0 + 16.0,  24.0,  24.0));
  });

  testWidgets('ListTile leading icon height does not exceed ListTile height', (WidgetTester tester) async {
    // regression test for https://github.com/flutter/flutter/issues/28765
    const SizedBox oversizedWidget = SizedBox(height: 80.0, width: 24.0, child: Placeholder());

    // Dense One line
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            children: const <Widget>[
              ListTile(
                leading: oversizedWidget,
                title: Text('A'),
                dense: true,
              ),
              ListTile(
                leading: oversizedWidget,
                title: Text('B'),
                dense: true,
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.getRect(find.byType(Placeholder).at(0)), const Rect.fromLTWH(16.0,  0.0, 24.0, 48.0));
    expect(tester.getRect(find.byType(Placeholder).at(1)), const Rect.fromLTWH(16.0, 48.0, 24.0, 48.0));

    // Non-dense One line
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            children: const <Widget>[
              ListTile(
                leading: oversizedWidget,
                title: Text('A'),
                dense: false,
              ),
              ListTile(
                leading: oversizedWidget,
                title: Text('B'),
                dense: false,
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.getRect(find.byType(Placeholder).at(0)), const Rect.fromLTWH(16.0,  0.0, 24.0, 56.0));
    expect(tester.getRect(find.byType(Placeholder).at(1)), const Rect.fromLTWH(16.0, 56.0, 24.0, 56.0));

    // Dense Two line
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            children: const <Widget>[
              ListTile(
                leading: oversizedWidget,
                title: Text('A'),
                subtitle: Text('A'),
                dense: true,
              ),
              ListTile(
                leading: oversizedWidget,
                title: Text('B'),
                subtitle: Text('B'),
                dense: true,
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.getRect(find.byType(Placeholder).at(0)), const Rect.fromLTWH(16.0,        8.0, 24.0, 48.0));
    expect(tester.getRect(find.byType(Placeholder).at(1)), const Rect.fromLTWH(16.0, 64.0 + 8.0, 24.0, 48.0));

    // Non-dense Two line
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            children: const <Widget>[
              ListTile(
                leading: oversizedWidget,
                title: Text('A'),
                subtitle: Text('A'),
                dense: false,
              ),
              ListTile(
                leading: oversizedWidget,
                title: Text('B'),
                subtitle: Text('B'),
                dense: false,
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.getRect(find.byType(Placeholder).at(0)), const Rect.fromLTWH(16.0,        8.0, 24.0, 56.0));
    expect(tester.getRect(find.byType(Placeholder).at(1)), const Rect.fromLTWH(16.0, 72.0 + 8.0, 24.0, 56.0));

    // Dense Three line
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            children: const <Widget>[
              ListTile(
                leading: oversizedWidget,
                title: Text('A'),
                subtitle: Text('A'),
                isThreeLine:  true,
                dense: true,
              ),
              ListTile(
                leading: oversizedWidget,
                title: Text('B'),
                subtitle: Text('B'),
                isThreeLine:  true,
                dense: true,
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.getRect(find.byType(Placeholder).at(0)), const Rect.fromLTWH(16.0,        16.0, 24.0, 48.0));
    expect(tester.getRect(find.byType(Placeholder).at(1)), const Rect.fromLTWH(16.0, 76.0 + 16.0, 24.0, 48.0));

    // Non-dense Three line
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            children: const <Widget>[
              ListTile(
                leading: oversizedWidget,
                title: Text('A'),
                subtitle: Text('A'),
                isThreeLine:  true,
                dense: false,
              ),
              ListTile(
                leading: oversizedWidget,
                title: Text('B'),
                subtitle: Text('B'),
                isThreeLine:  true,
                dense: false,
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.getRect(find.byType(Placeholder).at(0)), const Rect.fromLTWH(16.0,        16.0, 24.0, 56.0));
    expect(tester.getRect(find.byType(Placeholder).at(1)), const Rect.fromLTWH(16.0, 88.0 + 16.0, 24.0, 56.0));
  });

  testWidgets('ListTile trailing icon height does not exceed ListTile height', (WidgetTester tester) async {
    // regression test for https://github.com/flutter/flutter/issues/28765
    const SizedBox oversizedWidget = SizedBox(height: 80.0, width: 24.0, child: Placeholder());

    // Dense One line
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            children: const <Widget>[
              ListTile(
                trailing: oversizedWidget,
                title: Text('A'),
                dense: true,
              ),
              ListTile(
                trailing: oversizedWidget,
                title: Text('B'),
                dense: true,
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.getRect(find.byType(Placeholder).at(0)), const Rect.fromLTWH(800.0 - 16.0 - 24.0,    0, 24.0, 48.0));
    expect(tester.getRect(find.byType(Placeholder).at(1)), const Rect.fromLTWH(800.0 - 16.0 - 24.0, 48.0, 24.0, 48.0));

    // Non-dense One line
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            children: const <Widget>[
              ListTile(
                trailing: oversizedWidget,
                title: Text('A'),
                dense: false,
              ),
              ListTile(
                trailing: oversizedWidget,
                title: Text('B'),
                dense: false,
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.getRect(find.byType(Placeholder).at(0)), const Rect.fromLTWH(800.0 - 16.0 - 24.0,  0.0, 24.0, 56.0));
    expect(tester.getRect(find.byType(Placeholder).at(1)), const Rect.fromLTWH(800.0 - 16.0 - 24.0, 56.0, 24.0, 56.0));

    // Dense Two line
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            children: const <Widget>[
              ListTile(
                trailing: oversizedWidget,
                title: Text('A'),
                subtitle: Text('A'),
                dense: true,
              ),
              ListTile(
                trailing: oversizedWidget,
                title: Text('B'),
                subtitle: Text('B'),
                dense: true,
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.getRect(find.byType(Placeholder).at(0)), const Rect.fromLTWH(800.0 - 16.0 - 24.0,        8.0, 24.0, 48.0));
    expect(tester.getRect(find.byType(Placeholder).at(1)), const Rect.fromLTWH(800.0 - 16.0 - 24.0, 64.0 + 8.0, 24.0, 48.0));

    // Non-dense Two line
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            children: const <Widget>[
              ListTile(
                trailing: oversizedWidget,
                title: Text('A'),
                subtitle: Text('A'),
                dense: false,
              ),
              ListTile(
                trailing: oversizedWidget,
                title: Text('B'),
                subtitle: Text('B'),
                dense: false,
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.getRect(find.byType(Placeholder).at(0)), const Rect.fromLTWH(800.0 - 16.0 - 24.0,        8.0, 24.0, 56.0));
    expect(tester.getRect(find.byType(Placeholder).at(1)), const Rect.fromLTWH(800.0 - 16.0 - 24.0, 72.0 + 8.0, 24.0, 56.0));

    // Dense Three line
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            children: const <Widget>[
              ListTile(
                trailing: oversizedWidget,
                title: Text('A'),
                subtitle: Text('A'),
                isThreeLine:  true,
                dense: true,
              ),
              ListTile(
                trailing: oversizedWidget,
                title: Text('B'),
                subtitle: Text('B'),
                isThreeLine:  true,
                dense: true,
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.getRect(find.byType(Placeholder).at(0)), const Rect.fromLTWH(800.0 - 16.0 - 24.0,        16.0, 24.0, 48.0));
    expect(tester.getRect(find.byType(Placeholder).at(1)), const Rect.fromLTWH(800.0 - 16.0 - 24.0, 76.0 + 16.0, 24.0, 48.0));

    // Non-dense Three line
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            children: const <Widget>[
              ListTile(
                trailing: oversizedWidget,
                title: Text('A'),
                subtitle: Text('A'),
                isThreeLine:  true,
                dense: false,
              ),
              ListTile(
                trailing: oversizedWidget,
                title: Text('B'),
                subtitle: Text('B'),
                isThreeLine:  true,
                dense: false,
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.getRect(find.byType(Placeholder).at(0)), const Rect.fromLTWH(800.0 - 16.0 - 24.0,        16.0, 24.0, 56.0));
    expect(tester.getRect(find.byType(Placeholder).at(1)), const Rect.fromLTWH(800.0 - 16.0 - 24.0, 88.0 + 16.0, 24.0, 56.0));
  });

  testWidgets('ListTile only accepts focus when enabled', (WidgetTester tester) async {
    final GlobalKey childKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            children: <Widget>[
              ListTile(
                title: Text('A', key: childKey),
                dense: true,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(); // Let the focus take effect.

    final FocusNode tileNode = Focus.of(childKey.currentContext!);
    tileNode.requestFocus();
    await tester.pump(); // Let the focus take effect.
    expect(Focus.of(childKey.currentContext!).hasPrimaryFocus, isTrue);

    expect(tileNode.hasPrimaryFocus, isTrue);
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            children: <Widget>[
              ListTile(
                title: Text('A', key: childKey),
                dense: true,
                enabled: false,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.binding.focusManager.primaryFocus, isNot(equals(tileNode)));
    expect(Focus.of(childKey.currentContext!).hasPrimaryFocus, isFalse);
  });

  testWidgets('ListTile can autofocus unless disabled.', (WidgetTester tester) async {
    final GlobalKey childKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            children: <Widget>[
              ListTile(
                title: Text('A', key: childKey),
                dense: true,
                autofocus: true,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pump();
    expect(Focus.of(childKey.currentContext!).hasPrimaryFocus, isTrue);

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            children: <Widget>[
              ListTile(
                title: Text('A', key: childKey),
                dense: true,
                enabled: false,
                autofocus: true,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pump();
    expect(Focus.of(childKey.currentContext!).hasPrimaryFocus, isFalse);
  });

  testWidgets('ListTile is focusable and has correct focus color', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode(debugLabel: 'ListTile');
    tester.binding.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    Widget buildApp({bool enabled = true}) {
      return MaterialApp(
        home: Material(
          child: Center(
            child: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
              return Container(
                width: 100,
                height: 100,
                color: Colors.white,
                child: ListTile(
                  onTap: enabled ? () {} : null,
                  focusColor: Colors.orange[500],
                  autofocus: true,
                  focusNode: focusNode,
                ),
              );
            }),
          ),
        ),
      );
    }
    await tester.pumpWidget(buildApp());

    await tester.pumpAndSettle();
    expect(focusNode.hasPrimaryFocus, isTrue);
    expect(
      find.byType(Material),
      paints
        ..rect()
        ..rect(
            color: Colors.orange[500],
            rect: const Rect.fromLTRB(350.0, 250.0, 450.0, 350.0),
          )
        ..rect(
            color: const Color(0xffffffff),
            rect: const Rect.fromLTRB(350.0, 250.0, 450.0, 350.0),
          ),
    );

    // Check when the list tile is disabled.
    await tester.pumpWidget(buildApp(enabled: false));
    await tester.pumpAndSettle();
    expect(focusNode.hasPrimaryFocus, isFalse);
    expect(
      find.byType(Material),
      paints
        ..rect()
        ..rect(
            color: const Color(0xffffffff),
            rect: const Rect.fromLTRB(350.0, 250.0, 450.0, 350.0),
          ),
    );
  });

  testWidgets('ListTile can be hovered and has correct hover color', (WidgetTester tester) async {
    tester.binding.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    Widget buildApp({bool enabled = true}) {
      return MaterialApp(
        home: Material(
          child: Center(
            child: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
              return Container(
                width: 100,
                height: 100,
                color: Colors.white,
                child: ListTile(
                  onTap: enabled ? () {} : null,
                  hoverColor: Colors.orange[500],
                  autofocus: true,
                ),
              );
            }),
          ),
        ),
      );
    }
    await tester.pumpWidget(buildApp());

    await tester.pump();
    await tester.pumpAndSettle();
    expect(
      find.byType(Material),
      paints
        ..rect()
        ..rect(
            color: const Color(0x1f000000),
            rect: const Rect.fromLTRB(350.0, 250.0, 450.0, 350.0),
          )
        ..rect(
            color: const Color(0xffffffff),
            rect: const Rect.fromLTRB(350.0, 250.0, 450.0, 350.0),
          ),
    );

    // Start hovering
    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.moveTo(tester.getCenter(find.byType(ListTile)));

    await tester.pumpWidget(buildApp());
    await tester.pump();
    await tester.pumpAndSettle();
    expect(
      find.byType(Material),
      paints
        ..rect()
        ..rect(
            color: const Color(0x1f000000),
            rect: const Rect.fromLTRB(350.0, 250.0, 450.0, 350.0),
          )
        ..rect(
            color: Colors.orange[500],
            rect: const Rect.fromLTRB(350.0, 250.0, 450.0, 350.0),
          )
        ..rect(
            color: const Color(0xffffffff),
            rect: const Rect.fromLTRB(350.0, 250.0, 450.0, 350.0),
          ),
    );

    await tester.pumpWidget(buildApp(enabled: false));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(
      find.byType(Material),
      paints
        ..rect()
        ..rect(
            color: Colors.orange[500],
            rect: const Rect.fromLTRB(350.0, 250.0, 450.0, 350.0),
          )
        ..rect(
            color: const Color(0xffffffff),
            rect: const Rect.fromLTRB(350.0, 250.0, 450.0, 350.0),
          ),
    );
  });

  testWidgets('ListTile can be splashed and has correct splash color', (WidgetTester tester) async {
    final Widget buildApp = MaterialApp(
      home: Material(
        child: Center(
          child: SizedBox(
            width: 100,
            height: 100,
            child: ListTile(
              onTap: () {},
              splashColor: const Color(0xff88ff88),
            ),
          ),
        ),
      ),
    );

    await tester.pumpWidget(buildApp);
    await tester.pumpAndSettle();
    final TestGesture gesture = await tester.startGesture(tester.getRect(find.byType(ListTile)).center);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(Material), paints..circle(x: 50, y: 50, color: const Color(0xff88ff88)));
    await gesture.up();
  });

  testWidgets('ListTile can be triggered by keyboard shortcuts', (WidgetTester tester) async {
    tester.binding.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    const Key tileKey = Key('ListTile');
    bool tapped = false;
    Widget buildApp({bool enabled = true}) {
      return MaterialApp(
        home: Material(
          child: Center(
            child: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
              return Container(
                width: 200,
                height: 100,
                color: Colors.white,
                child: ListTile(
                  key: tileKey,
                  onTap: enabled ? () {
                    setState(() {
                      tapped = true;
                    });
                  } : null,
                  hoverColor: Colors.orange[500],
                  autofocus: true,
                ),
              );
            }),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });

  testWidgets('ListTile responds to density changes.', (WidgetTester tester) async {
    const Key key = Key('test');
    Future<void> buildTest(VisualDensity visualDensity) async {
      return tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Center(
              child: ListTile(
                key: key,
                onTap: () {},
                autofocus: true,
                visualDensity: visualDensity,
              ),
            ),
          ),
        ),
      );
    }

    await buildTest(VisualDensity.standard);
    final RenderBox box = tester.renderObject(find.byKey(key));
    await tester.pumpAndSettle();
    expect(box.size, equals(const Size(800, 56)));

    await buildTest(const VisualDensity(horizontal: 3.0, vertical: 3.0));
    await tester.pumpAndSettle();
    expect(box.size, equals(const Size(800, 68)));

    await buildTest(const VisualDensity(horizontal: -3.0, vertical: -3.0));
    await tester.pumpAndSettle();
    expect(box.size, equals(const Size(800, 44)));

    await buildTest(const VisualDensity(horizontal: 3.0, vertical: -3.0));
    await tester.pumpAndSettle();
    expect(box.size, equals(const Size(800, 44)));
  });

  testWidgets('ListTile shape is painted correctly', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/63877
    const ShapeBorder rectShape = RoundedRectangleBorder();
    const ShapeBorder stadiumShape = StadiumBorder();
    final Color tileColor = Colors.red.shade500;

    Widget buildListTile(ShapeBorder shape) {
      return MaterialApp(
        home: Material(
          child: Center(
            child: ListTile(shape: shape, tileColor: tileColor),
          ),
        ),
      );
    }

    // Test rectangle shape
    await tester.pumpWidget(buildListTile(rectShape));
    Rect rect = tester.getRect(find.byType(ListTile));

    // Check if a rounded rectangle was painted with the correct color and shape
    expect(
      find.byType(Material),
      paints..rect(color: tileColor, rect: rect),
    );

    // Test stadium shape
    await tester.pumpWidget(buildListTile(stadiumShape));
    rect = tester.getRect(find.byType(ListTile));

    // Check if a rounded rectangle was painted with the correct color and shape
    expect(
      find.byType(Material),
      paints..clipRect()..rrect(
        color: tileColor,
        rrect: RRect.fromRectAndRadius(rect, Radius.circular(rect.shortestSide / 2.0)),
      ),
    );
  });

  testWidgets('ListTile changes mouse cursor when hovered', (WidgetTester tester) async {
    // Test ListTile() constructor
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: MouseRegion(
              cursor: SystemMouseCursors.forbidden,
              child: ListTile(
                onTap: () {},
                mouseCursor: SystemMouseCursors.text,
              ),
            ),
          ),
        ),
      ),
    );

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse, pointer: 1);
    await gesture.addPointer(location: tester.getCenter(find.byType(ListTile)));

    await tester.pump();

    expect(RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.text);

    // Test default cursor
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: MouseRegion(
              cursor: SystemMouseCursors.forbidden,
              child: ListTile(
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.click);

    // Test default cursor when disabled
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: Center(
            child: MouseRegion(
              cursor: SystemMouseCursors.forbidden,
              child: ListTile(
                enabled: false,
              ),
            ),
          ),
        ),
      ),
    );

    expect(RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.basic);

    // Test default cursor when onTap or onLongPress is null
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: Center(
            child: MouseRegion(
              cursor: SystemMouseCursors.forbidden,
              child: ListTile(),
            ),
          ),
        ),
      ),
    );

    expect(RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.basic);
  });

  testWidgets('ListTile respects tileColor & selectedTileColor', (WidgetTester tester) async {
    bool isSelected = false;
    final Color tileColor = Colors.green.shade500;
    final Color selectedTileColor = Colors.red.shade500;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return ListTile(
                  selected: isSelected,
                  selectedTileColor: selectedTileColor,
                  tileColor: tileColor,
                  onTap: () {
                    setState(()=> isSelected = !isSelected);
                  },
                  title: const Text('Title'),
                );
              },
            ),
          ),
        ),
      ),
    );

    // Initially, when isSelected is false, the ListTile should respect tileColor.
    expect(find.byType(Material), paints..rect(color: tileColor));

    // Tap on tile to change isSelected.
    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();

    // When isSelected is true, the ListTile should respect selectedTileColor.
    expect(find.byType(Material), paints..rect(color: selectedTileColor));
  });

  testWidgets('ListTile shows Material ripple effects on top of tileColor', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/73616
    final Color tileColor = Colors.red.shade500;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: ListTile(
              tileColor: tileColor,
              onTap: () {},
              title: const Text('Title'),
            ),
          ),
        ),
      ),
    );

    // Before ListTile is tapped, it should be tileColor
    expect(find.byType(Material), paints..rect(color: tileColor));

    // Tap on tile to trigger ink effect and wait for it to be underway.
    await tester.tap(find.byType(ListTile));
    await tester.pump(const Duration(milliseconds: 200));

    // After tap, the tile could be drawn in tileColor, with the ripple (circle) on top
    expect(
      find.byType(Material),
      paints
        ..rect(color: tileColor)
        ..circle(),
    );
  });

  testWidgets('ListTile default tile color', (WidgetTester tester) async {
    bool isSelected = false;
    const Color defaultColor = Colors.transparent;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return ListTile(
                  selected: isSelected,
                  onTap: () {
                    setState(()=> isSelected = !isSelected);
                  },
                  title: const Text('Title'),
                );
              },
            ),
          ),
        ),
      ),
    );

    expect(find.byType(Material), paints..rect(color: defaultColor));

    // Tap on tile to change isSelected.
    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();

    expect(find.byType(Material), paints..rect(color: defaultColor));
  });

  testWidgets('ListTile layout at zero size', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/66636
    const Key key = Key('key');

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 0.0,
          height: 0.0,
          child: ListTile(
            key: key,
            tileColor: Colors.green,
          ),
        ),
      ),
    ));

    final RenderBox renderBox = tester.renderObject(find.byKey(key));
    expect(renderBox.size.width, equals(0.0));
    expect(renderBox.size.height, equals(0.0));
  });

  group('feedback', () {
    late FeedbackTester feedback;

    setUp(() {
      feedback = FeedbackTester();
    });

    tearDown(() {
      feedback.dispose();
    });

    testWidgets('ListTile with disabled feedback', (WidgetTester tester) async {
      const bool enableFeedback = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: ListTile(
              title: const Text('Title'),
              onTap: () {},
              enableFeedback: enableFeedback,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ListTile));
      await tester.pump(const Duration(seconds: 1));
      expect(feedback.clickSoundCount, 0);
      expect(feedback.hapticCount, 0);
    });

    testWidgets('ListTile with enabled feedback', (WidgetTester tester) async {
      const bool enableFeedback = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: ListTile(
              title: const Text('Title'),
              onTap: () {},
              enableFeedback: enableFeedback,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ListTile));
      await tester.pump(const Duration(seconds: 1));
      expect(feedback.clickSoundCount, 1);
      expect(feedback.hapticCount, 0);
    });

    testWidgets('ListTile with enabled feedback by default', (WidgetTester tester) async {

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: ListTile(
              title: const Text('Title'),
              onTap: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ListTile));
      await tester.pump(const Duration(seconds: 1));
      expect(feedback.clickSoundCount, 1);
      expect(feedback.hapticCount, 0);
    });

    testWidgets('ListTile with disabled feedback using ListTileTheme', (WidgetTester tester) async {
      const bool enableFeedbackTheme = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: ListTileTheme(
              data: const ListTileThemeData(enableFeedback: enableFeedbackTheme),
              child: ListTile(
                title: const Text('Title'),
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ListTile));
      await tester.pump(const Duration(seconds: 1));
      expect(feedback.clickSoundCount, 0);
      expect(feedback.hapticCount, 0);
    });

    testWidgets('ListTile.enableFeedback overrides ListTileTheme.enableFeedback', (WidgetTester tester) async {
      const bool enableFeedbackTheme = false;
      const bool enableFeedback = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: ListTileTheme(
              data: const ListTileThemeData(enableFeedback: enableFeedbackTheme),
              child: ListTile(
                enableFeedback: enableFeedback,
                title: const Text('Title'),
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ListTile));
      await tester.pump(const Duration(seconds: 1));
      expect(feedback.clickSoundCount, 1);
      expect(feedback.hapticCount, 0);
    });

    testWidgets('ListTile.mouseCursor overrides ListTileTheme.mouseCursor', (WidgetTester tester) async {
      final Key tileKey = UniqueKey();

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: ListTileTheme(
              data: const ListTileThemeData(mouseCursor: MaterialStateMouseCursor.clickable),
              child: ListTile(
                key: tileKey,
                mouseCursor: MaterialStateMouseCursor.textable,
                title: const Text('Title'),
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      final Offset listTile = tester.getCenter(find.byKey(tileKey));
      final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer();
      await gesture.moveTo(listTile);
      await tester.pumpAndSettle();
      expect(RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.text);
    });
  });

  testWidgets('ListTile horizontalTitleGap = 0.0', (WidgetTester tester) async {
    Widget buildFrame(TextDirection textDirection, { double? themeHorizontalTitleGap, double? widgetHorizontalTitleGap }) {
      return MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: textDirection,
          child: Material(
            child: ListTileTheme(
              data: ListTileThemeData(horizontalTitleGap: themeHorizontalTitleGap),
              child: Container(
                alignment: Alignment.topLeft,
                child: ListTile(
                  horizontalTitleGap: widgetHorizontalTitleGap,
                  leading: const Text('L'),
                  title: const Text('title'),
                  trailing: const Text('T'),
                ),
              ),
            ),
          ),
        ),
      );
    }

    double left(String text) => tester.getTopLeft(find.text(text)).dx;
    double right(String text) => tester.getTopRight(find.text(text)).dx;

    await tester.pumpWidget(buildFrame(TextDirection.ltr, widgetHorizontalTitleGap: 0));
    expect(tester.getSize(find.byType(ListTile)), const Size(800.0, 56.0));
    expect(left('title'), 56.0);

    await tester.pumpWidget(buildFrame(TextDirection.ltr, themeHorizontalTitleGap: 0));
    expect(tester.getSize(find.byType(ListTile)), const Size(800.0, 56.0));
    expect(left('title'), 56.0);

    await tester.pumpWidget(buildFrame(TextDirection.ltr, themeHorizontalTitleGap: 10, widgetHorizontalTitleGap: 0));
    expect(tester.getSize(find.byType(ListTile)), const Size(800.0, 56.0));
    expect(left('title'), 56.0);

    await tester.pumpWidget(buildFrame(TextDirection.rtl, widgetHorizontalTitleGap: 0));
    expect(tester.getSize(find.byType(ListTile)), const Size(800.0, 56.0));
    expect(right('title'), 744.0);

    await tester.pumpWidget(buildFrame(TextDirection.rtl, themeHorizontalTitleGap: 0));
    expect(tester.getSize(find.byType(ListTile)), const Size(800.0, 56.0));
    expect(right('title'), 744.0);

    await tester.pumpWidget(buildFrame(TextDirection.rtl, themeHorizontalTitleGap: 10, widgetHorizontalTitleGap: 0));
    expect(tester.getSize(find.byType(ListTile)), const Size(800.0, 56.0));
    expect(right('title'), 744.0);
  });

  testWidgets('ListTile horizontalTitleGap = (default) && ListTile minLeadingWidth = (default)', (WidgetTester tester) async {
    Widget buildFrame(TextDirection textDirection) {
      return MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: textDirection,
          child: Material(
            child: Container(
              alignment: Alignment.topLeft,
              child: const ListTile(
                leading: Text('L'),
                title: Text('title'),
                trailing: Text('T'),
              ),
            ),
          ),
        ),
      );
    }

    double left(String text) => tester.getTopLeft(find.text(text)).dx;
    double right(String text) => tester.getTopRight(find.text(text)).dx;

    await tester.pumpWidget(buildFrame(TextDirection.ltr));

    expect(tester.getSize(find.byType(ListTile)), const Size(800.0, 56.0));
    // horizontalTitleGap: ListTileDefaultValue.horizontalTitleGap (16.0)
    expect(left('title'), 72.0);

    await tester.pumpWidget(buildFrame(TextDirection.rtl));

    expect(tester.getSize(find.byType(ListTile)), const Size(800.0, 56.0));
    // horizontalTitleGap: ListTileDefaultValue.horizontalTitleGap (16.0)
    expect(right('title'), 728.0);
  });

  testWidgets('ListTile horizontalTitleGap with visualDensity', (WidgetTester tester) async {
    Widget buildFrame({
      double? horizontalTitleGap,
      VisualDensity? visualDensity,
    }) {
      return MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            child: Container(
              alignment: Alignment.topLeft,
              child: ListTile(
                visualDensity: visualDensity,
                horizontalTitleGap: horizontalTitleGap,
                leading: const Text('L'),
                title: const Text('title'),
                trailing: const Text('T'),
              ),
            ),
          ),
        ),
      );
    }

    double left(String text) => tester.getTopLeft(find.text(text)).dx;

    await tester.pumpWidget(buildFrame(
      horizontalTitleGap: 10.0,
      visualDensity: const VisualDensity(horizontal: VisualDensity.minimumDensity),
    ));
    expect(tester.getSize(find.byType(ListTile)), const Size(800.0, 56.0));
    expect(left('title'), 58.0);

    // Pump another frame of the same widget to ensure the underlying render
    // object did not cache the original horizontalTitleGap calculation based on the
    // visualDensity
    await tester.pumpWidget(buildFrame(
      horizontalTitleGap: 10.0,
      visualDensity: const VisualDensity(horizontal: VisualDensity.minimumDensity),
    ));
    expect(tester.getSize(find.byType(ListTile)), const Size(800.0, 56.0));
    expect(left('title'), 58.0);
  });

  testWidgets('ListTile minVerticalPadding = 80.0', (WidgetTester tester) async {
    Widget buildFrame(TextDirection textDirection, { double? themeMinVerticalPadding, double? widgetMinVerticalPadding }) {
      return MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: textDirection,
          child: Material(
            child: ListTileTheme(
              data: ListTileThemeData(minVerticalPadding: themeMinVerticalPadding),
              child: Container(
                alignment: Alignment.topLeft,
                child: ListTile(
                  minVerticalPadding: widgetMinVerticalPadding,
                  leading: const Text('L'),
                  title: const Text('title'),
                  trailing: const Text('T'),
                ),
              ),
            ),
          ),
        ),
      );
    }


    await tester.pumpWidget(buildFrame(TextDirection.ltr, widgetMinVerticalPadding: 80));
    // 80 + 80 + 16(Title) = 176
    expect(tester.getSize(find.byType(ListTile)), const Size(800.0, 176.0));

    await tester.pumpWidget(buildFrame(TextDirection.ltr, themeMinVerticalPadding: 80));
    expect(tester.getSize(find.byType(ListTile)), const Size(800.0, 176.0));

    await tester.pumpWidget(buildFrame(TextDirection.ltr, themeMinVerticalPadding: 0, widgetMinVerticalPadding: 80));
    expect(tester.getSize(find.byType(ListTile)), const Size(800.0, 176.0));

    await tester.pumpWidget(buildFrame(TextDirection.rtl, widgetMinVerticalPadding: 80));
    // 80 + 80 + 16(Title) = 176
    expect(tester.getSize(find.byType(ListTile)), const Size(800.0, 176.0));

    await tester.pumpWidget(buildFrame(TextDirection.rtl, themeMinVerticalPadding: 80));
    expect(tester.getSize(find.byType(ListTile)), const Size(800.0, 176.0));

    await tester.pumpWidget(buildFrame(TextDirection.rtl, themeMinVerticalPadding: 0, widgetMinVerticalPadding: 80));
    expect(tester.getSize(find.byType(ListTile)), const Size(800.0, 176.0));
  });

  testWidgets('ListTile minLeadingWidth = 60.0', (WidgetTester tester) async {
    Widget buildFrame(TextDirection textDirection, { double? themeMinLeadingWidth, double? widgetMinLeadingWidth }) {
      return MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: textDirection,
          child: Material(
            child: ListTileTheme(
              data: ListTileThemeData(minLeadingWidth: themeMinLeadingWidth),
              child: Container(
                alignment: Alignment.topLeft,
                child: ListTile(
                  minLeadingWidth: widgetMinLeadingWidth,
                  leading: const Text('L'),
                  title: const Text('title'),
                  trailing: const Text('T'),
                ),
              ),
            ),
          ),
        ),
      );
    }

    double left(String text) => tester.getTopLeft(find.text(text)).dx;
    double right(String text) => tester.getTopRight(find.text(text)).dx;

    await tester.pumpWidget(buildFrame(TextDirection.ltr, widgetMinLeadingWidth: 60));
    expect(tester.getSize(find.byType(ListTile)), const Size(800.0, 56.0));
    // 92.0 = 16.0(Default contentPadding) + 16.0(Default horizontalTitleGap) + 60.0
    expect(left('title'), 92.0);

    await tester.pumpWidget(buildFrame(TextDirection.ltr, themeMinLeadingWidth: 60));
    expect(tester.getSize(find.byType(ListTile)), const Size(800.0, 56.0));
    expect(left('title'), 92.0);

    await tester.pumpWidget(buildFrame(TextDirection.ltr, themeMinLeadingWidth: 0, widgetMinLeadingWidth: 60));
    expect(tester.getSize(find.byType(ListTile)), const Size(800.0, 56.0));
    expect(left('title'), 92.0);


    await tester.pumpWidget(buildFrame(TextDirection.rtl, widgetMinLeadingWidth: 60));
    expect(tester.getSize(find.byType(ListTile)), const Size(800.0, 56.0));
    // 708.0 = 800.0 - (16.0(Default contentPadding) + 16.0(Default horizontalTitleGap) + 60.0)
    expect(right('title'), 708.0);

    await tester.pumpWidget(buildFrame(TextDirection.rtl, themeMinLeadingWidth: 60));
    expect(tester.getSize(find.byType(ListTile)), const Size(800.0, 56.0));
    expect(right('title'), 708.0);

    await tester.pumpWidget(buildFrame(TextDirection.rtl, themeMinLeadingWidth: 0, widgetMinLeadingWidth: 60));
    expect(tester.getSize(find.byType(ListTile)), const Size(800.0, 56.0));
    expect(right('title'), 708.0);
  });

  testWidgets('colors are applied to leading and trailing text widgets', (WidgetTester tester) async {
    final Key leadingKey = UniqueKey();
    final Key trailingKey = UniqueKey();

    late ThemeData theme;
    Widget buildFrame({
      bool enabled = true,
      bool selected = false,
    }) {
      return MaterialApp(
        home: Material(
          child: Center(
            child: Builder(
              builder: (BuildContext context) {
                theme = Theme.of(context);
                return ListTile(
                  enabled: enabled,
                  selected: selected,
                  leading: TestText('leading', key: leadingKey),
                  title: const TestText('title'),
                  trailing: TestText('trailing', key: trailingKey),
                );
              },
            ),
          ),
        ),
      );
    }

    Color textColor(Key key) => tester.state<TestTextState>(find.byKey(key)).textStyle.color!;

    await tester.pumpWidget(buildFrame());
    // Enabled color should be default bodyMedium color.
    expect(textColor(leadingKey), theme.textTheme.bodyMedium!.color);
    expect(textColor(trailingKey), theme.textTheme.bodyMedium!.color);

    await tester.pumpWidget(buildFrame(selected: true));
    // Wait for text color to animate.
    await tester.pumpAndSettle();
    // Selected color should be ThemeData.primaryColor by default.
    expect(textColor(leadingKey), theme.primaryColor);
    expect(textColor(trailingKey), theme.primaryColor);

    await tester.pumpWidget(buildFrame(enabled: false));
    // Wait for text color to animate.
    await tester.pumpAndSettle();
    // Disabled color should be ThemeData.disabledColor by default.
    expect(textColor(leadingKey), theme.disabledColor);
    expect(textColor(trailingKey), theme.disabledColor);
  });

  testWidgets('selected, enabled ListTile default icon color, light and dark themes', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/pull/77004

    const ColorScheme lightColorScheme = ColorScheme.light();
    const ColorScheme darkColorScheme = ColorScheme.dark();
    final Key leadingKey = UniqueKey();
    final Key titleKey = UniqueKey();
    final Key subtitleKey = UniqueKey();
    final Key trailingKey = UniqueKey();

    Widget buildFrame({ required Brightness brightness, required bool selected }) {
      final ThemeData theme = brightness == Brightness.light
        ? ThemeData.from(colorScheme: const ColorScheme.light())
        : ThemeData.from(colorScheme: const ColorScheme.dark());
      return MaterialApp(
        theme: theme,
        home: Material(
          child: Center(
            child: ListTile(
              selected: selected,
              leading: TestIcon(key: leadingKey),
              title: TestIcon(key: titleKey),
              subtitle: TestIcon(key: subtitleKey),
              trailing: TestIcon(key: trailingKey),
            ),
          ),
        ),
      );
    }

    Color iconColor(Key key) => tester.state<TestIconState>(find.byKey(key)).iconTheme.color!;

    await tester.pumpWidget(buildFrame(brightness: Brightness.light, selected: true));
    expect(iconColor(leadingKey), lightColorScheme.primary);
    expect(iconColor(titleKey), lightColorScheme.primary);
    expect(iconColor(subtitleKey), lightColorScheme.primary);
    expect(iconColor(trailingKey), lightColorScheme.primary);

    await tester.pumpWidget(buildFrame(brightness: Brightness.light, selected: false));
    expect(iconColor(leadingKey), Colors.black45);
    expect(iconColor(titleKey), Colors.black45);
    expect(iconColor(subtitleKey), Colors.black45);
    expect(iconColor(trailingKey), Colors.black45);

    await tester.pumpWidget(buildFrame(brightness: Brightness.dark, selected: true));
    await tester.pumpAndSettle(); // Animated theme change
    expect(iconColor(leadingKey), darkColorScheme.primary);
    expect(iconColor(titleKey), darkColorScheme.primary);
    expect(iconColor(subtitleKey), darkColorScheme.primary);
    expect(iconColor(trailingKey), darkColorScheme.primary);

    // For this configuration, ListTile defers to the default IconTheme.
    // The default dark theme's IconTheme has color:white
    await tester.pumpWidget(buildFrame(brightness: Brightness.dark, selected: false));
    expect(iconColor(leadingKey),  Colors.white);
    expect(iconColor(titleKey),  Colors.white);
    expect(iconColor(subtitleKey),  Colors.white);
    expect(iconColor(trailingKey), Colors.white);
  });

  testWidgets('ListTile font size', (WidgetTester tester) async {
    Widget buildFrame({
      bool dense = false,
      bool enabled = true,
      bool selected = false,
      ListTileStyle? style,
    }) {
      return MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Material(
          child: Center(
            child: Builder(
              builder: (BuildContext context) {
                return ListTile(
                  dense: dense,
                  enabled: enabled,
                  selected: selected,
                  style: style,
                  leading: const TestText('leading'),
                  title: const TestText('title'),
                  subtitle: const TestText('subtitle') ,
                  trailing: const TestText('trailing'),
                );
              },
            ),
          ),
        ),
      );
    }

    // ListTile - ListTileStyle.list (default).
    await tester.pumpWidget(buildFrame());
    RenderParagraph leading = _getTextRenderObject(tester, 'leading');
    expect(leading.text.style!.fontSize, 14.0);
    RenderParagraph title = _getTextRenderObject(tester, 'title');
    expect(title.text.style!.fontSize, 16.0);
    RenderParagraph subtitle = _getTextRenderObject(tester, 'subtitle');
    expect(subtitle.text.style!.fontSize, 14.0);
    RenderParagraph trailing = _getTextRenderObject(tester, 'trailing');
    expect(trailing.text.style!.fontSize, 14.0);

    // ListTile - Densed - ListTileStyle.list (default).
    await tester.pumpWidget(buildFrame(dense: true));
    await tester.pumpAndSettle();
    leading = _getTextRenderObject(tester, 'leading');
    expect(leading.text.style!.fontSize, 14.0);
    title = _getTextRenderObject(tester, 'title');
    expect(title.text.style!.fontSize, 13.0);
    subtitle = _getTextRenderObject(tester, 'subtitle');
    expect(subtitle.text.style!.fontSize, 12.0);
    trailing = _getTextRenderObject(tester, 'trailing');
    expect(trailing.text.style!.fontSize, 14.0);

    // ListTile - ListTileStyle.drawer.
    await tester.pumpWidget(buildFrame(style: ListTileStyle.drawer));
    await tester.pumpAndSettle();
    leading = _getTextRenderObject(tester, 'leading');
    expect(leading.text.style!.fontSize, 14.0);
    title = _getTextRenderObject(tester, 'title');
    expect(title.text.style!.fontSize, 14.0);
    subtitle = _getTextRenderObject(tester, 'subtitle');
    expect(subtitle.text.style!.fontSize, 14.0);
    trailing = _getTextRenderObject(tester, 'trailing');
    expect(trailing.text.style!.fontSize, 14.0);

    // ListTile - Densed - ListTileStyle.drawer.
    await tester.pumpWidget(buildFrame(dense: true, style: ListTileStyle.drawer));
    await tester.pumpAndSettle();
    leading = _getTextRenderObject(tester, 'leading');
    expect(leading.text.style!.fontSize, 14.0);
    title = _getTextRenderObject(tester, 'title');
    expect(title.text.style!.fontSize, 13.0);
    subtitle = _getTextRenderObject(tester, 'subtitle');
    expect(subtitle.text.style!.fontSize, 12.0);
    trailing = _getTextRenderObject(tester, 'trailing');
    expect(trailing.text.style!.fontSize, 14.0);
  });

  testWidgets('ListTile text color', (WidgetTester tester) async {
    Widget buildFrame({
      bool dense = false,
      bool enabled = true,
      bool selected = false,
      ListTileStyle? style,
    }) {
      return MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Material(
          child: Center(
            child: Builder(
              builder: (BuildContext context) {
                return ListTile(
                  dense: dense,
                  enabled: enabled,
                  selected: selected,
                  style: style,
                  leading: const TestText('leading'),
                  title: const TestText('title'),
                  subtitle: const TestText('subtitle') ,
                  trailing: const TestText('trailing'),
                );
              },
            ),
          ),
        ),
      );
    }

    final ThemeData theme = ThemeData();

    // ListTile - ListTileStyle.list (default).
    await tester.pumpWidget(buildFrame());
    RenderParagraph leading = _getTextRenderObject(tester, 'leading');
    expect(leading.text.style!.color, theme.textTheme.bodyMedium!.color);
    RenderParagraph title = _getTextRenderObject(tester, 'title');
    expect(title.text.style!.color, theme.textTheme.titleMedium!.color);
    RenderParagraph subtitle = _getTextRenderObject(tester, 'subtitle');
    expect(subtitle.text.style!.color, theme.textTheme.bodySmall!.color);
    RenderParagraph trailing = _getTextRenderObject(tester, 'trailing');
    expect(trailing.text.style!.color, theme.textTheme.bodyMedium!.color);

    // ListTile - ListTileStyle.drawer.
    await tester.pumpWidget(buildFrame(style: ListTileStyle.drawer));
    await tester.pumpAndSettle();
    leading = _getTextRenderObject(tester, 'leading');
    expect(leading.text.style!.color, theme.textTheme.bodyMedium!.color);
    title = _getTextRenderObject(tester, 'title');
    expect(title.text.style!.color, theme.textTheme.bodyLarge!.color);
    subtitle = _getTextRenderObject(tester, 'subtitle');
    expect(subtitle.text.style!.color, theme.textTheme.bodySmall!.color);
    trailing = _getTextRenderObject(tester, 'trailing');
    expect(trailing.text.style!.color, theme.textTheme.bodyMedium!.color);
  });

  testWidgets('Default ListTile debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const ListTile().debugFillProperties(builder);

    final List<String> description = builder.properties
      .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
      .map((DiagnosticsNode node) => node.toString())
      .toList();

    expect(description, <String>[]);
  });

  testWidgets('ListTile implements debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const ListTile(
      leading: Text('leading'),
      title: Text('title'),
      subtitle: Text('trailing'),
      trailing: Text('trailing'),
      isThreeLine: true,
      dense: true,
      visualDensity: VisualDensity.standard,
      shape: RoundedRectangleBorder(),
      style: ListTileStyle.list,
      selectedColor: Color(0xff0000ff),
      iconColor: Color(0xff00ff00),
      textColor: Color(0xffff0000),
      contentPadding: EdgeInsets.zero,
      enabled: false,
      selected: true,
      focusColor: Color(0xff00ffff),
      hoverColor: Color(0xff0000ff),
      autofocus: true,
      tileColor: Color(0xffffff00),
      selectedTileColor: Color(0xff123456),
      enableFeedback: false,
      horizontalTitleGap: 4.0,
      minVerticalPadding: 2.0,
      minLeadingWidth: 6.0,
    ).debugFillProperties(builder);

    final List<String> description = builder.properties
      .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
      .map((DiagnosticsNode node) => node.toString())
      .toList();

    expect(
      description,
      equalsIgnoringHashCodes(<String>[
        'leading: Text',
        'title: Text',
        'subtitle: Text',
        'trailing: Text',
        'isThreeLine: THREE_LINE',
        'dense: true',
        'visualDensity: VisualDensity#00000(h: 0.0, v: 0.0)',
        'shape: RoundedRectangleBorder(BorderSide(width: 0.0, style: none), BorderRadius.zero)',
        'style: ListTileStyle.list',
        'selectedColor: Color(0xff0000ff)',
        'iconColor: Color(0xff00ff00)',
        'textColor: Color(0xffff0000)',
        'contentPadding: EdgeInsets.zero',
        'enabled: false',
        'selected: true',
        'focusColor: Color(0xff00ffff)',
        'hoverColor: Color(0xff0000ff)',
        'autofocus: true',
        'tileColor: Color(0xffffff00)',
        'selectedTileColor: Color(0xff123456)',
        'enableFeedback: false',
        'horizontalTitleGap: 4.0',
        'minVerticalPadding: 2.0',
        'minLeadingWidth: 6.0',
      ]),
    );
  });

  group('Material 2', () {
    // Tests that are only relevant for Material 2. Once ThemeData.useMaterial3
    // is turned on by default, these tests can be removed.

    testWidgets('ListTile font size', (WidgetTester tester) async {
      Widget buildFrame({
        bool dense = false,
        bool enabled = true,
        bool selected = false,
        ListTileStyle? style,
      }) {
        return MaterialApp(
          home: Material(
            child: Center(
              child: Builder(
                builder: (BuildContext context) {
                  return ListTile(
                    dense: dense,
                    enabled: enabled,
                    selected: selected,
                    style: style,
                    leading: const TestText('leading'),
                    title: const TestText('title'),
                    subtitle: const TestText('subtitle') ,
                    trailing: const TestText('trailing'),
                  );
                },
              ),
            ),
          ),
        );
      }

      // ListTile - ListTileStyle.list (default).
      await tester.pumpWidget(buildFrame());
      RenderParagraph leading = _getTextRenderObject(tester, 'leading');
      expect(leading.text.style!.fontSize, 14.0);
      RenderParagraph title = _getTextRenderObject(tester, 'title');
      expect(title.text.style!.fontSize, 16.0);
      RenderParagraph subtitle = _getTextRenderObject(tester, 'subtitle');
      expect(subtitle.text.style!.fontSize, 14.0);
      RenderParagraph trailing = _getTextRenderObject(tester, 'trailing');
      expect(trailing.text.style!.fontSize, 14.0);

      // ListTile - Densed - ListTileStyle.list (default).
      await tester.pumpWidget(buildFrame(dense: true));
      await tester.pumpAndSettle();
      leading = _getTextRenderObject(tester, 'leading');
      expect(leading.text.style!.fontSize, 14.0);
      title = _getTextRenderObject(tester, 'title');
      expect(title.text.style!.fontSize, 13.0);
      subtitle = _getTextRenderObject(tester, 'subtitle');
      expect(subtitle.text.style!.fontSize, 12.0);
      trailing = _getTextRenderObject(tester, 'trailing');
      expect(trailing.text.style!.fontSize, 14.0);

      // ListTile - ListTileStyle.drawer.
      await tester.pumpWidget(buildFrame(style: ListTileStyle.drawer));
      await tester.pumpAndSettle();
      leading = _getTextRenderObject(tester, 'leading');
      expect(leading.text.style!.fontSize, 14.0);
      title = _getTextRenderObject(tester, 'title');
      expect(title.text.style!.fontSize, 14.0);
      subtitle = _getTextRenderObject(tester, 'subtitle');
      expect(subtitle.text.style!.fontSize, 14.0);
      trailing = _getTextRenderObject(tester, 'trailing');
      expect(trailing.text.style!.fontSize, 14.0);

      // ListTile - Densed - ListTileStyle.drawer.
      await tester.pumpWidget(buildFrame(dense: true, style: ListTileStyle.drawer));
      await tester.pumpAndSettle();
      leading = _getTextRenderObject(tester, 'leading');
      expect(leading.text.style!.fontSize, 14.0);
      title = _getTextRenderObject(tester, 'title');
      expect(title.text.style!.fontSize, 13.0);
      subtitle = _getTextRenderObject(tester, 'subtitle');
      expect(subtitle.text.style!.fontSize, 12.0);
      trailing = _getTextRenderObject(tester, 'trailing');
      expect(trailing.text.style!.fontSize, 14.0);
    });

    testWidgets('ListTile text color', (WidgetTester tester) async {
      Widget buildFrame({
        bool dense = false,
        bool enabled = true,
        bool selected = false,
        ListTileStyle? style,
      }) {
        return MaterialApp(
          home: Material(
            child: Center(
              child: Builder(
                builder: (BuildContext context) {
                  return ListTile(
                    dense: dense,
                    enabled: enabled,
                    selected: selected,
                    style: style,
                    leading: const TestText('leading'),
                    title: const TestText('title'),
                    subtitle: const TestText('subtitle') ,
                    trailing: const TestText('trailing'),
                  );
                },
              ),
            ),
          ),
        );
      }

      final ThemeData theme = ThemeData();

      // ListTile - ListTileStyle.list (default).
      await tester.pumpWidget(buildFrame());
      RenderParagraph leading = _getTextRenderObject(tester, 'leading');
      expect(leading.text.style!.color, theme.textTheme.bodyMedium!.color);
      RenderParagraph title = _getTextRenderObject(tester, 'title');
      expect(title.text.style!.color, theme.textTheme.titleMedium!.color);
      RenderParagraph subtitle = _getTextRenderObject(tester, 'subtitle');
      expect(subtitle.text.style!.color, theme.textTheme.bodySmall!.color);
      RenderParagraph trailing = _getTextRenderObject(tester, 'trailing');
      expect(trailing.text.style!.color, theme.textTheme.bodyMedium!.color);

      // ListTile - ListTileStyle.drawer.
      await tester.pumpWidget(buildFrame(style: ListTileStyle.drawer));
      await tester.pumpAndSettle();
      leading = _getTextRenderObject(tester, 'leading');
      expect(leading.text.style!.color, theme.textTheme.bodyMedium!.color);
      title = _getTextRenderObject(tester, 'title');
      expect(title.text.style!.color, theme.textTheme.titleMedium!.color);
      subtitle = _getTextRenderObject(tester, 'subtitle');
      expect(subtitle.text.style!.color, theme.textTheme.bodySmall!.color);
      trailing = _getTextRenderObject(tester, 'trailing');
      expect(trailing.text.style!.color, theme.textTheme.bodyMedium!.color);
    });
  });
}

RenderParagraph _getTextRenderObject(WidgetTester tester, String text) {
  return tester.renderObject(find.descendant(
    of: find.byType(ListTile),
    matching: find.text(text),
  ));
}
