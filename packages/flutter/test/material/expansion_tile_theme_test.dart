// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

class TestIcon extends StatefulWidget {
  const TestIcon({super.key});

  @override
  TestIconState createState() => TestIconState();
}

class TestIconState extends State<TestIcon> {
  late IconThemeData iconTheme;

  @override
  Widget build(BuildContext context) {
    iconTheme = IconTheme.of(context);
    return const Icon(Icons.expand_more);
  }
}
class TestText extends StatefulWidget {
  const TestText(this.text, {super.key});

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
  test('ExpansionTileThemeData copyWith, ==, hashCode basics', () {
    expect(const ExpansionTileThemeData(), const ExpansionTileThemeData().copyWith());
    expect(const ExpansionTileThemeData().hashCode, const ExpansionTileThemeData().copyWith().hashCode);
  });

  test('ExpansionTileThemeData lerp special cases', () {
    expect(ExpansionTileThemeData.lerp(null, null, 0), null);
    const ExpansionTileThemeData data = ExpansionTileThemeData();
    expect(identical(ExpansionTileThemeData.lerp(data, data, 0.5), data), true);
  });

  test('ExpansionTileThemeData defaults', () {
    const ExpansionTileThemeData theme = ExpansionTileThemeData();
    expect(theme.backgroundColor, null);
    expect(theme.collapsedBackgroundColor, null);
    expect(theme.tilePadding, null);
    expect(theme.expandedAlignment, null);
    expect(theme.childrenPadding, null);
    expect(theme.iconColor, null);
    expect(theme.collapsedIconColor, null);
    expect(theme.textColor, null);
    expect(theme.collapsedTextColor, null);
    expect(theme.shape, null);
    expect(theme.collapsedShape, null);
    expect(theme.clipBehavior, null);
  });

  testWidgetsWithLeakTracking('Default ExpansionTileThemeData debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const TooltipThemeData().debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(description, <String>[]);
  });

  testWidgetsWithLeakTracking('ExpansionTileThemeData implements debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const ExpansionTileThemeData(
      backgroundColor: Color(0xff000000),
      collapsedBackgroundColor: Color(0xff6f83fc),
      tilePadding: EdgeInsets.all(20.0),
      expandedAlignment: Alignment.bottomCenter,
      childrenPadding: EdgeInsets.all(10.0),
      iconColor: Color(0xffa7c61c),
      collapsedIconColor: Color(0xffdd0b1f),
      textColor: Color(0xffffffff),
      collapsedTextColor: Color(0xff522bab),
      shape: Border(),
      collapsedShape: Border(),
      clipBehavior: Clip.antiAlias,
    ).debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(description, <String>[
      'backgroundColor: Color(0xff000000)',
      'collapsedBackgroundColor: Color(0xff6f83fc)',
      'tilePadding: EdgeInsets.all(20.0)',
      'expandedAlignment: Alignment.bottomCenter',
      'childrenPadding: EdgeInsets.all(10.0)',
      'iconColor: Color(0xffa7c61c)',
      'collapsedIconColor: Color(0xffdd0b1f)',
      'textColor: Color(0xffffffff)',
      'collapsedTextColor: Color(0xff522bab)',
      'shape: Border.all(BorderSide(width: 0.0, style: none))',
      'collapsedShape: Border.all(BorderSide(width: 0.0, style: none))',
      'clipBehavior: Clip.antiAlias',
    ]);
  });

  testWidgetsWithLeakTracking('ExpansionTileTheme - collapsed', (WidgetTester tester) async {
    final Key tileKey = UniqueKey();
    final Key titleKey = UniqueKey();
    final Key iconKey = UniqueKey();
    const Color backgroundColor = Colors.orange;
    const Color collapsedBackgroundColor = Colors.red;
    const Color iconColor = Colors.green;
    const Color collapsedIconColor = Colors.blue;
    const Color textColor = Colors.black;
    const Color collapsedTextColor = Colors.white;
    const ShapeBorder shape = Border(
      top: BorderSide(color: Colors.red),
      bottom: BorderSide(color: Colors.red),
    );
    const ShapeBorder collapsedShape = Border(
      top: BorderSide(color: Colors.green),
      bottom: BorderSide(color: Colors.green),
    );
    const Clip clipBehavior = Clip.antiAlias;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          expansionTileTheme: const ExpansionTileThemeData(
            backgroundColor: backgroundColor,
            collapsedBackgroundColor: collapsedBackgroundColor,
            tilePadding: EdgeInsets.fromLTRB(8, 12, 4, 10),
            expandedAlignment: Alignment.centerRight,
            childrenPadding: EdgeInsets.all(20.0),
            iconColor: iconColor,
            collapsedIconColor: collapsedIconColor,
            textColor: textColor,
            collapsedTextColor: collapsedTextColor,
            shape: shape,
            collapsedShape: collapsedShape,
            clipBehavior: clipBehavior,
          ),
        ),
        home: Material(
          child: Center(
            child: ExpansionTile(
              key: tileKey,
              title: TestText('Collapsed Tile', key: titleKey),
              trailing: TestIcon(key: iconKey),
              children: const <Widget>[Text('Tile 1')],
            ),
          ),
        ),
      ),
    );

    final ShapeDecoration shapeDecoration =  tester.firstWidget<Container>(find.descendant(
      of: find.byKey(tileKey),
      matching: find.byType(Container),
    )).decoration! as ShapeDecoration;

    final Clip tileClipBehavior = tester.firstWidget<Container>(find.descendant(
      of: find.byKey(tileKey),
      matching: find.byType(Container),
    )).clipBehavior;

    // expansionTile should have Clip.antiAlias as clipBehavior
    expect(tileClipBehavior, clipBehavior);

    // Check the tile's collapsed background color when collapsedBackgroundColor is applied.
    expect(shapeDecoration.color, collapsedBackgroundColor);

    final Rect titleRect = tester.getRect(find.text('Collapsed Tile'));
    final Rect trailingRect = tester.getRect(find.byIcon(Icons.expand_more));
    final Rect listTileRect = tester.getRect(find.byType(ListTile));
    final Rect tallerWidget = titleRect.height > trailingRect.height ? titleRect : trailingRect;

    // Check the positions of title and trailing Widgets, after padding is applied.
    expect(listTileRect.left, titleRect.left - 8);
    expect(listTileRect.right, trailingRect.right + 4);

    // Calculate the remaining height of ListTile from the default height.
    final double remainingHeight = 56 - tallerWidget.height;
    expect(listTileRect.top, tallerWidget.top - remainingHeight / 2 - 12);
    expect(listTileRect.bottom, tallerWidget.bottom + remainingHeight / 2 + 10);

    Color getIconColor() => tester.state<TestIconState>(find.byType(TestIcon)).iconTheme.color!;
    Color getTextColor() => tester.state<TestTextState>(find.byType(TestText)).textStyle.color!;

    // Check the collapsed icon color when iconColor is applied.
    expect(getIconColor(), collapsedIconColor);
    // Check the collapsed text color when textColor is applied.
    expect(getTextColor(), collapsedTextColor);
    // Check the collapsed ShapeBorder when shape is applied.
    expect(shapeDecoration.shape, collapsedShape);
  });

  testWidgetsWithLeakTracking('ExpansionTileTheme - expanded', (WidgetTester tester) async {
    final Key tileKey = UniqueKey();
    final Key titleKey = UniqueKey();
    final Key iconKey = UniqueKey();
    const Color backgroundColor = Colors.orange;
    const Color collapsedBackgroundColor = Colors.red;
    const Color iconColor = Colors.green;
    const Color collapsedIconColor = Colors.blue;
    const Color textColor = Colors.black;
    const Color collapsedTextColor = Colors.white;
    const ShapeBorder shape = Border(
      top: BorderSide(color: Colors.red),
      bottom: BorderSide(color: Colors.red),
    );
    const ShapeBorder collapsedShape = Border(
      top: BorderSide(color: Colors.green),
      bottom: BorderSide(color: Colors.green),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          expansionTileTheme: const ExpansionTileThemeData(
            backgroundColor: backgroundColor,
            collapsedBackgroundColor: collapsedBackgroundColor,
            tilePadding: EdgeInsets.fromLTRB(8, 12, 4, 10),
            expandedAlignment: Alignment.centerRight,
            childrenPadding: EdgeInsets.all(20.0),
            iconColor: iconColor,
            collapsedIconColor: collapsedIconColor,
            textColor: textColor,
            collapsedTextColor: collapsedTextColor,
            shape: shape,
            collapsedShape: collapsedShape,
          ),
        ),
        home: Material(
          child: Center(
            child: ExpansionTile(
              key: tileKey,
              initiallyExpanded: true,
              title: TestText('Expanded Tile', key: titleKey),
              trailing: TestIcon(key: iconKey),
              children: const <Widget>[Text('Tile 1')],
            ),
          ),
        ),
      ),
    );

    final ShapeDecoration shapeDecoration =  tester.firstWidget<Container>(find.descendant(
      of: find.byKey(tileKey),
      matching: find.byType(Container),
    )).decoration! as ShapeDecoration;
    // Check the tile's background color when backgroundColor is applied.
    expect(shapeDecoration.color, backgroundColor);

    final Rect titleRect = tester.getRect(find.text('Expanded Tile'));
    final Rect trailingRect = tester.getRect(find.byIcon(Icons.expand_more));
    final Rect listTileRect = tester.getRect(find.byType(ListTile));
    final Rect tallerWidget = titleRect.height > trailingRect.height ? titleRect : trailingRect;

    // Check the positions of title and trailing Widgets, after padding is applied.
    expect(listTileRect.left, titleRect.left - 8);
    expect(listTileRect.right, trailingRect.right + 4);

    // Calculate the remaining height of ListTile from the default height.
    final double remainingHeight = 56 - tallerWidget.height;
    expect(listTileRect.top, tallerWidget.top - remainingHeight / 2 - 12);
    expect(listTileRect.bottom, tallerWidget.bottom + remainingHeight / 2 + 10);

    Color getIconColor() => tester.state<TestIconState>(find.byType(TestIcon)).iconTheme.color!;
    Color getTextColor() => tester.state<TestTextState>(find.byType(TestText)).textStyle.color!;

    // Check the expanded icon color when iconColor is applied.
    expect(getIconColor(), iconColor);
    // Check the expanded text color when textColor is applied.
    expect(getTextColor(), textColor);
    // Check the expanded ShapeBorder when shape is applied.
    expect(shapeDecoration.shape, shape);

    // Check the child position when expandedAlignment is applied.
    final Rect childRect = tester.getRect(find.text('Tile 1'));
    expect(childRect.right, 800 - 20);
    expect(childRect.left, 800 - childRect.width - 20);

    // Check the child padding when childrenPadding is applied.
    final Rect paddingRect = tester.getRect(find.byType(Padding).last);
    expect(childRect.top, paddingRect.top + 20);
    expect(childRect.left, paddingRect.left + 20);
    expect(childRect.right, paddingRect.right - 20);
    expect(childRect.bottom, paddingRect.bottom - 20);
  });
}
