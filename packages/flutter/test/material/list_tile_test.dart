// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class TestIcon extends StatefulWidget {
  TestIcon({ Key key }) : super(key: key);

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
  TestText(this.text, { Key key }) : super(key: key);

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
  testWidgets('ListTile geometry', (WidgetTester tester) async {
    // See https://material.io/guidelines/components/lists.html

    bool hasSubtitle;

    Widget buildFrame({ bool dense: false, bool isTwoLine: false, bool isThreeLine: false }) {
      hasSubtitle = isTwoLine || isThreeLine;
      return new MaterialApp(
        home: new Material(
          child: new Center(
            child: new ListTile(
              leading: const Text('leading'),
              title: const Text('title'),
              subtitle: hasSubtitle ? const Text('subtitle') : null,
              trailing: const Text('trailing'),
              dense: dense,
              isThreeLine: isThreeLine,
            ),
          ),
        ),
      );
    }

    void testChildren() {
      expect(find.text('leading'), findsOneWidget);
      expect(find.text('title'), findsOneWidget);
      if (hasSubtitle)
        expect(find.text('subtitle'), findsOneWidget);
      expect(find.text('trailing'), findsOneWidget);
    }

    double left(String text) => tester.getTopLeft(find.text(text)).x;
    double right(String text) => tester.getTopRight(find.text(text)).x;
    double top(String text) => tester.getTopLeft(find.text(text)).y;
    double bottom(String text) => tester.getBottomLeft(find.text(text)).y;

    // 16.0 padding to the left and right of the leading and trailing widgets
    void testHorizontalGeometry() {
      expect(left('leading'), 16.0);
      expect(left('title'), 72.0);
      if (hasSubtitle)
        expect(left('subtitle'), 72.0);
      expect(left('title'), right('leading') + 16.0);
      expect(right('trailing'), 800.0 - 16.0);
    }

    void testVerticalGeometry(double expectedHeight) {
      expect(tester.getSize(find.byType(ListTile)), new Size(800.0, expectedHeight));
      if (hasSubtitle)
        expect(top('subtitle'), bottom('title'));
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
                    leading: new TestIcon(),
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

    Color iconColor() => tester.state<TestIconState>(find.byType(TestIcon)).iconTheme.color;
    Color textColor(Key key) => tester.state<TestTextState>(find.byKey(key)).textStyle.color;

    // A selected ListTile's leading and text get the primary color by default
    await(tester.pumpWidget(buildFrame(selected: true)));
    await(tester.pump(const Duration(milliseconds: 300))); // DefaultTextStyle changes animate
    expect(iconColor(), theme.primaryColor);
    expect(textColor(titleKey), theme.primaryColor);
    expect(textColor(subtitleKey), theme.primaryColor);

    // A selected ListTile's leading and text get the ListTileTheme's selectedColor
    await(tester.pumpWidget(buildFrame(selected: true, selectedColor: green)));
    await(tester.pump(const Duration(milliseconds: 300))); // DefaultTextStyle changes animate
    expect(iconColor(), green);
    expect(textColor(titleKey), green);
    expect(textColor(subtitleKey), green);

    // An unselected ListTile's leading icon gets the ListTileTheme's iconColor
    // An unselected ListTile's title texts get the ListTileTheme's textColor
    await(tester.pumpWidget(buildFrame(iconColor: red, textColor: green)));
    await(tester.pump(const Duration(milliseconds: 300))); // DefaultTextStyle changes animate
    expect(iconColor(), red);
    expect(textColor(titleKey), green);
    expect(textColor(subtitleKey), green);

    // If the item is disabled it's rendered with the theme's disabled color.
    await(tester.pumpWidget(buildFrame(enabled: false)));
    await(tester.pump(const Duration(milliseconds: 300)));  // DefaultTextStyle changes animate
    expect(iconColor(), theme.disabledColor);
    expect(textColor(titleKey), theme.disabledColor);
    expect(textColor(subtitleKey), theme.disabledColor);

    // If the item is disabled it's rendered with the theme's disabled color.
    // Even if it's selected.
    await(tester.pumpWidget(buildFrame(enabled: false, selected: true)));
    await(tester.pump(const Duration(milliseconds: 300)));  // DefaultTextStyle changes animate
    expect(iconColor(), theme.disabledColor);
    expect(textColor(titleKey), theme.disabledColor);
    expect(textColor(subtitleKey), theme.disabledColor);
  });

}
