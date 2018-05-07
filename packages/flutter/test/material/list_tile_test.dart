// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widgets/semantics_tester.dart';

class TestIcon extends StatefulWidget {
  const TestIcon({ Key key }) : super(key: key);

  @override
  TestIconState createState() => new TestIconState();
}

class TestIconState extends State<TestIcon> {
  IconThemeData iconTheme;

  @override
  Widget build(BuildContext context) {
    iconTheme = IconTheme.of(context);
    return const Icon(Icons.add);
  }
}

class TestText extends StatefulWidget {
  const TestText(this.text, { Key key }) : super(key: key);

  final String text;

  @override
  TestTextState createState() => new TestTextState();
}

class TestTextState extends State<TestText> {
  TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    textStyle = DefaultTextStyle.of(context).style;
    return new Text(widget.text);
  }
}

void main() {
  testWidgets('ListTile geometry (LTR)', (WidgetTester tester) async {
    // See https://material.io/go/design-lists

    final Key leadingKey = new GlobalKey();
    final Key trailingKey = new GlobalKey();
    bool hasSubtitle;

    const double leftPadding = 10.0;
    const double rightPadding = 20.0;
    Widget buildFrame({ bool dense: false, bool isTwoLine: false, bool isThreeLine: false, double textScaleFactor: 1.0 }) {
      hasSubtitle = isTwoLine || isThreeLine;
      return new MaterialApp(
        home: new MediaQuery(
          data: new MediaQueryData(
            padding: const EdgeInsets.only(left: leftPadding, right: rightPadding),
            textScaleFactor: textScaleFactor,
          ),
          child: new Material(
            child: new Center(
              child: new ListTile(
                leading: new Container(key: leadingKey, width: 24.0, height: 24.0),
                title: const Text('title'),
                subtitle: hasSubtitle ? const Text('subtitle') : null,
                trailing: new Container(key: trailingKey, width: 24.0, height: 24.0),
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
      if (hasSubtitle)
        expect(find.text('subtitle'), findsOneWidget);
      expect(find.byKey(trailingKey), findsOneWidget);
    }

    double left(String text) => tester.getTopLeft(find.text(text)).dx;
    double top(String text) => tester.getTopLeft(find.text(text)).dy;
    double bottom(String text) => tester.getBottomLeft(find.text(text)).dy;

    double leftKey(Key key) => tester.getTopLeft(find.byKey(key)).dx;
    double rightKey(Key key) => tester.getTopRight(find.byKey(key)).dx;
    double widthKey(Key key) => tester.getSize(find.byKey(key)).width;
    double heightKey(Key key) => tester.getSize(find.byKey(key)).height;


    // 16.0 padding to the left and right of the leading and trailing widgets
    // plus the media padding.
    void testHorizontalGeometry() {
      expect(leftKey(leadingKey), 16.0 + leftPadding);
      expect(left('title'), 72.0 + leftPadding);
      if (hasSubtitle)
        expect(left('subtitle'), 72.0 + leftPadding);
      expect(left('title'), rightKey(leadingKey) + 32.0);
      expect(rightKey(trailingKey), 800.0 - 16.0 - rightPadding);
      expect(widthKey(trailingKey), 24.0);
    }

    void testVerticalGeometry(double expectedHeight) {
      expect(tester.getSize(find.byType(ListTile)), new Size(800.0, expectedHeight));
      if (hasSubtitle)
        expect(top('subtitle'), bottom('title'));
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
    testVerticalGeometry(60.0);

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
    testVerticalGeometry(64.0);

    await tester.pumpWidget(buildFrame(dense: true, textScaleFactor: 4.0));
    testChildren();
    testHorizontalGeometry();
    testVerticalGeometry(64.0);

    await tester.pumpWidget(buildFrame(isTwoLine: true, textScaleFactor: 4.0));
    testChildren();
    testHorizontalGeometry();
    testVerticalGeometry(120.0);

    await tester.pumpWidget(buildFrame(isTwoLine: true, dense: true, textScaleFactor: 4.0));
    testChildren();
    testHorizontalGeometry();
    testVerticalGeometry(120.0);

    await tester.pumpWidget(buildFrame(isThreeLine: true, textScaleFactor: 4.0));
    testChildren();
    testHorizontalGeometry();
    testVerticalGeometry(120.0);

    await tester.pumpWidget(buildFrame(isThreeLine: true, dense: true, textScaleFactor: 4.0));
    testChildren();
    testHorizontalGeometry();
    testVerticalGeometry(120.0);
  });


  testWidgets('ListTile geometry (RTL)', (WidgetTester tester) async {
    const double leftPadding = 10.0;
    const double rightPadding = 20.0;
    await tester.pumpWidget(const MediaQuery(
      data: const MediaQueryData(
        padding: const EdgeInsets.only(left: leftPadding, right: rightPadding),
      ),
      child: const Directionality(
        textDirection: TextDirection.rtl,
        child: const Material(
          child: const Center(
            child: const ListTile(
              leading: const Text('leading'),
              title: const Text('title'),
              trailing: const Text('trailing'),
            ),
          ),
        ),
      ),
    ));

    double left(String text) => tester.getTopLeft(find.text(text)).dx;
    double right(String text) => tester.getTopRight(find.text(text)).dx;

    void testHorizontalGeometry() {
      expect(right('leading'), 800.0 - 16.0 - rightPadding);
      expect(right('title'), 800.0 - 72.0 - rightPadding);
      expect(left('leading') - right('title'), 16.0);
      expect(left('trailing'), 16.0 + leftPadding);
    }

    testHorizontalGeometry();
  });

  testWidgets('ListTile.divideTiles', (WidgetTester tester) async {
    final List<String> titles = <String>[ 'first', 'second', 'third' ];

    await tester.pumpWidget(new MaterialApp(
      home: new Material(
        child: new Builder(
          builder: (BuildContext context) {
            return new ListView(
              children: ListTile.divideTiles(
                context: context,
                tiles: titles.map((String title) => new ListTile(title: new Text(title))),
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

  testWidgets('ListTileTheme', (WidgetTester tester) async {
    final Key titleKey = new UniqueKey();
    final Key subtitleKey = new UniqueKey();
    final Key leadingKey = new UniqueKey();
    final Key trailingKey = new UniqueKey();
    ThemeData theme;

    Widget buildFrame({
      bool enabled: true,
      bool dense: false,
      bool selected: false,
      Color selectedColor,
      Color iconColor,
      Color textColor,
    }) {
      return new MaterialApp(
        home: new Material(
          child: new Center(
            child: new ListTileTheme(
              dense: dense,
              selectedColor: selectedColor,
              iconColor: iconColor,
              textColor: textColor,
              child: new Builder(
                builder: (BuildContext context) {
                  theme = Theme.of(context);
                  return new ListTile(
                    enabled: enabled,
                    selected: selected,
                    leading: new TestIcon(key: leadingKey),
                    trailing: new TestIcon(key: trailingKey),
                    title: new TestText('title', key: titleKey),
                    subtitle: new TestText('subtitle', key: subtitleKey),
                  );
                }
              ),
            ),
          ),
        ),
      );
    }

    const Color green = const Color(0xFF00FF00);
    const Color red = const Color(0xFFFF0000);

    Color iconColor(Key key) => tester.state<TestIconState>(find.byKey(key)).iconTheme.color;
    Color textColor(Key key) => tester.state<TestTextState>(find.byKey(key)).textStyle.color;

    // A selected ListTile's leading, trailing, and text get the primary color by default
    await tester.pumpWidget(buildFrame(selected: true));
    await tester.pump(const Duration(milliseconds: 300)); // DefaultTextStyle changes animate
    expect(iconColor(leadingKey), theme.primaryColor);
    expect(iconColor(trailingKey), theme.primaryColor);
    expect(textColor(titleKey), theme.primaryColor);
    expect(textColor(subtitleKey), theme.primaryColor);

    // A selected ListTile's leading, trailing, and text get the ListTileTheme's selectedColor
    await tester.pumpWidget(buildFrame(selected: true, selectedColor: green));
    await tester.pump(const Duration(milliseconds: 300)); // DefaultTextStyle changes animate
    expect(iconColor(leadingKey), green);
    expect(iconColor(trailingKey), green);
    expect(textColor(titleKey), green);
    expect(textColor(subtitleKey), green);

    // An unselected ListTile's leading and trailing get the ListTileTheme's iconColor
    // An unselected ListTile's title texts get the ListTileTheme's textColor
    await tester.pumpWidget(buildFrame(iconColor: red, textColor: green));
    await tester.pump(const Duration(milliseconds: 300)); // DefaultTextStyle changes animate
    expect(iconColor(leadingKey), red);
    expect(iconColor(trailingKey), red);
    expect(textColor(titleKey), green);
    expect(textColor(subtitleKey), green);

    // If the item is disabled it's rendered with the theme's disabled color.
    await tester.pumpWidget(buildFrame(enabled: false));
    await tester.pump(const Duration(milliseconds: 300)); // DefaultTextStyle changes animate
    expect(iconColor(leadingKey), theme.disabledColor);
    expect(iconColor(trailingKey), theme.disabledColor);
    expect(textColor(titleKey), theme.disabledColor);
    expect(textColor(subtitleKey), theme.disabledColor);

    // If the item is disabled it's rendered with the theme's disabled color.
    // Even if it's selected.
    await tester.pumpWidget(buildFrame(enabled: false, selected: true));
    await tester.pump(const Duration(milliseconds: 300)); // DefaultTextStyle changes animate
    expect(iconColor(leadingKey), theme.disabledColor);
    expect(iconColor(trailingKey), theme.disabledColor);
    expect(textColor(titleKey), theme.disabledColor);
    expect(textColor(subtitleKey), theme.disabledColor);
  });

  testWidgets('ListTile semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    await tester.pumpWidget(
      new Material(
        child: new Directionality(
          textDirection: TextDirection.ltr,
          child: new MediaQuery(
            data: const MediaQueryData(),
            child: new Column(
              children: const <Widget>[
                const ListTile(
                  title: const Text('one'),
                ),
                const ListTile(
                  title: const Text('two'),
                  selected: true,
                ),
                const ListTile(
                  title: const Text('three'),
                  enabled: false,
                ),
              ],
            ),
          ),
        )
      ),
    );

    expect(semantics, hasSemantics(
      new TestSemantics.root(
        children: <TestSemantics>[
          new TestSemantics.rootChild(
            label: 'one',
            flags: <SemanticsFlag>[
              SemanticsFlag.hasEnabledState,
              SemanticsFlag.isEnabled,
            ],
          ),
          new TestSemantics.rootChild(
            label: 'two',
            flags: <SemanticsFlag>[
              SemanticsFlag.isSelected,
              SemanticsFlag.hasEnabledState,
              SemanticsFlag.isEnabled,
            ],
          ),
          new TestSemantics.rootChild(
            label: 'three',
            flags: <SemanticsFlag>[
              SemanticsFlag.hasEnabledState,
            ],
          ),
        ]
      ),
      ignoreTransform: true, ignoreId: true, ignoreRect: true),
    );

    semantics.dispose();
  });
}
